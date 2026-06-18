import DesignSystem
import MoviesDomain
import SwiftUI

/// Shared column layout. Kept separate from the generic `MovieGridView` so the
/// skeleton can use it without naming a header type.
private enum MovieGridLayout {
    static let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)]
}

/// Adaptive poster grid driven by a paginator: prefetches the next page and
/// shows a load-more footer. Used by the list and search screens. An optional
/// `header` scrolls above the grid (e.g. the featured carousel).
struct MovieGridView<Header: View>: View {
    private let paginator: Paginator<Movie>
    private let posterURL: (Movie) -> URL?
    private let onSelect: (Movie) -> Void
    private var accessibilityIdentifier = "movie_list.grid"
    private var onScrollStarted: (() -> Void)?
    private let header: Header

    init(
        paginator: Paginator<Movie>,
        posterURL: @escaping (Movie) -> URL?,
        onSelect: @escaping (Movie) -> Void,
        accessibilityIdentifier: String = "movie_list.grid",
        onScrollStarted: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() }
    ) {
        self.paginator = paginator
        self.posterURL = posterURL
        self.onSelect = onSelect
        self.accessibilityIdentifier = accessibilityIdentifier
        self.onScrollStarted = onScrollStarted
        self.header = header()
    }

    @State private var scrollPosition = ScrollPosition()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                grid
                footer
            }
        }
        // Swiping dismisses the keyboard; the query and results stay put.
        .scrollDismissesKeyboard(.immediately)
        .scrollPosition($scrollPosition)
        .accessibilityIdentifier(accessibilityIdentifier)
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting { onScrollStarted?() }
        }
        .onChange(of: paginator.items.first?.id) { old, new in
            // A new first item means new results, so jump back to the top.
            guard old != nil, old != new else { return }
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.4)) {
                scrollPosition.scrollTo(edge: .top)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: MovieGridLayout.columns, spacing: 20) {
            ForEach(Array(paginator.items.enumerated()), id: \.element.id) { index, movie in
                Button {
                    onSelect(movie)
                } label: {
                    MovieCardView(movie: movie, posterURL: posterURL(movie))
                }
                .buttonStyle(.plain)
                // Blur-to-sharp dissolve; a plain fade under Reduce Motion.
                .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
                .animation(itemAnimation(forIndex: index), value: paginator.items)
                .task { await paginator.loadMoreIfNeeded(after: movie) }
            }
        }
        .padding(.horizontal)
    }

    /// Each card animates in slightly after the one before it, for a staggered
    /// wave. Uses a non-bouncy spring so there's no overshoot.
    private func itemAnimation(forIndex index: Int) -> Animation {
        if reduceMotion { return .easeInOut(duration: 0.2) }
        return .smooth(duration: 0.4).delay(cascadeDelay(for: index))
    }

    /// Stagger delay, capped and wrapped so later pages don't keep adding delay.
    private func cascadeDelay(for index: Int) -> Double {
        min(Double(index % 15) * 0.03, 0.4)
    }

    @ViewBuilder
    private var footer: some View {
        if case .loaded(let loadMore) = paginator.state {
            switch loadMore {
            case .loading, .ready:
                ProgressView()
                    .padding(.vertical, 24)
                    .accessibilityLabel(Text("Loading more movies"))
            case .failed:
                VStack(spacing: 8) {
                    Text("Couldn't load more movies.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await paginator.retryLoadMore() }
                    } label: {
                        Text("Try Again")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("movie_list.retry_more_button")
                }
                .padding(.vertical, 24)
            case .exhausted:
                EmptyView()
            }
        }
    }
}

struct MovieSkeletonGrid: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: MovieGridLayout.columns, spacing: 20) {
                ForEach(0..<9, id: \.self) { _ in
                    MovieCardView.skeleton
                }
            }
            .padding(.horizontal)
        }
        .scrollDisabled(true)
        .accessibilityIdentifier("movie_list.skeleton")
        .accessibilityLabel(Text("Loading movies"))
    }
}

#if DEBUG
#Preview("Grid") {
    @Previewable @State var paginator = Paginator<Movie> { page in
        try await PreviewMovieRepository().latestMovies(page: page)
    }
    MovieGridView(
        paginator: paginator,
        posterURL: { _ in nil },
        onSelect: { _ in }
    )
    .task { await paginator.loadFirstIfNeeded() }
}

#Preview("Skeleton") {
    MovieSkeletonGrid()
}
#endif
