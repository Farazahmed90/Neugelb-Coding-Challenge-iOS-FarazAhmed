import SwiftUI

struct SplashView: View {
    @State private var revealed = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("NEU")
                Text("GELB")
            }
            .font(.system(size: 72, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .scaleEffect(revealed ? 1 : 0.86)
            .opacity(revealed ? 1 : 0)
        }
        .task {
            withAnimation(.easeInOut(duration: 1.2)) {
                revealed = true
            }
        }
    }
}

#Preview {
    SplashView()
}
