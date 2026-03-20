import SwiftUI

struct ReauthenticationView: View {
    let context: ReauthenticationContext
    let isWorking: Bool
    let onCancel: () -> Void
    let onSubmitPassword: (String) async -> Void
    let onContinueWithProvider: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.tint)

                Text(.reauthenticationTitle)
                    .font(.title3.weight(.semibold))

                Text(.reauthenticationMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                switch context.method {
                case .email:
                    VStack(alignment: .leading, spacing: 12) {
                        if let email = context.email, !email.isEmpty {
                            Text(email)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        SecureField(L10n.string(.reauthenticationPasswordPlaceholder), text: $password)
                            .textContentType(.password)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task { await onSubmitPassword(password) }
                        } label: {
                            HStack {
                                if isWorking {
                                    ProgressView()
                                } else {
                                    Text(.reauthenticationContinueButton)
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .themedPrimaryButton(cornerRadius: 14)
                        }
                        .disabled(isWorking)
                    }

                case .apple, .google:
                    Button {
                        Task { await onContinueWithProvider() }
                    } label: {
                        HStack(spacing: 10) {
                            if isWorking {
                                ProgressView()
                            } else {
                                Image(systemName: context.method == .apple ? "applelogo" : "globe")
                                Text(context.method == .apple
                                     ? L10n.string(.reauthenticationAppleButton)
                                     : L10n.string(.reauthenticationGoogleButton))
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .themedPrimaryButton(cornerRadius: 14)
                    }
                    .disabled(isWorking)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle(L10n.string(.reauthenticationNavigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string(.commonClose)) {
                        onCancel()
                        dismiss()
                    }
                    .disabled(isWorking)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isWorking)
    }
}
