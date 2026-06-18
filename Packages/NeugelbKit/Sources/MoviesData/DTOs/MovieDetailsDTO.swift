import Foundation
import MoviesDomain

/// Full movie details from TMDB, with `credits` and `videos` folded in via
/// `append_to_response`. Mirrors the JSON after snake_case conversion and stays
/// internal to the data layer; the rest of the app sees domain types only.
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
    let status: String?
    let originalLanguage: String?
    let budget: Int?
    let revenue: Int?
    let productionCompanies: [ProductionCompanyDTO]?
    // Folded in via append_to_response=credits,videos.
    let credits: CreditsDTO?
    let videos: VideoListDTO?
}

// MARK: - Nested wire types

struct GenreDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

struct ProductionCompanyDTO: Decodable, Sendable {
    let name: String
}

struct CreditsDTO: Decodable, Sendable {
    let cast: [CastMemberDTO]?
}

struct CastMemberDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let character: String?
    let profilePath: String?
    let order: Int?
}

struct VideoListDTO: Decodable, Sendable {
    let results: [VideoDTO]?
}

struct VideoDTO: Decodable, Sendable {
    let key: String
    let site: String?
    let type: String?
    let official: Bool?
}

// MARK: - Mapping to domain

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
            voteCount: voteCount ?? 0,
            status: status.flatMap { $0.isEmpty ? nil : $0 },
            originalLanguage: originalLanguage.flatMap { $0.isEmpty ? nil : $0 },
            budget: budget.flatMap { $0 > 0 ? $0 : nil },
            revenue: revenue.flatMap { $0 > 0 ? $0 : nil },
            productionCompanies: (productionCompanies ?? []).map(\.name),
            cast: mappedCast(),
            trailerYouTubeID: bestTrailerKey()
        )
    }

    /// Top 12 billed cast, in TMDB's `order`, dropping anyone without a name.
    private func mappedCast() -> [CastMember] {
        let members = credits?.cast ?? []
        return members
            .sorted { ($0.order ?? .max) < ($1.order ?? .max) }
            .prefix(12)
            .compactMap { dto in
                guard let name = dto.name, !name.isEmpty else { return nil }
                return CastMember(
                    id: dto.id,
                    name: name,
                    character: dto.character.flatMap { $0.isEmpty ? nil : $0 },
                    profilePath: dto.profilePath
                )
            }
    }

    /// Prefer an official YouTube trailer, then any YouTube trailer, then any
    /// YouTube clip — so the play button only appears when it can actually play.
    private func bestTrailerKey() -> String? {
        let youTube = (videos?.results ?? []).filter {
            $0.site?.caseInsensitiveCompare("YouTube") == .orderedSame
        }
        let isTrailer = { (v: VideoDTO) in v.type?.caseInsensitiveCompare("Trailer") == .orderedSame }

        return youTube.first { isTrailer($0) && $0.official == true }?.key
            ?? youTube.first(where: isTrailer)?.key
            ?? youTube.first?.key
    }
}
