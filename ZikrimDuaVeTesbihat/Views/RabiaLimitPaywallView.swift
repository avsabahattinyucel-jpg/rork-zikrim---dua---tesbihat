import SwiftUI

struct RabiaLimitPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    let authService: AuthService
    @State private var showPremium: Bool = false
    @State private var isRestoringPurchases: Bool = false
    @State private var isShowingAuth: Bool = false
    @State private var errorMessage: String?

    private let rabiaLogoURL: URL? = URL(string: "https://r2-pub.rork.com/generated-images/1320b87e-b7e0-42f5-903c-374245e5442d.png")
    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Spacer(minLength: 12)

                        mainCard

                        actionButtons

                        SubscriptionLegalSection(
                            subscriptionTitle: PremiumConstants.subscriptionTitle(isYearly: true),
                            subscriptionDuration: PremiumConstants.subscriptionDuration(isYearly: true),
                            subscriptionPrice: PremiumConstants.fallbackPrice(isYearly: true),
                            isRestoring: isRestoringPurchases,
                            onRestore: { Task { await restorePurchases() } }
                        )
                    }
                    .frame(maxWidth: contentWidth(in: proxy))
                    .padding(.horizontal, 20)
                    .padding(.top, max(proxy.safeAreaInsets.top, 12))
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 28))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .alert(L10n.string(.hata2), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(L10n.string(.tamam2), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showPremium) {
            PremiumView(authService: authService)
        }
        .fullScreenCover(isPresented: $isShowingAuth) {
            AuthView(authService: authService)
        }
    }

    private var mainCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.selectionBackground.opacity(0.9), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 55
                        )
                    )
                    .frame(width: 100, height: 100)

                AsyncImage(url: rabiaLogoURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "bubble.left.and.sparkles.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(theme.accent)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(.circle)
                .allowsHitTesting(false)
            }

            VStack(spacing: 8) {
                Text(.bugunkuRabiaHakkinDoldu)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textPrimary)

                Text(.rabiaPremiumIleSinirsizIslamiNsohbetEdebilirsin)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(theme.accent)
                    Text(.sinirsizSohbet)
                        .font(.subheadline)
                        .foregroundStyle(theme.textPrimary)
                }
                HStack(spacing: 8) {
                    Image(systemName: "icloud.fill")
                        .font(.caption)
                        .foregroundStyle(theme.accent)
                    Text(.bulutSenkronizasyonu2)
                        .font(.subheadline)
                        .foregroundStyle(theme.textPrimary)
                }
                HStack(spacing: 8) {
                    Image(systemName: "books.vertical.fill")
                        .font(.caption)
                        .foregroundStyle(theme.accent)
                    Text(.premiumZikirPaketleri2)
                        .font(.subheadline)
                        .foregroundStyle(theme.textPrimary)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .appCardStyle(theme, elevated: true, cornerRadius: 24)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showPremium = true
            } label: {
                Text(.premiumAGec)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .themedPrimaryButton(cornerRadius: 14)
            }

            Button {
                dismiss()
            } label: {
                Text(.dahaSonra)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private func contentWidth(in proxy: GeometryProxy) -> CGFloat {
        min(max(proxy.size.width - 40, 0), PremiumConstants.compactPaywallMaxWidth)
    }

    private func restorePurchases() async {
        if !authService.hasSession {
            let didContinueAsGuest = await authService.continueAsGuest()
            if !didContinueAsGuest {
                errorMessage = L10n.string(.errorGuestSigninFailed)
                return
            }
        }

        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            let info = try await RevenueCatService.shared.restorePurchases()
            authService.applyRevenueCatInfo(info)
            await authService.refreshPremiumStatus(force: true)

            if RevenueCatService.shared.hasActiveEntitlement(info) {
                dismiss()
            } else {
                errorMessage = L10n.string(.errorNoActiveSubscription)
            }
        } catch {
            errorMessage = L10n.format(.errorRestoreFailed, error.localizedDescription)
        }
    }
}
