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
                    SecureField("TMDB Access Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("token_entry.field")
                } header: {
                    Text("TMDB Access Token")
                } footer: {
                    Text("Paste your TMDB API Read Access Token (v4) to load movies. It is stored securely in the Keychain. You can create a free token at themoviedb.org/settings/api.")
                }
            }
            .navigationTitle(Text("Welcome"))
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
                            Text("Save")
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
