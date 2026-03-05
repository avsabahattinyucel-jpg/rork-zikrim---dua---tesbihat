import SwiftUI

struct ListelerView: View {
    let storage: StorageService
    @State private var searchText: String = ""
    @State private var showCustomSheet: Bool = false

    private var allCategories: [ZikirCategory] {
        var cats = ZikirData.categories
        if !storage.customZikirs.isEmpty {
            cats.append(ZikirCategory(
                id: "custom",
                name: "Özel Zikirlerim",
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
                $0.turkishPronunciation.localizedStandardContains(searchText) ||
                $0.turkishMeaning.localizedStandardContains(searchText) ||
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
                                    Text("Favorilerim")
                                        .font(.headline)
                                    Text("\(favoriteItems.count) zikir")
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
                        NavigationLink(value: category.id) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name)
                                        .font(.headline)
                                    Text("\(category.items.count) zikir")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: category.icon)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Zikir ara...")
            .navigationTitle("Listeler")
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
        }
    }
}

nonisolated struct FavoriteDestination: Hashable {}

struct CategoryDetailView: View {
    let categoryId: String
    let storage: StorageService

    private var category: ZikirCategory? {
        if categoryId == "custom" {
            return ZikirCategory(id: "custom", name: "Özel Zikirlerim", icon: "person.fill", items: storage.customZikirs, isPremium: false)
        }
        return ZikirData.categories.first(where: { $0.id == categoryId })
    }

    var body: some View {
        Group {
            if let category {
                List {
                    ForEach(category.items) { item in
                        ZikirItemRow(item: item, storage: storage)
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(category.name)
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
                Text(item.turkishPronunciation)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .italic()

                Text(item.turkishMeaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("\(item.recommendedCount)x", systemImage: "repeat")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

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
        .navigationTitle("Favorilerim")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("Favori Yok", systemImage: "moon.stars", description: Text("Beğendiğiniz zikirleri favorilere ekleyin"))
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
                Section("Arapça Metin (Opsiyonel)") {
                    TextField("Arapça yazın...", text: $arabicText)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                Section("Türkçe Okunuş") {
                    TextField("Okunuşu yazın...", text: $pronunciation)
                }
                Section("Anlam") {
                    TextField("Anlamını yazın...", text: $meaning)
                }
                Section("Tekrar Sayısı") {
                    Stepper("\(count)", value: $count, in: 1...10000)
                }
            }
            .navigationTitle("Özel Zikir Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
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
