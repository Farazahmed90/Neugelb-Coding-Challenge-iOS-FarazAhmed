import Foundation
import MoviesDomain
import Observation

@MainActor
@Observable
public final class MovieListViewModel {
    public let paginator: Paginator<Movie>
    private let imageURLResolver: any ImageURLResolving

    public init(
        repository: any MovieRepository,
        imageURLResolver: any ImageURLResolving
    ) {
        self.imageURLResolver = imageURLResolver
        self.paginator = Paginator { page in
            try await repository.latestMovies(page: page)
        }
    }

    public var movies: [Movie] { paginator.items }

    public func posterURL(for movie: Movie) -> URL? {
        imageURLResolver.imageURL(forPath: movie.posterPath, kind: .posterThumbnail)
    }

    public func errorMessage(for state: Paginator<Movie>.State) -> String {
        guard case .failedFirst(let error) = state else {
            return ErrorMessage.generic
        }
        return ErrorMessage.message(for: error)
    }
}

/// Maps domain errors to user-facing copy (localized in the string catalog).
enum ErrorMessage {
    static let generic = String(
        localized: "Something went wrong. Please try again.",
        bundle: .module
    )

    static func message(for error: any Error) -> String {
        switch error as? MovieRepositoryError {
        case .network:
            return String(
                localized: "You appear to be offline. Check your connection and try again.",
                bundle: .module
            )
        case .unauthorized:
            return String(
                localized: "Your TMDB access token was rejected. Please update it.",
                bundle: .module
            )
        case .serverUnavailable:
            return String(
                localized: "The movie database is currently unavailable. Try again in a moment.",
                bundle: .module
            )
        case .notFound, .unknown, nil:
            return generic
        }
    }
}
