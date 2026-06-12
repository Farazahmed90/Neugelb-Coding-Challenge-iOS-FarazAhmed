import SwiftUI

@main
struct NeugelbCodingChallenge_iOS_FarazAhmedApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
