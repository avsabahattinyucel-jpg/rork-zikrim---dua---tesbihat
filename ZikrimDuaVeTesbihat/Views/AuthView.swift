import SwiftUI
import AuthenticationServices
import UIKit

struct AuthView: View {
    enum CloseAction {
        case dismiss
        case continueAsGuest
    }

    let authService: AuthService
    var closeAction: CloseAction = .dismiss
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
                                Button(.sifremiUnuttum) {
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.10))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .disabled(authService.isLoading)
                    .contentShape(Circle())
                    .accessibilityLabel(Text(.kapat2))
                }
            }
            .toolbarBackground(Color(red: 0.04, green: 0.08, blue: 0.16), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showResetSheet) {
                resetPasswordSheet
            }
            .onChange(of: authService.currentUser?.id) { _, newValue in
                if newValue != nil, closeAction == .dismiss { dismiss() }
            }
        }
    }

    private func handleClose() {
        switch closeAction {
        case .dismiss:
            dismiss()
        case .continueAsGuest:
            Task {
                _ = await authService.continueAsGuest()
            }
        }
    }

    private var backgroundView: some View {
        AtmosphericBackgroundView(
            baseColors: [
                Color(red: 0.04, green: 0.08, blue: 0.16),
                Color(red: 0.06, green: 0.12, blue: 0.22),
                Color(red: 0.04, green: 0.08, blue: 0.18)
            ],
            primaryGlow: Color(red: 0.18, green: 0.74, blue: 0.70),
            secondaryGlow: Color(red: 0.36, green: 0.44, blue: 0.88),
            overlayTint: Color.white.opacity(colorScheme == .dark ? 0.02 : 0.05),
            isDarkMode: colorScheme == .dark,
            primaryAlignment: .top,
            secondaryAlignment: .bottomTrailing,
            primaryOffsetRatio: CGSize(width: 0, height: -0.18),
            secondaryOffsetRatio: CGSize(width: 0.16, height: 0.22),
            glowIntensity: 1.05
        )
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            Image("opening")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)
                .allowsHitTesting(false)

            Text(AppName.fullTextKey)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 6) {
                Text(mode == .login ? "hesabiniza_giris_yapin" : "yeni_hesap_olusturun")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                Text(.rabiaUygulamaninIslamiRehberiOlarakHerAnSeninle)
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
                    Text(.googleIleDevamEt2)
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
                    Text(.appleIleDevamEt2)
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
            Text(.veyaEPostaIle)
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
                darkTextField(icon: "person", placeholder: L10n.string(.fullNameTitle), text: $displayName)
            }

            darkTextField(icon: "envelope", placeholder: L10n.string(.emailTitle), text: $email, keyboardType: .emailAddress)

            HStack(spacing: 0) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 40)

                if showPassword {
                    TextField(.sifre, text: $password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                } else {
                    SecureField(.sifre, text: $password)
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
                darkSecureField(icon: "lock.shield", placeholder: L10n.string(.confirmPassword), text: $confirmPassword)
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
                    Text(mode == .login ? "giris_yap" : "kayit_ol")
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
            Text(mode == .login ? "hesabiniz_yok_mu" : "zaten_hesabiniz_var_mi")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.4))

            Button(mode == .login ? "kayit_ol" : "giris_yap") {
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
            handleClose()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 14, weight: .semibold))
                Text(.misafirOlarakDevamEt2)
                    .font(.footnote.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(.white.opacity(0.82))
            .background(Color.white.opacity(0.06))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
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
                    Text(.sifreSifirlama)
                        .font(.title2.bold())
                    Text(.kayitliEPostaAdresinizeSifirlamaBaglantisiGonderecegiz)
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
                        Text(.sifirlamaBaglantisiGonderildi)
                            .font(.headline)
                        Text(.ePostaKutunuzuKontrolEdin)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                } else {
                    VStack(spacing: 16) {
                        AuthTextField(
                            icon: "envelope",
                            placeholder: L10n.string(.emailTitle),
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
                                    ProgressView()
                                } else {
                                    Text(.sifirlamaBaglantisiGonder)
                                        .font(.body.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .themedPrimaryButton(cornerRadius: 14)
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
                    Button(.kapat2) {
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
