import Foundation
import MoviesDomain

func makeMovie(id: Int, title: String = "Movie") -> Movie {
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

func makePage(ids: [Int], pageNumber: Int, totalPages: Int) -> Page<Movie> {
    Page(items: ids.map { makeMovie(id: $0) }, pageNumber: pageNumber, totalPages: totalPages)
}

/// Scriptable repository: enqueue one result per expected call.
final class MovieRepositoryMock: MovieRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var latestResults: [Result<Page<Movie>, any Error>]
    private(set) var requestedPages: [Int] = []

    init(latestResults: [Result<Page<Movie>, any Error>] = []) {
        self.latestResults = latestResults
    }

    func latestMovies(page: Int) async throws -> Page<Movie> {
        try lock.withLock {
            requestedPages.append(page)
            precondition(!latestResults.isEmpty, "MovieRepositoryMock ran out of stubs")
            return try latestResults.removeFirst().get()
        }
    }

    func movieDetails(id: Movie.ID) async throws -> MovieDetails {
        throw MovieRepositoryError.notFound
    }

    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        throw MovieRepositoryError.notFound
    }
}

struct ImageURLResolverStub: ImageURLResolving {
    func imageURL(forPath path: String?, kind: ImageKind) -> URL? {
        path.map { URL(string: "https://images.example.com/stub\($0)")! }
    }
}
