import Foundation

/// Typed catalog of the TMDB endpoints this app uses. Conforms to the generic
/// `Endpoint`, so adding a write endpoint is just a new case that overrides
/// `method`/`body` — for example:
///
/// ```swift
/// case rateMovie(id: Int, value: Double)
/// // method -> .post, body -> try? .json(["value": value])
/// ```
///
/// Cross-cutting concerns (bearer auth, `language`) are injected by
/// `TMDBAPIClient`, not encoded here.
enum TMDBEndpoint: Equatable, Sendable {
    case nowPlaying(page: Int)
    case movieDetails(id: Int)
    case searchMovies(query: String, page: Int)
}

extension TMDBEndpoint: Endpoint {
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
            // One round-trip pulls cast and trailers alongside the movie.
            return [URLQueryItem(name: "append_to_response", value: "credits,videos")]
        case .searchMovies(let query, let page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "page", value: String(page)),
            ]
        }
    }

    // method/headers/body inherit the GET defaults from `Endpoint`.
}
