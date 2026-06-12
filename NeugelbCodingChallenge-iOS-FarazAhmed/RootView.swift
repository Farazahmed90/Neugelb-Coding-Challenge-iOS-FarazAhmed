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
    }
}
