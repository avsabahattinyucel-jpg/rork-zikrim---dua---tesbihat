import Observation
import SwiftUI

struct AccountSettingsView: View {
    let storage: StorageService
    let authService: AuthService

    @State private var viewModel: AccountSettingsViewModel
    @State private var subscriptionStore: SubscriptionStore

    init(storage: StorageService, authService: AuthService) {
        self.storage = storage
        self.authService = authService
        _viewModel = State(initialValue: AccountSettingsViewModel(storage: storage, authService: authService))
        _subscriptionStore = State(initialValue: SubscriptionStore(authService: authService))
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        List {
            Section(L10n.string(.accountSectionTitle)) {
                NavigationLink {
                    ProfileDetailsView(storage: storage, authService: authService)
                } label: {
                    settingsRow(
                        title: L10n.string(.profileDetailsTitle),
                        subtitle: viewModel.resolvedName,
                        systemImage: "person.crop.circle.fill"
                    )
                }

                Button {
                    if viewModel.isPremium {
                        viewModel.isShowingPremiumManagement = true
                    } else {
                        viewModel.isShowingPaywall = true
                    }
                } label: {
                    settingsRow(
                        title: L10n.string(.subscriptionSectionTitle),
                        subtitle: viewModel.subscriptionStatusText,
                        systemImage: "crown.fill"
                    )
                }
                .buttonStyle(.plain)
            }

            Section(L10n.string(.premiumAvantajlari)) {
                if viewModel.isPremium {
                    NavigationLink {
                        IstatistikView(storage: storage, authService: authService)
                    } label: {
                        settingsRow(
                            title: L10n.string(.detayliIstatistik),
                            subtitle: L10n.string(.premiumStatusActive),
                            systemImage: "chart.bar.xaxis"
                        )
                    }

                    NavigationLink {
                        DataBackupView(storage: storage, authService: authService)
                    } label: {
                        settingsRow(
                            title: L10n.string(.veriYedekleme2),
                            subtitle: L10n.string(.premiumStatusActive),
                            systemImage: "icloud.fill"
                        )
                    }
                } else {
                    Button {
                        viewModel.isShowingPaywall = true
                    } label: {
                        settingsRow(
                            title: L10n.string(.detayliIstatistik),
                            subtitle: L10n.string(.premiumAGec2),
                            systemImage: "chart.bar.xaxis"
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.isShowingPaywall = true
                    } label: {
                        settingsRow(
                            title: L10n.string(.veriYedekleme2),
                            subtitle: L10n.string(.premiumAGec2),
                            systemImage: "icloud.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(L10n.string(.privacyAndLegalTitle)) {
                Button {
                    Task { await viewModel.restorePurchases() }
                } label: {
                    settingsRow(
                        title: L10n.string(.restorePurchasesTitle),
                        subtitle: viewModel.isRestoringPurchases ? L10n.string(.geriYukleniyor) : nil,
                        systemImage: "arrow.clockwise",
                        isLoading: viewModel.isRestoringPurchases
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRestoringPurchases || viewModel.isDeletingAccount)

                NavigationLink {
                    LegalHubView()
                } label: {
                    settingsRow(
                        title: L10n.string(.legalTitle),
                        subtitle: nil,
                        systemImage: "doc.text.fill"
                    )
                }
            }

            Section(L10n.string(.supportSectionTitle)) {
                Link(destination: AppReviewConfiguration.supportURL) {
                    settingsRow(
                        title: L10n.string(.contactSupportTitle),
                        subtitle: AppReviewConfiguration.supportURL.absoluteString,
                        systemImage: "questionmark.circle.fill"
                    )
                }

                if let supportURL = AppReviewConfiguration.supportEmailURL {
                    Link(destination: supportURL) {
                        settingsRow(
                            title: "Destek e-postası",
                            subtitle: AppReviewConfiguration.supportEmail,
                            systemImage: "envelope.fill"
                        )
                    }
                } else {
                    settingsRow(
                        title: "Destek e-postası",
                        subtitle: AppReviewConfiguration.supportEmail,
                        systemImage: "envelope.fill"
                    )
                }
            }

            if authService.isLoggedIn {
                DeleteAccountSection(isDeleting: viewModel.isDeletingAccount) {
                    viewModel.requestAccountDeletion()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.string(.profil2))
        .navigationBarTitleDisplayMode(.inline)
        .disabled(viewModel.isDeletingAccount)
        .overlay {
            if viewModel.isDeletingAccount {
                deletionProgressOverlay
            }
        }
        .sheet(isPresented: $bindableViewModel.isShowingPaywall) {
            PremiumView(authService: authService)
        }
        .sheet(isPresented: $bindableViewModel.isShowingPremiumManagement) {
            NavigationStack {
                PremiumManagementView(subscriptionStore: subscriptionStore)
            }
        }
        .fullScreenCover(isPresented: $bindableViewModel.isShowingAuth) {
            AuthView(authService: authService)
        }
        .sheet(item: $bindableViewModel.reauthenticationContext) { context in
            ReauthenticationView(
                context: context,
                isWorking: viewModel.isReauthenticating || viewModel.isDeletingAccount,
                onCancel: {
                    viewModel.clearReauthenticationState()
                },
                onSubmitPassword: { password in
                    await viewModel.reauthenticateWithPassword(password)
                },
                onContinueWithProvider: {
                    switch context.method {
                    case .apple:
                        await viewModel.reauthenticateWithApple()
                    case .google:
                        await viewModel.reauthenticateWithGoogle()
                    case .email:
                        break
                    }
                }
            )
        }
        .alert(L10n.string(.deleteAccountTitle), isPresented: $bindableViewModel.isShowingDeleteConfirmation) {
            Button(L10n.string(.deleteAccountTitle), role: .destructive) {
                Task { await viewModel.confirmAccountDeletion() }
            }
            Button(L10n.string(.iptal2), role: .cancel) {}
        } message: {
            Text(L10n.string(.deleteAccountConfirmationMessage))
        }
        .alert(L10n.string(.accountSettingsStatusTitle), isPresented: Binding(
            get: { bindableViewModel.feedbackMessage != nil },
            set: { if !$0 { bindableViewModel.feedbackMessage = nil } }
        )) {
            Button(L10n.string(.tamam2), role: .cancel) {}
        } message: {
            Text(bindableViewModel.feedbackMessage ?? "")
        }
        .task {
            await viewModel.refresh()
        }
    }

    private func settingsRow(
        title: String,
        subtitle: String?,
        systemImage: String,
        isLoading: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .tint(.accentColor)
                    .frame(width: 24, alignment: .leading)
            } else {
                Image(systemName: systemImage)
                    .frame(width: 24, alignment: .leading)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private var deletionProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(.deleteAccountLoadingTitle)
                    .font(.headline)
                Text(.deleteAccountLoadingMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 12)
        }
    }
}
