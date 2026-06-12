import Foundation
import MoviesDomain

/// Persists the latest first page so the app can show content offline.
public protocol MovieListCaching: Sendable {
    func save(_ page: Page<Movie>) async
    func loadLatest() async -> Page<Movie>?
}

/// JSON file in Application Support; an actor so concurrent saves from
/// refreshes can't interleave writes.
public actor MovieListDiskCache: MovieListCaching {
    private let fileURL: URL

    public init(directory: URL = URL.applicationSupportDirectory.appending(path: "MovieCache")) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appending(path: "now_playing_page1.json")
    }

    public func save(_ page: Page<Movie>) {
        guard let data = try? JSONEncoder().encode(page) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    public func loadLatest() -> Page<Movie>? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Page<Movie>.self, from: data)
    }
}

/// Decorator: passes everything to the remote repository, but keeps the
/// first now-playing page cached and serves it when the network is down.
public struct OfflineFallbackMovieRepository: MovieRepository {
    private let remote: any MovieRepository
    private let cache: any MovieListCaching

    public init(remote: any MovieRepository, cache: any MovieListCaching) {
        self.remote = remote
        self.cache = cache
    }

    public func latestMovies(page: Int) async throws -> Page<Movie> {
        do {
            let result = try await remote.latestMovies(page: page)
            if page == 1 {
                await cache.save(result)
            }
            return result
        } catch MovieRepositoryError.network where page == 1 {
            if let cached = await cache.loadLatest() {
                return cached
            }
            throw MovieRepositoryError.network
        }
    }

    public func movieDetails(id: Movie.ID) async throws -> MovieDetails {
        try await remote.movieDetails(id: id)
    }

    public func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        try await remote.searchMovies(matching: query, page: page)
    }
}
