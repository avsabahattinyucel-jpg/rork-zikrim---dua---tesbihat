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

    private var theme: AppTheme {
        themeManager.palette(using: systemColorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(theme.secondaryBackground)
                        .frame(width: 58, height: 58)

                    Image("diyanetlogo")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Resmi bilgi arşivi")
                        .font(.title3.bold())
                        .foregroundStyle(theme.primaryText)
                    Text("Din İşleri Yüksek Kurulu tarafından yayımlanan kamuya açık soru-cevap, karar ve mütalaa içerikleri için ayrılmış alan.")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .overlay(theme.divider)

            VStack(alignment: .leading, spacing: 8) {
                Label("Resmi metinler kaynak bağlantısıyla gösterilecek.", systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                Label("Bu alan Rehber içinde bağımsız bir bilgi modülü olarak kurgulandı.", systemImage: "square.grid.2x2.fill")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .padding(18)
        .appCardStyle(theme, elevated: true, cornerRadius: 24)
    }

    private var sourceStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kaynak Özeti")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                    Text("\(store.totalCount) kayıt")
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

            VStack(alignment: .leading, spacing: 6) {
                Text(store.payload.sourceName)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.primaryText)
                Text(store.payload.sourceDomain)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                if let datasetVersion = store.payload.datasetVersion, !datasetVersion.isEmpty {
                    Text("Dataset sürümü: \(datasetVersion)")
                        .font(.caption2)
                        .foregroundStyle(theme.mutedText)
                }
                if let generatedAt = store.payload.generatedAt {
                    Text("Dataset tarihi: \(generatedAt)")
                        .font(.caption2)
                        .foregroundStyle(theme.mutedText)
                }
            }
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }

    private var sectionCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bölümler")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            ForEach(store.sections) { section in
                NavigationLink {
                    DiyanetKnowledgeListView(store: store, initialType: section.type)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.12))
                                .frame(width: 38, height: 38)
                            Image(systemName: section.systemImage)
                                .font(.subheadline)
                                .foregroundStyle(theme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.primaryText)
                            Text("\(section.count) içerik")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(theme.mutedText)
                    }
                    .padding(14)
                    .appCardStyle(theme, elevated: false, cornerRadius: 16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Öne Çıkan Kategoriler")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            ForEach(store.topCategories.prefix(5), id: \.name) { category in
                HStack {
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryText)
                    Spacer()
                    Text("\(category.count)")
                        .font(.caption.bold())
                        .foregroundStyle(theme.secondaryText)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .appCardStyle(theme, elevated: false)
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
                    Text("İlk entegrasyon adımı hazır")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }
            }

            Text("Crawler export dosyası uygulamaya senkronlandığında liste ve detay ekranları otomatik dolacak.")
                .font(.caption)
                .foregroundStyle(theme.mutedText)
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }
}
