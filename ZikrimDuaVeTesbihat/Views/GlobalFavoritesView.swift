import SwiftUI

struct GlobalFavoritesView: View {
    @EnvironmentObject private var appState: AppState
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss

    @State private var quranService = QuranService()
    @StateObject private var readingSystemStore = QuranReadingSystemStore()
    @State private var selectedType: FavoriteItemType? = nil
    @State private var showDeletedAlert: Bool = false
    @State private var navigationPath = NavigationPath()

    private var filteredItems: [FavoriteItem] {
        storage.favorites(of: selectedType)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                filterSection

                Section {
                    ForEach(filteredItems) { item in
                        favoriteRow(item)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.string(.favoriler))
            .navigationDestination(for: QuranNavDestination.self) { dest in
                switch dest {
                case let .reader(route):
                    SurahDetailView(
                        route: route,
                        quranService: quranService,
                        storage: storage,
                        readingSystemStore: readingSystemStore
                    )
                case .bookmarks:
                    EmptyView()
                case .juzs:
                    EmptyView()
                case .audioControls:
                    EmptyView()
                }
            }
            .overlay {
                if filteredItems.isEmpty {
                    ContentUnavailableView(L10n.string(.favoriYok), systemImage: "moon.stars", description: Text(.kurAnZikirVeDualariFavorilereEkleyin))
                }
            }
            .task {
                readingSystemStore.bootstrapIfNeeded(lastRead: quranService.lastReadPosition)
            }
        }
    }

    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: L10n.string(.allFilter), isSelected: selectedType == nil) {
                        selectedType = nil
                    }
                    ForEach(FavoriteItemType.allCases, id: \.self) { type in
                        filterChip(title: type.title, isSelected: selectedType == type) {
                            selectedType = type
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func favoriteRow(_ item: FavoriteItem) -> some View {
        Button {
            handleFavoriteTap(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon(for: item.type))
                    .foregroundStyle(color(for: item.type))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    storage.toggleFavorite(item)
                } label: {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .alert(L10n.string(.buZikirArtikMevcutDegil), isPresented: $showDeletedAlert) {
            Button(.tamam2, role: .cancel) {}
        }
    }

    private func handleFavoriteTap(_ item: FavoriteItem) {
        if item.type == .quran {
            let parts = item.id.split(separator: ":")
            if let surahId = Int(parts.first ?? ""),
               let verseNumber = Int(parts.last ?? "") {
                navigationPath.append(QuranNavDestination.reader(QuranReadingRoute(surahId: surahId, ayahNumber: verseNumber)))
            } else {
                showDeletedAlert = true
            }
            return
        }

        guard item.type == .zikir || item.type == .dua else { return }

        if let counter = storage.counters.first(where: { $0.zikirItemId == item.id }) {
            storage.pendingSelectedCounterId = counter.id
            appState.selectTab(.dhikrs)
            dismiss()
        } else {
            let allZikir = ZikirData.categories.flatMap(\.items) + storage.customZikirs
            let rehberEntries = ZikirRehberiData.entries

            if let zikir = allZikir.first(where: { $0.id == item.id }) {
                let counter = CounterModel(name: zikir.localizedPronunciation, targetCount: zikir.recommendedCount, zikirItemId: zikir.id)
                storage.addCounter(counter)
                storage.pendingSelectedCounterId = counter.id
                appState.selectTab(.dhikrs)
                dismiss()
            } else if let rehber = rehberEntries.first(where: { $0.id == item.id }) {
                let counter = CounterModel(name: rehber.localizedTitle, targetCount: rehber.recommendedCount, zikirItemId: rehber.id)
                storage.addCounter(counter)
                storage.pendingSelectedCounterId = counter.id
                appState.selectTab(.dhikrs)
                dismiss()
            } else {
                showDeletedAlert = true
            }
        }
    }

    private func icon(for type: FavoriteItemType) -> String {
        switch type {
        case .quran: return "bookmark.fill"
        case .zikir: return "moon.stars.fill"
        case .dua: return "moon.stars.fill"
        }
    }

    private func color(for type: FavoriteItemType) -> Color {
        switch type {
        case .quran: return .teal
        case .zikir: return .yellow
        case .dua: return .indigo
        }
    }
}
