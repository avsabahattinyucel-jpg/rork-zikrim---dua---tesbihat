import Foundation
import RevenueCat

@Observable
@MainActor
class RevenueCatService: NSObject, PurchasesDelegate {

    static let shared = RevenueCatService()

    var isPremium: Bool = false

    private static let apiKey = "appl_CcbJkgelgIEhLWMaAhOCLGnBFdP"
    private static let entitlementID = "premium"

    static let monthlyProductID = "zikrim.tesbihat.monthly"
    static let yearlyProductID = "zikrim.tesbihat.yearly"

    private override init() {
        super.init()
    }

    func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: Self.apiKey)
        Purchases.shared.delegate = self

        Task {
            try? await updatePremiumStatus()
        }
    }

    func offerings() async throws -> Offerings {
        try await Purchases.shared.offerings()
    }

    func purchasePackage(_ package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        isPremium = hasActiveEntitlement(result.customerInfo)
        return result.customerInfo
    }

    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        isPremium = hasActiveEntitlement(info)
        return info
    }

    func updatePremiumStatus() async throws {
        let info = try await Purchases.shared.customerInfo()
        isPremium = hasActiveEntitlement(info)
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

    func customerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func logIn(appUserID: String) async throws {
        let (info, _) = try await Purchases.shared.logIn(appUserID)
        isPremium = hasActiveEntitlement(info)
    }

    func logOut() async throws {
        let info = try await Purchases.shared.logOut()
        isPremium = hasActiveEntitlement(info)
    }

    nonisolated func purchases(_ purchases: Purchases,
                               receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            RevenueCatService.shared.isPremium =
            RevenueCatService.shared.hasActiveEntitlement(customerInfo)
        }
    }
}
