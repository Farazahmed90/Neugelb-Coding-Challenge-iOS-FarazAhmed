import SwiftUI

/// Compact vote-average badge (e.g. "★ 8.7").
public struct RatingBadge: View {
    private let voteAverage: Double

    public init(voteAverage: Double) {
        self.voteAverage = voteAverage
    }

    public var body: some View {
        Label(formatted, systemImage: "star.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.65), in: .capsule)
            .accessibilityLabel(Text("Rated \(formatted) out of 10"))
    }

    private var formatted: String {
        voteAverage.formatted(.number.precision(.fractionLength(1)))
    }
}
