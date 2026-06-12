import DesignSystem
import SwiftUI

/// Search phases: typing hint, skeleton while searching, live results
/// grid (the autocomplete), no-results, and failure with retry.
struct MovieSearchResultsView: View {
    let viewModel: MovieSearchViewModel

    var body: some View {
        switch viewModel.phase {
        case .idle:
            ContentUnavailableView {
                Label {
                    Text("Search movies", bundle: .module)
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
            } description: {
                Text("Type at least two characters to search.", bundle: .module)
            }
        case .searching:
            MovieSkeletonGrid()
        case .failed(let message):
            ErrorStateView(
                message: message,
                retryTitle: String(localized: "Try Again", bundle: .module)
            ) {
                viewModel.retry()
            }
        case .loaded where viewModel.results.isEmpty:
            ContentUnavailableView.search(text: viewModel.query)
        case .loaded:
            if let paginator = viewModel.paginator {
                MovieGridView(
                    paginator: paginator,
                    posterURL: viewModel.posterURL,
                    accessibilityIdentifier: "search.results_grid",
                    onScrollStarted: { viewModel.dismissSuggestions() }
                )
                .opacity(viewModel.isRefreshing ? 0.55 : 1)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isRefreshing)
            }
        }
    }
}
