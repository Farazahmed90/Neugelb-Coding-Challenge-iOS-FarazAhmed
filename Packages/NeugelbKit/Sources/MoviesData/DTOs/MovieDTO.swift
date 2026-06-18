import Foundation
import MoviesDomain

/// A movie as it appears in TMDB list and search responses.
struct MovieDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let voteCount: Int?
}

extension MovieDTO {
    func toDomain() -> Movie {
        Movie(
            id: id,
            title: title,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: TMDBDateParser.date(from: releaseDate),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0
        )
    }
}
