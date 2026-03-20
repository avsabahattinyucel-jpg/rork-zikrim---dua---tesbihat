import Foundation
import Observation

@Observable
@MainActor
final class AccountSettingsViewModel {
    let storage: StorageService
    let authService: AuthService

    var isShowingPaywall: Bool = false
    var isShowingPremiumManagement: Bool = false
    var isShowingAuth: Bool = false
    var isShowingDeleteConfirmation: Bool = false
    var reauthenticationContext: ReauthenticationContext?
    var isRestoringPurchases: Bool = false
    var isDeletingAccount: Bool = false
    var isReauthenticating: Bool = false
    var feedbackMessage: String?

    private let deletionService: AccountDeletionService

    init(
        storage: StorageService,
        authService: AuthService,
        deletionService: AccountDeletionService? = nil
    ) {
        self.storage = storage
        self.authService = authService
        self.deletionService = deletionService ?? AccountDeletionService(authService: authService)
    }

    var isGuest: Bool { authService.isGuest }
    var isPremium: Bool { authService.isPremium }

    var resolvedName: String {
        if let profileName = loadedProfile?.name, !profileName.isEmpty {
            return profileName
        }
        if let name = authService.currentUser?.displayName, !name.isEmpty {
            return name
        }
        if let email = authService.currentUser?.email, !email.isEmpty {
            return email
        }
        if !storage.profile.displayName.isEmpty {
            return storage.profile.displayName
        }
        return L10n.string(.displayNameGuest)
    }

    var resolvedEmail: String {
        if let profileEmail = loadedProfile?.email, !profileEmail.isEmpty {
            return profileEmail
        }
        if let email = authService.currentUser?.email, !email.isEmpty {
            return email
        }
        if !storage.profile.email.isEmpty {
            return storage.profile.email
        }
        return isGuest ? L10n.string(.guestProfileStatus) : L10n.string(.emailUnavailable)
    }

    var subscriptionStatusText: String {
        if isGuest && !isPremium {
            return L10n.string(.guestProfileStatus)
        }

        return isPremium
            ? L10n.string(.premiumStatusActive)
            : L10n.string(.premiumStatusFree)
    }

    private var loadedProfile: (name: String, email: String, avatarBase64: String?)?

    func refresh() async {
        loadedProfile = await authService.fetchProfile()

        if let loadedProfile {
            storage.profile.displayName = loadedProfile.name
            storage.profile.email = loadedProfile.email
            storage.profile.avatarBase64 = loadedProfile.avatarBase64
            storage.saveProfile()
        }

        await authService.refreshPremiumStatus(force: false)
    }

    func restorePurchases() async {
        guard !isRestoringPurchases else { return }

        if !authService.hasSession {
            let didContinueAsGuest = await authService.continueAsGuest()
            if !didContinueAsGuest {
                feedbackMessage = L10n.string(.errorGuestSigninFailed)
            }
            guard didContinueAsGuest else { return }
        }

        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            let info = try await RevenueCatService.shared.restorePurchases()
            authService.applyRevenueCatInfo(info)
            await authService.refreshPremiumStatus(force: true)

            feedbackMessage = RevenueCatService.shared.hasActiveEntitlement(info)
                ? L10n.string(.satinAlimlarBasariliGeriYuklendi)
                : L10n.string(.aktifSatinAlmaBulunamadi)
        } catch {
            feedbackMessage = L10n.string(.geriYuklemeHataTekrarDene)
        }
    }

    func requestAccountDeletion() {
        guard authService.isLoggedIn else { return }
        isShowingDeleteConfirmation = true
    }

    func confirmAccountDeletion() async {
        await executeDeletion(skipReauthenticationCheck: false)
    }

    func reauthenticateWithPassword(_ password: String) async {
        guard !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            feedbackMessage = L10n.string(.reauthenticationPasswordRequired)
            return
        }

        await performReauthentication {
            try await authService.reauthenticate(withPassword: password)
        }
    }

    func reauthenticateWithGoogle() async {
        await performReauthentication {
            try await authService.reauthenticateWithGoogle()
        }
    }

    func reauthenticateWithApple() async {
        await performReauthentication {
            try await authService.reauthenticateWithApple()
        }
    }

    func clearReauthenticationState() {
        reauthenticationContext = nil
        isReauthenticating = false
    }

    private func performReauthentication(_ action: () async throws -> Void) async {
        guard !isReauthenticating else { return }
        isReauthenticating = true
        defer { isReauthenticating = false }

        do {
            try await action()
            reauthenticationContext = nil
            await executeDeletion(skipReauthenticationCheck: true)
        } catch {
            feedbackMessage = error.localizedDescription
        }
    }

    private func executeDeletion(skipReauthenticationCheck: Bool) async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await deletionService.deleteCurrentAccount(
                storage: storage,
                continueAsGuest: true,
                skipReauthenticationCheck: skipReauthenticationCheck
            )
            reauthenticationContext = nil
        } catch let error as AccountDeletionService.DeletionError {
            switch error {
            case .requiresRecentAuthentication(let context):
                reauthenticationContext = context
            default:
                feedbackMessage = error.localizedDescription
            }
        } catch {
            feedbackMessage = L10n.string(.deleteAccountGenericFailure)
        }
    }
}
