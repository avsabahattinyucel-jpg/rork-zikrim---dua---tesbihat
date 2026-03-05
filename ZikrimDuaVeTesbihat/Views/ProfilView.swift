import SwiftUI
import UIKit
import PhotosUI

struct ProfilView: View {
    let storage: StorageService
    let authService: AuthService

    @State private var showPremium: Bool = false
    @State private var showCamera: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var imageData: Data?
    @State private var isPremium: Bool = false
    @State private var displayName: String = ""
    @State private var showAuth: Bool = false

    private var resolvedName: String {
        if !displayName.isEmpty { return displayName }
        if let name = authService.currentUser?.displayName, !name.isEmpty { return name }
        if let email = authService.currentUser?.email, !email.isEmpty { return email }
        if !storage.profile.displayName.isEmpty { return storage.profile.displayName }
        return "Misafir Kullanıcı"
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    premiumHeroCard
                    accountCard
                    actionCard
                    settingsCard

                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .sheet(isPresented: $showPremium) {
                PremiumView(authService: authService)
            }
            .sheet(isPresented: $showPhotoPicker) {
                ProfileImagePickerView(selectedImageData: $imageData) {
                    showPhotoPicker = false
                    showCamera = true
                }
                .padding(.horizontal, 16)
                .presentationDetents([.height(170)])
            }
            .sheet(isPresented: $showCamera) {
                CameraImagePicker(imageData: $imageData)
            }
            .fullScreenCover(isPresented: $showAuth) {
                AuthView(authService: authService)
            }
            .task {
                await loadProfileData()
                await checkPremiumStatus()
            }
            .safeAreaInset(edge: .bottom) {
                ConditionalBannerAd(isPremium: isPremium)
            }
            .onChange(of: imageData) { _, newValue in
                storage.profile.avatarBase64 = newValue?.base64EncodedString()
                storage.saveProfile()
                Task { await syncPhoto() }
            }
            .onChange(of: authService.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    Task {
                        await loadProfileData()
                        await checkPremiumStatus()
                    }
                } else {
                    displayName = ""
                }
            }
            .onChange(of: authService.currentUser?.displayName) { _, newName in
                guard let newName, !newName.isEmpty else { return }
                if displayName.isEmpty {
                    displayName = newName
                }
            }
            .onChange(of: authService.currentUser?.email) { _, _ in
            }
        }
    }

    private var premiumHeroCard: some View {
        Button {
            showPremium = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(isPremium ? "Premium Aktif" : "Premium'a Geç")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(isPremium ? "Reklamsız deneyim ve tüm ayrıcalıklar açık" : "Aylık ₺79,9 · Yıllık ₺799 + 3 gün ücretsiz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var accountCard: some View {
        VStack(spacing: 14) {
            Button {
                showPhotoPicker = true
            } label: {
                avatarView
            }
            .buttonStyle(.plain)

            Text(resolvedName)
                .font(.title3.weight(.semibold))

            Text(isPremium ? "Premium Üye" : "Free Üye")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((isPremium ? Color.yellow : Color.secondary).opacity(0.18))
                .clipShape(.capsule)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color(.secondarySystemGroupedBackground), Color(.tertiarySystemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 22))
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = imageData ?? Data(base64Encoded: storage.profile.avatarBase64 ?? ""),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var actionCard: some View {
        VStack(spacing: 0) {
            Button {
                showPremium = true
            } label: {
                actionButtonLabel("Aboneliği yönet", icon: "crown.fill")
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            Button {
                Task { await restorePurchases() }
            } label: {
                actionButtonLabel("Satın alımları geri yükle", icon: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            if authService.isLoggedIn {
                Button(role: .destructive) {
                    authService.signOut()
                } label: {
                    actionButtonLabel("Çıkış yap", icon: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showAuth = true
                } label: {
                    actionButtonLabel("Giriş yap", icon: "person.crop.circle.badge.checkmark")
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            NavigationLink { NotificationSettingsView() } label: { settingsRow("Bildirim & Ses", icon: "bell.badge.fill") }
                .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink { NamazVakitleriView() } label: { settingsRow("Namaz Vakitleri", icon: "moon.stars.fill") }
                .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink { WidgetInfoView() } label: { settingsRow("Widget", icon: "square.grid.2x2.fill") }
                .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink { AboutView() } label: { settingsRow("Hakkında", icon: "info.circle.fill") }
                .buttonStyle(.plain)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private func actionButtonLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }

    private func settingsRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }

    private func loadProfileData() async {
        if let profile = await authService.fetchProfile(), !profile.name.isEmpty {
            displayName = profile.name
            storage.profile.displayName = profile.name
            storage.profile.email = profile.email
            storage.profile.avatarBase64 = profile.avatarBase64
            storage.saveProfile()
        } else if let name = authService.currentUser?.displayName, !name.isEmpty {
            displayName = name
        } else if let email = authService.currentUser?.email, !email.isEmpty {
            displayName = email
        } else {
            displayName = storage.profile.displayName
        }
    }

    private func syncPhoto() async {
        guard authService.isLoggedIn else { return }
        let email: String = authService.currentUser?.email ?? storage.profile.email
        _ = await authService.updateProfile(name: resolvedName, email: email, avatarBase64: storage.profile.avatarBase64)
    }

    private func restorePurchases() async {
        _ = try? await RevenueCatService.shared.restorePurchases()
        await checkPremiumStatus()
    }

    private func checkPremiumStatus() async {
        do {
            let info = try await RevenueCatService.shared.customerInfo()
            isPremium = RevenueCatService.shared.hasActiveEntitlement(info)
        } catch {}
    }

}

struct AboutView: View {
    var body: some View {
        List {
            Section("Zikrim Nedir?") {
                Text("Zikrim, günlük dua ve zikir pratiğini düzenli şekilde takip etmenizi sağlayan bir ibadet destek uygulamasıdır.")
            }

            Section("Uygulamanın Amacı") {
                Text("Amacımız; zikir sayaçları, rehber içerikler, namaz vakitleri ve kişisel takip araçlarıyla manevi rutini sürdürülebilir hale getirmektir.")
            }

            Section("Premium Avantajları") {
                Label("Reklamsız kullanım", systemImage: "checkmark.seal.fill")
                Label("Bulut senkronizasyonu", systemImage: "icloud.fill")
                Label("Detaylı istatistik", systemImage: "chart.bar.xaxis")
                Label("Widget desteği", systemImage: "rectangle.3.group.fill")
                Label("Bildirim ses paketi", systemImage: "speaker.wave.2.fill")
                Label("Filigransız paylaşım kartları", systemImage: "photo.badge.checkmark")
            }

            Section("Gizlilik") {
                Text("Verileriniz öncelikli olarak cihazınızda yerel olarak saklanır.")
            }

            Section("Sürüm") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }

            Section("İletişim") {
                Text("support@zikrim.app")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Hakkında")
    }
}
