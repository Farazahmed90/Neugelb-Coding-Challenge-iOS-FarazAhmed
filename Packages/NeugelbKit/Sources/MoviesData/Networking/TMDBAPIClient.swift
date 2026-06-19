import Foundation

/// Executes typed TMDB requests: auth header injection, status validation,
/// JSON decoding, and normalization of failures into `APIError`. Retries
/// transient failures (network drops, 5xx) on idempotent endpoints.
public struct TMDBAPIClient: Sendable {
    private let httpClient: any HTTPClient
    private let tokenProvider: any AccessTokenProviding
    private let configuration: TMDBConfiguration
    private let decoder: JSONDecoder
    private let maxRetryCount: Int
    private let retryBaseDelay: Duration

    public init(
        httpClient: any HTTPClient,
        tokenProvider: any AccessTokenProviding,
        configuration: TMDBConfiguration,
        maxRetryCount: Int = 2,
        retryBaseDelay: Duration = .milliseconds(300)
    ) {
        self.httpClient = httpClient
        self.tokenProvider = tokenProvider
        self.configuration = configuration
        self.maxRetryCount = maxRetryCount
        self.retryBaseDelay = retryBaseDelay

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func request<Response: Decodable & Sendable>(
        _ endpoint: some Endpoint
    ) async throws -> Response {
        let canRetry = endpoint.method.isIdempotent
        var attempt = 0
        while true {
            do {
                return try await perform(endpoint)
            } catch let error as APIError where canRetry && error.isRetryable && attempt < maxRetryCount {
                attempt += 1
                // Exponential backoff: base, 2×base, 4×base…
                try await Task.sleep(for: retryBaseDelay * (1 << (attempt - 1)))
            }
        }
    }

    private func perform<Response: Decodable & Sendable>(
        _ endpoint: some Endpoint
    ) async throws -> Response {
        let token = try await tokenProvider.accessToken()
        let urlRequest = endpoint.urlRequest(
            baseURL: configuration.apiBaseURL,
            defaultQueryItems: [
                URLQueryItem(name: "language", value: configuration.language)
            ],
            defaultHeaders: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json",
            ]
        )

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await httpClient.data(for: urlRequest)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            // Report cancellation as cancellation, not a network error, so view
            // models can ignore it.
            throw CancellationError()
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(underlying: error)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw APIError.unacceptableStatus(code: response.statusCode)
        }

        // Endpoints that return no body (e.g. 204) ask for `EmptyResponse`.
        if let empty = EmptyResponse() as? Response {
            return empty
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(underlying: error)
        }
    }
}
