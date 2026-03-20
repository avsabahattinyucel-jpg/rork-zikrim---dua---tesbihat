import SwiftUI

struct MoreDashboardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    let storage: StorageService
    let authService: AuthService
    let subscriptionStore: SubscriptionStore

    @State private var showPremiumPaywall: Bool = false
    @State private var showPremiumManagement: Bool = false
    @State private var showQibla: Bool = false
    @State private var isResolvingPremiumTap: Bool = false

    var body: some View {
        let palette = themeManager.palette(using: systemColorScheme)

        ThemedScreen {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 0) {
                        appHeader(palette: palette)
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                            .padding(.bottom, 20)

                        VStack(spacing: 14) {
                            premiumBannerButton(palette: palette)

                            dashboardSection(L10n.string(.moreSectionAccount), items: [
                                DashboardItem(title: L10n.string(.profil2), subtitle: L10n.string(.moreProfileSubtitle), icon: "person.crop.circle.fill", color: palette.accent, action: .navigation(AnyView(ProfilView(storage: storage, authService: authService))))
                            ], palette: palette)

                            dashboardSection(L10n.string(.moreSectionTools), items: [
                                DashboardItem(title: L10n.string(.namazVakitleri2), subtitle: L10n.string(.morePrayerTimesSubtitle), icon: "moon.stars.fill", color: Color(red: 0.06, green: 0.26, blue: 0.50), action: .navigation(AnyView(PrayerScreen(storage: storage)))),
                                DashboardItem(title: L10n.string(.kibleBulucu2), subtitle: L10n.string(.moreQiblaSubtitle), icon: "safari.fill", color: Color(red: 0.06, green: 0.46, blue: 0.50), action: .sheet({ showQibla = true })),
                                DashboardItem(title: L10n.string(.guideTitleDiscover), subtitle: L10n.string(.moreGuideSubtitle), icon: "map.fill", color: Color(red: 0.13, green: 0.55, blue: 0.35), action: .navigation(AnyView(ManeviRehberView(authService: authService))))
                            ], palette: palette)

                            dashboardSection(L10n.string(.moreSectionSettings), items: [
                                DashboardItem(title: L10n.string(.moreNotificationsSoundTitle), subtitle: L10n.string(.moreNotificationsSoundSubtitle), icon: "bell.badge.fill", color: .orange, action: .navigation(AnyView(NotificationSettingsView()))),
                                DashboardItem(title: L10n.string(.dhikrSettingsTitle), subtitle: L10n.string(.dhikrSettingsSubtitle), icon: "circle.hexagongrid.circle.fill", color: .green, action: .navigation(AnyView(DhikrSettingsView(storage: storage)))),
                                DashboardItem(title: L10n.string(.gorunum2), subtitle: L10n.string(.moreAppearanceSubtitle), icon: "circle.lefthalf.filled", color: palette.accent, action: .navigation(AnyView(AppearanceSettingsView()))),
                                DashboardItem(title: "Diyanet Verileri", subtitle: "Resmi kaynak paketini yenile ve sürüm durumunu görüntüle", icon: "building.columns.fill", color: Color(red: 0.06, green: 0.52, blue: 0.53), action: .navigation(AnyView(DiyanetDataSettingsView()))),
                                DashboardItem(title: L10n.string(.temalar2), subtitle: L10n.string(.moreThemesSubtitle), icon: "paintpalette.fill", color: Color(red: 0.55, green: 0.40, blue: 0.70), action: .navigation(AnyView(ThemePickerView(authService: authService)))),
                                DashboardItem(title: L10n.string(.widget2), subtitle: L10n.string(.moreWidgetSubtitle), icon: "square.grid.2x2.fill", color: .purple, action: .navigation(AnyView(WidgetInfoView(subscriptionStore: subscriptionStore, authService: authService))))
                            ], palette: palette)
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 32)
                    }
                }
                .background(Color.clear)
                .navigationBarHidden(true)
                .navigationDestination(isPresented: $showPremiumManagement) {
                    PremiumManagementView(subscriptionStore: subscriptionStore)
                }
                .sheet(isPresented: $showPremiumPaywall) {
                    PremiumView(authService: authService)
                }
                .sheet(isPresented: $showQibla) {
                    QiblaView()
                }
                .task {
                    await subscriptionStore.refresh(force: false)
                }
            }
        }
        .id(themeManager.navigationRefreshID)
    }

    private func appHeader(palette: ThemePalette) -> some View {
        HStack(spacing: 14) {
            Image("MoreHeaderAppIcon")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.93, green: 0.76, blue: 0.35).opacity(palette.isDarkMode ? 0.30 : 0.18), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.89, green: 0.70, blue: 0.26).opacity(palette.isDarkMode ? 0.32 : 0.22), radius: 12, y: 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(.zikrim2)
                    .font(.title2.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                palette.primaryText,
                                Color(red: 0.88, green: 0.71, blue: 0.31)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text(.duaZikirAndTesbih2)
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.72, green: 0.61, blue: 0.34))
            }
            Spacer()
            if subscriptionStore.isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                    Text(L10n.string(.premium))
                        .font(.caption.bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(colors: [Color.yellow.opacity(0.25), Color.orange.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.0))
                .clipShape(.capsule)
                .overlay(Capsule().strokeBorder(Color.yellow.opacity(0.35), lineWidth: 1))
            }
        }
    }

    private func premiumBannerButton(palette: ThemePalette) -> some View {
        Button {
            Task {
                await handlePremiumTap()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconBackgroundColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(subscriptionStore.isPremium
                             ? PremiumEntryL10n.cardActiveTitle
                             : PremiumEntryL10n.cardUnlockTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.primaryText)

                        if subscriptionStore.isPremium {
                            Text(L10n.string(.premiumStatusActive))
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(palette.accent.opacity(0.12))
                                .foregroundStyle(palette.accent)
                                .clipShape(.capsule)
                        }
                    }
                    Text(premiumSubtitle)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
                if isResolvingPremiumTap {
                    ProgressView()
                        .controlSize(.small)
                        .tint(palette.accent)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(palette.mutedText)
                }
            }
            .padding(18)
            .background(
                premiumBackground(for: palette)
            )
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(premiumBorderColor(for: palette), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isResolvingPremiumTap)
    }

    @ViewBuilder
    private func dashboardSection(_ title: String, items: [DashboardItem], palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(palette.secondaryText)
                .tracking(0.8)
                .padding(.leading, 4)
                .padding(.bottom, 2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    itemRow(item: item, isLast: index == items.count - 1, palette: palette)
                }
            }
            .background(palette.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(palette.borderColor.opacity(0.65), lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: 20))
        }
    }

    @ViewBuilder
    private func itemRow(item: DashboardItem, isLast: Bool, palette: ThemePalette) -> some View {
        let content = HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(item.color.opacity(0.16))
                    .frame(width: 36, height: 36)
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.primaryText)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(palette.mutedText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(.rect)

        switch item.action {
        case .navigation(let destination):
            NavigationLink(destination: destination) {
                content
            }
            .buttonStyle(.plain)
            if !isLast { Divider().padding(.leading, 66).overlay(palette.borderColor.opacity(0.35)) }
        case .sheet(let action):
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
            if !isLast { Divider().padding(.leading, 66).overlay(palette.borderColor.opacity(0.35)) }
        }
    }

    private var iconBackgroundColor: Color {
        subscriptionStore.isPremium
            ? Color(red: 0.79, green: 0.63, blue: 0.24)
            : Color(red: 0.72, green: 0.58, blue: 0.22)
    }

    private var premiumSubtitle: String {
        if subscriptionStore.isPremium,
           subscriptionStore.shouldDisplayRenewalDate,
           let renewalDate = subscriptionStore.renewalDisplayDate {
            return L10n.format(
                PremiumEntryL10n.cardRenewal,
                premiumDateFormatter.string(from: renewalDate)
            )
        }

        if subscriptionStore.isPremium {
            return subscriptionStore.currentPlanName ?? PremiumEntryL10n.cardActiveSubtitle
        }

        return PremiumEntryL10n.cardUnlockSubtitle
    }

    private func premiumBackground(for palette: ThemePalette) -> some View {
        ZStack {
            palette.elevatedCardBackground

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    subscriptionStore.isPremium
                        ? Color(red: 0.80, green: 0.67, blue: 0.30).opacity(palette.isDarkMode ? 0.14 : 0.10)
                        : palette.accent.opacity(palette.isDarkMode ? 0.12 : 0.08)
                )
        }
    }

    private func premiumBorderColor(for palette: ThemePalette) -> Color {
        subscriptionStore.isPremium
            ? Color(red: 0.82, green: 0.68, blue: 0.32).opacity(palette.isDarkMode ? 0.40 : 0.24)
            : palette.accent.opacity(palette.isDarkMode ? 0.30 : 0.18)
    }

    private func handlePremiumTap() async {
        guard !isResolvingPremiumTap else { return }

        isResolvingPremiumTap = true
        defer { isResolvingPremiumTap = false }

        if subscriptionStore.accessLevel == .loading || subscriptionStore.isLoading {
            await subscriptionStore.refresh(force: true)
        }

        if subscriptionStore.isPremium {
            showPremiumManagement = true
        } else {
            showPremiumPaywall = true
        }
    }

    private var premiumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .autoupdatingCurrent
        return formatter
    }
}


private struct DashboardItem {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: DashboardAction
}

private enum DashboardAction {
    case navigation(AnyView)
    case sheet(() -> Void)
}
