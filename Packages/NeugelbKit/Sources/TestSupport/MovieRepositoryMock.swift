import Foundation
import MoviesDomain

/// Scriptable repository: enqueue one result per expected call.
public final class MovieRepositoryMock: MovieRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var latestResults: [Result<Page<Movie>, any Error>]
    private var detailsResults: [Result<MovieDetails, any Error>]
    private var searchResults: [Result<Page<Movie>, any Error>]
    public private(set) var requestedPages: [Int] = []
    public private(set) var requestedDetailIDs: [Int] = []
    public private(set) var requestedQueries: [String] = []

    public init(
        latestResults: [Result<Page<Movie>, any Error>] = [],
        detailsResults: [Result<MovieDetails, any Error>] = [],
        searchResults: [Result<Page<Movie>, any Error>] = []
    ) {
        self.latestResults = latestResults
        self.detailsResults = detailsResults
        self.searchResults = searchResults
    }

    public func latestMovies(page: Int) async throws -> Page<Movie> {
        try lock.withLock {
            requestedPages.append(page)
            precondition(!latestResults.isEmpty, "MovieRepositoryMock ran out of stubs")
            return try latestResults.removeFirst().get()
        }
    }

    public func movieDetails(id: Movie.ID) async throws -> MovieDetails {
        try lock.withLock {
            requestedDetailIDs.append(id)
            precondition(!detailsResults.isEmpty, "MovieRepositoryMock ran out of stubs")
            return try detailsResults.removeFirst().get()
        }
    }

    public func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        try lock.withLock {
            requestedQueries.append(query)
            precondition(!searchResults.isEmpty, "MovieRepositoryMock ran out of stubs")
            return try searchResults.removeFirst().get()
        }
    }
}
