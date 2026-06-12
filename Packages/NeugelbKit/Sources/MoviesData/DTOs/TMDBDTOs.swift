import Foundation
import MoviesDomain

// MARK: - Wire types
// Mirror TMDB's JSON exactly (after snake_case conversion) and stay
// internal to the data layer; the rest of the app sees domain types only.

struct PageDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let results: [Item]
    let totalPages: Int
}

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

struct MovieDetailsDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let overview: String?
    let tagline: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int?
    let genres: [GenreDTO]?
    let voteAverage: Double?
    let voteCount: Int?
}

struct GenreDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

// MARK: - Mapping to domain

extension PageDTO where Item == MovieDTO {
    func toDomain() -> Page<Movie> {
        Page(
            items: results.map { $0.toDomain() },
            pageNumber: page,
            totalPages: totalPages
        )
    }
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

extension MovieDetailsDTO {
    func toDomain() -> MovieDetails {
        MovieDetails(
            id: id,
            title: title,
            overview: overview ?? "",
            tagline: tagline.flatMap { $0.isEmpty ? nil : $0 },
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: TMDBDateParser.date(from: releaseDate),
            runtimeMinutes: runtime.flatMap { $0 > 0 ? $0 : nil },
            genres: (genres ?? []).map { Genre(id: $0.id, name: $0.name) },
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0
        )
    }
}

/// TMDB dates are "yyyy-MM-dd" strings and occasionally empty.
enum TMDBDateParser {
    private static let calendar = Calendar(identifier: .gregorian)

    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.timeZone = TimeZone(identifier: "UTC")
        return calendar.date(from: components)
    }
}
