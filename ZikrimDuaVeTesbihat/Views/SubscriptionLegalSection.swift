import SwiftUI

struct SubscriptionLegalSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    let subscriptionTitle: String
    let subscriptionDuration: String
    let subscriptionPrice: String
    let isRestoring: Bool
    let onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(PremiumConstants.complianceSectionTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                complianceRow(title: PremiumConstants.compliancePlanLabel, value: subscriptionTitle)
                complianceRow(title: PremiumConstants.complianceDurationLabel, value: subscriptionDuration)
                complianceRow(title: PremiumConstants.compliancePriceLabel, value: subscriptionPrice)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(PremiumConstants.complianceDisclosures, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accentColor)
                            .padding(.top, 2)

                        Text(line)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            restoreButton

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    legalButton(title: L10n.string(.gizlilikPolitikasi), url: LegalLinks.privacyPolicyURL)
                    legalButton(title: LegalLinks.standardEULATitle, url: LegalLinks.termsOfUseURL)
                }

                VStack(spacing: 8) {
                    legalButton(title: L10n.string(.gizlilikPolitikasi), url: LegalLinks.privacyPolicyURL)
                    legalButton(title: LegalLinks.standardEULATitle, url: LegalLinks.termsOfUseURL)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }

    private func complianceRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var restoreButton: some View {
        Button(action: onRestore) {
            HStack(spacing: 8) {
                if isRestoring {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(L10n.string(.restorePurchasesTitle))
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, 12)
            .foregroundStyle(accentColor)
            .background(buttonBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRestoring)
    }

    private func legalButton(title: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(buttonBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.05)
                ]
                : [
                    Color.white.opacity(0.94),
                    Color(red: 0.93, green: 0.98, blue: 0.99).opacity(0.96)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var buttonBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 0.16, green: 0.73, blue: 0.76).opacity(0.08)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color(red: 0.13, green: 0.44, blue: 0.54).opacity(0.12)
    }

    private var accentColor: Color {
        Color(red: 0.20, green: 0.77, blue: 0.81)
    }
}
