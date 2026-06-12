import Foundation
import MoviesData
import Testing

struct TMDBEndpointTests {
    private func components(of request: URLRequest) -> URLComponents {
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
    }

    @Test func nowPlayingRequest() {
        let request = TMDBEndpoint.nowPlaying(page: 2)
            .urlRequest(configuration: .test, accessToken: "abc")
        let components = components(of: request)

        #expect(components.path == "/3/movie/now_playing")
        #expect(components.queryItems!.contains(URLQueryItem(name: "page", value: "2")))
        #expect(components.queryItems!.contains(URLQueryItem(name: "language", value: "en-US")))
    }

    @Test func movieDetailsRequest() {
        let request = TMDBEndpoint.movieDetails(id: 278)
            .urlRequest(configuration: .test, accessToken: "abc")

        #expect(components(of: request).path == "/3/movie/278")
    }

    @Test func searchRequestEncodesQueryAndExcludesAdult() {
        let request = TMDBEndpoint.searchMovies(query: "fight club & friends", page: 1)
            .urlRequest(configuration: .test, accessToken: "abc")
        let items = components(of: request).queryItems!

        #expect(items.contains(URLQueryItem(name: "query", value: "fight club & friends")))
        #expect(items.contains(URLQueryItem(name: "include_adult", value: "false")))
        #expect(items.contains(URLQueryItem(name: "page", value: "1")))
    }

    @Test func requestCarriesBearerAuthAndAcceptHeaders() {
        let request = TMDBEndpoint.nowPlaying(page: 1)
            .urlRequest(configuration: .test, accessToken: "secret-token")

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.httpMethod == "GET")
    }
}
