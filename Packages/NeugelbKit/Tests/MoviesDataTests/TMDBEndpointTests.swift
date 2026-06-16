import Foundation
import MoviesData
import Testing

struct TMDBEndpointTests {
    private let baseURL = TMDBConfiguration.test.apiBaseURL

    private func components(of request: URLRequest) -> URLComponents {
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
    }

    @Test func nowPlayingRequest() {
        let request = TMDBEndpoint.nowPlaying(page: 2).urlRequest(baseURL: baseURL)
        let components = components(of: request)

        #expect(components.path == "/3/movie/now_playing")
        #expect(components.queryItems!.contains(URLQueryItem(name: "page", value: "2")))
        #expect(request.httpMethod == "GET")
    }

    @Test func movieDetailsRequest() {
        let request = TMDBEndpoint.movieDetails(id: 278).urlRequest(baseURL: baseURL)

        #expect(components(of: request).path == "/3/movie/278")
    }

    @Test func searchRequestEncodesQueryAndExcludesAdult() {
        let request = TMDBEndpoint
            .searchMovies(query: "fight club & friends", page: 1)
            .urlRequest(baseURL: baseURL)
        let items = components(of: request).queryItems!

        #expect(items.contains(URLQueryItem(name: "query", value: "fight club & friends")))
        #expect(items.contains(URLQueryItem(name: "include_adult", value: "false")))
        #expect(items.contains(URLQueryItem(name: "page", value: "1")))
    }

    // MARK: - Generic builder

    /// A GET that overrides nothing, so it uses all the protocol defaults.
    private struct SimpleGet: Endpoint {
        let path: String
    }

    /// A write endpoint with a method, a custom header, and a JSON body.
    private struct CreateThing: Endpoint {
        let name: String
        var path: String { "things" }
        var method: HTTPMethod { .post }
        var headers: [String: String] { ["X-Trace": "abc"] }
        var body: HTTPBody? { try? .json(["name": name]) }
    }

    @Test func defaultsProduceASimpleGet() {
        let request = SimpleGet(path: "ping").urlRequest(baseURL: baseURL)

        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
        #expect(components(of: request).path == "/3/ping")
    }

    @Test func writeEndpointCarriesMethodHeadersAndJSONBody() throws {
        let request = CreateThing(name: "widget").urlRequest(baseURL: baseURL)

        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "X-Trace") == "abc")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let payload = try JSONDecoder().decode([String: String].self, from: request.httpBody!)
        #expect(payload == ["name": "widget"])
    }

    @Test func defaultsMergeAndEndpointHeadersWin() {
        let endpoint = CreateThing(name: "widget")
        let request = endpoint.urlRequest(
            baseURL: baseURL,
            defaultQueryItems: [URLQueryItem(name: "language", value: "en-US")],
            defaultHeaders: ["X-Trace": "default", "Accept": "application/json"]
        )

        // Client default applied...
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(
            components(of: request).queryItems!
                .contains(URLQueryItem(name: "language", value: "en-US"))
        )
        // ...but the endpoint's own header overrides the default.
        #expect(request.value(forHTTPHeaderField: "X-Trace") == "abc")
    }
}
