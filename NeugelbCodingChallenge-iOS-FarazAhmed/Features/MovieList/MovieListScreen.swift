import DesignSystem
import MoviesDomain
import SwiftUI

struct MovieListScreen: View {
    @Environment(AppRouter.self) private var router
    private let viewModel: MovieListViewModel
    @Bindable private var searchViewModel: MovieSearchViewModel

    init(viewModel: MovieListViewModel, searchViewModel: MovieSearchViewModel) {
        self.viewModel = viewModel
        self.searchViewModel = searchViewModel
    }

    var body: some View {
        Group {
            if searchViewModel.query.isEmpty {
                listContent
            } else {
                MovieSearchResultsView(viewModel: searchViewModel)
            }
        }
        .navigationTitle(Text(L10n.MovieList.title))
        .overlay(alignment: .bottom) {
            if !searchViewModel.suggestions.isEmpty {
                SearchSuggestionsPanel(suggestions: searchViewModel.suggestions) { title in
                    searchViewModel.acceptSuggestion(title)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Calm slide-up for the suggestions panel, no bounce.
        .animation(.smooth(duration: 0.45), value: searchViewModel.suggestions)
        .searchable(text: $searchViewModel.query, prompt: Text("Search movies"))
        .onSubmit(of: .search) { searchViewModel.submit() }
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
                retryTitle: String(localized: "Try Again")
            ) {
                await viewModel.paginator.loadFirst()
            }
        case .loaded where viewModel.movies.isEmpty:
            ContentUnavailableView(
                String(localized: L10n.MovieList.emptyTitle),
                systemImage: "popcorn",
                description: Text(L10n.MovieList.emptyDescription)
            )
        case .loaded:
            MovieGridView(
                paginator: viewModel.paginator,
                posterURL: viewModel.posterURL,
                onSelect: { router.navigate(to: .movieDetail($0)) }
            ) {
                if !viewModel.featured.isEmpty {
                    FeaturedCarousel(
                        movies: viewModel.featured,
                        backdropURL: viewModel.backdropURL,
                        onSelect: { router.navigate(to: .movieDetail($0)) }
                    )
                }
            }
            .refreshable { await viewModel.paginator.refresh() }
        }
    }
}

#if DEBUG
@MainActor
private func previewListScreen(failure: PreviewMovieRepository = PreviewMovieRepository()) -> some View {
    NavigationStack {
        MovieListScreen(
            viewModel: MovieListViewModel(repository: failure, imageURLResolver: PreviewImageURLResolver()),
            searchViewModel: MovieSearchViewModel(repository: failure, imageURLResolver: PreviewImageURLResolver())
        )
    }
    .environment(AppRouter())
}

#Preview("Loaded") {
    previewListScreen()
}

#Preview("Failure") {
    previewListScreen(failure: PreviewMovieRepository(failure: .network))
}

#Preview("Dark, Large Type") {
    previewListScreen()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility1)
}
#endif
