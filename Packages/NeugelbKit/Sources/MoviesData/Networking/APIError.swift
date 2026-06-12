import Foundation

public enum APIError: Error {
    /// No access token available from Keychain or bundle seed.
    case missingCredentials
    /// The response was not an HTTP response at all.
    case invalidResponse
    /// HTTP status outside 200..<300.
    case unacceptableStatus(code: Int)
    /// The body could not be decoded into the expected type.
    case decoding(underlying: any Error)
    /// The request failed at the transport level (offline, timeout, DNS…).
    case transport(underlying: any Error)
}

extension APIError {
    /// True when retrying might help (connectivity issues, server errors)
    /// as opposed to permanent failures like 401/404 or decoding bugs.
    public var isRetryable: Bool {
        switch self {
        case .transport:
            return true
        case .unacceptableStatus(let code):
            return code >= 500
        case .missingCredentials, .invalidResponse, .decoding, .unacceptableStatus:
            return false
        }
    }
}
