import Foundation
import MoviesDomain
import Testing
@testable import MoviesFeature

@MainActor
struct MovieDetailViewModelTests {
    private func makeViewModel(
        movie: Movie = makeMovie(id: 278),
        repository: MovieRepositoryMock
    ) -> MovieDetailViewModel {
        MovieDetailViewModel(
            movie: movie,
            repository: repository,
            imageURLResolver: ImageURLResolverStub()
        )
    }

    @Test func loadsDetails() async {
        let repository = MovieRepositoryMock(detailsResults: [.success(makeDetails(id: 278))])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .loaded(makeDetails(id: 278)))
        #expect(repository.requestedDetailIDs == [278])
    }

    @Test func loadIfNeededDoesNotReloadLoadedDetails() async {
        let repository = MovieRepositoryMock(detailsResults: [.success(makeDetails(id: 278))])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(repository.requestedDetailIDs == [278])
    }

    @Test func failureSurfacesMessageAndRetryRecovers() async {
        let repository = MovieRepositoryMock(detailsResults: [
            .failure(MovieRepositoryError.network),
            .success(makeDetails(id: 278)),
        ])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected failed state, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)

        await viewModel.retry()
        #expect(viewModel.state == .loaded(makeDetails(id: 278)))
    }

    @Test func backdropFallsBackToPosterPath() {
        let movie = Movie(
            id: 1,
            title: "No Backdrop",
            overview: "",
            posterPath: "/poster.jpg",
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: 5,
            voteCount: 10
        )
        let viewModel = makeViewModel(
            movie: movie,
            repository: MovieRepositoryMock()
        )

        #expect(viewModel.backdropURL?.absoluteString.contains("/poster.jpg") == true)
    }

    @Test func deallocatesAfterLoading() async {
        let repository = MovieRepositoryMock(detailsResults: [.success(makeDetails(id: 1))])
        var viewModel: MovieDetailViewModel? = makeViewModel(
            movie: makeMovie(id: 1),
            repository: repository
        )
        weak var weakViewModel = viewModel

        await viewModel?.loadIfNeeded()
        viewModel = nil

        #expect(weakViewModel == nil)
    }
}
