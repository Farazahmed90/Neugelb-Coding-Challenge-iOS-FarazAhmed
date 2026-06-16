import Foundation
import MoviesDomain
import Testing
@testable import NeugelbCodingChallenge_iOS_FarazAhmed

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

    @Test func suggestionsComeFromDistinctResultTitles() async {
        func movie(_ id: Int, _ title: String) -> Movie {
            Movie(
                id: id, title: title, overview: "", posterPath: nil,
                backdropPath: nil, releaseDate: nil, voteAverage: 0, voteCount: 0
            )
        }
        let movies = [
            movie(1, "Batman"),
            movie(2, "Batman"),  // duplicate title must collapse
            movie(3, "Batman Returns"),
        ]
        let repository = MovieRepositoryMock(searchResults: [
            .success(Page(items: movies, pageNumber: 1, totalPages: 1))
        ])
        let viewModel = makeViewModel(repository: repository)

        viewModel.query = "bat"
        await viewModel.settle()

        #expect(viewModel.suggestions == ["Batman", "Batman Returns"])
    }

    @Test func acceptingSuggestionSearchesItAndHidesSuggestions() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1)),
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1)),
        ])
        let viewModel = makeViewModel(repository: repository)
        viewModel.query = "mov"
        await viewModel.settle()
        #expect(!viewModel.suggestions.isEmpty)

        viewModel.acceptSuggestion("Movie 1")
        await viewModel.settle()

        #expect(repository.requestedQueries == ["mov", "Movie 1"])
        #expect(viewModel.suggestions.isEmpty)
        #expect(viewModel.phase == .loaded)
    }

    @Test func typingAgainRestoresSuggestions() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1)),
            .success(makePage(ids: [2], pageNumber: 1, totalPages: 1)),
        ])
        let viewModel = makeViewModel(repository: repository)
        viewModel.acceptSuggestion("Movie 1")
        await viewModel.settle()
        #expect(viewModel.suggestions.isEmpty)

        viewModel.query = "Movie 2"
        await viewModel.settle()

        #expect(viewModel.suggestions == ["Movie 2"])
    }

    @Test func submitSearchesImmediatelyAndHidesSuggestions() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1))
        ])
        // Long debounce proves submit bypasses it.
        let viewModel = MovieSearchViewModel(
            repository: repository,
            imageURLResolver: ImageURLResolverStub(),
            debounce: .seconds(60)
        )

        viewModel.query = "batman"
        viewModel.submit()
        await viewModel.settle()

        #expect(repository.requestedQueries == ["batman"])
        #expect(viewModel.phase == .loaded)
        #expect(viewModel.suggestions.isEmpty)
    }

    @Test func retypingKeepsResultsVisibleInsteadOfFlashingSkeleton() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1)),
            .success(makePage(ids: [2], pageNumber: 1, totalPages: 1)),
        ])
        let viewModel = makeViewModel(repository: repository)
        viewModel.query = "bat"
        await viewModel.settle()

        viewModel.query = "batman"
        // Old results must stay on screen through debounce + reload.
        #expect(viewModel.phase == .loaded)
        #expect(viewModel.results.map(\.id) == [1])

        await viewModel.settle()
        #expect(viewModel.results.map(\.id) == [2])
        #expect(!viewModel.isRefreshing)
    }

    @Test func identicalResultsKeepExistingPaginator() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1, 2], pageNumber: 1, totalPages: 3)),
            .success(makePage(ids: [1, 2], pageNumber: 1, totalPages: 3)),
        ])
        let viewModel = makeViewModel(repository: repository)
        viewModel.query = "batm"
        await viewModel.settle()
        let original = viewModel.paginator

        viewModel.query = "batma"
        await viewModel.settle()

        // Same result set must not swap the paginator: no visual change,
        // and pagination progress survives.
        #expect(viewModel.paginator === original)
    }

    @Test func dismissSuggestionsHidesPanelUntilNextKeystroke() async {
        let repository = MovieRepositoryMock(searchResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1)),
            .success(makePage(ids: [2], pageNumber: 1, totalPages: 1)),
        ])
        let viewModel = makeViewModel(repository: repository)
        viewModel.query = "bat"
        await viewModel.settle()
        #expect(!viewModel.suggestions.isEmpty)

        viewModel.dismissSuggestions()
        #expect(viewModel.suggestions.isEmpty)

        viewModel.query = "batman"
        await viewModel.settle()
        #expect(!viewModel.suggestions.isEmpty)
    }

    @Test func deallocatesWithPendingDebounce() async {
        let repository = MovieRepositoryMock()
        var viewModel: MovieSearchViewModel? = makeViewModel(repository: repository)
        weak var weakViewModel = viewModel

        viewModel?.query = "batman"
        viewModel = nil

        // The debounce task holds self weakly, so the model can deallocate
        // even with a search pending.
        #expect(weakViewModel == nil)
    }
}
