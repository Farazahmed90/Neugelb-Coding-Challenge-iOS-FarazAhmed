import Foundation

// Response type for endpoints that return no body (e.g. 204 No Content).
struct EmptyResponse: Decodable, Sendable {
    init() {}
    init(from decoder: any Decoder) throws {}
}
