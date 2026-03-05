import SwiftUI

struct GlobalFavoritesView: View {
    let storage: StorageService

    @State private var selectedType: FavoriteItemType? = nil

    private var filteredItems: [FavoriteItem] {
        storage.favorites(of: selectedType)
    }

    var body: some View {
        NavigationStack {
            List {
                filterSection

                Section {
                    ForEach(filteredItems) { item in
                        favoriteRow(item)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Favoriler")
            .overlay {
                if filteredItems.isEmpty {
                    ContentUnavailableView("Favori Yok", systemImage: "moon.stars", description: Text("Kur'an, zikir ve duaları favorilere ekleyin"))
                }
            }
        }
    }

    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "Tümü", isSelected: selectedType == nil) {
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
        HStack(spacing: 12) {
            Image(systemName: icon(for: item.type))
                .foregroundStyle(color(for: item.type))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
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
