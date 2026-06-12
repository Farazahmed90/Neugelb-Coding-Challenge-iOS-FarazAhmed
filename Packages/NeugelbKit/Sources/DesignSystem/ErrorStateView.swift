import SwiftUI

/// Full-screen failure state with a retry affordance.
public struct ErrorStateView: View {
    private let message: String
    private let retryTitle: String
    private let retry: () async -> Void

    public init(
        message: String,
        retryTitle: String,
        retry: @escaping () async -> Void
    ) {
        self.message = message
        self.retryTitle = retryTitle
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label(message, systemImage: "wifi.exclamationmark")
        } actions: {
            Button(retryTitle) {
                Task { await retry() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("error_state.retry_button")
        }
    }
}
