import Foundation
import MoviesDomain
import Observation

@MainActor
@Observable
final class MovieListViewModel {
    
    let paginator: Paginator<Movie>
    private let imageURLResolver: any ImageURLResolving
    
    var movies: [Movie] { paginator.items }

    /// First few titles for the featured carousel at the top of the list.
    /// Prefers movies with a backdrop so the hero isn't a placeholder; falls
    /// back to the first few when none have one.
    var featured: [Movie] {
        let withBackdrop = paginator.items.filter { $0.backdropPath != nil }
        return Array((withBackdrop.isEmpty ? paginator.items : withBackdrop).prefix(5))
    }

    init(repository: any MovieRepository, imageURLResolver: any ImageURLResolving) {
        self.imageURLResolver = imageURLResolver
        self.paginator = Paginator { page in
            try await repository.latestMovies(page: page)
        }
    }

    func posterURL(for movie: Movie) -> URL? {
        imageURLResolver.imageURL(forPath: movie.posterPath, kind: .posterThumbnail)
    }

    func backdropURL(for movie: Movie) -> URL? {
        imageURLResolver.imageURL(forPath: movie.backdropPath ?? movie.posterPath, kind: .backdrop)
    }

    func errorMessage(for state: Paginator<Movie>.State) -> String {
        guard case .failedFirst(let error) = state else { return ErrorMessage.generic }
        return ErrorMessage.message(for: error)
    }
}
