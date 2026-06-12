import Foundation
import MoviesDomain
import Observation

@MainActor
@Observable
public final class MovieDetailViewModel {
    public enum State: Equatable {
        case loading
        case loaded(MovieDetails)
        case failed(message: String)
    }

    /// Summary passed from the list; rendered instantly while the full
    /// details load so navigation never feels blocked.
    public let movie: Movie
    public private(set) var state: State = .loading

    private let repository: any MovieRepository
    private let imageURLResolver: any ImageURLResolving

    public init(
        movie: Movie,
        repository: any MovieRepository,
        imageURLResolver: any ImageURLResolving
    ) {
        self.movie = movie
        self.repository = repository
        self.imageURLResolver = imageURLResolver
    }

    public func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    public func retry() async {
        state = .loading
        await load()
    }

    public var backdropURL: URL? {
        imageURLResolver.imageURL(
            forPath: movie.backdropPath ?? movie.posterPath,
            kind: .backdrop
        )
    }

    public var posterURL: URL? {
        imageURLResolver.imageURL(forPath: movie.posterPath, kind: .posterLarge)
    }

    private func load() async {
        do {
            state = .loaded(try await repository.movieDetails(id: movie.id))
        } catch is CancellationError {
            // View disappeared; .task will reload on next appearance.
        } catch {
            state = .failed(message: ErrorMessage.message(for: error))
        }
    }
}
