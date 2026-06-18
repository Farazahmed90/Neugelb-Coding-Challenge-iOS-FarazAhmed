import Foundation

/// HTTP verbs an `Endpoint` can declare. Backend-agnostic.
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

extension HTTPMethod {
    // Safe to auto-retry — replaying the call has the same effect.
    var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete: return true
        case .post, .patch: return false
        }
    }
}
