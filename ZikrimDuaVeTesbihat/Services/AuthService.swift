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
    private let appleDefaultDisplayName = "Apple Kullanıcısı"
    private let invalidAppleTokenError = "Invalid Token"
    private let invalidAppleCredentialError = "Invalid Credential"
    private let canceledAppleSignInError = "User Canceled"
    private let appleIDCredentialError = "Apple kimlik bilgisi alınamadı."

    var currentUser: AuthUser? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isFirebaseConfigured: Bool = false
    var isGoogleProviderReady: Bool = false
    var welcomeMessage: String? = nil

    var isLoggedIn: Bool {
        currentUser != nil && currentUser?.provider != .anonymous
    }

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String? = nil
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
    nonisolated(unsafe) private weak var applePresentationAnchorWindow: UIWindow?

    override init() {
        super.init()
        prepareAuthProviders()
        loadPersistedUser()
        startAuthListener()
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
                } else {
                    self.currentUser = nil
                    self.persistUser(nil)
                }
            }
        }
    }

    private func detectProvider(_ user: FirebaseAuth.User) -> AuthUser.AuthProvider {
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

    private func persistUser(_ user: AuthUser?) {
        if let user, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userKey)
        }
    }

    func continueAsGuest() {
        guard isFirebaseConfigured else {
            currentUser = AuthUser(id: UUID().uuidString, email: nil, displayName: "Misafir", provider: .anonymous, createdAt: Date())
            return
        }
        Task {
            do {
                let result = try await Auth.auth().signInAnonymously()
                let user = AuthUser(
                    id: result.user.uid,
                    email: nil,
                    displayName: "Misafir",
                    provider: .anonymous,
                    createdAt: Date()
                )
                currentUser = user
                persistUser(user)
            } catch {
                errorMessage = "Misafir girişi başlatılamadı."
            }
        }
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
                errorMessage = "Apple kimlik doğrulama jetonu alınamadı. Lütfen tekrar deneyin."
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
            errorMessage = "Apple giriş hatası\nBundle ID: \(bundleID)\nKod: \(nsError.code)\nMesaj: \(nsError.localizedDescription)\nPayload: \(payload)"
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
                errorMessage = "Apple giriş doğrulaması başarısız oldu. Lütfen tekrar deneyin."
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
            errorMessage = "Apple giriş hatası\nBundle ID: \(bundleID)\nKod: \(nsError.code)\nMesaj: \(nsError.localizedDescription)\nPayload: \(payload)"
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
            errorMessage = "Apple kimlik doğrulama jetonu alınamadı. Lütfen tekrar deneyin."
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
                self.errorMessage = "Apple/Firebase giriş hatası\nBundle ID: \(bundleID)\nKod: \(nsError.code)\nMesaj: \(nsError.localizedDescription)\nPayload: \(payload)"
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
            errorMessage = "Google girişi henüz hazır değil. Lütfen tekrar deneyin."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            guard let rootVC = await rootViewController() else {
                errorMessage = "Google ile giriş yapılamadı."
                isLoading = false
                return
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google kimlik bilgisi alınamadı."
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
            errorMessage = "Kimlik doğrulama servisi başlatılamadı."
            return
        }
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Geçerli bir e-posta adresi girin."
            isLoading = false
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalıdır."
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
            errorMessage = "Kimlik doğrulama servisi başlatılamadı."
            return
        }
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Geçerli bir e-posta adresi girin."
            isLoading = false
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalıdır."
            isLoading = false
            return
        }
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "İsim alanını doldurun."
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
            errorMessage = "Kimlik doğrulama servisi başlatılamadı."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard isValidEmail(email) else {
            errorMessage = "Geçerli bir e-posta adresi girin."
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
            errorMessage = "Profil kaydı yapılamadı."
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

    func signOut() {
        guard isFirebaseConfigured else {
            currentUser = nil
            persistUser(nil)
            UserDefaults.standard.set(false, forKey: loginStateKey)
            UserDefaults.standard.removeObject(forKey: appleUserIdentifierKey)
            return
        }
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            welcomeMessage = nil
            persistUser(nil)
            UserDefaults.standard.set(false, forKey: loginStateKey)
            UserDefaults.standard.removeObject(forKey: appleUserIdentifierKey)
        } catch {
            errorMessage = "Çıkış yapılırken bir hata oluştu."
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
        do {
            try await RevenueCatService.shared.logIn(appUserID: userID)
        } catch {}
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
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential, !credential.user.isEmpty {
                UserDefaults.standard.set(credential.user, forKey: self.appleUserIdentifierKey)
            }
            guard let continuation = self.appleSignInContinuation else { return }
            self.appleSignInContinuation = nil
            continuation.resume(returning: authorization)
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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

        Task { @MainActor in
            self.currentNonce = nil
            guard let continuation = self.appleSignInContinuation else { return }
            self.appleSignInContinuation = nil
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
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
