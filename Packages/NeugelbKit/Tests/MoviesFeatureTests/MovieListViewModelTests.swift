import Foundation
import MoviesDomain
import Testing
@testable import MoviesFeature

@MainActor
struct MovieListViewModelTests {
    @Test func resolvesPosterURLs() {
        let viewModel = MovieListViewModel(
            repository: MovieRepositoryMock(),
            imageURLResolver: ImageURLResolverStub()
        )
        let movie = makeMovie(id: 7)

        #expect(viewModel.posterURL(for: movie)?.absoluteString.contains("/poster7.jpg") == true)
    }

    @Test func mapsDomainErrorsToMessages() {
        let viewModel = MovieListViewModel(
            repository: MovieRepositoryMock(),
            imageURLResolver: ImageURLResolverStub()
        )

        let network = viewModel.errorMessage(for: .failedFirst(MovieRepositoryError.network))
        let unauthorized = viewModel.errorMessage(
            for: .failedFirst(MovieRepositoryError.unauthorized)
        )

        #expect(network != unauthorized)
        #expect(!network.isEmpty)
    }

    @Test func deallocatesAfterLoading() async {
        // Regression guard against retain cycles between the view model,
        // its paginator, and the fetch closure.
        let repository = MovieRepositoryMock(latestResults: [
            .success(makePage(ids: [1], pageNumber: 1, totalPages: 1))
        ])

        var viewModel: MovieListViewModel? = MovieListViewModel(
            repository: repository,
            imageURLResolver: ImageURLResolverStub()
        )
        weak var weakViewModel = viewModel
        weak var weakPaginator = viewModel?.paginator

        await viewModel?.paginator.loadFirst()
        viewModel = nil

        #expect(weakViewModel == nil)
        #expect(weakPaginator == nil)
    }
}
