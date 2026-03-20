import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    let authService: AuthService

    @State private var showPremiumPaywall: Bool = false
    @State private var hapticTrigger: Int = 0

    private var isPremium: Bool { authService.isPremium }
    private var currentTheme: AppTheme { themeManager.currentTheme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard

                VStack(alignment: .leading, spacing: 12) {
                    Text(.tema2)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(currentTheme.primaryText)

                    Text(.temaSadeceSekmeRenginiDegilKartlarVeYuzeyTonlariniDaEtkiler)
                        .font(.subheadline)
                        .foregroundStyle(currentTheme.secondaryText)
                }

                LazyVStack(spacing: 14) {
                    ForEach(ThemeID.allCases) { themeID in
                        ThemePreviewCard(
                            themeID: themeID,
                            theme: themeManager.theme(for: themeID, systemColorScheme: systemColorScheme),
                            isSelected: themeManager.currentThemeID == themeID,
                            showProBadge: themeID.isPremium && !isPremium
                        ) {
                            handleSelection(for: themeID)
                        }
                    }
                }

                Text(.premiumTemalarAbonelikleBirlikteGelir2)
                    .font(.footnote)
                    .foregroundStyle(currentTheme.secondaryText)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .themedScreenBackground()
        .themedNavigation(title: L10n.string(.temalar2), displayMode: .inline)
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumView(authService: authService)
        }
        .task {
            await authService.refreshPremiumStatus()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 26)
                .fill(currentTheme.heroGradient)
                .frame(height: 124)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentTheme.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)

                        Text(.seciliTemaSuAndaUygulamaYuzeylerindeAktif)
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.86))

                        HStack(spacing: 8) {
                            previewPill(color: currentTheme.navBarBackground, label: "Nav")
                            previewPill(color: currentTheme.tabBarBackground, label: "Tab")
                            previewPill(color: currentTheme.accent, label: "Accent")
                        }
                    }
                    .padding(20)
                }

            Text(String(localized: "theme_picker_helper_text", defaultValue: "Tema degistigi anda navbar, tab bar, kartlar ve Rabia bilesenleri birlikte guncellenir."))
                .font(.footnote)
                .foregroundStyle(currentTheme.secondaryText)
        }
        .padding(18)
        .background(currentTheme.elevatedCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(currentTheme.divider.opacity(0.70), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private func previewPill(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.16))
        .clipShape(Capsule())
    }

    private func handleSelection(for themeID: ThemeID) {
        if themeID.isPremium && !isPremium {
            showPremiumPaywall = true
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            themeManager.selectTheme(themeID)
        }
        hapticTrigger += 1
    }
}
