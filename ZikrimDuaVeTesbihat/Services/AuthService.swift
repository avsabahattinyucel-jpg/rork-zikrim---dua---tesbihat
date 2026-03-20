import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import RevenueCat
import UIKit
import AuthenticationServices
import CryptoKit
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

nonisolated struct AuthUser: Codable, Sendable {
    let id: String
    var email: String?
    var displayName: String?
    var provider: AuthProvider
    var createdAt: Date

    nonisolated enum AuthProvider: String, Codable, Sendable {
        case apple
        case google
        case email
        case anonymous
    }
}

nonisolated struct ReauthenticationContext: Identifiable, Equatable, Sendable {
    nonisolated enum Method: String, Sendable {
        case apple
        case google
        case email
    }

    let method: Method
    let email: String?

    var id: Method { method }
}

@Observable
@MainActor
class AuthService: NSObject {
    private let userKey = "auth_user_firebase"
    private let appleUserIdentifierKey = "auth_apple_user_identifier"
    private let appleEmailKey = "auth_apple_email"
    private let appleFullNameKey = "auth_apple_full_name"
    private let appleIdentityTokenKey = "auth_apple_identity_token"
    private let loginStateKey = "isLoggedIn"
    private let appleProviderID = "apple.com"
    private let appleUTF8Encoding = String.Encoding.utf8
    private let appleTokenMaxLogPreviewLength = 18
    private let appleTokenMinLength = 10
    private let appleNoncePreviewLength = 10
    private let appleNameSeparator = " "
    private var appleDefaultDisplayName: String { L10n.string(.displayNameAppleUser) }
    private let invalidAppleTokenError = "Invalid Token"
    private let invalidAppleCredentialError = "Invalid Credential"
    private let canceledAppleSignInError = "User Canceled"
    private var appleIDCredentialError: String { L10n.string(.errorAppleCredentialMissing) }

    var currentUser: AuthUser? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isFirebaseConfigured: Bool = false
    var isGoogleProviderReady: Bool = false
    var welcomeMessage: String? = nil

    var isLoggedIn: Bool {
        currentUser != nil && currentUser?.provider != .anonymous
    }

    var hasSession: Bool {
        currentUser != nil
    }

    var isGuest: Bool = true
    var isPremium: Bool = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String? = nil
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
    private weak var applePresentationAnchorWindow: UIWindow?
    private var lastRevenueCatUserID: String? = nil
    private var revenueCatObserver: NSObjectProtocol?

    override init() {
        super.init()
        prepareAuthProviders()
        loadPersistedUser()
        applyAuthState(for: currentUser)
        startAuthListener()
        observeRevenueCatUpdates()
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.synchronizeSubscriptionStateForCurrentSession()
        }
    }

    private func observeRevenueCatUpdates() {
        revenueCatObserver = NotificationCenter.default.addObserver(
            forName: .revenueCatCustomerInfoDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.object as? CustomerInfo else { return }
            Task { @MainActor [weak self] in
                self?.applyRevenueCatInfo(info)
            }
        }
    }

    private func prepareAuthProviders() {
        isFirebaseConfigured = FirebaseApp.app() != nil
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            isGoogleProviderReady = false
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        isGoogleProviderReady = true
    }

    private func startAuthListener() {
        guard isFirebaseConfigured else { return }
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let firebaseUser {
                    let provider = self.detectProvider(firebaseUser)
                    let user = AuthUser(
                        id: firebaseUser.uid,
                        email: firebaseUser.email,
                        displayName: firebaseUser.displayName,
                        provider: provider,
                        createdAt: firebaseUser.metadata.creationDate ?? Date()
                    )
                    self.currentUser = user
                    self.persistUser(user)
                    self.applyAuthState(for: user)
                    if provider != .anonymous {
                        await self.syncRevenueCatSession(for: user.id)
                    } else {
                        await self.refreshPremiumStatus(force: true)
                    }
                } else if let existingGuest = self.currentUser, existingGuest.provider == .anonymous {
                    self.applyAuthState(for: existingGuest)
                    await self.refreshPremiumStatus(force: true)
                } else {
                    self.currentUser = nil
                    self.persistUser(nil)
                    self.applyAuthState(for: nil)
                    await self.resetRevenueCatSession()
                }
            }
        }
    }

    private func detectProvider(_ user: FirebaseAuth.User) -> AuthUser.AuthProvider {
        if user.isAnonymous {
            return .anonymous
        }
        for info in user.providerData {
            switch info.providerID {
            case "google.com": return .google
            case "apple.com": return .apple
            case "password": return .email
            default: break
            }
        }
        return .email
    }

    private func loadPersistedUser() {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(AuthUser.self, from: data) else { return }
        currentUser = user
    }

    private func applyAuthState(for user: AuthUser?) {
        let guest = (user == nil || user?.provider == .anonymous)
        isGuest = guest
        if user == nil {
            setPremium(false)
        }
    }

    private func setPremium(_ value: Bool) {
        if isPremium != value {
            isPremium = value
        }
    }

    func refreshPremiumStatus(force: Bool = false) async {
        guard hasSession else {
            await resetRevenueCatSession()
            return
        }
        do {
            let info = try await RevenueCatService.shared.customerInfo(force: force)
            let hasPremium = RevenueCatService.shared.hasActiveEntitlement(info)
            setPremium(hasPremium)
        } catch {
            setPremium(false)
        }
    }

    func applyRevenueCatInfo(_ info: CustomerInfo) {
        let hasPremium = hasSession && RevenueCatService.shared.hasActiveEntitlement(info)
        setPremium(hasPremium)
    }

    private func syncRevenueCatSession(for userID: String) async {
        if lastRevenueCatUserID != userID {
            do {
                try await RevenueCatService.shared.logIn(appUserID: userID)
                lastRevenueCatUserID = userID
            } catch {}
        }
        await refreshPremiumStatus(force: true)
    }

    private func persistUser(_ user: AuthUser?) {
        if let user, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userKey)
        }
    }

    @discardableResult
    func continueAsGuest() async -> Bool {
        if currentUser?.provider == .anonymous {
            errorMessage = nil
            return true
        }

        guard !isLoading else {
            return currentUser?.provider == .anonymous
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard isFirebaseConfigured else {
            return await activateLocalGuestSession()
        }

        do {
            let result = try await Auth.auth().signInAnonymously()
            let user = AuthUser(
                id: result.user.uid,
                email: nil,
                displayName: L10n.string(.displayNameGuest),
                provider: .anonymous,
                createdAt: Date()
            )
            currentUser = user
            persistUser(user)
            applyAuthState(for: user)
            await refreshPremiumStatus(force: true)
            return true
        } catch {
            print("Guest sign-in fallback activated: \(error.localizedDescription)")
            return await activateLocalGuestSession()
        }
    }

    private func makeLocalGuestUser() -> AuthUser {
        AuthUser(
            id: UUID().uuidString,
            email: nil,
            displayName: L10n.string(.displayNameGuest),
            provider: .anonymous,
            createdAt: Date()
        )
    }

    private func activateLocalGuestSession() async -> Bool {
        let guestUser = makeLocalGuestUser()
        currentUser = guestUser
        persistUser(guestUser)
        applyAuthState(for: guestUser)
        await refreshPremiumStatus(force: true)
        return true
    }

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let noncePair = makeAppleNoncePair()
        let rawNonce = noncePair.raw
        let hashedNonce = noncePair.hashed
        currentNonce = rawNonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        print("Apple Sign In: nonce hazırlandı rawPrefix=\(String(rawNonce.prefix(appleNoncePreviewLength))) hashPrefix=\(String(hashedNonce.prefix(appleNoncePreviewLength)))")

        do {
            let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
                self.appleSignInContinuation = continuation
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.presentationContextProvider = self
                controller.performRequests()
            }

            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  !appleIDCredential.user.isEmpty else {
                errorMessage = appleIDCredentialError
                return
            }

            guard let identityTokenData = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
                print("Apple Sign In: identityToken alınamadı")
                errorMessage = L10n.string(.errorAppleTokenMissing)
                return
            }
            print("Apple Sign In: identityToken alındı length=\(idTokenString.count)")

            UserDefaults.standard.set(appleIDCredential.user, forKey: appleUserIdentifierKey)

            let givenName = appleIDCredential.fullName?.givenName ?? ""
            let familyName = appleIDCredential.fullName?.familyName ?? ""
            let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
            if !fullName.isEmpty {
                UserDefaults.standard.set(fullName, forKey: appleFullNameKey)
            }
            if let email = appleIDCredential.email, !email.isEmpty {
                UserDefaults.standard.set(email, forKey: appleEmailKey)
            }

            let nonceForFirebase: String
            if let capturedRawNonce = currentNonce {
                if capturedRawNonce != rawNonce {
                    print("Apple Sign In Nonce Warning: currentNonce/rawNonce mismatch. currentPrefix=\(String(capturedRawNonce.prefix(appleNoncePreviewLength))) rawPrefix=\(String(rawNonce.prefix(appleNoncePreviewLength))). Firebase sign-in denenecek.")
                }
                nonceForFirebase = capturedRawNonce
            } else {
                print("Apple Sign In Nonce Warning: currentNonce nil. generated rawNonce ile devam ediliyor.")
                nonceForFirebase = rawNonce
            }

            let credential: OAuthCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonceForFirebase,
                fullName: appleIDCredential.fullName
            )
            currentNonce = nil

            let persistedEmail = UserDefaults.standard.string(forKey: appleEmailKey)
            let persistedName = UserDefaults.standard.string(forKey: appleFullNameKey)

            if isFirebaseConfigured {
                print("Apple Firebase Sign-In: Auth.auth().signIn başlatılıyor")
                let authResult = try await Auth.auth().signIn(with: credential)
                let firebaseUser = authResult.user

                var displayName = firebaseUser.displayName
                if !fullName.isEmpty {
                    displayName = fullName
                } else if let pn = persistedName, !pn.isEmpty {
                    displayName = pn
                }

                if let name = displayName, !name.isEmpty {
                    let changeRequest = firebaseUser.createProfileChangeRequest()
                    changeRequest.displayName = name
                    try? await changeRequest.commitChanges()
                }

                let user = AuthUser(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? appleIDCredential.email ?? persistedEmail,
                    displayName: displayName,
                    provider: .apple,
                    createdAt: firebaseUser.metadata.creationDate ?? Date()
                )
                currentUser = user
                persistUser(user)
                UserDefaults.standard.set(true, forKey: loginStateKey)
                await restorePurchasesAndSync(userID: user.id)
                await ensureProfileDocument(for: user)
            } else {
                let localName = !fullName.isEmpty ? fullName : (persistedName ?? appleDefaultDisplayName)
                let user = AuthUser(
                    id: UUID().uuidString,
                    email: appleIDCredential.email ?? persistedEmail,
                    displayName: localName,
                    provider: .apple,
                    createdAt: Date()
                )
                currentUser = user
                persistUser(user)
                UserDefaults.standard.set(true, forKey: loginStateKey)
            }
        } catch let error as ASAuthorizationError where error.code == .canceled {
            print("Apple Sign In: User canceled")
        } catch {
            let nsError = error as NSError
            let bundleID = Bundle.main.bundleIdentifier ?? "unknown.bundle.id"
            let payload = String(describing: nsError.userInfo)
            print("Apple Sign In Error: bundleID=\(bundleID) domain=\(nsError.domain) code=\(nsError.code) message=\(nsError.localizedDescription) payload=\(payload) debugDescription=\(nsError.debugDescription)")
            errorMessage = L10n.format(.errorAppleSigninDetail, bundleID, nsError.code, nsError.localizedDescription, payload)
        }
    }

    func updatePresentationAnchor(_ window: UIWindow?) {
        applePresentationAnchorWindow = window
    }

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let noncePair = makeAppleNoncePair()
        currentNonce = noncePair.raw
        request.requestedScopes = [.fullName, .email]
        request.nonce = noncePair.hashed
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let nonce = currentNonce else {
                errorMessage = L10n.string(.errorAppleSigninVerificationFailed)
                return
            }
            currentNonce = nil
            await finalizeAppleSignIn(authorization: authorization, nonce: nonce)
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
                return
            }
            let nsError = error as NSError
            let bundleID = Bundle.main.bundleIdentifier ?? "unknown.bundle.id"
            let payload = String(describing: nsError.userInfo)
            print("Apple Sign In Completion Error: bundleID=\(bundleID) domain=\(nsError.domain) code=\(nsError.code) message=\(nsError.localizedDescription) payload=\(payload) debugDescription=\(nsError.debugDescription)")
            errorMessage = L10n.format(.errorAppleSigninDetail, bundleID, nsError.code, nsError.localizedDescription, payload)
        }
    }

    private func finalizeAppleSignIn(authorization: ASAuthorization, nonce: String) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              !appleIDCredential.user.isEmpty else {
            errorMessage = appleIDCredentialError
            return
        }

        guard let identityTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
            errorMessage = L10n.string(.errorAppleTokenMissing)
            return
        }


        UserDefaults.standard.set(appleIDCredential.user, forKey: appleUserIdentifierKey)

        let givenName = appleIDCredential.fullName?.givenName ?? ""
        let familyName = appleIDCredential.fullName?.familyName ?? ""
        let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        if !fullName.isEmpty {
            UserDefaults.standard.set(fullName, forKey: appleFullNameKey)
        }
        if let email = appleIDCredential.email, !email.isEmpty {
            UserDefaults.standard.set(email, forKey: appleEmailKey)
        }


        let credential: OAuthCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let persistedEmail = UserDefaults.standard.string(forKey: appleEmailKey)
        let persistedName = UserDefaults.standard.string(forKey: appleFullNameKey)

        if isFirebaseConfigured {
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                let firebaseUser = authResult.user

                var resolvedDisplayName: String? = nil
                if !fullName.isEmpty {
                    resolvedDisplayName = fullName
                } else if let persistedName, !persistedName.isEmpty {
                    resolvedDisplayName = persistedName
                } else if let firebaseDisplayName = firebaseUser.displayName, !firebaseDisplayName.isEmpty {
                    resolvedDisplayName = firebaseDisplayName
                }

                if let resolvedDisplayName, !resolvedDisplayName.isEmpty {
                    let changeRequest = firebaseUser.createProfileChangeRequest()
                    changeRequest.displayName = resolvedDisplayName
                    try? await changeRequest.commitChanges()
                }

                var resolvedEmail: String? = nil
                if let firebaseEmail = firebaseUser.email, !firebaseEmail.isEmpty {
                    resolvedEmail = firebaseEmail
                } else if let appleEmail = appleIDCredential.email, !appleEmail.isEmpty {
                    resolvedEmail = appleEmail
                } else if let persistedEmail, !persistedEmail.isEmpty {
                    resolvedEmail = persistedEmail
                }

                let user = AuthUser(
                    id: firebaseUser.uid,
                    email: resolvedEmail,
                    displayName: resolvedDisplayName,
                    provider: .apple,
                    createdAt: firebaseUser.metadata.creationDate ?? Date()
                )
                currentUser = user
                persistUser(user)
                UserDefaults.standard.set(true, forKey: loginStateKey)
                await restorePurchasesAndSync(userID: user.id)
                await ensureProfileDocument(for: user)
            } catch {
                let nsError = error as NSError
                let bundleID = Bundle.main.bundleIdentifier ?? "unknown.bundle.id"
                let payload = String(describing: nsError.userInfo)
                print("❌ FIREBASE AUTH ERROR DETAYI: bundleID=\(bundleID) domain=\(nsError.domain) code=\(nsError.code) message=\(nsError.localizedDescription) payload=\(payload) debugDescription=\(nsError.debugDescription)")
                print("DEBUG_FULL_ERROR: \(error)")
                self.errorMessage = L10n.format(.errorAppleFirebaseSigninDetail, bundleID, nsError.code, nsError.localizedDescription, payload)
            }
        } else {
            let localName = !fullName.isEmpty ? fullName : (persistedName ?? appleDefaultDisplayName)
            let user = AuthUser(
                id: UUID().uuidString,
                email: appleIDCredential.email ?? persistedEmail,
                displayName: localName,
                provider: .apple,
                createdAt: Date()
            )
            currentUser = user
            persistUser(user)
            UserDefaults.standard.set(true, forKey: loginStateKey)
        }
    }

    func signInWithGoogle() async {
        guard isFirebaseConfigured, isGoogleProviderReady else {
            errorMessage = L10n.string(.errorGoogleSigninNotReady)
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            guard let rootVC = await rootViewController() else {
                errorMessage = L10n.string(.errorGoogleSigninFailed)
                isLoading = false
                return
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = L10n.string(.errorGoogleCredentialMissing)
                isLoading = false
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            let user = AuthUser(
                id: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName,
                provider: .google,
                createdAt: firebaseUser.metadata.creationDate ?? Date()
            )
            currentUser = user
            persistUser(user)
            await restorePurchasesAndSync(userID: user.id)
            await ensureProfileDocument(for: user)
        } catch {
            let nsError = error as NSError
            if nsError.domain != "com.google.GIDSignIn" || nsError.code != -5 {
                errorMessage = localizedFirebaseError(error)
            }
        }
        isLoading = false
    }

    func signInWithEmail(email: String, password: String) async {
        guard isFirebaseConfigured else {
            errorMessage = L10n.string(.errorAuthServiceStartFailed)
            return
        }
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = L10n.string(.errorEmailInvalid)
            isLoading = false
            return
        }
        guard password.count >= 6 else {
            errorMessage = L10n.string(.errorPasswordTooShort)
            isLoading = false
            return
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let firebaseUser = result.user
            let user = AuthUser(
                id: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName,
                provider: .email,
                createdAt: firebaseUser.metadata.creationDate ?? Date()
            )
            currentUser = user
            persistUser(user)
            await restorePurchasesAndSync(userID: user.id)
            await ensureProfileDocument(for: user)
        } catch {
            errorMessage = localizedFirebaseError(error)
        }
        isLoading = false
    }

    func registerWithEmail(email: String, password: String, displayName: String) async {
        guard isFirebaseConfigured else {
            errorMessage = L10n.string(.errorAuthServiceStartFailed)
            return
        }
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = L10n.string(.errorEmailInvalid)
            isLoading = false
            return
        }
        guard password.count >= 6 else {
            errorMessage = L10n.string(.errorPasswordTooShort)
            isLoading = false
            return
        }
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = L10n.string(.errorNameRequired)
            isLoading = false
            return
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            let user = AuthUser(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                provider: .email,
                createdAt: Date()
            )
            currentUser = user
            persistUser(user)
            await restorePurchasesAndSync(userID: user.id)
            await ensureProfileDocument(for: user)
        } catch {
            errorMessage = localizedFirebaseError(error)
        }
        isLoading = false
    }

    func resetPassword(email: String) async -> Bool {
        guard isFirebaseConfigured else {
            errorMessage = L10n.string(.errorAuthServiceStartFailed)
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard isValidEmail(email) else {
            errorMessage = L10n.string(.errorEmailInvalid)
            return false
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            return true
        } catch {
            errorMessage = localizedFirebaseError(error)
            return false
        }
    }

    func updateProfile(name: String, email: String, avatarBase64: String?) async -> Bool {
        guard let userID = currentUser?.id else { return false }

        if isFirebaseConfigured,
           let firebaseUser = Auth.auth().currentUser,
           let currentEmail = firebaseUser.email,
           !email.isEmpty,
           email != currentEmail,
           currentUser?.provider == .email {
            do {
                try await firebaseUser.sendEmailVerification(beforeUpdatingEmail: email)
            } catch {
                errorMessage = localizedFirebaseError(error)
                return false
            }
        }

        #if canImport(FirebaseFirestore)
        let payload: [String: Any] = [
            "name": name,
            "email": email,
            "avatarBase64": avatarBase64 as Any,
            "updatedAt": Timestamp(date: Date())
        ]
        do {
            try await Firestore.firestore().collection("profiles").document(userID).setData(payload, merge: true)
            currentUser?.displayName = name
            currentUser?.email = email
            persistUser(currentUser)
            return true
        } catch {
            errorMessage = L10n.string(.errorProfileSaveFailed)
            return false
        }
        #else
        currentUser?.displayName = name
        currentUser?.email = email
        persistUser(currentUser)
        return true
        #endif
    }

    func fetchProfile() async -> (name: String, email: String, avatarBase64: String?)? {
        guard let userID = currentUser?.id else { return nil }
        #if canImport(FirebaseFirestore)
        do {
            let snapshot = try await Firestore.firestore().collection("profiles").document(userID).getDocument()
            guard let data = snapshot.data() else { return nil }
            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? currentUser?.email ?? ""
            let avatar = data["avatarBase64"] as? String
            return (name, email, avatar)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    func currentReauthenticationContext() -> ReauthenticationContext? {
        guard isLoggedIn else { return nil }

        switch currentUser?.provider {
        case .apple:
            return ReauthenticationContext(method: .apple, email: currentUser?.email)
        case .google:
            return ReauthenticationContext(method: .google, email: currentUser?.email)
        case .email:
            return ReauthenticationContext(method: .email, email: currentUser?.email)
        case .anonymous, .none:
            return nil
        }
    }

    func requiresRecentAuthentication(maxAge: TimeInterval = 300) -> Bool {
        guard isFirebaseConfigured,
              let lastSignInDate = Auth.auth().currentUser?.metadata.lastSignInDate else {
            return true
        }

        return Date().timeIntervalSince(lastSignInDate) > maxAge
    }

    func reauthenticate(withPassword password: String) async throws {
        guard let firebaseUser = Auth.auth().currentUser,
              let email = firebaseUser.email else {
            throw AuthErrorCode.userNotFound
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            _ = try await firebaseUser.reauthenticate(with: credential)
        } catch {
            throw localizedReauthenticationError(error)
        }
    }

    func reauthenticateWithGoogle() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthErrorCode.userNotFound
        }

        guard let rootVC = await rootViewController() else {
            throw NSError(
                domain: "AuthService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: L10n.string(.reauthenticationFailed)]
            )
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(
                    domain: "AuthService",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: L10n.string(.reauthenticationFailed)]
                )
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            _ = try await firebaseUser.reauthenticate(with: credential)
        } catch {
            throw localizedReauthenticationError(error)
        }
    }

    func reauthenticateWithApple() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthErrorCode.userNotFound
        }

        let noncePair = makeAppleNoncePair()
        currentNonce = noncePair.raw

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = []
        request.nonce = noncePair.hashed

        do {
            let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
                self.appleSignInContinuation = continuation
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.presentationContextProvider = self
                controller.performRequests()
            }

            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
                throw NSError(
                    domain: "AuthService",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: L10n.string(.reauthenticationFailed)]
                )
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: noncePair.raw,
                fullName: nil
            )
            _ = try await firebaseUser.reauthenticate(with: firebaseCredential)
            currentNonce = nil
        } catch {
            currentNonce = nil
            throw localizedReauthenticationError(error)
        }
    }

    func signOut() {
        Task { await performSignOut() }
    }

    private func performSignOut() async {
        errorMessage = nil

        // 1) Firebase/Auth signOut
        if isFirebaseConfigured {
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
            } catch {
                errorMessage = L10n.string(.errorSignOutFailed)
                return
            }
        }

        // 2) RevenueCat logOut
        await resetRevenueCatSession()

        // 3) Profil bilgilerini logged-out state'e döndür
        currentUser = nil
        welcomeMessage = nil
        persistUser(nil)
        clearPersistedSessionMetadata()

        // 4) UI'yı anında refresh et
        applyAuthState(for: nil)
    }

    func finalizeAccountRemoval(
        storage: StorageService,
        deletedUserID: String,
        transitionToGuest: Bool = true
    ) async {
        errorMessage = nil

        if isFirebaseConfigured {
            try? Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        }

        await resetRevenueCatSession()

        currentUser = nil
        welcomeMessage = nil
        persistUser(nil)
        clearPersistedSessionMetadata()

        storage.resetForFreshGuestSession(removingUserID: deletedUserID)
        SharedDefaults.clearAll()
        CloudSyncService.shared.clearLocalSyncState()
        RabiaConversationStore.shared.clearMessages(for: deletedUserID)
        RabiaConversationStore.shared.clearMessages(for: nil)
        RabiaMemoryService.shared.clear()

        [
            "daily_custom_habits_v1",
            "daily_draft_note",
            "daily_draft_dua",
            "daily_draft_reflection",
            "faith_flow_free_unlocked_day_v1"
        ]
        .forEach { UserDefaults.standard.removeObject(forKey: $0) }

        applyAuthState(for: nil)

        if transitionToGuest {
            _ = await continueAsGuest()
        }
    }

    private func ensureProfileDocument(for user: AuthUser) async {
        #if canImport(FirebaseFirestore)
        let doc = Firestore.firestore().collection("profiles").document(user.id)
        do {
            let snapshot = try await doc.getDocument()
            if !snapshot.exists {
                try await doc.setData([
                    "name": user.displayName ?? "",
                    "email": user.email ?? "",
                    "updatedAt": Timestamp(date: Date())
                ], merge: true)
            }
        } catch {}
        #endif
    }

    private func restorePurchasesAndSync(userID: String) async {
        await syncRevenueCatSession(for: userID)
    }

    private func synchronizeSubscriptionStateForCurrentSession() async {
        guard let user = currentUser else {
            await resetRevenueCatSession()
            return
        }

        if user.provider == .anonymous {
            await refreshPremiumStatus(force: true)
        } else {
            await syncRevenueCatSession(for: user.id)
        }
    }

    private func resetRevenueCatSession() async {
        if RevenueCatService.shared.isReady {
            try? await RevenueCatService.shared.logOut()
        }
        RevenueCatService.shared.clearCachedPremiumState()
        lastRevenueCatUserID = nil
        setPremium(false)
    }

    private func clearPersistedSessionMetadata() {
        UserDefaults.standard.set(false, forKey: loginStateKey)
        UserDefaults.standard.removeObject(forKey: appleUserIdentifierKey)
        UserDefaults.standard.removeObject(forKey: appleEmailKey)
        UserDefaults.standard.removeObject(forKey: appleFullNameKey)
        UserDefaults.standard.removeObject(forKey: appleIdentityTokenKey)
    }

    func rootViewController() async -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func localizedFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .wrongPassword:
                return "E-posta veya şifre yanlış."
            case .invalidCredential:
                return "Kimlik doğrulama başarısız oldu. Lütfen tekrar deneyin."
            case .userNotFound:
                return "Bu e-posta ile kayıtlı hesap bulunamadı."
            case .emailAlreadyInUse:
                return "Bu e-posta zaten kullanılıyor."
            case .weakPassword:
                return "Şifre çok zayıf. En az 6 karakter kullanın."
            case .invalidEmail:
                return "Geçerli bir e-posta adresi girin."
            case .networkError:
                return "İnternet bağlantınızı kontrol edin."
            case .tooManyRequests:
                return "Çok fazla deneme. Lütfen bekleyin."
            case .userDisabled:
                return "Bu hesap devre dışı bırakılmıştır."
            case .missingOrInvalidNonce:
                return "Apple giriş doğrulaması başarısız oldu. Lütfen tekrar deneyin."
            default:
                return "Giriş yapılamadı. Tekrar deneyin."
            }
        }
        return "Bir hata oluştu. Tekrar deneyin."
    }

    private func localizedAppleSignInError(_ error: Error) -> String {
        if let authError = error as? AuthErrorCode {
            switch authError {
            case .missingOrInvalidNonce:
                return "Apple giriş doğrulaması başarısız oldu. Lütfen tekrar deneyin."
            case .invalidCredential:
                return "Apple hesabı doğrulanamadı. Lütfen tekrar deneyin."
            case .networkError:
                return "İnternet bağlantınızı kontrol edin."
            default:
                return localizedFirebaseError(error)
            }
        }

        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .missingOrInvalidNonce:
                return "Apple giriş doğrulaması başarısız oldu. Lütfen tekrar deneyin."
            case .invalidCredential:
                return "Apple hesabı doğrulanamadı. Lütfen tekrar deneyin."
            default:
                return localizedFirebaseError(error)
            }
        }

        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .canceled:
                return canceledAppleSignInError
            default:
                return "Apple ile giriş yapılamadı. Lütfen tekrar deneyin."
            }
        }

        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code),
           code == .operationNotAllowed {
            return "Apple girişi şu anda aktif değil. Lütfen destekle iletişime geçin."
        }

        return localizedFirebaseError(error)
    }

    private func localizedReauthenticationError(_ error: Error) -> NSError {
        let message: String

        if let authorizationError = error as? ASAuthorizationError {
            if authorizationError.code == .canceled {
                message = L10n.string(.reauthenticationCancelled)
            } else {
                message = L10n.string(.reauthenticationFailed)
            }
        } else if let authCode = AuthErrorCode(rawValue: (error as NSError).code),
                  authCode == .wrongPassword || authCode == .invalidCredential {
            message = L10n.string(.reauthenticationInvalidCredentials)
        } else {
            message = localizedFirebaseError(error)
        }

        return NSError(
            domain: "AuthService.Reauthentication",
            code: (error as NSError).code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func makeAppleNoncePair() -> (raw: String, hashed: String) {
        let rawNonce = randomNonceString()
        let hashedNonce = sha256(rawNonce)
        return (raw: rawNonce, hashed: hashedNonce)
    }

}


// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential, !credential.user.isEmpty {
            UserDefaults.standard.set(credential.user, forKey: self.appleUserIdentifierKey)
        }
        guard let continuation = self.appleSignInContinuation else { return }
        self.appleSignInContinuation = nil
        continuation.resume(returning: authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("Apple Sign In Delegate Error: User Canceled")
            default:
                print("Apple Sign In Delegate Error: \(authError)")
            }
        } else {
            print("Apple Sign In Delegate Error: \(error)")
        }

        self.currentNonce = nil
        guard let continuation = self.appleSignInContinuation else { return }
        self.appleSignInContinuation = nil
        continuation.resume(throwing: error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let anchoredWindow = applePresentationAnchorWindow {
            return anchoredWindow
        }

        let activeWindowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        if let keyWindow = activeWindowScene?.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }

        if let firstWindow = activeWindowScene?.windows.first {
            return firstWindow
        }

        return ASPresentationAnchor()
    }
}
