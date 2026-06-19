import Foundation
@testable import MoviesData
import Testing

struct AccessTokenProviderTests {
    private let key = TMDBAccessTokenProvider.keychainKey

    @Test func prefersTokenAlreadyInStore() async throws {
        let store = InMemorySecretStore(storage: [key: "stored-token"])
        let provider = TMDBAccessTokenProvider(store: store) { "bundled-token" }

        #expect(try await provider.accessToken() == "stored-token")
    }

    @Test func seedsStoreFromBundledSecretOnFirstRun() async throws {
        let store = InMemorySecretStore()
        let provider = TMDBAccessTokenProvider(store: store) { "bundled-token" }

        #expect(try await provider.accessToken() == "bundled-token")
        #expect(try store.read(key) == "bundled-token")
    }

    @Test func failsWithMissingCredentialsWhenNoSourceAvailable() async {
        let provider = TMDBAccessTokenProvider(store: InMemorySecretStore()) { nil }

        await #expect {
            _ = try await provider.accessToken()
        } throws: { error in
            guard case APIError.missingCredentials = error else { return false }
            return true
        }
        #expect(await !provider.hasToken())
    }

    @Test func ignoresEmptyBundledSecret() async {
        let provider = TMDBAccessTokenProvider(store: InMemorySecretStore()) { "" }

        #expect(await !provider.hasToken())
    }

    @Test func updatePersistsUserProvidedToken() async throws {
        let store = InMemorySecretStore()
        let provider = TMDBAccessTokenProvider(store: store) { nil }

        try await provider.update(token: "user-token")

        #expect(try await provider.accessToken() == "user-token")
        #expect(try store.read(key) == "user-token")
        #expect(await provider.hasToken())
    }
}
