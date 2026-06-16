import MoviesDomain
import Observation

/// A navigation destination in the app's stack. New screens add a case here.
enum Route: Hashable {
    case movieDetail(Movie)
}

/// Owns the navigation stack and exposes intent-based navigation, so screens
/// push routes instead of hardcoding destinations. Injected via the
/// environment; the composition root binds it to a `NavigationStack`.
@MainActor
@Observable
final class AppRouter {
    var path: [Route] = []

    func navigate(to route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
