import Foundation
@testable import MoviesData
import MoviesDomain
import TestSupport
import Testing

struct OfflineFallbackRepositoryTests {
    @Test func successfulFirstPageIsCached() async throws {
        let cache = CacheSpy()
        let repository = OfflineFallbackMovieRepository(
            remote: MovieRepositoryMock(latestResults: [.success(makePage(ids: [1, 2], totalPages: 5))]),
            cache: cache
        )

        _ = try await repository.latestMovies(page: 1)

        #expect(await cache.stored?.items.map(\.id) == [1, 2])
    }

    @Test func networkFailureServesCachedFirstPage() async throws {
        let repository = OfflineFallbackMovieRepository(
            remote: MovieRepositoryMock(latestResults: [.failure(MovieRepositoryError.network)]),
            cache: CacheSpy(stored: makePage(ids: [7], totalPages: 5))
        )

        let page = try await repository.latestMovies(page: 1)

        #expect(page.items.map(\.id) == [7])
    }

    @Test func networkFailureWithoutCacheRethrows() async {
        let repository = OfflineFallbackMovieRepository(
            remote: MovieRepositoryMock(latestResults: [.failure(MovieRepositoryError.network)]),
            cache: CacheSpy()
        )

        await #expect(throws: MovieRepositoryError.network) {
            _ = try await repository.latestMovies(page: 1)
        }
    }

    @Test func nonNetworkErrorsAreNeverMasked() async {
        let repository = OfflineFallbackMovieRepository(
            remote: MovieRepositoryMock(latestResults: [.failure(MovieRepositoryError.unauthorized)]),
            cache: CacheSpy(stored: makePage(ids: [7], totalPages: 5))
        )

        await #expect(throws: MovieRepositoryError.unauthorized) {
            _ = try await repository.latestMovies(page: 1)
        }
    }

    @Test func laterPagesAreNotServedFromCache() async {
        let repository = OfflineFallbackMovieRepository(
            remote: MovieRepositoryMock(latestResults: [.failure(MovieRepositoryError.network)]),
            cache: CacheSpy(stored: makePage(ids: [7], totalPages: 5))
        )

        await #expect(throws: MovieRepositoryError.network) {
            _ = try await repository.latestMovies(page: 2)
        }
    }

    @Test func diskCacheRoundTrips() async {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = MovieListDiskCache(directory: directory)
        let page = makePage(ids: [1, 2, 3], totalPages: 5)

        await cache.save(page)
        let loaded = await MovieListDiskCache(directory: directory).loadLatest()

        #expect(loaded == page)
    }
}
