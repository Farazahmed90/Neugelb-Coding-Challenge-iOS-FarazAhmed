import Foundation

/// Executes typed TMDB requests: auth header injection, status validation,
/// JSON decoding, and normalization of failures into `APIError`.
public struct TMDBAPIClient: Sendable {
    private let httpClient: any HTTPClient
    private let tokenProvider: any AccessTokenProviding
    private let configuration: TMDBConfiguration
    private let decoder: JSONDecoder

    public init(
        httpClient: any HTTPClient,
        tokenProvider: any AccessTokenProviding,
        configuration: TMDBConfiguration
    ) {
        self.httpClient = httpClient
        self.tokenProvider = tokenProvider
        self.configuration = configuration

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func request<Response: Decodable & Sendable>(
        _ endpoint: TMDBEndpoint
    ) async throws -> Response {
        let token = try await tokenProvider.accessToken()
        let urlRequest = endpoint.urlRequest(configuration: configuration, accessToken: token)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await httpClient.data(for: urlRequest)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            // Surface cancellation as cancellation, never as a user-facing
            // network error, so view models can ignore it cleanly.
            throw CancellationError()
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(underlying: error)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw APIError.unacceptableStatus(code: response.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(underlying: error)
        }
    }
}
