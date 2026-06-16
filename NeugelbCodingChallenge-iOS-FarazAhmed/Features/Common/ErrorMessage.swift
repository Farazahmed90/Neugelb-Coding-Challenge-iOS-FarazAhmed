import Foundation
import MoviesDomain

/// Maps domain errors to localized, user-facing copy. Shared by the feature view models.
enum ErrorMessage {
    static let generic = String(localized: "Something went wrong. Please try again.")

    static func message(for error: any Error) -> String {
        switch error as? MovieRepositoryError {
        case .network:
            return String(localized: "You appear to be offline. Check your connection and try again.")
        case .unauthorized:
            return String(localized: "Your TMDB access token was rejected. Please update it.")
        case .serverUnavailable:
            return String(localized: "The movie database is currently unavailable. Try again in a moment.")
        case .notFound:
            return String(localized: "This movie could not be found.")
        case .unknown, nil:
            return generic
        }
    }
}
