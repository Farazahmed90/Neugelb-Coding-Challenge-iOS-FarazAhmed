#if DEBUG
import SwiftUI

@MainActor
private func makeScreen(failure: PreviewMovieRepository = PreviewMovieRepository()) -> some View {
    NavigationStack {
        MovieListScreen(
            viewModel: MovieListViewModel(
                repository: failure,
                imageURLResolver: PreviewImageURLResolver()
            ),
            searchViewModel: MovieSearchViewModel(
                repository: failure,
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
}

#Preview("Loaded") {
    makeScreen()
}

#Preview("Failure") {
    makeScreen(failure: PreviewMovieRepository(failure: .network))
}

#Preview("Dark, Large Type") {
    makeScreen()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility1)
}
#endif
