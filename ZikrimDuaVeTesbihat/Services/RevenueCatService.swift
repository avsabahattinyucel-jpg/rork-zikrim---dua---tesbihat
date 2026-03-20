import Foundation
import RevenueCat

extension Notification.Name {
    static let revenueCatCustomerInfoDidChange = Notification.Name("revenueCatCustomerInfoDidChange")
}

@Observable
@MainActor
class RevenueCatService: NSObject, PurchasesDelegate {
    enum ConfigurationError: LocalizedError {
        case missingAPIKey

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Premium sistemi şu anda hazır değil. Lütfen biraz sonra tekrar deneyin."
            }
        }
    }

    static let shared = RevenueCatService()

    var isPremium: Bool = false
    private(set) var latestCustomerInfo: CustomerInfo?

    private static let entitlementID = "premium"

    static let monthlyProductID = "zikrim.tesbihat.monthly"
    static let yearlyProductID = "zikrim.tesbihat.yearly"

    private override init() {
        super.init()
    }

    private var isConfigured: Bool = false
    var isReady: Bool { isConfigured }

    func configure() {
        guard !isConfigured else { return }
        guard let apiKey = Self.resolvedAPIKey else {
            #if DEBUG
            print("[RevenueCat] configure skipped: missing API key in Config.swift")
            #endif
            return
        }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        isConfigured = true

        Task {
            try? await updatePremiumStatus()
        }
    }

    func offerings() async throws -> Offerings {
        configure()
        guard isConfigured else {
            throw ConfigurationError.missingAPIKey
        }
        return try await Purchases.shared.offerings()
    }

    func purchasePackage(_ package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        apply(customerInfo: result.customerInfo)
        return result.customerInfo
    }

    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        apply(customerInfo: info)
        return info
    }

    func updatePremiumStatus() async throws {
        configure()
        guard isConfigured else {
            throw ConfigurationError.missingAPIKey
        }
        let info = try await Purchases.shared.customerInfo()
        apply(customerInfo: info)
    }

    func hasActiveEntitlement(_ info: CustomerInfo) -> Bool {
        if info.entitlements[Self.entitlementID]?.isActive == true {
            return true
        }

        if info.entitlements.active.values.contains(where: { $0.isActive }) {
            return true
        }

        let activeProducts = Set(info.activeSubscriptions)
        if activeProducts.contains(Self.monthlyProductID) ||
           activeProducts.contains(Self.yearlyProductID) {
            return true
        }

        return false
    }

    func customerInfo(force: Bool = false) async throws -> CustomerInfo {
        configure()
        guard isConfigured else {
            throw ConfigurationError.missingAPIKey
        }
        if force {
            Purchases.shared.invalidateCustomerInfoCache()
        }
        let info = try await Purchases.shared.customerInfo()
        apply(customerInfo: info)
        return info
    }

    func logIn(appUserID: String) async throws {
        configure()
        guard isConfigured else {
            throw ConfigurationError.missingAPIKey
        }
        let (info, _) = try await Purchases.shared.logIn(appUserID)
        apply(customerInfo: info)
    }

    func logOut() async throws {
        configure()
        guard isConfigured else {
            latestCustomerInfo = nil
            isPremium = false
            return
        }
        _ = try await Purchases.shared.logOut()
        Purchases.shared.invalidateCustomerInfoCache()
        latestCustomerInfo = nil
        isPremium = false
    }

    func clearCachedPremiumState() {
        guard isConfigured else {
            latestCustomerInfo = nil
            isPremium = false
            return
        }
        Purchases.shared.invalidateCustomerInfoCache()
        latestCustomerInfo = nil
        isPremium = false
    }

    nonisolated func purchases(_ purchases: Purchases,
                               receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            RevenueCatService.shared.apply(customerInfo: customerInfo)
        }
    }

    func activeEntitlement(from info: CustomerInfo) -> EntitlementInfo? {
        if let premiumEntitlement = info.entitlements[Self.entitlementID], premiumEntitlement.isActive {
            return premiumEntitlement
        }

        return info.entitlements.active.values.first(where: { $0.isActive })
    }

    func primaryActiveProductID(from info: CustomerInfo) -> String? {
        activeEntitlement(from: info)?.productIdentifier ?? info.activeSubscriptions.first
    }

    private func apply(customerInfo: CustomerInfo) {
        latestCustomerInfo = customerInfo
        isPremium = hasActiveEntitlement(customerInfo)
        NotificationCenter.default.post(
            name: .revenueCatCustomerInfoDidChange,
            object: customerInfo
        )
    }

    private static var resolvedAPIKey: String? {
        if let infoPlistKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatPublicSDKKey") as? String {
            let trimmedInfoPlistKey = infoPlistKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedInfoPlistKey.isEmpty {
                return trimmedInfoPlistKey
            }
        }

        #if DEBUG
        let preferredKey = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        if !preferredKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return preferredKey
        }
        #endif

        let fallbackKey = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        let trimmedFallback = fallbackKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFallback.isEmpty {
            return trimmedFallback
        }

        // Keep local Xcode builds working even when CI-generated config injection is absent.
        return "appl_CcbJkgelgIEhLWMaAhOCLGnBFdP"
    }
}
