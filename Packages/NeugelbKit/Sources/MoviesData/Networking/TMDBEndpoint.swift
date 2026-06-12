import Foundation

/// Typed catalog of the TMDB endpoints this app uses.
public enum TMDBEndpoint: Equatable, Sendable {
    case nowPlaying(page: Int)
    case movieDetails(id: Int)
    case searchMovies(query: String, page: Int)

    var path: String {
        switch self {
        case .nowPlaying:
            return "movie/now_playing"
        case .movieDetails(let id):
            return "movie/\(id)"
        case .searchMovies:
            return "search/movie"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .nowPlaying(let page):
            return [URLQueryItem(name: "page", value: String(page))]
        case .movieDetails:
            return []
        case .searchMovies(let query, let page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "page", value: String(page)),
            ]
        }
    }

    /// Builds the request with TMDB v4 bearer authentication.
    public func urlRequest(configuration: TMDBConfiguration, accessToken: String) -> URLRequest {
        var components = URLComponents(
            url: configuration.apiBaseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = queryItems + [
            URLQueryItem(name: "language", value: configuration.language)
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
