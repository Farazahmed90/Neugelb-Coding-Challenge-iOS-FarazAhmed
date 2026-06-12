import DesignSystem
import MoviesDomain
import SwiftUI

/// Latest movies in an adaptive poster grid with infinite scrolling,
/// pull-to-refresh, skeleton/error/empty states, and debounced search.
public struct MovieListScreen: View {
    private let viewModel: MovieListViewModel
    @Bindable private var searchViewModel: MovieSearchViewModel

    public init(viewModel: MovieListViewModel, searchViewModel: MovieSearchViewModel) {
        self.viewModel = viewModel
        self.searchViewModel = searchViewModel
    }

    public var body: some View {
        Group {
            if searchViewModel.query.isEmpty {
                listContent
            } else {
                MovieSearchResultsView(viewModel: searchViewModel)
            }
        }
        .navigationTitle(Text("Now Playing", bundle: .module))
        .searchable(
            text: $searchViewModel.query,
            prompt: Text("Search movies", bundle: .module)
        )
        .task { await viewModel.paginator.loadFirstIfNeeded() }
    }

    @ViewBuilder
    private var listContent: some View {
        switch viewModel.paginator.state {
        case .idle, .loadingFirst:
            MovieSkeletonGrid()
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
        case .loaded:
            MovieGridView(
                paginator: viewModel.paginator,
                posterURL: viewModel.posterURL
            )
            .refreshable { await viewModel.paginator.refresh() }
        }
    }
}
