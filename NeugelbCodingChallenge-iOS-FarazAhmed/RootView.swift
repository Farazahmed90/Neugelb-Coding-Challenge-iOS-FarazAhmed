import MoviesData
import MoviesDomain
import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    @State private var movieListViewModel: MovieListViewModel
    @State private var searchViewModel: MovieSearchViewModel
    @State private var router = AppRouter()

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
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
        .sheet(isPresented: $needsToken) {
            TokenEntryView { token in
                try? await dependencies.tokenProvider.update(token: token)
                needsToken = false
                await movieListViewModel.paginator.loadFirst()
            }
        }
    }
}
