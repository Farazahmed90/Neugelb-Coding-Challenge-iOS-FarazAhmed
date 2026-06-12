import MoviesData
import MoviesDomain
import MoviesFeature
import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    @State private var movieListViewModel: MovieListViewModel
    @State private var searchViewModel: MovieSearchViewModel

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
        NavigationStack {
            MovieListScreen(viewModel: movieListViewModel, searchViewModel: searchViewModel)
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailScreen(
                        viewModel: MovieDetailViewModel(
                            movie: movie,
                            repository: dependencies.movieRepository,
                            imageURLResolver: dependencies.imageURLResolver
                        )
                    )
                }
        }
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
