import SwiftUI

struct FooterLinks: View {
    let isRestoring: Bool
    let onRestore: () -> Void
    let onPrivacy: () -> Void
    let onTerms: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text("İstediğin zaman iptal edebilirsin")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ViewThatFits(in: .horizontal) {
                inlineLinks
                wrappedLinks
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var inlineLinks: some View {
        HStack(spacing: 10) {
            footerButton(
                title: L10n.string(.restorePurchasesTitle),
                isLoading: isRestoring,
                action: onRestore
            )
            separator
            footerButton(title: L10n.string(.gizlilikPolitikasi), action: onPrivacy)
            separator
            footerButton(title: LegalLinks.standardEULAShortTitle, action: onTerms)
        }
        .multilineTextAlignment(.center)
    }

    private var wrappedLinks: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                footerButton(
                    title: L10n.string(.restorePurchasesTitle),
                    isLoading: isRestoring,
                    action: onRestore
                )
                separator
                footerButton(title: L10n.string(.gizlilikPolitikasi), action: onPrivacy)
            }

            footerButton(title: LegalLinks.standardEULAShortTitle, action: onTerms)
        }
    }

    private var separator: some View {
        Text("·")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.tertiary)
    }

    private func footerButton(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if isLoading {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(title)
                    }
                } else {
                    Text(title)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
