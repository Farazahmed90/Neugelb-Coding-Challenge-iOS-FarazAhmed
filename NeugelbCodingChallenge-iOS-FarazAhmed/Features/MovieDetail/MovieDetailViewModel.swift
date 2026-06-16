import Foundation
import MoviesDomain
import Observation

@MainActor
@Observable
final class MovieDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(MovieDetails)
        case failed(message: String)
    }

    /// Summary from the list, rendered instantly while the full details load.
    let movie: Movie
    private let repository: any MovieRepository
    private let imageURLResolver: any ImageURLResolving

    private(set) var state: State = .loading

    var backdropURL: URL? {
        imageURLResolver.imageURL(forPath: movie.backdropPath ?? movie.posterPath, kind: .backdrop)
    }
    var posterURL: URL? {
        imageURLResolver.imageURL(forPath: movie.posterPath, kind: .posterLarge)
    }

    /// The loaded details, if available.
    var details: MovieDetails? {
        if case .loaded(let details) = state { return details }
        return nil
    }

    func profileURL(for member: CastMember) -> URL? {
        imageURLResolver.imageURL(forPath: member.profilePath, kind: .profile)
    }

    /// Deep link to the trailer on YouTube, when one is available.
    var trailerURL: URL? {
        guard let id = details?.trailerYouTubeID else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(id)")
    }

    init(movie: Movie, repository: any MovieRepository, imageURLResolver: any ImageURLResolving) {
        self.movie = movie
        self.repository = repository
        self.imageURLResolver = imageURLResolver
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    func retry() async {
        state = .loading
        await load()
    }

    private func load() async {
        do {
            state = .loaded(try await repository.movieDetails(id: movie.id))
        } catch is CancellationError {
            // View disappeared; .task reloads on next appearance.
        } catch {
            state = .failed(message: ErrorMessage.message(for: error))
        }
    }
}
