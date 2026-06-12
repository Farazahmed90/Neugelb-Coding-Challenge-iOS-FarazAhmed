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

    /// True while a newer search replaces already-visible results;
    /// the UI dims the grid instead of flashing a skeleton.
    public private(set) var isRefreshing = false

    public var results: [Movie] { paginator?.items ?? [] }

    /// Distinct top result titles offered as search-field completions.
    public var suggestions: [String] {
        guard phase == .loaded, suggestionsVisible else { return [] }
        var seen = Set<String>()
        let titles = results.prefix(20).map(\.title)
            .filter { seen.insert($0.lowercased()).inserted }
        return Array(titles.prefix(8))
    }

    /// Suggestions hide after one is chosen and reappear on typing,
    /// otherwise the suggestion overlay would keep covering the results.
    private var suggestionsVisible = true
    private var isApplyingSuggestion = false

    public func acceptSuggestion(_ title: String) {
        isApplyingSuggestion = true
        query = title
    }

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

    /// Keyboard search key: skip the debounce, search now, close panel.
    public func submit() {
        debounceTask?.cancel()
        suggestionsVisible = false
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        debounceTask = Task { [weak self] in
            await self?.search(for: trimmed)
        }
    }

    /// Awaits the pending debounce + search; used by tests for determinism.
    func settle() async {
        await debounceTask?.value
    }

    private func queryChanged() {
        suggestionsVisible = !isApplyingSuggestion
        isApplyingSuggestion = false
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

    /// Closes the suggestions panel (e.g. when the user starts scrolling).
    public func dismissSuggestions() {
        suggestionsVisible = false
    }

    private func search(for trimmed: String) async {
        // Keep previous results on screen while re-searching; flipping to
        // the skeleton on every keystroke makes the grid flash.
        if paginator == nil {
            phase = .searching
        } else {
            isRefreshing = true
        }
        defer { isRefreshing = false }

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
