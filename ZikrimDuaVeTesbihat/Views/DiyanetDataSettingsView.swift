import SwiftUI

struct DiyanetDataSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @StateObject private var store = DiyanetKnowledgeStore()

    private var theme: AppTheme {
        themeManager.palette(using: systemColorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                overviewCard
                actionsCard
                infoCard

                if let errorMessage = store.errorMessage, !errorMessage.isEmpty {
                    errorCard(message: errorMessage)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .themedScreenBackground()
        .themedNavigation(title: "Diyanet Verileri", displayMode: .large)
        .task {
            await store.loadIfNeeded()
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Veri Durumu")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            settingsRow(label: "Veri kaynağı", value: store.dataOrigin.displayName)
            settingsRow(label: "Kayıt sayısı", value: "\(store.totalCount)")
            settingsRow(label: "Sürüm", value: store.payload.datasetVersion ?? "Bilinmiyor")
            settingsRow(label: "Son güncelleme", value: displayUpdatedAt)
            settingsRow(label: "Uzak güncelleme", value: store.remoteUpdatesEnabled ? "Açık" : "Kapalı")
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İşlemler")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            Button {
                Task {
                    await store.refreshFromRemote()
                }
            } label: {
                HStack {
                    Label("Verileri şimdi yenile", systemImage: "arrow.clockwise")
                    Spacer()
                    if store.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .themedPrimaryButton(cornerRadius: 14)
            }
            .buttonStyle(.plain)
            .disabled(store.isLoading || !store.remoteUpdatesEnabled)
            .opacity(store.remoteUpdatesEnabled ? 1 : 0.6)

            Button(role: .destructive) {
                store.clearCache()
                Task {
                    await store.load()
                }
            } label: {
                HStack {
                    Label("Önbelleği temizle", systemImage: "trash")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(theme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Not")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            Text("Bu bölüm Diyanet kaynaklı resmi veri paketinin sürüm ve senkron durumunu gösterir. İçerikler uzaktan güncellenebildiğinde uygulama yeni resmi kayıtları uygulama güncellemesi gerektirmeden alabilir.")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .appCardStyle(theme, elevated: false)
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Durum")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
        }
        .padding(16)
        .appCardStyle(theme, elevated: false)
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private var displayUpdatedAt: String {
        if let publishedAt = store.publishedAt,
           let formatted = formattedDateTime(from: publishedAt) {
            return formatted
        }

        if let generatedAt = store.payload.generatedAt,
           let formatted = formattedDateTime(from: generatedAt) {
            return formatted
        }

        if let generatedAt = store.payload.generatedAt,
           !generatedAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return generatedAt
        }

        return "Bilinmiyor"
    }

    private func formattedDateTime(from rawValue: String) -> String? {
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]

        let parsedDate = formatterWithFractional.date(from: rawValue)
            ?? formatterWithoutFractional.date(from: rawValue)

        guard let parsedDate else {
            return nil
        }

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "tr_TR")
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: parsedDate)
    }
}
