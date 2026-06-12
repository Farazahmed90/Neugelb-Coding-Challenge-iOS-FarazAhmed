#if DEBUG
import SwiftUI

#Preview("Loaded") {
    NavigationStack {
        MovieDetailScreen(
            viewModel: MovieDetailViewModel(
                movie: PreviewData.movies[0],
                repository: PreviewMovieRepository(),
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
}

#Preview("Failure, Dark") {
    NavigationStack {
        MovieDetailScreen(
            viewModel: MovieDetailViewModel(
                movie: PreviewData.movies[1],
                repository: PreviewMovieRepository(failure: .network),
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
    .preferredColorScheme(.dark)
}
#endif
