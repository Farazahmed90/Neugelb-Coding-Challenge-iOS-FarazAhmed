import Foundation
import MoviesDomain
import Observation

/// Handles infinite scrolling for any paginated source. It prefetches the next
/// page near the end, drops duplicate items that TMDB sometimes repeats across
/// pages, avoids overlapping loads, and tracks first-page and load-more
/// failures separately.
@MainActor
@Observable
final class Paginator<Item: Identifiable & Hashable & Sendable> {
    typealias FetchPage = @Sendable (_ page: Int) async throws -> Page<Item>

    enum State: Equatable {
        case idle
        case loadingFirst
        case failedFirst(any Error & Sendable)
        case loaded(LoadMore)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loadingFirst, .loadingFirst), (.failedFirst, .failedFirst):
                return true
            case (.loaded(let lhsMore), (.loaded(let rhsMore))):
                return lhsMore == rhsMore
            default:
                return false
            }
        }
    }

    enum LoadMore: Equatable {
        case ready
        case loading
        case failed
        case exhausted
    }

    private(set) var items: [Item] = []
    private(set) var state: State = .idle

    private let prefetchThreshold: Int
    private let fetchPage: FetchPage
    private var nextPage = 1
    private var seenIDs = Set<Item.ID>()

    init(prefetchThreshold: Int = 5, fetchPage: @escaping FetchPage) {
        self.prefetchThreshold = prefetchThreshold
        self.fetchPage = fetchPage
    }

    /// Safe to call from `.task` on every appearance: loads only once.
    func loadFirstIfNeeded() async {
        guard case .idle = state else { return }
        await loadFirst()
    }

    func loadFirst() async {
        state = .loadingFirst
        await fetchAndReplace()
    }

    /// Re-fetches page one. If it fails, the current items stay so a failed
    /// pull-to-refresh doesn't clear the list.
    func refresh() async {
        if items.isEmpty {
            await loadFirst()
            return
        }
        await fetchAndReplace(keepItemsOnFailure: true)
    }

    func loadMoreIfNeeded(after item: Item) async {
        guard case .loaded(.ready) = state else { return }
        guard items.suffix(prefetchThreshold).contains(where: { $0.id == item.id }) else { return }
        await loadMore()
    }

    func retryLoadMore() async {
        guard case .loaded(.failed) = state else { return }
        state = .loaded(.ready)
        await loadMore()
    }

    private func fetchAndReplace(keepItemsOnFailure: Bool = false) async {
        do {
            let page = try await fetchPage(1)
            items = page.items
            seenIDs = Set(page.items.map(\.id))
            nextPage = 2
            state = .loaded(page.hasMore ? .ready : .exhausted)
        } catch is CancellationError {
            // The view went away mid-load; leave the state as is.
        } catch {
            if keepItemsOnFailure, !items.isEmpty {
                state = .loaded(.ready)
            } else {
                items = []
                state = .failedFirst(error)
            }
        }
    }

    private func loadMore() async {
        // Set the state before awaiting so the many calls from appearing cells
        // collapse into one fetch.
        state = .loaded(.loading)
        do {
            let page = try await fetchPage(nextPage)
            let fresh = page.items.filter { seenIDs.insert($0.id).inserted }
            items.append(contentsOf: fresh)
            nextPage += 1
            state = .loaded(page.hasMore ? .ready : .exhausted)
        } catch is CancellationError {
            state = .loaded(.ready)
        } catch {
            state = .loaded(.failed)
        }
    }
}
