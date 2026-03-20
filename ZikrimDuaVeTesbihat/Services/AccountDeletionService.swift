import Foundation
import FirebaseAuth
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
final class AccountDeletionService {
    enum DeletionError: LocalizedError {
        case guestAccount
        case missingAuthenticatedUser
        case requiresRecentAuthentication(ReauthenticationContext)
        case backendCleanupFailed
        case accountDeletionFailed

        var errorDescription: String? {
            switch self {
            case .guestAccount:
                return L10n.string(.deleteAccountUnavailableForGuest)
            case .missingAuthenticatedUser:
                return L10n.string(.deleteAccountGenericFailure)
            case .requiresRecentAuthentication:
                return L10n.string(.deleteAccountRequiresReauthentication)
            case .backendCleanupFailed:
                return L10n.string(.deleteAccountBackendCleanupFailed)
            case .accountDeletionFailed:
                return L10n.string(.deleteAccountGenericFailure)
            }
        }
    }

    private struct ProfileDocumentSnapshot {
        let exists: Bool
        let data: [String: Any]
    }

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func deleteCurrentAccount(
        storage: StorageService,
        continueAsGuest: Bool = true,
        skipReauthenticationCheck: Bool = false
    ) async throws {
        guard authService.isLoggedIn else {
            throw DeletionError.guestAccount
        }

        guard let firebaseUser = Auth.auth().currentUser,
              let currentUser = authService.currentUser else {
            throw DeletionError.missingAuthenticatedUser
        }

        if !skipReauthenticationCheck, authService.requiresRecentAuthentication() {
            throw DeletionError.requiresRecentAuthentication(
                authService.currentReauthenticationContext() ??
                ReauthenticationContext(method: .email, email: currentUser.email)
            )
        }

        let profileSnapshot = try await snapshotProfileDocument(for: currentUser.id)

        do {
            try await deletePrimaryBackendData(for: currentUser.id)
        } catch {
            throw DeletionError.backendCleanupFailed
        }

        do {
            try await firebaseUser.delete()
        } catch let nsError as NSError
            where AuthErrorCode(rawValue: nsError.code) == .requiresRecentLogin {
            try? await restoreProfileDocument(profileSnapshot, for: currentUser.id)
            throw DeletionError.requiresRecentAuthentication(
                authService.currentReauthenticationContext() ??
                ReauthenticationContext(method: .email, email: currentUser.email)
            )
        } catch {
            try? await restoreProfileDocument(profileSnapshot, for: currentUser.id)
            throw DeletionError.accountDeletionFailed
        }

        await authService.finalizeAccountRemoval(
            storage: storage,
            deletedUserID: currentUser.id,
            transitionToGuest: continueAsGuest
        )

        // Cloud backup lives outside Firebase Auth, so it is safe to remove after the account is gone.
        try? await CloudSyncService.shared.deleteBackupIfExists()
    }

    private func deletePrimaryBackendData(for userID: String) async throws {
        #if canImport(FirebaseFirestore)
        try await Firestore.firestore().collection("profiles").document(userID).delete()
        #endif
    }

    private func snapshotProfileDocument(for userID: String) async throws -> ProfileDocumentSnapshot {
        #if canImport(FirebaseFirestore)
        let snapshot = try await Firestore.firestore().collection("profiles").document(userID).getDocument()
        return ProfileDocumentSnapshot(
            exists: snapshot.exists,
            data: snapshot.data() ?? [:]
        )
        #else
        return ProfileDocumentSnapshot(exists: false, data: [:])
        #endif
    }

    private func restoreProfileDocument(_ snapshot: ProfileDocumentSnapshot, for userID: String) async throws {
        guard snapshot.exists else { return }

        #if canImport(FirebaseFirestore)
        try await Firestore.firestore().collection("profiles").document(userID).setData(snapshot.data, merge: false)
        #endif
    }
}
