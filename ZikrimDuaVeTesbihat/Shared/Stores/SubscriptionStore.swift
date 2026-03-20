import Foundation
import Observation
import RevenueCat

@Observable
@MainActor
final class SubscriptionStore {
    enum AccessLevel: String, Equatable, Sendable {
        case loading
        case free
        case premium
    }

    private let authService: AuthService
    private let revenueCatService: RevenueCatService
    private var revenueCatObserver: NSObjectProtocol?

    private(set) var accessLevel: AccessLevel = .loading {
        didSet {
            SharedDefaults.updatePremiumAccess(accessLevel == .premium)
        }
    }
    private(set) var currentPlanName: String?
    private(set) var renewalDate: Date?
    private(set) var expirationDate: Date?
    private(set) var isLifetime: Bool = false
    private(set) var isSandboxSubscription: Bool = false
    private(set) var isLoading: Bool = true

    var isPremium: Bool {
        accessLevel == .premium
    }

    var renewalDisplayDate: Date? {
        Self.displayDate(forRenewalMoment: renewalDate)
    }

    var shouldDisplayRenewalDate: Bool {
        renewalDisplayDate != nil && !isSandboxSubscription
    }

    init(
        authService: AuthService,
        revenueCatService: RevenueCatService? = nil
    ) {
        self.authService = authService
        self.revenueCatService = revenueCatService ?? RevenueCatService.shared
        syncFromCurrentServices(sessionState: .restoring)
        observeRevenueCatUpdates()
    }

    func resetForLaunch() {
        accessLevel = .loading
        clearEntitlementDetails()
        isLoading = true
    }

    @discardableResult
    func preload(for sessionState: SessionStore.State) async -> AccessLevel {
        await refresh(sessionState: sessionState, force: false, showsLoadingState: true)
        return accessLevel
    }

    @discardableResult
    func syncFromCurrentServices(sessionState: SessionStore.State) -> AccessLevel {
        switch sessionState {
        case .restoring:
            accessLevel = .loading
            clearEntitlementDetails()
            isLoading = true
        case .unauthenticated:
            accessLevel = .free
            clearEntitlementDetails()
            isLoading = false
        case .guest:
            accessLevel = authService.isPremium ? .premium : .free
            if accessLevel == .free {
                clearEntitlementDetails()
            }
            isLoading = false
        case .authenticated:
            accessLevel = authService.isPremium ? .premium : .free
            if accessLevel == .free {
                clearEntitlementDetails()
            }
            isLoading = false
        }

        return accessLevel
    }

    @discardableResult
    func refresh(force: Bool = false) async -> AccessLevel {
        await refresh(
            sessionState: currentSessionState,
            force: force,
            showsLoadingState: accessLevel == .loading
        )
    }

    @discardableResult
    func applyCustomerInfo(_ info: CustomerInfo) -> AccessLevel {
        apply(customerInfo: info, sessionState: currentSessionState)
    }

    @discardableResult
    func restorePurchases() async throws -> CustomerInfo {
        let info = try await revenueCatService.restorePurchases()
        apply(customerInfo: info, sessionState: currentSessionState)
        return info
    }

    static func fallback(for sessionState: SessionStore.State) -> AccessLevel {
        switch sessionState {
        case .authenticated:
            return .free
        case .restoring:
            return .loading
        case .unauthenticated, .guest:
            return .free
        }
    }

    nonisolated static func displayDate(
        forRenewalMoment renewalDate: Date?,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        guard let renewalDate else { return nil }

        // RevenueCat provides the exact boundary when the current period ends.
        // For date-only UI, showing one second earlier maps that boundary to the
        // last full access day users expect to see.
        return calendar.date(byAdding: .second, value: -1, to: renewalDate) ?? renewalDate
    }

    private var currentSessionState: SessionStore.State {
        if let user = authService.currentUser {
            return user.provider == .anonymous ? .guest(user) : .authenticated(user)
        }
        return .unauthenticated
    }

    private func observeRevenueCatUpdates() {
        revenueCatObserver = NotificationCenter.default.addObserver(
            forName: .revenueCatCustomerInfoDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.object as? CustomerInfo else { return }
            Task { @MainActor [weak self] in
                self?.applyCustomerInfo(info)
            }
        }
    }

    @discardableResult
    private func refresh(
        sessionState: SessionStore.State,
        force: Bool,
        showsLoadingState: Bool
    ) async -> AccessLevel {
        switch sessionState {
        case .restoring:
            accessLevel = .loading
            clearEntitlementDetails()
            isLoading = true
            return accessLevel
        case .unauthenticated:
            accessLevel = .free
            clearEntitlementDetails()
            isLoading = false
            return accessLevel
        case .guest, .authenticated:
            if let latestCustomerInfo = revenueCatService.latestCustomerInfo {
                apply(customerInfo: latestCustomerInfo, sessionState: sessionState)
            }

            if showsLoadingState {
                accessLevel = accessLevel == .loading ? .loading : accessLevel
            }
            isLoading = true

            do {
                let info = try await revenueCatService.customerInfo(force: force)
                apply(customerInfo: info, sessionState: sessionState)
            } catch {
                accessLevel = authService.isPremium ? .premium : .free
                if accessLevel == .free {
                    clearEntitlementDetails()
                }
                isLoading = false
            }

            return accessLevel
        }
    }

    @discardableResult
    private func apply(
        customerInfo: CustomerInfo,
        sessionState: SessionStore.State
    ) -> AccessLevel {
        switch sessionState {
        case .authenticated, .guest:
            break
        case .restoring, .unauthenticated:
            accessLevel = .free
            clearEntitlementDetails()
            isLoading = false
            return accessLevel
        }

        authService.applyRevenueCatInfo(customerInfo)

        let hasPremium = revenueCatService.hasActiveEntitlement(customerInfo)
        accessLevel = hasPremium ? .premium : .free

        guard hasPremium else {
            clearEntitlementDetails()
            isLoading = false
            return accessLevel
        }

        let entitlement = revenueCatService.activeEntitlement(from: customerInfo)
        let productID = entitlement?.productIdentifier ?? revenueCatService.primaryActiveProductID(from: customerInfo)

        currentPlanName = planName(for: productID)
        expirationDate = entitlement?.expirationDate
        renewalDate = entitlement?.willRenew == true ? entitlement?.expirationDate : nil
        isSandboxSubscription = entitlement?.isSandbox == true || entitlement?.store == .testStore
        isLifetime = entitlement?.expirationDate == nil && productID == nil
            ? !customerInfo.activeSubscriptions.isEmpty
            : entitlement?.expirationDate == nil
        isLoading = false
        return accessLevel
    }

    private func clearEntitlementDetails() {
        currentPlanName = nil
        renewalDate = nil
        expirationDate = nil
        isLifetime = false
        isSandboxSubscription = false
    }

    private func planName(for productID: String?) -> String? {
        switch productID {
        case RevenueCatService.monthlyProductID:
            return L10n.string(.premiumMonthly)
        case RevenueCatService.yearlyProductID:
            return L10n.string(.premiumYearly)
        case .some:
            return L10n.string(.premium)
        case .none:
            return nil
        }
    }
}
