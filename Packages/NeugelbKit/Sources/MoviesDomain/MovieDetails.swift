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
        voteCount: Int
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
