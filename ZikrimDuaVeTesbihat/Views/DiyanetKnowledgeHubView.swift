import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    static var groupedBackgroundCompat: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }

    static var secondaryGroupedBackgroundCompat: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color.gray.opacity(0.08)
        #endif
    }
}

extension View {
    @ViewBuilder
    func diyanetNavigationTitleStyle() -> some View {
        #if canImport(UIKit)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }
}

struct DiyanetKnowledgeHubView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @StateObject private var store = DiyanetKnowledgeStore()

    private let sectionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var theme: AppTheme {
        themeManager.palette(using: systemColorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                if store.isLoading {
                    loadingCard
                } else if let errorMessage = store.errorMessage, store.records.isEmpty {
                    emptyStateCard(message: errorMessage)
                } else {
                    sourceStatsCard

                    if !store.sections.isEmpty {
                        sectionCards
                    }

                    if !store.topCategories.isEmpty {
                        categoryCard
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .themedScreenBackground()
        .themedNavigation(title: "Diyanet Kaynakları", displayMode: .large)
        .task {
            await store.loadIfNeeded()
        }
    }

    private var headerCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.cardBackground,
                            theme.secondaryBackground.opacity(0.97),
                            theme.cardBackground,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(theme.accent.opacity(0.18))
                        .frame(width: 170, height: 170)
                        .blur(radius: 14)
                        .offset(x: 38, y: -44)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(Color.white.opacity(theme.isDarkMode ? 0.06 : 0.24))
                        .frame(width: 140, height: 140)
                        .blur(radius: 12)
                        .offset(x: -28, y: 40)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(theme.accent.opacity(theme.isDarkMode ? 0.15 : 0.10), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    heroPill(title: "Resmi kaynak", systemImage: "checkmark.shield.fill")
                    heroPill(title: "\(store.totalCount) kayıt", systemImage: "books.vertical.fill")
                }

                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDarkMode ? 0.14 : 0.88),
                                        theme.secondaryBackground.opacity(theme.isDarkMode ? 0.95 : 0.98),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.36), lineWidth: 1)
                            )
                            .shadow(color: theme.accent.opacity(theme.isDarkMode ? 0.22 : 0.12), radius: 18, y: 8)

                        Image("diyanetlogo")
                            .resizable()
                            .scaledToFit()
                            .padding(13)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Diyanet Kaynakları")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)

                        Text("Din İşleri Yüksek Kurulu'nun kamuya açık soru-cevap, karar ve mütalaa içerikleri tek yerde.")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Resmi metinler aynen korunur, kaynak bağlantısıyla birlikte sunulur.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(theme.primaryText.opacity(0.88))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.elevatedCardBackground.opacity(theme.isDarkMode ? 0.78 : 0.96))
                    )

                HStack(spacing: 10) {
                    heroInfoCard(
                        title: "Kaynak",
                        value: "Diyanet",
                        detail: store.payload.sourceDomain
                    )
                    heroInfoCard(
                        title: "Son güncelleme",
                        value: displayUpdatedAt,
                        detail: store.dataOrigin.displayName
                    )
                }
            }
            .padding(20)
        }
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.18 : 0.08), radius: 28, y: 12)
    }

    private var sourceStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Canlı veri durumu")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                    Text("Sürüm ve senkron bilgileri")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                NavigationLink {
                    DiyanetKnowledgeListView(store: store)
                } label: {
                    Text("Tümünü Gör")
                        .font(.caption.bold())
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                compactMetricCard(
                    title: "Veri kaynağı",
                    value: store.dataOrigin.displayName,
                    systemImage: "antenna.radiowaves.left.and.right"
                )
                compactMetricCard(
                    title: "Sürüm",
                    value: shortVersionText,
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                )
            }
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }

    private var displayDatasetVersion: String {
        let rawValue = store.payload.datasetVersion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return rawValue.isEmpty ? "Bilinmiyor" : rawValue
    }

    private var shortVersionText: String {
        let full = displayDatasetVersion
        guard full.count > 19 else { return full }
        return String(full.prefix(19))
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

    private func heroPill(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.bold())
            Text(title)
                .font(.caption.bold())
        }
        .foregroundStyle(theme.primaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(theme.elevatedCardBackground.opacity(theme.isDarkMode ? 0.84 : 0.94))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.28), lineWidth: 1)
        )
    }

    private func heroInfoCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(0.9)
                .foregroundStyle(theme.secondaryText)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(theme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
            Text(detail)
                .font(.caption)
                .foregroundStyle(theme.mutedText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.elevatedCardBackground.opacity(theme.isDarkMode ? 0.8 : 0.96))
        )
    }

    private func compactMetricCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundStyle(theme.accent)
            Text(title)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(theme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 102, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.elevatedCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(theme.divider.opacity(0.35), lineWidth: 1)
        )
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

    private var sectionCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keşif alanları")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            LazyVGrid(columns: sectionColumns, spacing: 12) {
                ForEach(store.sections) { section in
                    NavigationLink {
                        DiyanetKnowledgeListView(store: store, initialType: section.type)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(theme.accent.opacity(0.12))
                                    .frame(width: 46, height: 46)
                                Image(systemName: section.systemImage)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(theme.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(theme.primaryText)
                                    .multilineTextAlignment(.leading)
                                Text(sectionSubtitle(for: section.type))
                                    .font(.caption)
                                    .foregroundStyle(theme.secondaryText)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 0)

                            HStack {
                                Text("\(section.count) içerik")
                                    .font(.caption.bold())
                                    .foregroundStyle(theme.primaryText)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 166, alignment: .topLeading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(theme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(theme.divider.opacity(0.28), lineWidth: 1)
                        )
                        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.14 : 0.06), radius: 14, y: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionSubtitle(for type: DiyanetContentType) -> String {
        switch type {
        case .qa:
            return "Gündelik dini sorulara resmi cevaplar"
        case .faq:
            return "Hızlı bakış için sık sorulan konular"
        case .karar:
            return "Kurul tarafından yayımlanan resmi kararlar"
        case .mutalaa:
            return "Müzakere ve görüş niteliğindeki metinler"
        }
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Öne çıkan kategoriler")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            VStack(spacing: 10) {
                ForEach(Array(store.topCategories.prefix(5).enumerated()), id: \.element.name) { index, category in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.primaryText)
                            Spacer()
                            Text("\(category.count)")
                                .font(.caption.bold())
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        GeometryReader { proxy in
                            let width = proxy.size.width
                            let ratio = max(0.12, min(CGFloat(category.count) / CGFloat(maxTopCategoryCount), 1))

                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(theme.selectionBackground.opacity(0.72))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accent.opacity(0.52), theme.accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: width * ratio)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, index == 0 ? 0 : 2)
                }
            }
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }

    private var maxTopCategoryCount: Int {
        store.topCategories.map(\.count).max() ?? 1
    }

    private var loadingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ProgressView()
                Text("Diyanet veri paketi yükleniyor")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme, elevated: true)
    }

    private func emptyStateCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "tray.full.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Kaynaklar şu anda gösterilemiyor")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }
            }

            Text("Kaynak verisi kullanılabilir olduğunda liste ve detay ekranları burada otomatik olarak görünecek.")
                .font(.caption)
                .foregroundStyle(theme.mutedText)
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }
}
