import SwiftUI

/// Sliding highlight used on redacted skeleton placeholders.
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .mask {
                GeometryReader { proxy in
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.45), location: 0),
                            .init(color: .black, location: 0.5),
                            .init(color: .black.opacity(0.45), location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 3)
                    .offset(x: phase * proxy.size.width * 2)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

public extension View {
    /// Applies a shimmer sweep; combine with `.redacted(reason: .placeholder)`.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
