import Foundation

/// A request body together with the `Content-Type` it should be sent as.
/// The builder sets the header automatically so call sites never forget it.
public struct HTTPBody: Sendable {
    public let data: Data
    public let contentType: String

    public init(data: Data, contentType: String) {
        self.data = data
        self.contentType = contentType
    }

    /// JSON-encodes any `Encodable` payload (`Content-Type: application/json`).
    public static func json(
        _ value: some Encodable,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> HTTPBody {
        HTTPBody(data: try encoder.encode(value), contentType: "application/json")
    }

    /// Raw bytes with a caller-supplied content type (form data, protobuf, …).
    public static func raw(_ data: Data, contentType: String) -> HTTPBody {
        HTTPBody(data: data, contentType: contentType)
    }
}

/// Backend-agnostic description of a single HTTP request, relative to some
/// base URL. Method/headers/body default to a simple GET, so read-only
/// endpoints stay a one-line `path`, while POST/PUT/PATCH endpoints just
/// override the pieces they need. Auth and other cross-cutting concerns are
/// injected by the client, not baked into the endpoint.
public protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var body: HTTPBody? { get }
}

public extension Endpoint {
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
    var body: HTTPBody? { nil }

    /// Assembles a `URLRequest` from this endpoint.
    ///
    /// - Parameters:
    ///   - baseURL: Backend root the `path` is appended to.
    ///   - defaultQueryItems: Query items applied to every request (e.g. an
    ///     API's `language`/`api_key`). Endpoint items come first.
    ///   - defaultHeaders: Headers applied to every request (e.g. `Accept`,
    ///     `Authorization`). Endpoint-specific headers override these.
    func urlRequest(
        baseURL: URL,
        defaultQueryItems: [URLQueryItem] = [],
        defaultHeaders: [String: String] = [:]
    ) -> URLRequest {
        var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )!
        let allQueryItems = queryItems + defaultQueryItems
        if !allQueryItems.isEmpty {
            components.queryItems = allQueryItems
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue

        // Client defaults first, then let the endpoint override them.
        for (field, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let body {
            request.httpBody = body.data
            request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
