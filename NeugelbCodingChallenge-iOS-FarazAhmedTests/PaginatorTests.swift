import Foundation
import MoviesDomain
import Testing
@testable import NeugelbCodingChallenge_iOS_FarazAhmed

@MainActor
struct PaginatorTests {
    private func makePaginator(
        repository: MovieRepositoryMock,
        prefetchThreshold: Int = 5
    ) -> Paginator<Movie> {
        Paginator(prefetchThreshold: prefetchThreshold) { page in
            try await repository.latestMovies(page: page)
        }
    }

    @Test func loadsFirstPage() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1, 2, 3], pageNumber: 1, totalPages: 2))
        ])
        let paginator = makePaginator(repository: repository)

        await paginator.loadFirst()

        #expect(paginator.items.map(\.id) == [1, 2, 3])
        #expect(paginator.state == .loaded(.ready))
    }

    @Test func firstPageOfSinglePageCatalogIsExhausted() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1))
        ])
        let paginator = makePaginator(repository: repository)

        await paginator.loadFirst()

        #expect(paginator.state == .loaded(.exhausted))
    }

    @Test func loadFirstIfNeededIsIdempotent() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1))
        ])
        let paginator = makePaginator(repository: repository)

        await paginator.loadFirstIfNeeded()
        await paginator.loadFirstIfNeeded()

        #expect(repository.requestedPages == [1])
    }

    @Test func failedFirstPageExposesError() async {
        let repository = MovieRepositoryMock(latestResults: [
            .failure(MovieRepositoryError.network)
        ])
        let paginator = makePaginator(repository: repository)

        await paginator.loadFirst()

        guard case .failedFirst(let error) = paginator.state else {
            Issue.record("Expected failedFirst, got \(paginator.state)")
            return
        }
        #expect(error as? MovieRepositoryError == .network)
        #expect(paginator.items.isEmpty)
    }

    @Test func loadsNextPageWhenNearEnd() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1, 2, 3], pageNumber: 1, totalPages: 2)),
            .success(makePage(ids: [4, 5], pageNumber: 2, totalPages: 2)),
        ])
        let paginator = makePaginator(repository: repository)
        await paginator.loadFirst()

        await paginator.loadMoreIfNeeded(after: paginator.items.last!)

        #expect(paginator.items.map(\.id) == [1, 2, 3, 4, 5])
        #expect(paginator.state == .loaded(.exhausted))
        #expect(repository.requestedPages == [1, 2])
    }

    @Test func doesNotLoadMoreForItemsOutsideThreshold() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: Array(1...20), pageNumber: 1, totalPages: 2))
        ])
        let paginator = makePaginator(repository: repository, prefetchThreshold: 5)
        await paginator.loadFirst()

        await paginator.loadMoreIfNeeded(after: paginator.items[0])

        #expect(repository.requestedPages == [1])
    }

    @Test func deduplicatesItemsRepeatedAcrossPages() async {
        // TMDB shifts items between pages as the catalog updates, so the
        // same movie can legitimately appear on consecutive pages.
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1, 2, 3], pageNumber: 1, totalPages: 2)),
            .success(makePage(ids: [3, 4], pageNumber: 2, totalPages: 2)),
        ])
        let paginator = makePaginator(repository: repository)
        await paginator.loadFirst()

        await paginator.loadMoreIfNeeded(after: paginator.items.last!)

        #expect(paginator.items.map(\.id) == [1, 2, 3, 4])
    }

    @Test func failedLoadMoreKeepsItemsAndAllowsRetry() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1, 2], pageNumber: 1, totalPages: 3)),
            .failure(MovieRepositoryError.serverUnavailable),
            .success(makePage(ids: [3], pageNumber: 2, totalPages: 3)),
        ])
        let paginator = makePaginator(repository: repository)
        await paginator.loadFirst()

        await paginator.loadMoreIfNeeded(after: paginator.items.last!)
        #expect(paginator.state == .loaded(.failed))
        #expect(paginator.items.map(\.id) == [1, 2])

        await paginator.retryLoadMore()
        #expect(paginator.items.map(\.id) == [1, 2, 3])
        #expect(paginator.state == .loaded(.ready))
    }

    @Test func refreshReplacesContent() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1, 2], pageNumber: 1, totalPages: 2)),
            .success(makePage(ids: [10, 11], pageNumber: 1, totalPages: 2)),
        ])
        let paginator = makePaginator(repository: repository)
        await paginator.loadFirst()

        await paginator.refresh()

        #expect(paginator.items.map(\.id) == [10, 11])
        #expect(repository.requestedPages == [1, 1])
    }

    @Test func failedRefreshKeepsExistingItems() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1, 2], pageNumber: 1, totalPages: 2)),
            .failure(MovieRepositoryError.network),
        ])
        let paginator = makePaginator(repository: repository)
        await paginator.loadFirst()

        await paginator.refresh()

        // A failed pull-to-refresh must never blank out a working list.
        #expect(paginator.items.map(\.id) == [1, 2])
        #expect(paginator.state == .loaded(.ready))
    }

    @Test func refreshAfterDedupReportsFreshPageNumbering() async {
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 2)),
            .success(makePage(ids: [2], pageNumber: 2, totalPages: 2)),
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 2)),
            .success(makePage(ids: [2], pageNumber: 2, totalPages: 2)),
        ])
        let paginator = makePaginator(repository: repository)
        await paginator.loadFirst()
        await paginator.loadMoreIfNeeded(after: paginator.items.last!)

        await paginator.refresh()
        // After refresh, the seen-ID set must reset or page 2 items would
        // be filtered out as duplicates.
        await paginator.loadMoreIfNeeded(after: paginator.items.last!)

        #expect(paginator.items.map(\.id) == [1, 2])
    }
}
