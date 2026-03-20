import SwiftUI

struct ListelerView: View {
    let storage: StorageService
    let authService: AuthService
    @State private var searchText: String = ""
    @State private var showCustomSheet: Bool = false
    @State private var showPremiumPaywall: Bool = false

    private var isPremium: Bool { authService.isPremium }

    private var allCategories: [ZikirCategory] {
        var cats = ZikirData.categories
        if !storage.customZikirs.isEmpty {
            cats.append(ZikirCategory(
                id: "custom",
                name: L10n.string(.customDhikrTitle),
                icon: "person.fill",
                items: storage.customZikirs,
                isPremium: false
            ))
        }
        return cats
    }

    private var favoriteItems: [ZikirItem] {
        let allItems = ZikirData.categories.flatMap(\.items) + ZikirData.dailyDuas + storage.customZikirs
        return allItems.filter { storage.isFavorite($0.id) }
    }

    private var filteredCategories: [ZikirCategory] {
        guard !searchText.isEmpty else { return allCategories }
        return allCategories.compactMap { category in
            let filtered = category.items.filter {
                $0.localizedPronunciation.localizedStandardContains(searchText) ||
                $0.localizedMeaning.localizedStandardContains(searchText) ||
                $0.arabicText.contains(searchText)
            }
            guard !filtered.isEmpty else { return nil }
            return ZikirCategory(id: category.id, name: category.name, icon: category.icon, items: filtered, isPremium: category.isPremium)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !favoriteItems.isEmpty && searchText.isEmpty {
                    Section {
                        NavigationLink(value: FavoriteDestination()) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(.favorilerim)
                                        .font(.headline)
                                    Text(L10n.format(.dhikrCount, favoriteItems.count))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundStyle(.pink)
                            }
                        }
                    }
                }

                ForEach(filteredCategories) { category in
                    Section {
                        if category.isPremium && !isPremium {
                            Button {
                                showPremiumPaywall = true
                            } label: {
                                HStack {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(category.localizedName)
                                                .font(.headline)
                                            Text(L10n.format(.dhikrCount, category.items.count))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    } icon: {
                                        Image(systemName: category.icon)
                                            .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.0))
                                    }
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.0))
                                }
                            }
                            .tint(.primary)
                        } else {
                            NavigationLink(value: category.id) {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(category.localizedName)
                                            .font(.headline)
                                        Text(L10n.format(.dhikrCount, category.items.count))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(category.isPremium ? Color(red: 0.85, green: 0.65, blue: 0.0) : Color.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "zikir_ara")
            .navigationTitle(L10n.string(.listeler2))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustomSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .navigationDestination(for: String.self) { categoryId in
                CategoryDetailView(categoryId: categoryId, storage: storage)
            }
            .navigationDestination(for: FavoriteDestination.self) { _ in
                FavoritesListView(storage: storage)
            }
            .sheet(isPresented: $showCustomSheet) {
                AddCustomZikirSheet(storage: storage)
            }
            .sheet(isPresented: $showPremiumPaywall) {
                PremiumView(authService: authService)
            }
            .task {
                await authService.refreshPremiumStatus()
            }
        }
    }
}

nonisolated struct FavoriteDestination: Hashable {}

struct CategoryDetailView: View {
    let categoryId: String
    let storage: StorageService

    private var category: ZikirCategory? {
        if categoryId == "custom" {
            return ZikirCategory(id: "custom", name: L10n.string(.customDhikrTitle), icon: "person.fill", items: storage.customZikirs, isPremium: false)
        }
        return ZikirData.categories.first(where: { $0.id == categoryId })
    }

    private var isCustomCategory: Bool {
        categoryId == "custom"
    }

    var body: some View {
        Group {
            if let category {
                List {
                    ForEach(category.items) { item in
                        ZikirItemRow(item: item, storage: storage)
                            .contextMenu {
                                if isCustomCategory {
                                    Button(role: .destructive) {
                                        storage.deleteCustomZikir(item)
                                    } label: {
                                        Label(L10n.string(.sil2), systemImage: "trash")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if isCustomCategory {
                                    Button(role: .destructive) {
                                        storage.deleteCustomZikir(item)
                                    } label: {
                                        Label(L10n.string(.sil2), systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(category.localizedName)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct ZikirItemRow: View {
    let item: ZikirItem
    let storage: StorageService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.arabicText)
                .font(.title3)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(item.localizedPronunciation)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .italic()

                Text(item.localizedMeaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("\(item.recommendedCount)", systemImage: "number.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("\(item.recommendedCount) \(L10n.string(.tekrarSayisi))")

                Spacer()

                Text(item.source)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Button {
                    storage.toggleFavorite(item.id)
                } label: {
                    Image(systemName: storage.isFavorite(item.id) ? "moon.stars.fill" : "moon.stars")
                        .foregroundStyle(storage.isFavorite(item.id) ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FavoritesListView: View {
    let storage: StorageService

    private var items: [ZikirItem] {
        let allItems = ZikirData.categories.flatMap(\.items) + ZikirData.dailyDuas + storage.customZikirs
        return allItems.filter { storage.isFavorite($0.id) }
    }

    var body: some View {
        List {
            ForEach(items) { item in
                ZikirItemRow(item: item, storage: storage)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.string(.favorilerim))
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(L10n.string(.favoriYok), systemImage: "moon.stars", description: Text(.begendiginizZikirleriFavorilereEkleyin))
            }
        }
    }
}

struct AddCustomZikirSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var pronunciation: String = ""
    @State private var meaning: String = ""
    @State private var arabicText: String = ""
    @State private var count: Int = 33

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string(.arapcaMetinOpsiyonel)) {
                    TextField(.arapcaYazin, text: $arabicText)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                Section(L10n.string(.turkceOkunus)) {
                    TextField(.okunusuYazin, text: $pronunciation)
                }
                Section(L10n.string(.anlam2)) {
                    TextField(.anlaminiYazin, text: $meaning)
                }
                Section(L10n.string(.tekrarSayisi)) {
                    Stepper("\(count)", value: $count, in: 1...10000)
                }
            }
            .navigationTitle(L10n.string(.ozelZikirEkle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.iptal) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.kaydet2) {
                        let item = ZikirItem(
                            id: UUID().uuidString,
                            category: "custom",
                            arabicText: arabicText,
                            turkishPronunciation: pronunciation,
                            turkishMeaning: meaning,
                            recommendedCount: count,
                            source: "Özel"
                        )
                        storage.addCustomZikir(item)
                        dismiss()
                    }
                    .disabled(pronunciation.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
