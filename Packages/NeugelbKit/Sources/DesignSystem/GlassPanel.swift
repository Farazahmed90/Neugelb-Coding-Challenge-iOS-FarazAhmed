import SwiftUI

public extension View {
    /// Liquid Glass surface on iOS 26+, translucent material fallback
    /// on iOS 18, so floating panels feel native on every OS version.
    @ViewBuilder
    func glassPanel(cornerRadius: CGFloat = 24) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
        }
    }
}
