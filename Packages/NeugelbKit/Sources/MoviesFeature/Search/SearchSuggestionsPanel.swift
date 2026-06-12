import DesignSystem
import SwiftUI

/// Compact completion panel floating directly above the search bar,
/// styled as a glass surface like a native part of the search field.
struct SearchSuggestionsPanel: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    private let visibleCount = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.prefix(visibleCount).enumerated()), id: \.element) {
                index, title in
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
                    .padding(.vertical, 12)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("search.suggestion")

                if index < min(suggestions.count, visibleCount) - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .glassPanel(cornerRadius: 20)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Search suggestions", bundle: .module))
    }
}
