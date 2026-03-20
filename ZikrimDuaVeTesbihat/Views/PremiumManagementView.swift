import SwiftUI

struct PremiumManagementView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.openURL) private var openURL

    let subscriptionStore: SubscriptionStore

    @State private var isRestoringPurchases: Bool = false
    @State private var feedbackMessage: String?

    private static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")

    var body: some View {
        let palette = themeManager.palette(using: systemColorScheme)

        ThemedScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection(palette: palette)
                    statusCard(palette: palette)
                    featuresCard(palette: palette)
                    actionStack(palette: palette)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .navigationTitle(PremiumEntryL10n.managementTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(L10n.string(.accountSettingsStatusTitle), isPresented: Binding(
            get: { feedbackMessage != nil },
            set: { if !$0 { feedbackMessage = nil } }
        )) {
            Button(L10n.string(.tamam2), role: .cancel) {}
        } message: {
            Text(feedbackMessage ?? "")
        }
        .task {
            await subscriptionStore.refresh(force: false)
        }
    }

    private func headerSection(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(PremiumEntryL10n.cardActiveTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(palette.primaryText)

                    Text(headerSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                    Text(L10n.string(.premiumStatusActive))
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(palette.accent.opacity(0.12))
                .foregroundStyle(palette.accent)
                .clipShape(.capsule)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(palette.elevatedCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(palette.borderColor.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: palette.shadowColor.opacity(0.08), radius: 18, y: 10)
    }

    private func statusCard(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            statusRow(
                title: PremiumEntryL10n.managementPlan,
                value: subscriptionStore.currentPlanName ?? L10n.string(.premium)
            )

            statusDivider(palette: palette)

            statusRow(
                title: PremiumEntryL10n.managementStatus,
                value: subscriptionStore.isPremium ? L10n.string(.premiumStatusActive) : L10n.string(.premiumStatusFree)
            )

            if let renewalValue {
                statusDivider(palette: palette)
                statusRow(
                    title: PremiumEntryL10n.managementRenews,
                    value: renewalValue
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(palette.borderColor.opacity(0.65), lineWidth: 1)
        )
    }

    private func featuresCard(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(PremiumEntryL10n.managementFeatures)
                .font(.headline.weight(.semibold))
                .foregroundStyle(palette.primaryText)

            ForEach(featureItems, id: \.title) { feature in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .frame(width: 20, alignment: .center)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.primaryText)
                        Text(feature.detail)
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(palette.borderColor.opacity(0.65), lineWidth: 1)
        )
    }

    private func actionStack(palette: ThemePalette) -> some View {
        VStack(spacing: 12) {
            premiumActionButton(
                title: PremiumEntryL10n.managementManage,
                systemImage: "arrow.up.forward.app.fill",
                fills: true,
                isLoading: false,
                palette: palette
            ) {
                guard let url = Self.manageSubscriptionsURL else { return }
                openURL(url)
            }

            premiumActionButton(
                title: PremiumEntryL10n.managementRestore,
                systemImage: "arrow.clockwise",
                fills: false,
                isLoading: isRestoringPurchases,
                palette: palette
            ) {
                Task {
                    await restorePurchases()
                }
            }

            Link(destination: AppReviewConfiguration.supportURL) {
                actionLabel(
                    title: PremiumEntryL10n.managementSupport,
                    systemImage: "questionmark.circle.fill",
                    fills: false,
                    isLoading: false,
                    palette: palette
                )
            }
            .buttonStyle(.plain)

            if let supportURL = AppReviewConfiguration.supportEmailURL {
                Link(destination: supportURL) {
                    actionLabel(
                        title: "Destek e-postası",
                        systemImage: "envelope.fill",
                        fills: false,
                        isLoading: false,
                        palette: palette
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statusRow(title: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 12)
    }

    private func statusDivider(palette: ThemePalette) -> some View {
        Divider()
            .overlay(palette.borderColor.opacity(0.35))
    }

    private func premiumActionButton(
        title: String,
        systemImage: String,
        fills: Bool,
        isLoading: Bool,
        palette: ThemePalette,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionLabel(
                title: title,
                systemImage: systemImage,
                fills: fills,
                isLoading: isLoading,
                palette: palette
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func actionLabel(
        title: String,
        systemImage: String,
        fills: Bool,
        isLoading: Bool,
        palette: ThemePalette
    ) -> some View {
        HStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(fills ? .white : palette.accent)
            } else {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
            }

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()
        }
        .foregroundStyle(fills ? Color.white : palette.primaryText)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(fills ? palette.accent : palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke((fills ? Color.clear : palette.borderColor.opacity(0.65)), lineWidth: 1)
        )
    }

    private var renewalValue: String? {
        guard subscriptionStore.shouldDisplayRenewalDate else { return nil }
        guard let renewalDate = subscriptionStore.renewalDisplayDate else { return nil }
        return dateFormatter.string(from: renewalDate)
    }

    private var headerSubtitle: String {
        if subscriptionStore.isSandboxSubscription {
            return subscriptionStore.currentPlanName ?? PremiumEntryL10n.cardActiveSubtitle
        }

        if let renewalDate = subscriptionStore.renewalDisplayDate {
            return L10n.format(PremiumEntryL10n.cardRenewal, dateFormatter.string(from: renewalDate))
        }

        if let currentPlanName = subscriptionStore.currentPlanName {
            return currentPlanName
        }

        return PremiumEntryL10n.cardActiveSubtitle
    }

    private var featureItems: [(icon: String, title: String, detail: String)] {
        [
            (
                "message.badge.waveform.fill",
                L10n.string(.premiumPaywallFeatureRabiaTitle),
                L10n.string(.premiumPaywallFeatureRabiaDetail)
            ),
            (
                "waveform.and.mic",
                L10n.string(.premiumPaywallFeatureAudioTitle),
                L10n.string(.premiumPaywallFeatureAudioDetail)
            ),
            (
                "paintpalette.fill",
                L10n.string(.premiumTemalarAbonelikleBirlikteGelir2),
                L10n.string(.filigransizPaylasimKartlari)
            ),
            (
                "sparkles",
                L10n.string(.bulutSenkronizasyonu2),
                L10n.string(.tumVerileriniziBulutaKaydedin)
            )
        ]
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .autoupdatingCurrent
        return formatter
    }

    private func restorePurchases() async {
        guard !isRestoringPurchases else { return }

        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            let info = try await subscriptionStore.restorePurchases()
            feedbackMessage = RevenueCatService.shared.hasActiveEntitlement(info)
                ? L10n.string(.satinAlimlarBasariliGeriYuklendi)
                : L10n.string(.aktifSatinAlmaBulunamadi)
        } catch {
            feedbackMessage = L10n.format(.errorRestoreFailed, error.localizedDescription)
        }
    }
}
