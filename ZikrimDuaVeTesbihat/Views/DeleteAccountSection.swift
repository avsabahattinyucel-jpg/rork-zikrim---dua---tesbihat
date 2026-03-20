import SwiftUI

struct DeleteAccountSection: View {
    let isDeleting: Bool
    let action: () -> Void

    var body: some View {
        Section {
            Button(role: .destructive, action: action) {
                HStack(spacing: 12) {
                    if isDeleting {
                        ProgressView()
                            .tint(.red)
                    } else {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(.deleteAccountTitle)
                            .foregroundStyle(.red)
                        Text(.deleteAccountHint)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .disabled(isDeleting)
        } header: {
            Text(.dangerZoneTitle)
        }
    }
}
