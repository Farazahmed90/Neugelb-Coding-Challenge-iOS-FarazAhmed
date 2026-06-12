#if DEBUG
import SwiftUI

#Preview("Loaded") {
    NavigationStack {
        MovieListScreen(
            viewModel: MovieListViewModel(
                repository: PreviewMovieRepository(),
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
}

#Preview("Failure") {
    NavigationStack {
        MovieListScreen(
            viewModel: MovieListViewModel(
                repository: PreviewMovieRepository(failure: .network),
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
}

#Preview("Dark, Large Type") {
    NavigationStack {
        MovieListScreen(
            viewModel: MovieListViewModel(
                repository: PreviewMovieRepository(),
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
    .preferredColorScheme(.dark)
    .dynamicTypeSize(.accessibility1)
}
#endif
