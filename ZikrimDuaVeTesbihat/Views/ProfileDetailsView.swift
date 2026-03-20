import SwiftUI
import UIKit

struct ProfileDetailsView: View {
    let storage: StorageService
    let authService: AuthService

    @State private var showPhotoPicker: Bool = false
    @State private var showCamera: Bool = false
    @State private var showAuth: Bool = false
    @State private var imageData: Data?
    @State private var displayName: String = ""

    private var isGuest: Bool { authService.isGuest }

    private var resolvedName: String {
        if !displayName.isEmpty { return displayName }
        if let name = authService.currentUser?.displayName, !name.isEmpty { return name }
        if let email = authService.currentUser?.email, !email.isEmpty { return email }
        if !storage.profile.displayName.isEmpty { return storage.profile.displayName }
        return L10n.string(.displayNameGuest)
    }

    private var resolvedEmail: String {
        if let email = authService.currentUser?.email, !email.isEmpty { return email }
        if !storage.profile.email.isEmpty { return storage.profile.email }
        return L10n.string(.guestProfileStatus)
    }

    private var memberSinceText: String {
        guard let date = authService.currentUser?.createdAt else {
            return L10n.string(.guestProfileStatus)
        }

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        avatarView
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 4) {
                        Text(resolvedName)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text(isGuest ? L10n.string(.guestProfileStatus) : resolvedEmail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Section(L10n.string(.accountSectionTitle)) {
                profileInfoRow(title: L10n.string(.profileNameLabel), value: resolvedName)
                profileInfoRow(title: L10n.string(.emailTitle), value: resolvedEmail)

                if !isGuest {
                    profileInfoRow(title: L10n.string(.memberSince), value: memberSinceText)
                }
            }

            if authService.isLoggedIn {
                Section {
                    Button(role: .destructive) {
                        authService.signOut()
                    } label: {
                        Label(L10n.string(.cikisYap), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            } else {
                Section {
                    Button {
                        showAuth = true
                    } label: {
                        Label(L10n.string(.girisYap), systemImage: "person.crop.circle.badge.plus")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.string(.profileDetailsTitle))
        .navigationBarTitleDisplayMode(.inline)
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
        }
        .onChange(of: imageData) { _, newValue in
            storage.profile.avatarBase64 = newValue?.base64EncodedString()
            storage.saveProfile()
            Task { await syncPhoto() }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = imageData ?? Data(base64Encoded: storage.profile.avatarBase64 ?? ""),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 88, height: 88)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func profileInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 16)
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
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
        let email = authService.currentUser?.email ?? storage.profile.email
        _ = await authService.updateProfile(name: resolvedName, email: email, avatarBase64: storage.profile.avatarBase64)
    }
}
