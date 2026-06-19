import Foundation
import MoviesDomain

public func makeMovie(id: Int, title: String = "Movie") -> Movie {
    Movie(
        id: id,
        title: "\(title) \(id)",
        overview: "",
        posterPath: "/poster\(id).jpg",
        backdropPath: nil,
        releaseDate: nil,
        voteAverage: 7.0,
        voteCount: 100
    )
}

public func makePage(ids: [Int], pageNumber: Int = 1, totalPages: Int) -> Page<Movie> {
    Page(items: ids.map { makeMovie(id: $0) }, pageNumber: pageNumber, totalPages: totalPages)
}

public func makeDetails(id: Int) -> MovieDetails {
    MovieDetails(
        id: id,
        title: "Movie \(id)",
        overview: "Overview \(id)",
        tagline: "Tagline",
        posterPath: "/poster\(id).jpg",
        backdropPath: "/backdrop\(id).jpg",
        releaseDate: nil,
        runtimeMinutes: 120,
        genres: [Genre(id: 1, name: "Drama")],
        voteAverage: 7.5,
        voteCount: 1_000
    )
}
