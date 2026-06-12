#if DEBUG
import Foundation
import MoviesDomain

/// Sample content for SwiftUI previews.
enum PreviewData {
    static let movies: [Movie] = [
        Movie(
            id: 278,
            title: "The Shawshank Redemption",
            overview: "Imprisoned in the 1940s for the double murder of his wife and her lover, upstanding banker Andy Dufresne begins a new life at the Shawshank prison.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: Date(timeIntervalSince1970: 780_000_000),
            voteAverage: 8.7,
            voteCount: 28_599
        ),
        Movie(
            id: 550,
            title: "Fight Club",
            overview: "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: Date(timeIntervalSince1970: 940_000_000),
            voteAverage: 8.4,
            voteCount: 30_041
        ),
        Movie(
            id: 99999901,
            title: "Unreleased Indie With a Very Long Title That Wraps",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: 0,
            voteCount: 0
        ),
    ]
}

struct PreviewMovieRepository: MovieRepository {
    var failure: MovieRepositoryError?

    func latestMovies(page: Int) async throws -> Page<Movie> {
        if let failure { throw failure }
        return Page(items: PreviewData.movies, pageNumber: page, totalPages: page + 1)
    }

    func movieDetails(id: Movie.ID) async throws -> MovieDetails {
        if let failure { throw failure }
        let movie = PreviewData.movies.first { $0.id == id } ?? PreviewData.movies[0]
        return MovieDetails(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            tagline: "Fear can hold you prisoner. Hope can set you free.",
            posterPath: movie.posterPath,
            backdropPath: movie.backdropPath,
            releaseDate: movie.releaseDate,
            runtimeMinutes: 142,
            genres: [Genre(id: 18, name: "Drama"), Genre(id: 80, name: "Crime")],
            voteAverage: movie.voteAverage,
            voteCount: movie.voteCount
        )
    }

    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        if let failure { throw failure }
        return Page(items: PreviewData.movies, pageNumber: 1, totalPages: 1)
    }
}

struct PreviewImageURLResolver: ImageURLResolving {
    func imageURL(forPath path: String?, kind: ImageKind) -> URL? { nil }
}
#endif
