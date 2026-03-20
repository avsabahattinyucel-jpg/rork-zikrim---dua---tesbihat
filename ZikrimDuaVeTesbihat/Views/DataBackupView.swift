import SwiftUI

struct DataBackupView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let storage: StorageService
    let authService: AuthService
    private var cloudSync: CloudSyncService { CloudSyncService.shared }
    @State private var showRestoreAlert: Bool = false
    @State private var showSuccessToast: Bool = false
    @State private var successMessage: String = ""
    @State private var showICloudAlert: Bool = false
    @State private var showPremiumPaywall: Bool = false

    private var isPremium: Bool { authService.isPremium }
    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Group {
            if isPremium {
                ScrollView {
                    VStack(spacing: 20) {
                        iCloudStatusCard

                        backupCard

                        restoreCard

                        syncInfoCard

                        if let error = cloudSync.syncError {
                            errorBanner(error)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            } else {
                lockedContent
            }
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(L10n.string(.veriYedekleme2))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumView(authService: authService)
        }
        .overlay {
            if showSuccessToast {
                successToastOverlay
            }
        }
        .alert(L10n.string(.geriYukle2), isPresented: $showRestoreAlert) {
            Button(.geriYukle2, role: .destructive) {
                Task {
                    await cloudSync.syncFromCloud(storage: storage)
                    if cloudSync.syncError == nil {
                        successMessage = "Veriler basariyla geri yuklendi!"
                        showSuccessToast = true
                        dismissToast()
                    }
                }
            }
            Button(.iptal2, role: .cancel) {}
        } message: {
            Text(.buluttakiVerilerMevcutVerilerinizinUzerineYazilacakDevamEtmekIstiyorMusunuz2)
        }
        .alert(L10n.string(.icloudGerekli2), isPresented: $showICloudAlert) {
            Button(.tamam2, role: .cancel) {}
        } message: {
            Text(.icloudHesabinizaGirisYapmanizGerekiyorAyarlarAppleKimliginizIcloudBolumundenGirisYapin)
        }
        .task {
            guard isPremium else { return }
            await cloudSync.checkiCloudStatus()
        }
    }

    private var lockedContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "icloud.slash.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text(L10n.string(.veriYedekleme2))
                        .font(.title3.bold())

                    Text(L10n.string(.buOzellikYalnizcaPremiumKullanicilaraAciktir))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(L10n.string(.premiumAGec2)) {
                    showPremiumPaywall = true
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .themedPrimaryButton(cornerRadius: 16)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    private var iCloudStatusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(cloudSync.iCloudAvailable ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: cloudSync.iCloudAvailable ? "checkmark.icloud.fill" : "xmark.icloud.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(cloudSync.iCloudAvailable ? .green : .red)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(.icloudDurumu2)
                    .font(.subheadline.weight(.semibold))
                Text(cloudSync.iCloudAvailable ? "bagli_ve_hazir" : "baglanti_yok")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if cloudSync.iCloudAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(.icloudAYedekle)
                        .font(.subheadline.weight(.semibold))
                    Text(.tumVerileriniziBulutaKaydedin)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    guard cloudSync.iCloudAvailable else {
                        showICloudAlert = true
                        return
                    }
                    await cloudSync.uploadToCloud(storage: storage)
                    if cloudSync.syncError == nil {
                        successMessage = "Yedekleme basariyla tamamlandi!"
                        showSuccessToast = true
                        dismissToast()
                    }
                }
            } label: {
                HStack {
                    if cloudSync.isUploading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                    }
                    Text(cloudSync.isUploading ? "yedekleniyor" : "simdi_yedekle")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .themedPrimaryButton(cornerRadius: 12)
            }
            .disabled(cloudSync.isUploading)

            if let lastSync = cloudSync.lastSyncDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text(L10n.format(.lastBackupFormat, lastSync.formatted(date: .abbreviated, time: .shortened)))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var restoreCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "icloud.and.arrow.down.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(.icloudDanGeriYukle2)
                        .font(.subheadline.weight(.semibold))
                    Text(.buluttakiYedegiCihazinizaAktarin)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                guard cloudSync.iCloudAvailable else {
                    showICloudAlert = true
                    return
                }
                showRestoreAlert = true
            } label: {
                HStack {
                    if cloudSync.isDownloading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(cloudSync.isDownloading ? "geri_yukleniyor" : "geri_yukle_2")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .themedSecondaryButton(cornerRadius: 12)
            }
            .disabled(cloudSync.isDownloading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var syncInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(.senkronizasyonBilgisi2, systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                infoRow(icon: "circle.circle.fill", text: L10n.string(.syncInfoDhikrProgress))
                infoRow(icon: "heart.fill", text: L10n.string(.syncInfoFavorites))
                infoRow(icon: "chart.bar.fill", text: L10n.string(.syncInfoStatsDaily))
                infoRow(icon: "book.closed.fill", text: L10n.string(.syncInfoJournal))
                infoRow(icon: "gearshape.fill", text: L10n.string(.syncInfoSettingsProfile))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(14)
        .background(Color.red.opacity(0.1))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var successToastOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(successMessage)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(.capsule)
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.4), value: showSuccessToast)
    }

    private func dismissToast() {
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            showSuccessToast = false
        }
    }
}
