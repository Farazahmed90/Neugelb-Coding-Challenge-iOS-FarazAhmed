import Foundation
@testable import MoviesData

// MARK: - HTTP transport

actor HTTPClientMock: HTTPClient {
    enum Stub {
        case success(data: Data, statusCode: Int)
        case failure(any Error)
    }

    private var stubs: [Stub]
    private(set) var requests: [URLRequest] = []

    init(_ stubs: Stub...) {
        self.stubs = stubs
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        precondition(!stubs.isEmpty, "HTTPClientMock needs at least one stub")
        // Repeat the last stub once consumed, so a single stub survives the
        // client's automatic retries.
        let stub = stubs.count > 1 ? stubs.removeFirst() : stubs[0]
        switch stub {
        case .success(let data, let statusCode):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Auth

struct StaticTokenProvider: AccessTokenProviding {
    var token = "test-token"

    func accessToken() async throws -> String { token }
}

// MARK: - Secrets

final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: String]

    init(storage: [String: String] = [:]) {
        self.storage = storage
    }

    func read(_ key: String) throws -> String? {
        lock.withLock { storage[key] }
    }

    func save(_ value: String, for key: String) throws {
        lock.withLock { storage[key] = value }
    }

    func delete(_ key: String) throws {
        _ = lock.withLock { storage.removeValue(forKey: key) }
    }
}

// MARK: - Fixtures

enum Fixtures {
    static func data(_ name: String) throws -> Data {
        let url = Bundle.module.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "Fixtures"
        )!
        return try Data(contentsOf: url)
    }
}

// MARK: - Shared configuration

extension TMDBConfiguration {
    static let test = TMDBConfiguration(
        apiBaseURL: URL(string: "https://api.example.com/3")!,
        imageBaseURL: URL(string: "https://images.example.com/t/p")!,
        language: "en-US"
    )
}
