import SwiftUI
import UIKit

extension RehberCategory {
    var color: Color {
        switch self {
        case .favoriler: return .yellow
        case .gunlukRutinler: return .teal
        case .duygusalDurumlar: return .indigo
        case .hayatDurumlari: return .orange
        case .kisaTesbihatlar: return .green
        case .kuranDualari: return .blue
        case .rabbena: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case .esmaülHüsna: return Color(red: 0.8, green: 0.6, blue: 0.1)
        case .hisnulMuslim: return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .cevsen: return Color(red: 0.7, green: 0.2, blue: 0.5)
        case .kullanici: return .purple
        }
    }
}

extension MoodFilter {
    var color: Color {
        switch self {
        case .huzursuz: return .indigo
        case .sukur: return .orange
        case .dardaKaldim: return .red
        case .hastaOldum: return .mint
        case .sinavBasarisi: return .blue
        }
    }
}

struct ZikirRehberiView: View {
    let storage: StorageService
    let onStartCounter: () -> Void

    @State private var selectedCategory: RehberCategory = .gunlukRutinler
    @State private var selectedMood: MoodFilter? = nil
    @State private var searchText: String = ""
    @State private var selectedEntry: RehberEntry? = nil
    @State private var showAddCustom: Bool = false
    @State private var isPremium: Bool = false
    @State private var showKhutbah: Bool = false
    @State private var geminiService = GroqService()
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var spiritualQuestion: String = ""
    @State private var spiritualAnswer: String? = nil
    @State private var isAskingSpiritualQuestion: Bool = false
    @State private var showDailyLimitAlert: Bool = false
    @FocusState private var isSpiritualQuestionFocused: Bool

    private var allGuideEntries: [RehberEntry] {
        ZikirRehberiData.entries + storage.customZikirs.map { item in
            RehberEntry(
                id: item.id,
                title: item.turkishPronunciation,
                arabicText: item.arabicText,
                transliteration: item.turkishPronunciation,
                meaning: item.turkishMeaning,
                purpose: item.source,
                recommendedCount: item.recommendedCount,
                category: .kullanici,
                notes: item.category,
                schedule: "Kullanıcı ekledi"
            )
        }
    }

    private var aiMatchedEntries: [RehberEntry] {
        let ids = Set(geminiService.aiSearchResults)
        return allGuideEntries.filter { ids.contains($0.id) }
    }

    private var filteredEntries: [RehberEntry] {
        if let mood = selectedMood {
            let base = allGuideEntries.filter { $0.moodTags.contains(mood.rawValue) }
            guard !searchText.isEmpty else { return base }
            let q = searchText.lowercased()
            return base.filter { $0.title.lowercased().contains(q) || $0.transliteration.lowercased().contains(q) || $0.purpose.lowercased().contains(q) }
        }

        let base: [RehberEntry]
        if selectedCategory == .favoriler {
            base = allGuideEntries.filter { storage.isFavorite($0.id) }
        } else {
            base = allGuideEntries.filter { $0.category == selectedCategory }
        }

        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q)
            || $0.transliteration.lowercased().contains(q)
            || $0.purpose.lowercased().contains(q)
            || ($0.schedule?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryScroll
                Divider()
                entryList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Zikir ve Dua Rehberim")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Zikir, dua veya duygu yaz…")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                geminiService.aiSearchResults = []
                geminiService.assistantAdvice = nil
                geminiService.searchError = nil
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2 else { return }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(800))
                    guard !Task.isCancelled else { return }
                    print("[ZikirRehberi] 🔍 AI arama başlıyor: \(trimmed)")
                    await geminiService.maneviAssistantSearch(query: trimmed, entries: allGuideEntries)
                }
            }
            .navigationDestination(isPresented: $showKhutbah) {
                KhutbahView()
            }
            .navigationDestination(for: RehberEntry.self) { entry in
                ZikirRehberiDetailView(
                    entry: entry,
                    storage: storage,
                    onStartCounter: onStartCounter
                )
            }
            .safeAreaInset(edge: .bottom) {
                ConditionalBannerAd(isPremium: isPremium)
            }
            .sheet(isPresented: $showAddCustom) {
                GuideCustomEntrySheet(storage: storage)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCustom = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
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

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RehberCategory.allCases, id: \.self) { cat in
                    CategoryChip(
                        category: cat,
                        isSelected: selectedCategory == cat && selectedMood == nil
                    ) {
                        withAnimation(.spring(duration: 0.28)) {
                            selectedCategory = cat
                            selectedMood = nil
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if searchText.isEmpty && selectedMood == nil {
                    moodSection
                    ForEach(filteredEntries) { entry in
                        NavigationLink(value: entry) {
                            RehberEntryCard(entry: entry, storage: storage)
                        }
                        .buttonStyle(.plain)
                    }
                } else if !searchText.isEmpty {
                    maneviAssistantCard

                    if !filteredEntries.isEmpty {
                        HStack {
                            Text("ARAMA SONUÇLARI")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .tracking(0.6)
                            Spacer()
                            Text("\(filteredEntries.count) sonuç")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 4)

                        ForEach(filteredEntries) { entry in
                            NavigationLink(value: entry) {
                                RehberEntryCard(entry: entry, storage: storage)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if let mood = selectedMood {
                    activeMoodBanner(mood: mood)

                    if filteredEntries.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "moon.stars")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("Bu ruh hali için dua bulunamadı")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                    } else {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(value: entry) {
                                RehberEntryCard(entry: entry, storage: storage)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(value: entry) {
                            RehberEntryCard(entry: entry, storage: storage)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    private var maneviAssistantCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.8), Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Manevi Asistan")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("\"\(searchText)\" için analiz ediliyor")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if geminiService.isSearching {
                    ProgressView()
                        .scaleEffect(0.75)
                        .tint(.teal)
                }
            }

            if geminiService.isSearching {
                VStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerPlaceholder()
                    }
                }
            } else if let advice = geminiService.assistantAdvice {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.caption)
                        .foregroundStyle(.teal)
                        .padding(.top, 2)
                    Text(advice)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
                .padding(12)
                .background(Color.teal.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.teal.opacity(0.2), lineWidth: 1)
                )

                if !aiMatchedEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ÖNERİLEN DUALALAR")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        ForEach(aiMatchedEntries) { entry in
                            NavigationLink(value: entry) {
                                RehberEntryCard(entry: entry, storage: storage)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Bu içerik Rabia tarafından hazırlanmıştır.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else if let error = geminiService.searchError {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
                Text("Arama yapmak için en az 3 karakter girin…")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.teal.opacity(0.25), lineWidth: 1)
        )
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "heart.text.square.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("HALİNİZE GÖRE DUA")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(MoodFilter.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.spring(duration: 0.28)) {
                            selectedMood = mood
                        }
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(mood.color.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: mood.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(mood.color)
                            }
                            Text(mood.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(mood.color.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 4)
    }

    private var maneviyataSorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.sparkles.fill")
                    .font(.subheadline)
                    .foregroundStyle(.teal)
                Text("Maneviyata Sor")
                    .font(.headline)
                Spacer()
                AIBadge()
            }

            TextField("Dini sorunu yaz...", text: $spiritualQuestion, axis: .vertical)
                .focused($isSpiritualQuestionFocused)
                .submitLabel(.done)
                .onSubmit {
                    askSpiritualQuestion()
                }
                .lineLimit(2...4)
                .padding(12)
                .background(Color(.tertiarySystemFill))
                .clipShape(.rect(cornerRadius: 12))

            Button {
                askSpiritualQuestion()
            } label: {
                HStack(spacing: 8) {
                    if isAskingSpiritualQuestion {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Rabia düşünüyor…")
                            .font(.subheadline.bold())
                    } else {
                        Text("Soruyu Gönder")
                            .font(.subheadline.bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.teal.opacity(0.16))
                .foregroundStyle(.teal)
                .clipShape(.rect(cornerRadius: 12))
            }
            .disabled(isAskingSpiritualQuestion || spiritualQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if isAskingSpiritualQuestion {
                ShimmerPlaceholder()
            } else if let spiritualAnswer {
                Text(spiritualAnswer)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(Color.teal.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 12))
            }

            if !isPremium {
                Text("Ücretsiz kullanıcılar için günde 1 soru hakkı vardır.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.teal.opacity(0.22), lineWidth: 1)
        )
        .alert("Günlük soru hakkı doldu", isPresented: $showDailyLimitAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Premium ile sınırsız Maneviyata Sor kullanabilirsiniz.")
        }
    }

    private func askSpiritualQuestion() {
        let trimmed = spiritualQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSpiritualQuestionFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        Task {
            if !isPremium {
                if let info = try? await RevenueCatService.shared.customerInfo(), RevenueCatService.shared.hasActiveEntitlement(info) {
                    isPremium = true
                }
            }

            if !isPremium && !geminiService.canAskDailySpiritualQuestion() {
                showDailyLimitAlert = true
                return
            }

            isAskingSpiritualQuestion = true
            let result = try? await geminiService.answerSpiritualQuestion(trimmed)
            spiritualAnswer = result ?? "Şu an yanıt üretilemedi. Lütfen tekrar deneyin."
            if !isPremium {
                geminiService.markDailySpiritualQuestionAsked()
            }
            isAskingSpiritualQuestion = false
        }
    }

    private func activeMoodBanner(mood: MoodFilter) -> some View {
        Button {
            withAnimation(.spring(duration: 0.28)) {
                selectedMood = nil
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(mood.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: mood.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(mood.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(mood.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("\(filteredEntries.count) dua/zikir bulundu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("Temizle")
                        .font(.caption.bold())
                        .foregroundStyle(mood.color)
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(mood.color)
                }
            }
            .padding(14)
            .background(mood.color.opacity(0.08))
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(mood.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var khutbahBanner: some View {
        Button {
            showKhutbah = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.75), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "text.book.closed.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Haftanın Hutbesi")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.teal)
                    }
                    Text("Cuma hutbesini oku, dinle ve AI özeti gör")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.teal.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }


}

struct CategoryChip: View {
    let category: RehberCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption.bold())
                Text(category.displayName)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? category.color.opacity(0.18)
                    : Color(.tertiarySystemFill)
            )
            .foregroundStyle(isSelected ? category.color : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? category.color.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
    }
}

struct RehberEntryCard: View {
    let entry: RehberEntry
    let storage: StorageService
    let catColor: Color

    init(entry: RehberEntry, storage: StorageService) {
        self.entry = entry
        self.storage = storage
        self.catColor = entry.category.color
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(catColor)
                .frame(width: 4)
                .clipShape(.rect(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if entry.isInformational {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(catColor)
                            }
                            Text(entry.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        Text(entry.transliteration)
                            .font(.subheadline)
                            .foregroundStyle(catColor)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        storage.toggleFavorite(entry.id)
                    } label: {
                        Image(systemName: storage.isFavorite(entry.id) ? "moon.stars.fill" : "moon.stars")
                            .font(.subheadline)
                            .foregroundStyle(storage.isFavorite(entry.id) ? Color.yellow : Color(.tertiaryLabel))
                    }
                }

                Text(entry.purpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    CountBadge(count: entry.recommendedCount, note: entry.recommendedCountNote, color: catColor)
                    if let schedule = entry.schedule {
                        Label(schedule, systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if !entry.isInformational {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(14)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

struct CountBadge: View {
    let count: Int
    let note: String?
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
                .font(.caption2.bold())
            Text(countLabel)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var countLabel: String {
        if let note, !note.isEmpty {
            return "\(count)+"
        }
        return "\(count)x"
    }
}

struct GuideCustomEntrySheet: View {
    let storage: StorageService

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var arabicText: String = ""
    @State private var transliteration: String = ""
    @State private var meaning: String = ""
    @State private var purpose: String = ""
    @State private var countText: String = "33"
    @State private var contextTag: String = "Gün içinde"
    @State private var category: String = "Kişisel"

    var body: some View {
        NavigationStack {
            Form {
                Section("Yeni zikir/dua") {
                    TextField("Başlık", text: $title)
                    TextField("Arapça", text: $arabicText, axis: .vertical)
                        .lineLimit(2...5)
                    TextField("Okunuş", text: $transliteration)
                    TextField("Anlam", text: $meaning, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Kısa açıklama", text: $purpose, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Sayı & Etiket") {
                    TextField("Önerilen tekrar", text: $countText)
                        .keyboardType(.numberPad)
                    TextField("Zaman/bağlam etiketi", text: $contextTag)
                    TextField("Kategori", text: $category)
                }
            }
            .navigationTitle("Rehbere Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveEntry()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveEntry() {
        let count = max(Int(countText) ?? 33, 1)
        let item = ZikirItem(
            id: "guide_custom_\(UUID().uuidString)",
            category: category.isEmpty ? "Kişisel" : category,
            arabicText: arabicText,
            turkishPronunciation: title,
            turkishMeaning: meaning.isEmpty ? purpose : meaning,
            recommendedCount: count,
            source: contextTag
        )
        storage.addCustomZikir(item)
    }
}

struct ZikirRehberiDetailView: View {
    let entry: RehberEntry
    let storage: StorageService
    let onStartCounter: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var arabicFontSize: CGFloat = 28
    @State private var showCounterAdded: Bool = false

    private let catColor: Color

    init(entry: RehberEntry, storage: StorageService, onStartCounter: @escaping () -> Void) {
        self.entry = entry
        self.storage = storage
        self.onStartCounter = onStartCounter
        self.catColor = entry.category.color
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerBanner
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 20) {
                    arabicSection
                    transliterationSection
                    meaningSection
                    purposeSection
                    if let notes = entry.notes {
                        notesSection(notes)
                    }
                    countSection
                }
                .padding(.horizontal, 20)

                if !entry.isInformational {
                    startButton
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    storage.toggleFavorite(entry.id)
                } label: {
                    Image(systemName: storage.isFavorite(entry.id) ? "moon.stars.fill" : "moon.stars")
                        .foregroundStyle(storage.isFavorite(entry.id) ? .yellow : .secondary)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showCounterAdded {
                addedToast
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: showCounterAdded)
    }

    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            catColor.opacity(0.12)
                .frame(maxWidth: .infinity)
                .frame(height: 120)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(catColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: entry.category.icon)
                        .font(.title2)
                        .foregroundStyle(catColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.category.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(catColor)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    if let schedule = entry.schedule {
                        Label(schedule, systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private var arabicSection: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack {
                Text("Arapça")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        arabicFontSize = max(20, arabicFontSize - 4)
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        arabicFontSize = min(44, arabicFontSize + 4)
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(entry.arabicText)
                .font(.system(size: arabicFontSize, weight: .medium))
                .environment(\.layoutDirection, .rightToLeft)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(10)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var transliterationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Okunuş", systemImage: "text.quote")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(entry.transliteration)
                .font(.body)
                .foregroundStyle(catColor)
                .italic()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Anlam", systemImage: "character.book.closed.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(entry.meaning)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var purposeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Fazilet", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(catColor)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(entry.purpose)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(catColor.opacity(0.08))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(catColor.opacity(0.25), lineWidth: 1)
        )
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notlar", systemImage: "note.text")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var countSection: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(countDisplay)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(catColor)
                Text("Önerilen Sayı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(catColor.opacity(0.1))
            .clipShape(.rect(cornerRadius: 16))

            if let note = entry.recommendedCountNote {
                VStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundStyle(catColor)
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            }

            if let schedule = entry.schedule {
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(catColor)
                    Text(schedule)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    private var countDisplay: String {
        let n = entry.recommendedCount
        if n >= 1000 {
            return "\(n / 1000).\(String(format: "%03d", n % 1000))"
        }
        return "\(n)"
    }

    private var startButton: some View {
        Button {
            addCounterAndStart()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "circle.circle.fill")
                    .font(.title3)
                Text("Zikir Sayacına Gönder")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(catColor)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 16))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showCounterAdded)
    }

    private var addedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Sayaç oluşturuldu")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func addCounterAndStart() {
        let counter = CounterModel(
            name: entry.title,
            targetCount: entry.recommendedCount,
            zikirItemId: entry.id
        )
        storage.addCounter(counter)
        storage.setActiveZikrSession(
            ZikrSession(
                zikrTitle: entry.title,
                arabicText: entry.arabicText,
                transliteration: entry.transliteration,
                meaning: entry.meaning,
                recommendedCount: entry.recommendedCount,
                category: entry.category.displayName,
                sourceID: entry.id
            )
        )
        storage.pendingSelectedCounterId = counter.id
        showCounterAdded = true
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            await MainActor.run {
                onStartCounter()
                showCounterAdded = false
            }
        }
    }
}
