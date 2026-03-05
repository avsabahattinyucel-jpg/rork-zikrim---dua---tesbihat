import SwiftUI

struct MoreDashboardView: View {
    let storage: StorageService
    let authService: AuthService

    @State private var showPremium: Bool = false
    @State private var showQibla: Bool = false
    @State private var isPremium: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    appHeader
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    VStack(spacing: 14) {
                        premiumBannerButton

                        dashboardSection("Hesap", items: [
                            DashboardItem(title: "Profil", subtitle: "Bilgiler ve istatistikler", icon: "person.crop.circle.fill", color: .teal, action: .navigation(AnyView(ProfilView(storage: storage, authService: authService))))
                        ])

                        dashboardSection("Araçlar", items: [
                            DashboardItem(title: "Kıble Bulucu", subtitle: "Kabe yönünü bul", icon: "safari.fill", color: Color(red: 0.06, green: 0.46, blue: 0.50), action: .sheet({ showQibla = true })),
                            DashboardItem(title: "Manevi Rehber", subtitle: "Cami, helal yemek, kitapçı bul", icon: "map.fill", color: Color(red: 0.13, green: 0.55, blue: 0.35), action: .navigation(AnyView(ManeviRehberView()))),
                            DashboardItem(title: "Favorilerim", subtitle: "Kaydettiğin zikirler", icon: "moon.stars.fill", color: Color(red: 0.90, green: 0.72, blue: 0.05), action: .navigation(AnyView(GlobalFavoritesView(storage: storage))))
                        ])

                        dashboardSection("Ayarlar", items: [
                            DashboardItem(title: "Bildirim & Ses", subtitle: "Hatırlatıcı, ezan ve ses ayarları", icon: "bell.badge.fill", color: .orange, action: .navigation(AnyView(NotificationSettingsView()))),
                            DashboardItem(title: "Widget", subtitle: "Ana ekran bileşenleri", icon: "square.grid.2x2.fill", color: .purple, action: .navigation(AnyView(WidgetInfoView()))),
                            DashboardItem(title: "Veri Yedekleme", subtitle: "iCloud senkronizasyonu", icon: "icloud.fill", color: .cyan, action: .navigation(AnyView(ProfilView(storage: storage, authService: authService))))
                        ])
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showPremium) {
                PremiumView(authService: authService)
            }
            .sheet(isPresented: $showQibla) {
                QiblaView()
            }
            .task {
                do {
                    let info = try await RevenueCatService.shared.customerInfo()
                    isPremium = RevenueCatService.shared.hasActiveEntitlement(info)
                    AdService.shared.updatePremiumStatus(isPremium)
                } catch {}
            }
            .safeAreaInset(edge: .bottom) {
                ConditionalBannerAd(isPremium: isPremium)
            }
        }
    }

    private var appHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.04, green: 0.14, blue: 0.32), Color(red: 0.04, green: 0.36, blue: 0.40)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color(red: 0.04, green: 0.36, blue: 0.40).opacity(0.4), radius: 10, y: 4)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Zikrim")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("Dua, Zikir & Tesbih")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                    Text("Premium")
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

    private var premiumBannerButton: some View {
        Button {
            showPremium = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.0))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPremium ? "Premium Aktif" : "Premium'a Geç")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(isPremium ? "Tüm özelliklere sahipsin" : "Reklamlara son, sınırsız Rabia")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.08), Color.orange.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.yellow.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dashboardSection(_ title: String, items: [DashboardItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(0.8)
                .padding(.leading, 4)
                .padding(.bottom, 2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    itemRow(item: item, isLast: index == items.count - 1)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 20))
        }
    }

    @ViewBuilder
    private func itemRow(item: DashboardItem, isLast: Bool) -> some View {
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
                    .foregroundStyle(.primary)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        switch item.action {
        case .navigation(let destination):
            NavigationLink(destination: destination) {
                content
            }
            .buttonStyle(.plain)
            if !isLast { Divider().padding(.leading, 66) }
        case .sheet(let action):
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
            if !isLast { Divider().padding(.leading, 66) }
        }
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
