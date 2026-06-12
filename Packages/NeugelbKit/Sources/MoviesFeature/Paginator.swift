import Foundation
import MoviesDomain
import Observation

/// Drives infinite scrolling over any paginated source: threshold-based
/// prefetch, de-duplication of repeated items (a real TMDB quirk when the
/// catalog shifts between page requests), overlapping-load protection,
/// and distinct first-page vs load-more failure states.
@MainActor
@Observable
public final class Paginator<Item: Identifiable & Hashable & Sendable> {
    public typealias FetchPage = @Sendable (_ page: Int) async throws -> Page<Item>

    public enum State: Equatable {
        case idle
        case loadingFirst
        case failedFirst(any Error & Sendable)
        case loaded(LoadMore)

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loadingFirst, .loadingFirst),
                 (.failedFirst, .failedFirst):
                return true
            case (.loaded(let lhsMore), (.loaded(let rhsMore))):
                return lhsMore == rhsMore
            default:
                return false
            }
        }
    }

    public enum LoadMore: Equatable {
        case ready
        case loading
        case failed
        case exhausted
    }

    public private(set) var items: [Item] = []
    public private(set) var state: State = .idle

    /// How close to the end of the list an item must be to trigger the
    /// next page fetch.
    private let prefetchThreshold: Int
    private let fetchPage: FetchPage
    private var nextPage = 1
    private var seenIDs = Set<Item.ID>()

    public init(prefetchThreshold: Int = 5, fetchPage: @escaping FetchPage) {
        self.prefetchThreshold = prefetchThreshold
        self.fetchPage = fetchPage
    }

    /// Loads the first page if nothing is loaded yet; safe to call from
    /// `.task` on every appearance.
    public func loadFirstIfNeeded() async {
        guard case .idle = state else { return }
        await loadFirst()
    }

    /// Loads (or retries) the first page, replacing any previous content.
    public func loadFirst() async {
        state = .loadingFirst
        await fetchAndReplace()
    }

    /// Re-fetches page one. Existing items stay visible while refreshing;
    /// on failure they are kept so a failed pull-to-refresh never blanks
    /// a working list.
    public func refresh() async {
        if items.isEmpty {
            await loadFirst()
            return
        }
        await fetchAndReplace(keepItemsOnFailure: true)
    }

    /// Triggers the next page fetch when `item` is near the end of the list.
    public func loadMoreIfNeeded(after item: Item) async {
        guard case .loaded(.ready) = state else { return }
        guard items.suffix(prefetchThreshold).contains(where: { $0.id == item.id }) else {
            return
        }
        await loadMore()
    }

    /// Retries a failed load-more.
    public func retryLoadMore() async {
        guard case .loaded(.failed) = state else { return }
        state = .loaded(.ready)
        await loadMore()
    }

    // MARK: - Private

    private func fetchAndReplace(keepItemsOnFailure: Bool = false) async {
        do {
            let page = try await fetchPage(1)
            items = page.items
            seenIDs = Set(page.items.map(\.id))
            nextPage = 2
            state = .loaded(page.hasMore ? .ready : .exhausted)
        } catch is CancellationError {
            // View went away mid-flight; leave state untouched.
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
        // Setting the state before suspending is what makes overlapping
        // calls (every cell appearance fires one) collapse into one fetch.
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
