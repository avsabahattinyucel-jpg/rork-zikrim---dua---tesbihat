import SwiftUI

struct KuranView: View {
    let storage: StorageService
    @State private var quranService = QuranService()
    @State private var searchText: String = ""
    @State private var showBookmarks: Bool = false
    @State private var showSettings: Bool = false
    @State private var isPremium: Bool = false
    @State private var geminiService = GroqService()
    @State private var showAIAccessAlert: Bool = false

    private var filteredSurahs: [QuranSurah] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return QuranSurahData.surahs }

        let matchingByName = QuranSurahData.surahs.filter {
            $0.turkishName.localizedStandardContains(trimmed) ||
            $0.arabicName.contains(trimmed) ||
            "\($0.id)".contains(trimmed)
        }

        let matchingByMeal = QuranSurahData.offlineVerses
            .filter { _, verses in
                verses.contains { $0.turkishTranslation.localizedStandardContains(trimmed) }
            }
            .compactMap { surahId, _ in
                QuranSurahData.surahs.first(where: { $0.id == surahId })
            }

        return Array(Set(matchingByName + matchingByMeal)).sorted(by: { $0.id < $1.id })
    }

    var body: some View {
        NavigationStack {
            List {
                if let last = quranService.lastReadPosition, searchText.isEmpty {
                    Section {
                        NavigationLink(value: QuranNavDestination(surahId: last.surahId, scrollTo: last.verseNumber)) {
                            HStack(spacing: 14) {
                                Image(systemName: "bookmark.fill")
                                    .font(.title3)
                                    .foregroundStyle(.teal)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Kaldığım Yerden Devam Et")
                                        .font(.subheadline.bold())
                                    Text("\(last.surahName) • \(last.verseNumber). ayet")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !quranService.bookmarks.isEmpty && searchText.isEmpty {
                    Section {
                        Button {
                            showBookmarks = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "star.fill")
                                    .font(.title3)
                                    .foregroundStyle(.yellow)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Yer İmlerim")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text("\(quranService.bookmarks.count) yer imi")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Semantik Arama · Rabia") {
                        Button {
                            runSemanticSearch()
                        } label: {
                            HStack {
                                Label("Rabia ile ara", systemImage: "sparkles")
                                Spacer()
                                if quranService.isSemanticSearching {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }

                        if let semantic = quranService.semanticResultText, !semantic.isEmpty {
                            Text(semantic)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 4)
                        }
                    }
                }

                Section(header: Text("Sureler").font(.subheadline).fontWeight(.semibold)) {
                    ForEach(filteredSurahs) { surah in
                        NavigationLink(value: QuranNavDestination(surahId: surah.id, scrollTo: nil)) {
                            SurahRowView(surah: surah)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Sure veya ayet meali ara...")
            .alert("Rabia Özelliği", isPresented: $showAIAccessAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Bu Rabia özelliği premium kullanıcılar içindir. Ücretsiz kullanımda reklam izlenir.")
            }
            .navigationTitle("Kur'an-ı Kerim")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                }
            }
            .navigationDestination(for: QuranNavDestination.self) { dest in
                SurahDetailView(
                    surahId: dest.surahId,
                    scrollToVerse: dest.scrollTo,
                    quranService: quranService,
                    storage: storage
                )
            }
            .sheet(isPresented: $showBookmarks) {
                QuranBookmarksView(quranService: quranService)
            }
            .sheet(isPresented: $showSettings) {
                QuranSettingsSheet(quranService: quranService)
            }
            .safeAreaInset(edge: .bottom) {
                ConditionalBannerAd(isPremium: isPremium)
            }
            .task {
                do {
                    let info = try await RevenueCatService.shared.customerInfo()
                    isPremium = RevenueCatService.shared.hasActiveEntitlement(info)
                    AdService.shared.updatePremiumStatus(isPremium)
                } catch {}
            }
        }
    }

    private func runSemanticSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !isPremium {
            showAIAccessAlert = true
            AdService.shared.showInterstitial()
        }

        Task {
            await quranService.semanticSearchInQuran(query: trimmed, gemini: geminiService)
        }
    }
}

nonisolated struct QuranNavDestination: Hashable {
    let surahId: Int
    let scrollTo: Int?
}

struct SurahRowView: View {
    let surah: QuranSurah

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.teal.opacity(0.15))
                Text("\(surah.id)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.teal)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(surah.turkishName)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text(surah.revelationTypeTurkish)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(surah.revelationType == "Meccan" ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                        .foregroundStyle(surah.revelationType == "Meccan" ? .orange : .blue)
                        .clipShape(.capsule)
                    Text("\(surah.totalVerses) ayet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(surah.arabicName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct QuranBookmarksView: View {
    let quranService: QuranService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(quranService.bookmarks.sorted(by: { $0.addedAt > $1.addedAt })) { bookmark in
                    HStack(spacing: 14) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(.teal)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(bookmark.surahName)
                                .font(.subheadline.bold())
                            Text("\(bookmark.verseNumber). Ayet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(surahArabicName(bookmark.surahId))
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    let sorted = quranService.bookmarks.sorted(by: { $0.addedAt > $1.addedAt })
                    for idx in indexSet {
                        let bm = sorted[idx]
                        if let verse = QuranVerse?.none {
                            _ = verse
                        }
                        let dummyVerse = QuranVerse(surahId: bm.surahId, verseNumber: bm.verseNumber, arabicText: "", turkishTranslation: "")
                        quranService.toggleBookmark(verse: dummyVerse, surahName: bm.surahName)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Yer İmlerim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                }
            }
            .overlay {
                if quranService.bookmarks.isEmpty {
                    ContentUnavailableView("Yer İmi Yok", systemImage: "bookmark.slash", description: Text("Ayet ekranında yer imi ekleyebilirsiniz"))
                }
            }
        }
    }

    private func surahArabicName(_ id: Int) -> String {
        QuranSurahData.surahs.first(where: { $0.id == id })?.arabicName ?? ""
    }
}

struct QuranSettingsSheet: View {
    let quranService: QuranService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Görüntüleme Modu") {
                    Picker("Mod", selection: Binding(
                        get: { quranService.displayMode },
                        set: { quranService.displayMode = $0; quranService.saveSettings() }
                    )) {
                        ForEach(QuranDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Arapça Yazı Boyutu") {
                    HStack {
                        Text("أ").font(.caption)
                        Slider(
                            value: Binding(
                                get: { Double(quranService.arabicFontSize) },
                                set: { quranService.arabicFontSize = CGFloat($0); quranService.saveSettings() }
                            ),
                            in: 18...40
                        )
                        Text("أ").font(.title)
                    }
                    Text("Önizleme")
                        .font(.system(size: quranService.arabicFontSize))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .foregroundStyle(.secondary)
                }

                Section("Türkçe Yazı Boyutu") {
                    HStack {
                        Text("A").font(.caption2)
                        Slider(
                            value: Binding(
                                get: { Double(quranService.turkishFontSize) },
                                set: { quranService.turkishFontSize = CGFloat($0); quranService.saveSettings() }
                            ),
                            in: 12...22
                        )
                        Text("A").font(.title3)
                    }
                    Text("Önizleme metni")
                        .font(.system(size: quranService.turkishFontSize))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Kur'an Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                }
            }
        }
    }
}
