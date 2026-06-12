import Foundation

/// Supplies the TMDB API read access token to the networking layer.
public protocol AccessTokenProviding: Sendable {
    func accessToken() async throws -> String
}

/// Keychain-first token resolution:
/// 1. Return the token already stored in the Keychain.
/// 2. Otherwise seed the Keychain from the dev-only bundled `Secrets.plist`
///    (gitignored; absent in fresh clones) and return it.
/// 3. Otherwise fail with `.missingCredentials`, which the app surfaces as
///    a one-time token entry screen feeding `update(token:)`.
///
/// Note: any client-side secret is extractable from a device; the Keychain
/// protects it at rest, but the production-grade answer is a backend proxy.
public actor TMDBAccessTokenProvider: AccessTokenProviding {
    public static let keychainKey = "tmdb.api.read-access-token"

    private let store: any SecretStore
    private let bundledToken: @Sendable () -> String?
    private var cached: String?

    public init(
        store: any SecretStore,
        bundledToken: @escaping @Sendable () -> String? = { BundledSecrets.accessToken() }
    ) {
        self.store = store
        self.bundledToken = bundledToken
    }

    public func accessToken() async throws -> String {
        if let cached {
            return cached
        }
        if let stored = try store.read(Self.keychainKey) {
            cached = stored
            return stored
        }
        if let seed = bundledToken(), !seed.isEmpty {
            try store.save(seed, for: Self.keychainKey)
            cached = seed
            return seed
        }
        throw APIError.missingCredentials
    }

    /// Stores a token entered by the user (first-launch fallback flow).
    public func update(token: String) throws {
        try store.save(token, for: Self.keychainKey)
        cached = token
    }

    /// True when a token can be resolved without user input.
    public func hasToken() async -> Bool {
        (try? await accessToken()) != nil
    }
}

/// Reads the development seed token from the app bundle.
public enum BundledSecrets {
    public static func accessToken(in bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dictionary = plist as? [String: Any] else {
            return nil
        }
        return dictionary["TMDB_ACCESS_TOKEN"] as? String
    }
}
