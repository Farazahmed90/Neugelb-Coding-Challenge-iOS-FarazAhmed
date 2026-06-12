import MoviesDomain
import MoviesFeature
import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    @State private var movieListViewModel: MovieListViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _movieListViewModel = State(
            initialValue: MovieListViewModel(
                repository: dependencies.movieRepository,
                imageURLResolver: dependencies.imageURLResolver
            )
        )
    }

    var body: some View {
        NavigationStack {
            MovieListScreen(viewModel: movieListViewModel)
            // Movie detail destination lands with #Neugelb-003.
        }
        .environment(\.imageLoader, dependencies.imageLoader)
    }
}
