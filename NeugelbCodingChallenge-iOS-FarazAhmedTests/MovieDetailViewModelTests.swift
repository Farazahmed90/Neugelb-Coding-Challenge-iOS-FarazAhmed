import Foundation
import MoviesDomain
import TestSupport
import Testing
@testable import NeugelbCodingChallenge_iOS_FarazAhmed

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
        // makeMovie has a poster but no backdrop, which is the case under test.
        let viewModel = makeViewModel(
            movie: makeMovie(id: 1),
            repository: MovieRepositoryMock()
        )

        #expect(viewModel.backdropURL?.absoluteString.contains("/poster1.jpg") == true)
    }
}
