import Foundation
import MoviesData
import Testing

struct TMDBAPIClientTests {
    private struct Probe: Decodable, Sendable, Equatable {
        let id: Int
    }

    @Test func decodesSuccessfulResponse() async throws {
        let http = HTTPClientMock(.success(data: Data(#"{"id": 7}"#.utf8), statusCode: 200))
        let client = TMDBAPIClient(
            httpClient: http, tokenProvider: StaticTokenProvider(), configuration: .test
        )

        let probe: Probe = try await client.request(TMDBEndpoint.nowPlaying(page: 1))
        #expect(probe == Probe(id: 7))
    }

    @Test func injectsBearerAuthAcceptAndLanguage() async throws {
        let http = HTTPClientMock(.success(data: Data(#"{"id": 1}"#.utf8), statusCode: 200))
        let client = TMDBAPIClient(
            httpClient: http,
            tokenProvider: StaticTokenProvider(token: "secret-token"),
            configuration: .test
        )

        let _: Probe = try await client.request(TMDBEndpoint.nowPlaying(page: 1))

        let request = try #require(await http.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")

        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(items.contains(URLQueryItem(name: "language", value: "en-US")))
    }

    @Test(arguments: [401, 404, 500])
    func failsOnUnacceptableStatus(statusCode: Int) async {
        let http = HTTPClientMock(.success(data: Data(), statusCode: statusCode))
        let client = TMDBAPIClient(
            httpClient: http, tokenProvider: StaticTokenProvider(), configuration: .test
        )

        await #expect {
            let _: Probe = try await client.request(TMDBEndpoint.nowPlaying(page: 1))
        } throws: { error in
            guard case APIError.unacceptableStatus(let code) = error else { return false }
            return code == statusCode
        }
    }

    @Test func wrapsTransportFailures() async {
        let http = HTTPClientMock(.failure(URLError(.notConnectedToInternet)))
        let client = TMDBAPIClient(
            httpClient: http, tokenProvider: StaticTokenProvider(), configuration: .test
        )

        await #expect {
            let _: Probe = try await client.request(TMDBEndpoint.nowPlaying(page: 1))
        } throws: { error in
            guard case APIError.transport = error else { return false }
            return true
        }
    }

    @Test func surfacesCancellationAsCancellationError() async {
        let http = HTTPClientMock(.failure(URLError(.cancelled)))
        let client = TMDBAPIClient(
            httpClient: http, tokenProvider: StaticTokenProvider(), configuration: .test
        )

        await #expect {
            let _: Probe = try await client.request(TMDBEndpoint.nowPlaying(page: 1))
        } throws: { error in
            error is CancellationError
        }
    }

    @Test func wrapsDecodingFailures() async {
        let http = HTTPClientMock(.success(data: Data("not json".utf8), statusCode: 200))
        let client = TMDBAPIClient(
            httpClient: http, tokenProvider: StaticTokenProvider(), configuration: .test
        )

        await #expect {
            let _: Probe = try await client.request(TMDBEndpoint.nowPlaying(page: 1))
        } throws: { error in
            guard case APIError.decoding = error else { return false }
            return true
        }
    }

    @Test func retryabilityClassification() {
        #expect(APIError.transport(underlying: URLError(.timedOut)).isRetryable)
        #expect(APIError.unacceptableStatus(code: 503).isRetryable)
        #expect(!APIError.unacceptableStatus(code: 404).isRetryable)
        #expect(!APIError.missingCredentials.isRetryable)
    }
}
