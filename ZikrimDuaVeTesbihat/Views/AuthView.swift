import SwiftUI
import AuthenticationServices
import UIKit

struct AuthView: View {
    let authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: AuthMode = .login
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var displayName: String = ""
    @State private var showPassword: Bool = false
    @State private var showResetSheet: Bool = false
    @State private var resetEmail: String = ""
    @State private var resetSent: Bool = false
    @State private var animateLogo: Bool = false
    private let familyHeroImageURL: URL? = URL(string: "https://r2-pub.rork.com/generated-images/178723b3-4987-4698-8f78-a39e5b773d47.png")

    enum AuthMode { case login, register }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.top, 48)
                            .padding(.bottom, 40)

                        VStack(spacing: 16) {
                            googleSignInButton
                            appleSignInButton

                            divider

                            emailSection

                            if let error = authService.errorMessage {
                                errorBanner(error)
                            }

                            actionButton

                            if mode == .login {
                                Button("Şifremi Unuttum") {
                                    resetEmail = email
                                    showResetSheet = true
                                }
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.5))
                            }

                            modeSwitchButton

                            guestButton
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .sheet(isPresented: $showResetSheet) {
                resetPasswordSheet
            }
            .onChange(of: authService.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn { dismiss() }
            }
        }
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.16),
                    Color(red: 0.06, green: 0.12, blue: 0.22),
                    Color(red: 0.04, green: 0.08, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.teal.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: -200)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.indigo.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 120, y: 300)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            if let familyHeroImageURL {
                Color.clear
                    .frame(height: 170)
                    .overlay {
                        AsyncImage(url: familyHeroImageURL) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .allowsHitTesting(false)
                            } else if phase.error != nil {
                                Image(systemName: "figure.2.and.child.holdinghands")
                                    .font(.system(size: 42, weight: .medium))
                                    .foregroundStyle(.teal.opacity(0.9))
                                    .allowsHitTesting(false)
                            } else {
                                ProgressView()
                                    .tint(.teal)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
            }

            Text("Zikrim - Dua & Tesbihat")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 6) {
                Text(mode == .login ? "Hesabınıza giriş yapın" : "Yeni hesap oluşturun")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                Text("Rabia, uygulamanın manevi asistanı olarak her an seninle.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var googleSignInButton: some View {
        Button {
            Task { await authService.signInWithGoogle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                if authService.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Google ile Devam Et")
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white.opacity(0.1))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .disabled(authService.isLoading)
    }

    private var appleSignInButton: some View {
        Button {
            Task {
                await authService.signInWithApple()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .semibold))
                if authService.isLoading {
                    ProgressView()
                        .tint(colorScheme == .dark ? .black : .white)
                } else {
                    Text("Apple ile Devam Et")
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(colorScheme == .dark ? Color.white : Color.black)
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            .clipShape(.rect(cornerRadius: 14))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.18), lineWidth: 1)
        )
        .disabled(authService.isLoading)
        .background {
            AuthWindowAnchorBridge { window in
                authService.updatePresentationAnchor(window)
            }
        }
    }

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
            Text("veya e-posta ile")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
        }
    }


    private var emailSection: some View {
        VStack(spacing: 12) {
            if mode == .register {
                darkTextField(icon: "person", placeholder: "Ad Soyad", text: $displayName)
            }

            darkTextField(icon: "envelope", placeholder: "E-posta", text: $email, keyboardType: .emailAddress)

            HStack(spacing: 0) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 40)

                if showPassword {
                    TextField("Şifre", text: $password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                } else {
                    SecureField("Şifre", text: $password)
                        .foregroundStyle(.white)
                }

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 40)
                }
            }
            .padding(.horizontal, 4)
            .frame(height: 54)
            .background(Color.white.opacity(0.08))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            if mode == .register {
                darkSecureField(icon: "lock.shield", placeholder: "Şifreyi Onayla", text: $confirmPassword)
            }
        }
    }

    private func darkTextField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 40)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 4)
        .frame(height: 54)
        .background(Color.white.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func darkSecureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 40)

            SecureField(placeholder, text: text)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 4)
        .frame(height: 54)
        .background(Color.white.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.12))
        .clipShape(.rect(cornerRadius: 10))
    }

    private var actionButton: some View {
        Button {
            Task {
                if mode == .login {
                    await authService.signInWithEmail(email: email, password: password)
                } else {
                    guard password == confirmPassword else {
                        return
                    }
                    await authService.registerWithEmail(
                        email: email,
                        password: password,
                        displayName: displayName
                    )
                }
            }
        } label: {
            Group {
                if authService.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(mode == .login ? "Giriş Yap" : "Kayıt Ol")
                        .font(.body.weight(.bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: [.teal, .cyan.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 14))
            .shadow(color: .teal.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(authService.isLoading)
    }

    private var modeSwitchButton: some View {
        HStack(spacing: 4) {
            Text(mode == .login ? "Hesabınız yok mu?" : "Zaten hesabınız var mı?")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.4))

            Button(mode == .login ? "Kayıt Ol" : "Giriş Yap") {
                withAnimation(.spring(duration: 0.3)) {
                    mode = mode == .login ? .register : .login
                    authService.errorMessage = nil
                }
            }
            .font(.footnote.bold())
            .foregroundStyle(.teal)
        }
        .padding(.top, 4)
    }

    private var guestButton: some View {
        Button {
            authService.continueAsGuest()
            dismiss()
        } label: {
            Text("Misafir olarak devam et")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.35))
                .underline()
        }
        .disabled(authService.isLoading)
    }

    private var resetPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)
                    Text("Şifre Sıfırlama")
                        .font(.title2.bold())
                    Text("Kayıtlı e-posta adresinize sıfırlama bağlantısı göndereceğiz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 24)

                if resetSent {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Sıfırlama bağlantısı gönderildi")
                            .font(.headline)
                        Text("E-posta kutunuzu kontrol edin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                } else {
                    VStack(spacing: 16) {
                        AuthTextField(
                            icon: "envelope",
                            placeholder: "E-posta",
                            text: $resetEmail,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        .padding(.horizontal, 24)

                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 24)
                        }

                        Button {
                            Task {
                                let success = await authService.resetPassword(email: resetEmail)
                                if success { resetSent = true }
                            }
                        } label: {
                            Group {
                                if authService.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sıfırlama Bağlantısı Gönder")
                                        .font(.body.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 14))
                        }
                        .padding(.horizontal, 24)
                        .disabled(authService.isLoading)
                    }
                }

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showResetSheet = false
                        resetSent = false
                        authService.errorMessage = nil
                    }
                }
            }
        }
    }
}

struct AuthWindowAnchorBridge: UIViewRepresentable {
    let onResolve: @MainActor (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        DispatchQueue.main.async {
            onResolve(view.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            onResolve(uiView.window)
        }
    }
}

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 40)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 52)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}
