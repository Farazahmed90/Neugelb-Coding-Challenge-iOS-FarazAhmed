import MoviesDomain
import Testing
@testable import NeugelbCodingChallenge_iOS_FarazAhmed

@MainActor
struct AppRouterTests {
    // AppRouter is a thin wrapper over a path array; only the crash-guard
    // (popping an empty stack) carries logic worth pinning down.
    @Test func popOnEmptyStackIsSafe() {
        let router = AppRouter()
        router.pop()
        #expect(router.path.isEmpty)
    }
}
