import Foundation
import MoviesDomain
import Observation

/// Debounced search. Each keystroke restarts the debounce, cancels the
/// in-flight request, and ignores any late response so it can't overwrite
/// newer results.
@MainActor
@Observable
final class MovieSearchViewModel {
    enum Phase: Equatable, Hashable {
        case idle
        case searching
        case loaded
        case failed(message: String)
    }

    var query = "" {
        didSet { queryChanged() }
    }

    private(set) var phase: Phase = .idle
    private(set) var paginator: Paginator<Movie>?

    /// True while new results are loading over old ones, so the UI dims the grid instead of showing a skeleton.
    private(set) var isRefreshing = false

    var results: [Movie] { paginator?.items ?? [] }

    var suggestions: [String] {
        guard phase == .loaded, suggestionsVisible else { return [] }
        var seen = Set<String>()
        let titles = results.prefix(20).map(\.title).filter { seen.insert($0.lowercased()).inserted }
        return Array(titles.prefix(8))
    }

    /// Hide suggestions after one is picked, and show them again on the next
    /// keystroke, so the panel doesn't keep covering the results.
    private var suggestionsVisible = true
    private var isApplyingSuggestion = false

    private let repository: any MovieRepository
    private let imageURLResolver: any ImageURLResolving
    private let debounce: Duration
    private var debounceTask: Task<Void, Never>?

    init(
        repository: any MovieRepository,
        imageURLResolver: any ImageURLResolving,
        debounce: Duration = .milliseconds(300)
    ) {
        self.repository = repository
        self.imageURLResolver = imageURLResolver
        self.debounce = debounce
    }

    func posterURL(for movie: Movie) -> URL? {
        imageURLResolver.imageURL(forPath: movie.posterPath, kind: .posterThumbnail)
    }

    func acceptSuggestion(_ title: String) {
        isApplyingSuggestion = true
        query = title
    }

    func retry() {
        queryChanged()
    }

    /// Search key on the keyboard: skip the debounce, search now, hide the panel.
    func submit() {
        debounceTask?.cancel()
        suggestionsVisible = false
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        debounceTask = Task { [weak self] in
            await self?.search(for: trimmed)
        }
    }

    func dismissSuggestions() {
        guard suggestionsVisible else { return }
        suggestionsVisible = false
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

    private func search(for trimmed: String) async {
        var refreshCue: Task<Void, Never>?
        if paginator == nil {
            phase = .searching
        } else {
            // Short delay before dimming, so a fast response doesn't flash a dim.
            refreshCue = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                self?.isRefreshing = true
            }
        }
        defer {
            refreshCue?.cancel()
            isRefreshing = false
        }

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
            // Same results as before: keep the current paginator (and its page
            // progress) so the grid doesn't reload.
            if let current = self.paginator,
               current.items.map(\.id) == paginator.items.map(\.id) {
                phase = .loaded
            } else {
                self.paginator = paginator
                phase = .loaded
            }
        case .idle, .loadingFirst:
            break
        }
    }
}
