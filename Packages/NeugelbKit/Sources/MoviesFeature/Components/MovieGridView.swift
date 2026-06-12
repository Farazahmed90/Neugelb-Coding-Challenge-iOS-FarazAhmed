import DesignSystem
import MoviesDomain
import SwiftUI

/// Adaptive poster grid bound to a paginator, with infinite-scroll
/// triggers and the load-more footer. Shared by list and search.
struct MovieGridView: View {
    let paginator: Paginator<Movie>
    let posterURL: (Movie) -> URL?
    var accessibilityIdentifier = "movie_list.grid"

    static let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Self.columns, spacing: 20) {
                ForEach(paginator.items) { movie in
                    NavigationLink(value: movie) {
                        MovieCardView(movie: movie, posterURL: posterURL(movie))
                    }
                    .buttonStyle(.plain)
                    .task { await paginator.loadMoreIfNeeded(after: movie) }
                }
            }
            .padding(.horizontal)

            footer
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private var footer: some View {
        if case .loaded(let loadMore) = paginator.state {
            switch loadMore {
            case .loading, .ready:
                // `.ready` shows the spinner too: by the time it is visible
                // the threshold prefetch has fired; avoids a flicker swap.
                ProgressView()
                    .padding(.vertical, 24)
                    .accessibilityLabel(Text("Loading more movies", bundle: .module))
            case .failed:
                VStack(spacing: 8) {
                    Text("Couldn't load more movies.", bundle: .module)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await paginator.retryLoadMore() }
                    } label: {
                        Text("Try Again", bundle: .module)
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

/// Redacted shimmer grid shown while a first page loads.
struct MovieSkeletonGrid: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: MovieGridView.columns, spacing: 20) {
                ForEach(0..<9, id: \.self) { _ in
                    MovieCardView.skeleton
                }
            }
            .padding(.horizontal)
        }
        .scrollDisabled(true)
        .accessibilityIdentifier("movie_list.skeleton")
        .accessibilityLabel(Text("Loading movies", bundle: .module))
    }
}
