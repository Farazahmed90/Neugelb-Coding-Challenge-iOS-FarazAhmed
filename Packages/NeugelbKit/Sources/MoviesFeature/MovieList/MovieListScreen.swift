import DesignSystem
import MoviesDomain
import SwiftUI

/// Latest movies in an adaptively sized poster grid with infinite
/// scrolling, pull-to-refresh, and skeleton/error/empty states.
public struct MovieListScreen: View {
    private let viewModel: MovieListViewModel

    public init(viewModel: MovieListViewModel) {
        self.viewModel = viewModel
    }

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)]

    public var body: some View {
        content
            .navigationTitle(Text("Now Playing", bundle: .module))
            .task { await viewModel.paginator.loadFirstIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.paginator.state {
        case .idle, .loadingFirst:
            skeletonGrid
        case .failedFirst:
            ErrorStateView(
                message: viewModel.errorMessage(for: viewModel.paginator.state),
                retryTitle: String(localized: "Try Again", bundle: .module)
            ) {
                await viewModel.paginator.loadFirst()
            }
        case .loaded where viewModel.movies.isEmpty:
            ContentUnavailableView(
                String(localized: "No movies right now", bundle: .module),
                systemImage: "popcorn",
                description: Text("Pull to refresh and check again.", bundle: .module)
            )
        case .loaded(let loadMore):
            movieGrid(loadMore: loadMore)
        }
    }

    private func movieGrid(loadMore: Paginator<Movie>.LoadMore) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.movies) { movie in
                    NavigationLink(value: movie) {
                        MovieCardView(movie: movie, posterURL: viewModel.posterURL(for: movie))
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.paginator.loadMoreIfNeeded(after: movie)
                    }
                }
            }
            .padding(.horizontal)

            listFooter(loadMore: loadMore)
        }
        .accessibilityIdentifier("movie_list.grid")
        .refreshable { await viewModel.paginator.refresh() }
    }

    @ViewBuilder
    private func listFooter(loadMore: Paginator<Movie>.LoadMore) -> some View {
        switch loadMore {
        case .loading, .ready:
            // `.ready` shows the spinner too: by the time it is visible the
            // threshold prefetch has fired, so this avoids a flicker swap.
            ProgressView()
                .padding(.vertical, 24)
                .accessibilityLabel(Text("Loading more movies", bundle: .module))
        case .failed:
            VStack(spacing: 8) {
                Text("Couldn't load more movies.", bundle: .module)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    Task { await viewModel.paginator.retryLoadMore() }
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

    private var skeletonGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
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
