import DesignSystem
import SwiftUI

/// Compact completion panel floating directly above the search bar,
/// styled as a glass surface like a native part of the search field.
/// Grows with its rows and scrolls once it exceeds `maxHeight`.
struct SearchSuggestionsPanel: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    private let maxHeight: CGFloat = 196
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element) { index, title in
                    Button {
                        onSelect(title)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(title)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.backward")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("search.suggestion")

                    if index < suggestions.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                contentHeight = height
            }
        }
        .frame(height: min(contentHeight, maxHeight))
        .scrollBounceBehavior(.basedOnSize)
        .glassPanel(cornerRadius: 20)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(L10n.Search.suggestionsLabel))
    }
}
