import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        List {
            Section {
                ForEach(AppAppearanceMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.setAppearanceMode(mode)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(mode == themeManager.appearanceMode ? theme.palette.heroGradient : LinearGradient(colors: [theme.backgroundSecondary, theme.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)

                                Image(systemName: mode.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(mode == themeManager.appearanceMode ? Color.white : theme.accent)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(mode.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.textPrimary)
                                Text(description(for: mode))
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                            }

                            Spacer()

                            if themeManager.appearanceMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .tint(theme.textPrimary)
                    .listRowBackground(theme.cardBackground)
                }
            } header: {
                Text(.gorunum)
            } footer: {
                Text(.sistemAyariSeciliyseUygulamaIphoneUnAcikVeyaKoyuGorunumunuTakipEder)
            }
        }
        .scrollContentBackground(.hidden)
        .appScreenBackground(theme)
        .navigationTitle(L10n.string(.gorunum))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.navBarBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
    }

    private func description(for mode: AppAppearanceMode) -> String {
        switch mode {
        case .system:
            return String(
                localized: "appearance_description_system",
                defaultValue: "Automatically follow your phone's appearance."
            )
        case .light:
            return String(
                localized: "appearance_description_light",
                defaultValue: "Always keep the app in light appearance."
            )
        case .dark:
            return String(
                localized: "appearance_description_dark",
                defaultValue: "Always keep the app in dark appearance."
            )
        }
    }
}
