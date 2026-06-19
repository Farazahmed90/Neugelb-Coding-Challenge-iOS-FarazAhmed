import Foundation

/// Full details for a single movie.
public struct MovieDetails: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String
    public let tagline: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: Date?
    public let runtimeMinutes: Int?
    public let genres: [Genre]
    public let voteAverage: Double
    public let voteCount: Int

    // Extended facts (all optional / empty-safe so partial responses still map).
    public let status: String?
    /// ISO 639-1 code (e.g. "en"); the UI localizes it to a display name.
    public let originalLanguage: String?
    public let budget: Int?
    public let revenue: Int?
    public let productionCompanies: [String]
    /// Top-billed cast, already ordered.
    public let cast: [CastMember]
    /// YouTube video id of the best available trailer, if any.
    public let trailerYouTubeID: String?

    public init(
        id: Int,
        title: String,
        overview: String,
        tagline: String?,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: Date?,
        runtimeMinutes: Int?,
        genres: [Genre],
        voteAverage: Double,
        voteCount: Int,
        status: String? = nil,
        originalLanguage: String? = nil,
        budget: Int? = nil,
        revenue: Int? = nil,
        productionCompanies: [String] = [],
        cast: [CastMember] = [],
        trailerYouTubeID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.tagline = tagline
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.runtimeMinutes = runtimeMinutes
        self.genres = genres
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.status = status
        self.originalLanguage = originalLanguage
        self.budget = budget
        self.revenue = revenue
        self.productionCompanies = productionCompanies
        self.cast = cast
        self.trailerYouTubeID = trailerYouTubeID
    }
}

/// A single billed cast member.
public struct CastMember: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let character: String?
    public let profilePath: String?

    public init(id: Int, name: String, character: String?, profilePath: String?) {
        self.id = id
        self.name = name
        self.character = character
        self.profilePath = profilePath
    }
}

public struct Genre: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
