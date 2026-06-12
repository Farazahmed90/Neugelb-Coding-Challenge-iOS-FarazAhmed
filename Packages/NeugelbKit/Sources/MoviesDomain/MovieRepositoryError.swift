/// Failure vocabulary of `MovieRepository`, independent of any transport.
/// The data layer maps its concrete errors into these cases so features
/// can present user-appropriate messages without knowing about HTTP.
public enum MovieRepositoryError: Error, Equatable, Sendable {
    /// Connectivity problems: offline, timeouts, DNS failures.
    case network
    /// The API rejected our credentials (or none are configured).
    case unauthorized
    /// The requested resource does not exist.
    case notFound
    /// The service is having problems (5xx).
    case serverUnavailable
    /// Anything else, including malformed responses.
    case unknown
}
