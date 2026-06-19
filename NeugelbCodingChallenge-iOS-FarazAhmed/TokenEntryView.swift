import SwiftUI

/// First-launch fallback when no TMDB token is available from the
/// Keychain or the bundled dev secrets: lets the reviewer paste a token
/// once; it is stored in the Keychain from then on.
struct TokenEntryView: View {
    let onSave: (String) async -> Void

    @State private var token = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(String(localized: L10n.TokenEntry.accessTokenLabel), text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("token_entry.field")
                } header: {
                    Text(L10n.TokenEntry.accessTokenLabel)
                } footer: {
                    Text(L10n.TokenEntry.instructions)
                }
            }
            .navigationTitle(Text(L10n.TokenEntry.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isSaving = true
                        Task {
                            await onSave(token.trimmingCharacters(in: .whitespacesAndNewlines))
                            isSaving = false
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(L10n.TokenEntry.save)
                        }
                    }
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .accessibilityIdentifier("token_entry.save")
                }
            }
        }
        .interactiveDismissDisabled()
    }
}
