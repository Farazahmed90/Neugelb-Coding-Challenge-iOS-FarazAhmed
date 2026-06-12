import Foundation
import MoviesData
import MoviesDomain
import Testing

private func makeMoviePage(ids: [Int], totalPages: Int = 5) -> Page<Movie> {
    Page(
        items: ids.map {
            Movie(
                id: $0, title: "Movie \($0)", overview: "", posterPath: nil,
                backdropPath: nil, releaseDate: nil, voteAverage: 7, voteCount: 1
            )
        },
        pageNumber: 1,
        totalPages: totalPages
    )
}

private struct RemoteStub: MovieRepository {
    var pageResult: Result<Page<Movie>, MovieRepositoryError>

    func latestMovies(page: Int) async throws -> Page<Movie> {
        try pageResult.get()
    }

    func movieDetails(id: Movie.ID) async throws -> MovieDetails {
        throw MovieRepositoryError.notFound
    }

    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        throw MovieRepositoryError.notFound
    }
}

private actor CacheSpy: MovieListCaching {
    var stored: Page<Movie>?

    init(stored: Page<Movie>? = nil) {
        self.stored = stored
    }

    func save(_ page: Page<Movie>) {
        stored = page
    }

    func loadLatest() -> Page<Movie>? {
        stored
    }
}

struct OfflineFallbackRepositoryTests {
    @Test func successfulFirstPageIsCached() async throws {
        let cache = CacheSpy()
        let repository = OfflineFallbackMovieRepository(
            remote: RemoteStub(pageResult: .success(makeMoviePage(ids: [1, 2]))),
            cache: cache
        )

        _ = try await repository.latestMovies(page: 1)

        #expect(await cache.stored?.items.map(\.id) == [1, 2])
    }

    @Test func networkFailureServesCachedFirstPage() async throws {
        let repository = OfflineFallbackMovieRepository(
            remote: RemoteStub(pageResult: .failure(.network)),
            cache: CacheSpy(stored: makeMoviePage(ids: [7]))
        )

        let page = try await repository.latestMovies(page: 1)

        #expect(page.items.map(\.id) == [7])
    }

    @Test func networkFailureWithoutCacheRethrows() async {
        let repository = OfflineFallbackMovieRepository(
            remote: RemoteStub(pageResult: .failure(.network)),
            cache: CacheSpy()
        )

        await #expect(throws: MovieRepositoryError.network) {
            _ = try await repository.latestMovies(page: 1)
        }
    }

    @Test func nonNetworkErrorsAreNeverMasked() async {
        let repository = OfflineFallbackMovieRepository(
            remote: RemoteStub(pageResult: .failure(.unauthorized)),
            cache: CacheSpy(stored: makeMoviePage(ids: [7]))
        )

        await #expect(throws: MovieRepositoryError.unauthorized) {
            _ = try await repository.latestMovies(page: 1)
        }
    }

    @Test func laterPagesAreNotServedFromCache() async {
        let repository = OfflineFallbackMovieRepository(
            remote: RemoteStub(pageResult: .failure(.network)),
            cache: CacheSpy(stored: makeMoviePage(ids: [7]))
        )

        await #expect(throws: MovieRepositoryError.network) {
            _ = try await repository.latestMovies(page: 2)
        }
    }

    @Test func diskCacheRoundTrips() async {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = MovieListDiskCache(directory: directory)
        let page = makeMoviePage(ids: [1, 2, 3])

        await cache.save(page)
        let loaded = await MovieListDiskCache(directory: directory).loadLatest()

        #expect(loaded == page)
    }
}
