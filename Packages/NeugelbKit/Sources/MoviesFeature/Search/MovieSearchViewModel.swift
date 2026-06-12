import Foundation
import MoviesDomain
import Observation

/// Debounced movie search. Each keystroke restarts the debounce window;
/// in-flight requests are cancelled through structured concurrency and
/// stale responses are dropped before they can overwrite newer results.
@MainActor
@Observable
public final class MovieSearchViewModel {
    public enum Phase: Equatable {
        case idle
        case searching
        case loaded
        case failed(message: String)
    }

    public var query = "" {
        didSet { queryChanged() }
    }

    public private(set) var phase: Phase = .idle
    public private(set) var paginator: Paginator<Movie>?

    public var results: [Movie] { paginator?.items ?? [] }

    private let repository: any MovieRepository
    private let imageURLResolver: any ImageURLResolving
    private let debounce: Duration
    private var debounceTask: Task<Void, Never>?

    public init(
        repository: any MovieRepository,
        imageURLResolver: any ImageURLResolving,
        debounce: Duration = .milliseconds(300)
    ) {
        self.repository = repository
        self.imageURLResolver = imageURLResolver
        self.debounce = debounce
    }

    public func posterURL(for movie: Movie) -> URL? {
        imageURLResolver.imageURL(forPath: movie.posterPath, kind: .posterThumbnail)
    }

    /// Re-runs the current query after a failure.
    public func retry() {
        queryChanged()
    }

    /// Awaits the pending debounce + search; used by tests for determinism.
    func settle() async {
        await debounceTask?.value
    }

    private func queryChanged() {
        debounceTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            paginator = nil
            phase = .idle
            return
        }

        debounceTask = Task { [weak self, debounce] in
            guard (try? await Task.sleep(for: debounce)) != nil else { return }
            await self?.search(for: trimmed)
        }
    }

    private func search(for trimmed: String) async {
        phase = .searching
        let repository = repository
        let paginator = Paginator<Movie> { page in
            try await repository.searchMovies(matching: trimmed, page: page)
        }
        await paginator.loadFirst()

        // A newer keystroke may have arrived while this search was running.
        guard trimmed == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        switch paginator.state {
        case .failedFirst(let error):
            self.paginator = nil
            phase = .failed(message: ErrorMessage.message(for: error))
        case .loaded:
            self.paginator = paginator
            phase = .loaded
        case .idle, .loadingFirst:
            // Cancelled mid-flight; a newer search owns the state now.
            break
        }
    }
}
