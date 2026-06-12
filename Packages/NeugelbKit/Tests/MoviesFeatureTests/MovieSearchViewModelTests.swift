import Foundation
import MoviesDomain
import Testing
@testable import MoviesFeature

@MainActor
struct MovieSearchViewModelTests {
    private func makeViewModel(repository: MovieRepositoryMock) -> MovieSearchViewModel {
        MovieSearchViewModel(
            repository: repository,
            imageURLResolver: ImageURLResolverStub(),
            debounce: .milliseconds(5)
        )
    }

    @Test func staysIdleBelowTwoCharacters() async {
        let repository = MovieRepositoryMock()
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "b"
        await viewModel.settle()

        #expect(viewModel.phase == .idle)
        #expect(repository.requestedQueries.isEmpty)
    }

    @Test func debounceCoalescesRapidKeystrokes() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1))
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "ba"
        viewModel.query = "bat"
        viewModel.query = "batman"
        await viewModel.settle()

        #expect(repository.requestedQueries == ["batman"])
        #expect(viewModel.phase == .loaded)
    }

    @Test func trimsWhitespaceFromQuery() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1))
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "  batman  "
        await viewModel.settle()

        #expect(repository.requestedQueries == ["batman"])
    }

    @Test func loadsResults() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [5, 6], pageNumber: 1, totalPages: 1))
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "movie"
        await viewModel.settle()

        #expect(viewModel.results.map(\.id) == [5, 6])
        #expect(viewModel.phase == .loaded)
    }

    @Test func emptyResultsStayLoadedForNoResultsState() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [], pageNumber: 1, totalPages: 0))
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "zzzz"
        await viewModel.settle()

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.results.isEmpty)
    }

    @Test func failureSurfacesMessageAndRetryRecovers() async {
        let repository = MovieRepositoryMock(searchResults: [
            .failure(MovieRepositoryError.network),
            .success(makePage(ids: [9], pageNumber: 1, totalPages: 1)),
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "batman"
        await viewModel.settle()
        guard case .failed = viewModel.phase else {
            Issue.record("Expected failed phase, got \(viewModel.phase)")
            return
        }

        viewModel.retry()
        await viewModel.settle()

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.results.map(\.id) == [9])
    }

    @Test func clearingQueryResetsToIdle() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1))
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "batman"
        await viewModel.settle()
        viewModel.query = ""

        #expect(viewModel.phase == .idle)
        #expect(viewModel.results.isEmpty)
    }

    @Test func searchResultsPaginate() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1, 2], pageNumber: 1, totalPages: 2)),
            .success(makePage(ids: [3], pageNumber: 2, totalPages: 2)),
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "batman"
        await viewModel.settle()
        await viewModel.paginator?.loadMoreIfNeeded(after: viewModel.results.last!)

        #expect(viewModel.results.map(\.id) == [1, 2, 3])
        #expect(repository.requestedQueries == ["batman", "batman"])
    }

    @Test func deallocatesWithPendingDebounce() async {
        let repository = MovieRepositoryMock()
        var viewModel: MovieSearchViewModel? = makeViewModel(repository: repository)
        weak var weakViewModel = viewModel

        viewModel?.query = "batman"
        viewModel = nil

        // The debounce task holds self weakly, so the model must die even
        // with a search pending.
        #expect(weakViewModel == nil)
    }
}
