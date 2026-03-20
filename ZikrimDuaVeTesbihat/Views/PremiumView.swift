import Combine
import RevenueCat
import SwiftUI

struct PremiumView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let authService: AuthService

    @State private var offerings: Offerings?
    @State private var isPurchasing: Bool = false
    @State private var selectedPlan: PlanType = .yearly
    @State private var errorMessage: String?
    @State private var isShowingAuth: Bool = false
    @State private var isContentVisible: Bool = false
    @State private var isRestoringPurchases: Bool = false
    @State private var isLoadingOfferings: Bool = false
    @State private var offeringsStatusMessage: String?

    private enum PlanType: String {
        case monthly
        case yearly
    }

    private var featureHighlights: [(icon: String, titleKey: L10n.Key, detailKey: L10n.Key)] {
        [
            (
                "message.badge.waveform.fill",
                .premiumPaywallListRabiaTitle,
                .premiumPaywallListRabiaDetail
            ),
            (
                "waveform.and.mic",
                .premiumPaywallListAudioTitle,
                .premiumPaywallListAudioDetail
            ),
            (
                "icloud.fill",
                .bulutSenkronizasyonu2,
                .tumVerileriniziBulutaKaydedin
            ),
            (
                "books.vertical.fill",
                .premiumPaywallListLibraryTitle,
                .premiumPaywallListLibraryDetail
            ),
            (
                "paintpalette.fill",
                .premiumPaywallListThemesTitle,
                .premiumPaywallListThemesDetail
            )
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: verticalSpacing(in: proxy)) {
                    topBar
                        .premiumEntrance(isVisible: isContentVisible, index: 0, reduceMotion: reduceMotion)

                    HeroVideoCard(height: heroHeight(in: proxy))
                        .premiumEntrance(isVisible: isContentVisible, index: 1, reduceMotion: reduceMotion)

                    headerSection
                        .premiumEntrance(isVisible: isContentVisible, index: 2, reduceMotion: reduceMotion)

                    featureList
                        .premiumEntrance(isVisible: isContentVisible, index: 3, reduceMotion: reduceMotion)

                    pricingSection
                        .premiumEntrance(isVisible: isContentVisible, index: 4, reduceMotion: reduceMotion)

                    subscribeSection
                        .premiumEntrance(isVisible: isContentVisible, index: 5, reduceMotion: reduceMotion)
                }
                .frame(maxWidth: contentWidth(in: proxy))
                .frame(minHeight: proxy.size.height - 1, alignment: .top)
                .padding(.horizontal, horizontalPadding(in: proxy))
                .padding(.top, max(proxy.safeAreaInsets.top, 12))
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 28))
                .frame(maxWidth: .infinity)
            }
            .background(PremiumPaywallBackgroundView(reduceMotion: reduceMotion))
        }
        .toolbar(.hidden, for: .navigationBar)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert(L10n.string(.hata2), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(L10n.string(.tamam2), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $isShowingAuth) {
            AuthView(authService: authService)
        }
        .task {
            await loadOfferings()
        }
        .onAppear {
            animateEntranceIfNeeded()
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(closeButtonBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string(.commonClose))
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.premiumPaywallEyebrow)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(accentGradient)
                .tracking(1.2)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(closeButtonBorder.opacity(0.9), lineWidth: 1)
                )

            Text(.premiumPaywallTitle)
                .font(.system(size: titleSize, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .lineSpacing(2)

            Text(.premiumPaywallUpdatedSubtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(.premiumAvantajlari)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(1.0)

            ForEach(Array(featureHighlights.enumerated()), id: \.offset) { _, item in
                PremiumFeatureCard(
                    icon: item.icon,
                    title: L10n.string(item.titleKey),
                    detail: L10n.string(item.detailKey)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(L10n.string(item.titleKey)). \(L10n.string(item.detailKey))")
            }
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 10) {
            PricingCard(
                title: L10n.string(.premiumYearly),
                price: yearlyBilledPrice,
                billingLabel: L10n.string(.paywallYearlyBillingLabel),
                detail: yearlySecondaryDetail,
                badge: L10n.string(.premiumMostPopular),
                isSelected: selectedPlan == .yearly,
                isPromoted: true
            ) {
                selectPlan(.yearly)
            }

            PricingCard(
                title: L10n.string(.premiumMonthly),
                price: monthlyBilledPrice,
                billingLabel: L10n.string(.paywallMonthlyBillingLabel),
                detail: monthlySecondaryDetail,
                badge: nil,
                isSelected: selectedPlan == .monthly,
                isPromoted: false
            ) {
                selectPlan(.monthly)
            }
        }
    }

    private var subscribeSection: some View {
        VStack(spacing: 10) {
            PremiumCallToActionButton(
                title: L10n.string(.premiumAGec2),
                isLoading: isPurchasing,
                isEnabled: !isPurchasing && !isLoadingOfferings && selectedPackage != nil,
                reduceMotion: reduceMotion
            ) {
                Task { await purchaseSelectedPlan() }
            }

            if let offeringsStatusMessage, selectedPackage == nil {
                Text(offeringsStatusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if selectedPackage == nil {
                Button {
                    Task { await loadOfferings() }
                } label: {
                    HStack(spacing: 8) {
                        if isLoadingOfferings {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                        }

                        Text(L10n.string(.tekrarDene2))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .padding(.horizontal, 14)
                    .foregroundStyle(accentGradient)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(closeButtonBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoadingOfferings)
            }

            SubscriptionLegalSection(
                subscriptionTitle: selectedPlanTitle,
                subscriptionDuration: selectedPlanDuration,
                subscriptionPrice: selectedPlanPrice,
                isRestoring: isRestoringPurchases,
                onRestore: { Task { await restorePurchases() } }
            )
        }
    }

    private var closeButtonBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color(red: 0.12, green: 0.42, blue: 0.50).opacity(0.12)
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.74, blue: 0.74),
                Color(red: 0.33, green: 0.84, blue: 0.92)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var titleSize: CGFloat {
        36
    }

    private var monthlyPackage: Package? {
        allAvailablePackages.first {
            $0.storeProduct.productIdentifier == RevenueCatService.monthlyProductID
        }
    }

    private var yearlyPackage: Package? {
        allAvailablePackages.first {
            $0.storeProduct.productIdentifier == RevenueCatService.yearlyProductID
        }
    }

    private var allAvailablePackages: [Package] {
        guard let offerings else { return [] }

        let currentPackages = offerings.current?.availablePackages ?? []
        if !currentPackages.isEmpty {
            return currentPackages
        }

        var seenProductIDs = Set<String>()

        return offerings.all.values
            .flatMap(\.availablePackages)
            .filter { package in
                seenProductIDs.insert(package.storeProduct.productIdentifier).inserted
            }
    }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .monthly:
            return monthlyPackage
        case .yearly:
            return yearlyPackage
        }
    }

    private var monthlyBilledPrice: String {
        monthlyPackage?.storeProduct.localizedPriceString ?? PremiumConstants.fallbackPrice(isYearly: false)
    }

    private var yearlyBilledPrice: String {
        yearlyPackage?.storeProduct.localizedPriceString ?? PremiumConstants.fallbackPrice(isYearly: true)
    }

    private var monthlySecondaryDetail: String? {
        L10n.string(.paywallMonthlySecondaryDetail)
    }

    private var yearlySecondaryDetail: String? {
        L10n.string(.paywallYearlySecondaryDetail)
    }

    private var selectedPlanTitle: String {
        PremiumConstants.subscriptionTitle(isYearly: selectedPlan == .yearly)
    }

    private var selectedPlanDuration: String {
        PremiumConstants.subscriptionDuration(isYearly: selectedPlan == .yearly)
    }

    private var selectedPlanPrice: String {
        switch selectedPlan {
        case .monthly:
            return monthlyBilledPrice
        case .yearly:
            return yearlyBilledPrice
        }
    }

    private func loadOfferings() async {
        isLoadingOfferings = true
        offeringsStatusMessage = nil
        defer { isLoadingOfferings = false }

        do {
            let loadedOfferings = try await RevenueCatService.shared.offerings()
            offerings = loadedOfferings

            if allAvailablePackages.isEmpty {
                offeringsStatusMessage = L10n.string(.errorPremiumPackageMissing)
            }
        } catch {
            offerings = nil
            offeringsStatusMessage = error.localizedDescription
        }
    }

    private func purchaseSelectedPlan() async {
        if !authService.hasSession {
            let didContinueAsGuest = await authService.continueAsGuest()
            guard didContinueAsGuest else {
                errorMessage = L10n.string(.errorGuestSigninFailed)
                return
            }
        }

        guard let package = selectedPackage else {
            errorMessage = L10n.string(.errorPremiumPackageMissing)
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let info = try await RevenueCatService.shared.purchasePackage(package)
            if RevenueCatService.shared.hasActiveEntitlement(info) {
                authService.applyRevenueCatInfo(info)
                await authService.refreshPremiumStatus(force: true)
                dismiss()
            }
        } catch {
            if let rcError = error as? RevenueCat.ErrorCode,
               rcError == .purchaseCancelledError {
                return
            }

            errorMessage = L10n.format(.errorPurchaseFailed, error.localizedDescription)
        }
    }

    private func restorePurchases() async {
        if !authService.hasSession {
            let didContinueAsGuest = await authService.continueAsGuest()
            guard didContinueAsGuest else {
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

    private func contentWidth(in proxy: GeometryProxy) -> CGFloat {
        min(max(proxy.size.width - (horizontalPadding(in: proxy) * 2), 0), PremiumConstants.paywallMaxWidth)
    }

    private func horizontalPadding(in proxy: GeometryProxy) -> CGFloat {
        proxy.size.width >= 700 ? 28 : 18
    }

    private func heroHeight(in proxy: GeometryProxy) -> CGFloat {
        switch proxy.size.height {
        case ..<700:
            return 150
        case ..<820:
            return 158
        default:
            return 166
        }
    }

    private func verticalSpacing(in proxy: GeometryProxy) -> CGFloat {
        proxy.size.height < 760 ? 12 : 14
    }

    private func animateEntranceIfNeeded() {
        guard !isContentVisible else { return }

        if reduceMotion {
            isContentVisible = true
            return
        }

        withAnimation(.spring(response: 0.78, dampingFraction: 0.88)) {
            isContentVisible = true
        }
    }

    private func selectPlan(_ plan: PlanType) {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.18)
            : Animation.spring(response: 0.32, dampingFraction: 0.82)

        withAnimation(animation) {
            selectedPlan = plan
        }
    }
}
