import SwiftUI
import UIKit

private enum GuideSearchUIState {
    case idle
    case loading
    case success
    case error
}

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
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    let storage: StorageService
    let authService: AuthService
    let onStartCounter: () -> Void

    @State private var selectedCategory: RehberCategory = .gunlukRutinler
    @State private var selectedMood: MoodFilter? = nil
    @State private var searchText: String = ""
    @State private var selectedEntry: RehberEntry? = nil
    @State private var showAddCustom: Bool = false
    @State private var showPremiumSheet: Bool = false
    @State private var showKhutbah: Bool = false
    @State private var showDiyanetSources: Bool = false
    @State private var showHadithLibrary: Bool = false
    @StateObject private var diyanetStore = DiyanetKnowledgeStore()
    @StateObject private var hadithStore = HadithStore()
    @State private var geminiService = GroqService()
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var guideSearchState: GuideSearchUIState = .idle
    @State private var lastSubmittedGuideQuery: String = ""
    @State private var spiritualQuestion: String = ""
    @State private var spiritualAnswer: String? = nil
    @State private var isAskingSpiritualQuestion: Bool = false
    @State private var showDailyLimitAlert: Bool = false
    @State private var selectedHisnulGuideTabID: String? = nil
    @FocusState private var isSpiritualQuestionFocused: Bool
    @FocusState private var isGuideSearchFieldFocused: Bool

    private var isPremium: Bool { authService.isPremium }
    private var hisnulGuideSections: [GuideSectionViewModel] { GuideContentStore.guideSections() }

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
                schedule: L10n.string(.userAdded),
                guideTabID: RehberCategory.kullanici.rawValue
            )
        }
    }

    private var availableCategories: [RehberCategory] {
        let present = Set(allGuideEntries.map(\.category))
        let hasHisnulMuslimEntries = allGuideEntries.contains { $0.isHisnulMuslimEntry }

        return RehberCategory.allCases.filter { category in
            if category == .favoriler {
                return true
            }
            if category == .hisnulMuslim {
                return hasHisnulMuslimEntries
            }
            return present.contains(category)
        }
    }

    private var effectiveSelectedCategory: RehberCategory {
        availableCategories.contains(selectedCategory) ? selectedCategory : (availableCategories.first ?? .gunlukRutinler)
    }

    private var aiMatchedEntries: [RehberEntry] {
        let ids = Set(geminiService.aiSearchResults)
        return allGuideEntries.filter { ids.contains($0.id) }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    private var filteredEntries: [RehberEntry] {
        if let mood = selectedMood {
            let base = allGuideEntries.filter { !$0.isHisnulMuslimEntry && $0.moodTags.contains(mood.rawValue) }
            guard !searchText.isEmpty else { return base }
            return base.filter { entryMatchesSearch($0, query: searchText) }
        }

        let base: [RehberEntry]
        if effectiveSelectedCategory == .favoriler {
            base = allGuideEntries.filter { storage.isFavorite($0.id) }
        } else if effectiveSelectedCategory == .hisnulMuslim {
            base = allGuideEntries.filter {
                $0.isHisnulMuslimEntry && matchesSelectedHisnulGuideTab($0)
            }
        } else {
            base = allGuideEntries.filter { $0.category == effectiveSelectedCategory }
        }

        guard !searchText.isEmpty else { return base }
        return base.filter { entryMatchesSearch($0, query: searchText) }
    }

    private var filteredDiyanetRecords: [DiyanetKnowledgeRecord] {
        guard !trimmedSearchText.isEmpty else { return [] }
        return Array(diyanetStore.filteredRecords(searchText: trimmedSearchText, selectedType: nil).prefix(6))
    }

    private var filteredHadithRecords: [Hadith] {
        guard !trimmedSearchText.isEmpty else { return [] }
        return hadithStore.filteredHadiths(searchText: trimmedSearchText, limit: 4)
    }

    private var localizedAllLabel: String {
        switch AppLanguage(code: RabiaAppLanguage.currentCode()) {
        case .tr:
            return "Tümü"
        case .ar:
            return "الكل"
        default:
            return "All"
        }
    }

    private var hisnulGuideFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                hisnulGuideFilterChip(title: localizedAllLabel, isSelected: selectedHisnulGuideTabID == nil) {
                    withAnimation(.spring(duration: 0.28)) {
                        selectedHisnulGuideTabID = nil
                    }
                }

                ForEach(hisnulGuideSections) { section in
                    hisnulGuideFilterChip(title: section.title, isSelected: selectedHisnulGuideTabID == section.id) {
                        withAnimation(.spring(duration: 0.28)) {
                            selectedHisnulGuideTabID = section.id
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
    }

    var body: some View {
        let palette = themeManager.palette(using: systemColorScheme)

        NavigationStack {
            VStack(spacing: 0) {
                categoryScroll
                guideSearchBar
                Divider()
                entryList
            }
            .background(palette.pageBackground)
            .navigationTitle(L10n.string(.zikirVeDuaRehberim2))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.resolvedIsDarkMode(using: systemColorScheme) ? .dark : .light, for: .navigationBar)
            .onChange(of: searchText) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    resetGuideSearchState(clearSubmission: true)
                } else if trimmed != lastSubmittedGuideQuery {
                    resetGuideSearchState(clearSubmission: false)
                }
            }
            .navigationDestination(isPresented: $showKhutbah) {
                KhutbahView()
            }
            .navigationDestination(isPresented: $showDiyanetSources) {
                DiyanetKnowledgeHubView()
            }
            .navigationDestination(isPresented: $showHadithLibrary) {
                HadithLibraryView(store: hadithStore)
            }
            .navigationDestination(for: RehberEntry.self) { entry in
                ZikirRehberiDetailView(
                    entry: entry,
                    storage: storage,
                    onStartCounter: onStartCounter
                )
            }
            .sheet(isPresented: $showAddCustom) {
                GuideCustomEntrySheet(storage: storage)
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumView(authService: authService)
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
                await authService.refreshPremiumStatus()
                await diyanetStore.loadIfNeeded()
                await hadithStore.loadIfNeeded()
            }
        }
        .id(themeManager.navigationRefreshID)
    }

    private var guideSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(themeManager.current.textSecondary)

            TextField("", text: $searchText, prompt: Text(.guideSearchPlaceholder).foregroundStyle(themeManager.current.textSecondary))
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
                .focused($isGuideSearchFieldFocused)

            if guideSearchState == .loading {
                ProgressView()
                    .controlSize(.small)
                    .tint(themeManager.current.textSecondary)
            }

            if !trimmedSearchText.isEmpty {
                Button {
                    clearGuideSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(themeManager.current.elevatedBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(themeManager.current.border.opacity(0.65), lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableCategories, id: \.self) { cat in
                    CategoryChip(
                        category: cat,
                        isSelected: effectiveSelectedCategory == cat && selectedMood == nil,
                        isLocked: cat.requiresPremiumAccess && !isPremium
                    ) {
                        if cat.requiresPremiumAccess && !isPremium {
                            showPremiumSheet = true
                        } else {
                            withAnimation(.spring(duration: 0.28)) {
                                selectedCategory = cat
                                selectedMood = nil
                                if cat != .hisnulMuslim {
                                    selectedHisnulGuideTabID = nil
                                }
                            }
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
                    officialSourcesSection
                    moodSection
                    if effectiveSelectedCategory == .hisnulMuslim {
                        hisnulGuideFilterSection
                    }
                    ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { _, entry in
                        guideEntryRow(entry)
                    }
                } else if !searchText.isEmpty {
                    maneviAssistantCard

                    if effectiveSelectedCategory == .hisnulMuslim {
                        hisnulGuideFilterSection
                    }

                    if !filteredEntries.isEmpty {
                        HStack {
                            Text(.aramaSonuclari)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .tracking(0.6)
                            Spacer()
                            Text(L10n.format(.searchResultsCountFormat, filteredEntries.count))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 4)

                        ForEach(filteredEntries) { entry in
                            guideEntryRow(entry)
                        }
                    }

                    if !filteredDiyanetRecords.isEmpty {
                        diyanetSearchResultsSection
                    }

                    if !filteredHadithRecords.isEmpty {
                        hadithSearchResultsSection
                    }
                } else if let mood = selectedMood {
                    activeMoodBanner(mood: mood)

                    if filteredEntries.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "moon.stars")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text(.buRuhHaliIcinDuaBulunamadi)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                    } else {
                        ForEach(filteredEntries) { entry in
                            guideEntryRow(entry)
                        }
                    }
                } else {
                    ForEach(filteredEntries) { entry in
                        guideEntryRow(entry)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    private func deleteCustomEntry(_ entry: RehberEntry) {
        guard entry.category == .kullanici else { return }
        guard storage.customZikirs.contains(where: { $0.id == entry.id }) else { return }
        storage.deleteCustomZikir(id: entry.id)
    }

    private func guideEntryRow(_ entry: RehberEntry) -> some View {
        RehberEntryRow(
            entry: entry,
            storage: storage,
            isPremiumUnlocked: isPremium,
            onDeleteCustom: deleteCustomEntry,
            onRequirePremium: { showPremiumSheet = true }
        )
    }

    private var maneviAssistantCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            maneviAssistantHeader
            maneviAssistantStateContent
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.teal.opacity(0.25), lineWidth: 1)
        )
    }

    private var maneviAssistantHeader: some View {
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
                Text(.islamiAsistan)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                if guideSearchState == .loading {
                    Text(.guideSearchLoading)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if guideSearchState == .loading {
                ProgressView()
                    .scaleEffect(0.75)
                    .tint(.teal)
            }
        }
    }

    @ViewBuilder
    private var maneviAssistantStateContent: some View {
        if guideSearchState == .loading {
            maneviAssistantLoadingContent
        } else if guideSearchState == .success, let advice = geminiService.assistantAdvice {
            maneviAssistantSuccessContent(advice: advice)
        } else if guideSearchState == .error {
            maneviAssistantErrorContent
        } else if guideSearchState == .idle {
            maneviAssistantIdleContent
        }
    }

    private var maneviAssistantLoadingContent: some View {
        VStack(spacing: 8) {
            Text(.guideSearchLoading)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(0..<3, id: \.self) { _ in
                ShimmerPlaceholder()
            }
        }
    }

    private func maneviAssistantSuccessContent(advice: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    Text(.onerilenDualalar)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(0.6)

                    ForEach(aiMatchedEntries) { entry in
                        guideEntryRow(entry)
                    }
                }
            }

            Text(.buIcerikRabiaTarafindanHazirlanmistir)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var maneviAssistantErrorContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.caption)
                .foregroundStyle(.orange)
            Text(.guideSearchError)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var maneviAssistantIdleContent: some View {
        Text(.guideSearchHelperText)
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private func performSearch() {
        let trimmed = trimmedSearchText
        guard !trimmed.isEmpty else { return }
        guard !(guideSearchState == .loading && trimmed == lastSubmittedGuideQuery) else { return }

        isGuideSearchFieldFocused = false
        searchTask?.cancel()
        geminiService.aiSearchResults = []
        geminiService.assistantAdvice = nil
        geminiService.searchError = nil
        guideSearchState = .loading
        lastSubmittedGuideQuery = trimmed

        searchTask = Task {
            print("[ZikirRehberi] 🔍 AI arama başlıyor: \(trimmed)")
            await geminiService.maneviAssistantSearch(query: trimmed, entries: allGuideEntries)
            if Task.isCancelled { return }
            await MainActor.run {
                if geminiService.searchError != nil {
                    guideSearchState = .error
                } else {
                    guideSearchState = .success
                }
            }
        }
    }

    private func resetGuideSearchState(clearSubmission: Bool) {
        searchTask?.cancel()
        searchTask = nil
        geminiService.aiSearchResults = []
        geminiService.assistantAdvice = nil
        geminiService.searchError = nil
        guideSearchState = .idle

        if clearSubmission {
            lastSubmittedGuideQuery = ""
        }
    }

    private func clearGuideSearch() {
        isGuideSearchFieldFocused = false
        searchText = ""
        resetGuideSearchState(clearSubmission: true)
    }

    private func matchesSelectedHisnulGuideTab(_ entry: RehberEntry) -> Bool {
        guard let selectedHisnulGuideTabID else { return true }
        return entry.guideTabID == selectedHisnulGuideTabID
    }

    private func hisnulGuideFilterChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? RehberCategory.hisnulMuslim.color : Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(RehberCategory.hisnulMuslim.color.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func entryMatchesSearch(_ entry: RehberEntry, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        return entry.localizedTitle.localizedStandardContains(trimmed)
            || entry.localizedTransliteration.localizedStandardContains(trimmed)
            || entry.localizedPurpose.localizedStandardContains(trimmed)
            || entry.arabicText.contains(trimmed)
            || (entry.localizedSchedule?.localizedStandardContains(trimmed) ?? false)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "heart.text.square.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(.halinizeGoreDua)
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

    private var officialSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "building.columns.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("Resmi Kaynaklar")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
            }

            Button {
                showDiyanetSources = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.78), Color.teal.opacity(0.64)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: "building.columns.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diyanet Kaynakları")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("Soru-cevap, karar ve mütalaa içeriklerini resmi kaynak atfıyla ayrı bir bilgi alanında sun.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.blue.opacity(0.18), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                showHadithLibrary = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.76), Color.teal.opacity(0.62)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: "quote.opening")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hadisler")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("Seçilmiş hadisleri uygulama dilinde, sade ve kolay takip edilir biçimde oku.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.green.opacity(0.16), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            khutbahBanner
        }
        .padding(.bottom, 4)
    }

    private var diyanetSearchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Label("Diyanet Resmi Kaynaklar", systemImage: "building.columns.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink {
                    DiyanetKnowledgeListView(store: diyanetStore, initialSearchText: trimmedSearchText)
                } label: {
                    Text("Tüm resmi sonuçlar")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
                .buttonStyle(.plain)
            }

            ForEach(filteredDiyanetRecords) { record in
                NavigationLink {
                    DiyanetKnowledgeDetailView(record: record)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.teal.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "building.columns.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.teal)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)

                                Text(record.previewText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }

                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Text(record.type.displayName)
                                .font(.caption.bold())
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.teal.opacity(0.1))
                                .clipShape(Capsule())

                            if let topCategory = record.categoryPath.first {
                                Text(topCategory)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("Diyanet")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.teal.opacity(0.16), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var hadithSearchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Label("Hadisler", systemImage: "quote.opening")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink {
                    HadithLibraryView(store: hadithStore, initialSearchText: trimmedSearchText)
                } label: {
                    Text("Tüm hadisler")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
                .buttonStyle(.plain)
            }

            ForEach(filteredHadithRecords) { hadith in
                NavigationLink {
                    HadithDetailRouteView(hadith: hadith, store: hadithStore)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.teal.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "quote.opening")
                                    .font(.caption.bold())
                                    .foregroundStyle(.teal)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(hadith.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)

                                if let summaryText = hadithSearchSummaryText(for: hadith) {
                                    Text(summaryText)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                            }

                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Text("Hadis")
                                .font(.caption.bold())
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.teal.opacity(0.1))
                                .clipShape(Capsule())

                            Text(AppLanguage(code: hadith.language).displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.teal.opacity(0.16), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func hadithSearchSummaryText(for hadith: Hadith) -> String? {
        if let shortCardText = hadith.shortCardText?.trimmingCharacters(in: .whitespacesAndNewlines), !shortCardText.isEmpty {
            return shortCardText
        }

        let bodyText = hadith.hadeeth.trimmingCharacters(in: .whitespacesAndNewlines)
        if !bodyText.isEmpty, bodyText.count <= 140 {
            return bodyText
        }

        let attribution = hadith.attribution?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !attribution.isEmpty {
            return attribution
        }

        let title = hadith.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }

    private var maneviyataSorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.sparkles.fill")
                    .font(.subheadline)
                    .foregroundStyle(.teal)
                Text(.islamiRehbereSor)
                    .font(.headline)
                Spacer()
                AIBadge()
            }

            TextField(.diniSorunuYaz, text: $spiritualQuestion, axis: .vertical)
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
                        Text(.rabiaDusunuyor)
                            .font(.subheadline.bold())
                    } else {
                        Text(.soruyuGonder)
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
                Text(.ucretsizKullanicilarIcinGunde1SoruHakkiVardir)
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
        .alert(L10n.string(.gunlukSoruHakkiDoldu), isPresented: $showDailyLimitAlert) {
            Button(.tamam2, role: .cancel) {}
        } message: {
            Text(.premiumIleSinirsizIslamiRehbereSorKullanabilirsiniz)
        }
    }

    private func askSpiritualQuestion() {
        let trimmed = spiritualQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSpiritualQuestionFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        Task {
            if !isPremium {
                await authService.refreshPremiumStatus(force: true)
            }

            let hasPremium = authService.isPremium
            if !hasPremium && !geminiService.canAskDailySpiritualQuestion() {
                showDailyLimitAlert = true
                return
            }

            isAskingSpiritualQuestion = true
            let result = try? await geminiService.answerSpiritualQuestion(trimmed)
            spiritualAnswer = result ?? L10n.string(.responseUnavailableTryAgain)
            if !hasPremium {
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
                    Text(L10n.format(.dhikrFoundCount, filteredEntries.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text(.temizle2)
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
                        Text(.haftaninHutbesi)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.teal)
                    }
                    Text(.cumaHutbesiniOkuDinleVeAiOzetiGor)
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
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption.bold())
                Text(category.displayName)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                if isLocked {
                    Image(systemName: "crown.fill")
                        .font(.caption2.bold())
                }
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

struct RehberEntryRow: View {
    let entry: RehberEntry
    let storage: StorageService
    let isPremiumUnlocked: Bool
    let onDeleteCustom: (RehberEntry) -> Void
    let onRequirePremium: () -> Void

    private var isDeletable: Bool {
        entry.category == .kullanici && storage.customZikirs.contains(where: { $0.id == entry.id })
    }

    private var isLocked: Bool {
        entry.category.requiresPremiumAccess && !isPremiumUnlocked
    }

    var body: some View {
        let card = RehberEntryCard(entry: entry, storage: storage, isLocked: isLocked)

        if isLocked {
            Button(action: onRequirePremium) {
                card
            }
            .buttonStyle(.plain)
        } else {
            let link = NavigationLink(value: entry) {
                card
            }
            .buttonStyle(.plain)

            if isDeletable {
                link
                    .contextMenu {
                        deleteAction
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        deleteAction
                    }
            } else {
                link
            }
        }
    }

    @ViewBuilder
    private var deleteAction: some View {
        Button(role: .destructive) {
            onDeleteCustom(entry)
        } label: {
            Label(L10n.string(.sil2), systemImage: "trash")
        }
    }
}

struct RehberEntryCard: View {
    let entry: RehberEntry
    let storage: StorageService
    let isLocked: Bool
    let catColor: Color

    init(entry: RehberEntry, storage: StorageService, isLocked: Bool = false) {
        self.entry = entry
        self.storage = storage
        self.isLocked = isLocked
        self.catColor = entry.displayCategory.color
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
                            Text(entry.localizedTitle)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if isLocked {
                                Image(systemName: "crown.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(catColor)
                            }
                        }
                        Text(entry.localizedTransliteration)
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

                Text(entry.localizedPurpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if entry.localizedSourceLabel != nil || entry.verificationStatus != nil {
                    HStack(spacing: 8) {
                        if let source = entry.localizedSourceLabel {
                            GuideMetadataBadge(
                                text: source,
                                systemImage: "book.closed.fill",
                                tint: .secondary
                            )
                        }

                        if let status = entry.verificationStatus {
                            VerificationBadge(status: status)
                        }
                    }
                }

                HStack(spacing: 8) {
                    if !entry.isInformational {
                        CountBadge(count: entry.recommendedCount, note: entry.localizedRecommendedCountNote, color: catColor)
                    }
                    if let schedule = entry.localizedSchedule {
                        Label(schedule, systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if isLocked {
                        Text(.premiumRequiredTitle)
                            .font(.caption2.bold())
                            .foregroundStyle(catColor)
                    } else {
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
            Image(systemName: "number.circle.fill")
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
        return "\(count)"
    }
}

struct GuideMetadataBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.1))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}

struct VerificationBadge: View {
    let status: GuideVerificationStatus

    var body: some View {
        Text(status.badgeText)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .verified:
            return .green
        case .needsReview:
            return .orange
        case .unknown:
            return .secondary
        }
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
    @State private var contextTag: String = L10n.string(.gunIcinde)
    @State private var category: String = L10n.string(.dhikrCustomCategoryDefault)

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string(.yeniZikirOrDua)) {
                    TextField(.baslik, text: $title)
                    TextField(.arapcaMetinOpsiyonel2, text: $arabicText, axis: .vertical)
                        .lineLimit(2...5)
                    TextField(.okunus2, text: $transliteration)
                    TextField(.anlam2, text: $meaning, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(.kisaAciklama, text: $purpose, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section(L10n.string(.sayiEtiket)) {
                    TextField(.onerilenTekrar, text: $countText)
                        .keyboardType(.numberPad)
                    TextField(.zamanOrBaglamEtiketi, text: $contextTag)
                    TextField(.kategori, text: $category)
                }
            }
            .navigationTitle(L10n.string(.rehbereEkle2))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.iptal) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.kaydet2) {
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
        let trimmedArabicText = arabicText.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = ZikirItem(
            id: "guide_custom_\(UUID().uuidString)",
            category: category.isEmpty ? L10n.string(.dhikrCustomCategoryDefault) : category,
            arabicText: trimmedArabicText,
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
    @State private var arabicFontSize: CGFloat
    @State private var showCounterAdded: Bool = false

    private let catColor: Color
    private var hasArabicText: Bool {
        !entry.arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var hasSupplementaryInfo: Bool {
        entry.localizedRecommendedCountNote != nil || entry.localizedSchedule != nil || !entry.isInformational
    }
    private var isCevsenInformational: Bool {
        entry.category == .cevsen && entry.isInformational
    }
    private var sectionInfoTitle: String {
        if isCevsenInformational {
            switch AppLanguage(code: RabiaAppLanguage.currentCode()) {
            case .tr:
                return "Bölüm Bilgisi"
            case .ar:
                return "معلومات القسم"
            default:
                return "Section Info"
            }
        }

        switch AppLanguage(code: RabiaAppLanguage.currentCode()) {
        case .tr:
            return "Okunuş"
        case .ar:
            return "القراءة"
        default:
            return "Reading"
        }
    }

    private var sourceSectionTitle: String {
        switch AppLanguage(code: RabiaAppLanguage.currentCode()) {
        case .tr:
            return "Kaynak ve Doğrulama"
        case .ar:
            return "المصدر والتحقق"
        default:
            return "Source and Verification"
        }
    }

    init(entry: RehberEntry, storage: StorageService, onStartCounter: @escaping () -> Void) {
        self.entry = entry
        self.storage = storage
        self.onStartCounter = onStartCounter
        self.catColor = entry.displayCategory.color
        if entry.category == .cevsen {
            _arabicFontSize = State(initialValue: 20)
        } else {
            _arabicFontSize = State(initialValue: 22)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerBanner
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 20) {
                    if hasArabicText {
                        arabicSection
                    }
                    if !entry.localizedTransliteration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        transliterationSection
                    }
                    meaningSection
                    if !isCevsenInformational {
                        purposeSection
                    }
                    if entry.localizedSourceLabel != nil || entry.verificationStatus != nil {
                        sourceTransparencySection
                    }
                    if let notes = entry.localizedNotes {
                        notesSection(notes)
                    }
                    if hasSupplementaryInfo {
                        countSection
                    }
                }
                .padding(.horizontal, 20)

                if entry.supportsCounter {
                    startButton
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(entry.localizedTitle)
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
                    Image(systemName: entry.displayCategory.icon)
                        .font(.title2)
                        .foregroundStyle(catColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayCategory.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(catColor)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    if let schedule = entry.localizedSchedule {
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
                Text(.arapca)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        arabicFontSize = max(16, arabicFontSize - 2)
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        arabicFontSize = min(30, arabicFontSize + 2)
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(entry.arabicText)
                .font(QuranFontResolver.arabicFont(for: .classicMushaf, size: arabicFontSize, relativeTo: .title2))
                .environment(\.layoutDirection, .rightToLeft)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(14)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var transliterationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(sectionInfoTitle, systemImage: "text.quote")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(entry.localizedTransliteration)
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
            Label(.anlam2, systemImage: "character.book.closed.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(entry.localizedMeaning)
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
            Label(.fazilet2, systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(catColor)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(entry.localizedPurpose)
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

    private var sourceTransparencySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(sourceSectionTitle, systemImage: "checkmark.shield")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            if let source = entry.localizedSourceLabel {
                Text(source)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            if let status = entry.verificationStatus {
                VerificationBadge(status: status)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(.notlar2, systemImage: "note.text")
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
                Text(.onerilenSayi)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(catColor.opacity(0.1))
            .clipShape(.rect(cornerRadius: 16))

            if let note = entry.localizedRecommendedCountNote {
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

            if let schedule = entry.localizedSchedule {
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
                Text(.tesbiheEkle2)
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
            Text(.tesbihOlusturuldu)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func addCounterAndStart() {
        guard entry.supportsCounter else { return }

        let counter = CounterModel(
            name: entry.localizedTitle,
            targetCount: entry.recommendedCount,
            zikirItemId: entry.id
        )
        storage.addCounter(counter)
        storage.setActiveZikrSession(
            ZikrSession(
                zikrTitle: entry.localizedTitle,
                arabicText: entry.arabicText,
                transliteration: entry.localizedTransliteration,
                meaning: entry.localizedMeaning,
                recommendedCount: entry.recommendedCount,
                category: entry.displayCategory.displayName,
                sourceID: entry.id
            )
        )
        storage.pendingSelectedCounterId = counter.id
        showCounterAdded = true
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                dismiss()
                onStartCounter()
                showCounterAdded = false
            }
        }
    }
}
