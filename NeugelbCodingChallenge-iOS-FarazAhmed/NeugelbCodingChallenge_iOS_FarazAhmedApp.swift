import SwiftUI

@main
struct NeugelbCodingChallenge_iOS_FarazAhmedApp: App {
    private let dependencies = AppDependencies.live()
    @State private var splashDone = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView(dependencies: dependencies, isActive: splashDone)
                if !splashDone {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(.easeInOut(duration: 0.6)) { splashDone = true }
            }
        }
    }
}
