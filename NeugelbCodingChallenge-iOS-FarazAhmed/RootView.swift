import DesignSystem
import MoviesData
import MoviesDomain
import SwiftUI

struct RootView: View {
    private let dependencies: AppDependencies
    /// False while the launch splash is up, so the token sheet waits for it.
    private let isActive: Bool

    @State private var movieListViewModel: MovieListViewModel
    @State private var searchViewModel: MovieSearchViewModel
    @State private var router = AppRouter()

    init(dependencies: AppDependencies, isActive: Bool = true) {
        self.dependencies = dependencies
        self.isActive = isActive
        _movieListViewModel = State(
            initialValue: MovieListViewModel(
                repository: dependencies.movieRepository,
                imageURLResolver: dependencies.imageURLResolver
            )
        )
        _searchViewModel = State(
            initialValue: MovieSearchViewModel(
                repository: dependencies.movieRepository,
                imageURLResolver: dependencies.imageURLResolver
            )
        )
    }

    @State private var needsToken = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            MovieListScreen(viewModel: movieListViewModel, searchViewModel: searchViewModel)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .movieDetail(let movie):
                        MovieDetailScreen(
                            viewModel: MovieDetailViewModel(
                                movie: movie,
                                repository: dependencies.movieRepository,
                                imageURLResolver: dependencies.imageURLResolver
                            )
                        )
                    }
                }
        }
        .environment(router)
        .environment(\.imageLoader, dependencies.imageLoader)
        .task {
            needsToken = await !dependencies.tokenProvider.hasToken()
        }
        .onChange(of: movieListViewModel.isUnauthorized) { _, rejected in
            // A stored-but-invalid token surfaces here; re-prompt so it can be replaced.
            if rejected { needsToken = true }
        }
        .sheet(isPresented: Binding(get: { needsToken && isActive }, set: { needsToken = $0 })) {
            TokenEntryView { token in
                try? await dependencies.tokenProvider.update(token: token)
                await movieListViewModel.paginator.loadFirst()
                // Keep prompting if the new token is also rejected.
                needsToken = movieListViewModel.isUnauthorized
            }
        }
    }
}
