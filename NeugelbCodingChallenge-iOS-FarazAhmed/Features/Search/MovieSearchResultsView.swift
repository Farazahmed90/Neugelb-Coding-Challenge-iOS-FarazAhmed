import DesignSystem
import SwiftUI

struct MovieSearchResultsView: View {
    @Environment(AppRouter.self) private var router
    let viewModel: MovieSearchViewModel

    var body: some View {
        ZStack {
            phaseContent
                .id(viewModel.phase)
                // Fade between phases (idle, skeleton, results) instead of a
                // harder swap.
                .transition(.opacity)
        }
        .animation(.smooth(duration: 0.3), value: viewModel.phase)
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .idle:
            ContentUnavailableView {
                Label {
                    Text("Search movies")
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
            } description: {
                Text(L10n.Search.minCharacters)
            }
        case .searching:
            MovieSkeletonGrid()
        case .failed(let message):
            ErrorStateView(message: message, retryTitle: String(localized: "Try Again")) {
                viewModel.retry()
            }
        case .loaded where viewModel.results.isEmpty:
            ContentUnavailableView.search(text: viewModel.query)
        case .loaded:
            if let paginator = viewModel.paginator {
                MovieGridView(
                    paginator: paginator,
                    posterURL: viewModel.posterURL,
                    onSelect: { router.navigate(to: .movieDetail($0)) },
                    accessibilityIdentifier: "search.results_grid",
                    onScrollStarted: { viewModel.dismissSuggestions() }
                )
                .opacity(viewModel.isRefreshing ? 0.55 : 1)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isRefreshing)
                // Hide the suggestions on the first drag, together with the
                // keyboard. The scroll-phase callback alone reacts one drag late
                // because the keyboard dismissal eats the first one.
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10).onChanged { _ in
                        viewModel.dismissSuggestions()
                    }
                )
            }
        }
    }
}
