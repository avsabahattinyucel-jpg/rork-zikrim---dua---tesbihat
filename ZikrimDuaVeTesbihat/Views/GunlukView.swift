import SwiftUI
import UIKit
import Combine
import CoreLocation

struct GunlukView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    let storage: StorageService
    let authService: AuthService
    let onNavigateToTab: (AppTab) -> Void

    @State private var prayerViewModel = PrayerTimesViewModel.shared
    @StateObject private var diyanetStore = DiyanetKnowledgeStore()
    @StateObject private var hadithStore = HadithStore()
    @State private var showProfile: Bool = false
    @State private var showDailySharePreview: Bool = false
    @State private var showDailyHadithDetail: Bool = false
    @State private var now: Date = Date()
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var saveMessage: String? = nil
    @State private var isSavingEntry: Bool = false
    @State private var saveTrigger: Bool = false
    @State private var showNotesSheet: Bool = false
    @State private var editingEntry: DailyJournalEntry? = nil
    @State private var selectedHabitDate: Date? = nil
    @State private var showHabitDetail: Bool = false
    @State private var showAllHistory: Bool = false
    @State private var selectedReligiousDay: ReligiousDay? = nil
    @State private var khutbahService = KhutbahService()
    @State private var geminiService = GroqService()
    @State private var isGeneratingCard: Bool = false
    @State private var spiritualQuestionPremiumAlert: Bool = false
    @State private var spiritualQuestion: String = ""
    @State private var spiritualAnswer: String = ""
    @State private var showSpiritualPopup: Bool = false
    @State private var isAskingSpiritualQuestion: Bool = false
    @State private var showPremiumSheet: Bool = false
    @State private var dailyShareQuote: IslamicWorkCompletionQuote = IslamicWorkCompletionQuotePool.quote()
    @State private var dailyHadith: Hadith?
    @State private var dailyHadithShareItem: Hadith?
    @State private var dailyHadithDateSeed: Date?
    @State private var dailyHadithLanguageCode: String?
    @State private var isLoadingDailyHadith: Bool = false
    @State private var dailyHadithLoadFailed: Bool = false
    @FocusState private var isSpiritualFieldFocused: Bool

    private var isPremium: Bool { authService.isPremium }
    @State private var customHabitText: String = ""
    @FocusState private var isCustomHabitFieldFocused: Bool
    @AppStorage("daily_custom_habits_v1") private var customHabitsRaw: String = ""

    @State private var shukurDraft: String = ""
    @State private var isEditingShukur: Bool = false
    @FocusState private var isShukurFieldFocused: Bool
    @State private var noteSparkle: Bool = false
    @State private var faithFlowDate: Date = Date()
    @State private var faithFlowNoteDraft: String = ""
    @State private var faithFlowNiyetDraft: String = ""
    @State private var faithFlowShukurDraft: String = ""
    @State private var faithFlowZikirDraft: String = ""
    @State private var faithFlowAdvice: String = ""
    @FocusState private var isFaithFlowNoteFocused: Bool
    @State private var isLoadingFaithFlowAdvice: Bool = false
    @State private var showExploreMap: Bool = false
    @State private var exploreSummaryStore = ExploreSummaryStore.shared
    @State private var navigationPath: [DailyRoute] = []

    @State private var prayerBounce: String? = nil

    @AppStorage("daily_draft_note") private var draftNote: String = ""
    @AppStorage("daily_draft_dua") private var draftDua: String = ""
    @AppStorage("daily_draft_reflection") private var draftReflection: String = ""

    private var record: DailyHabitRecord { storage.todayHabitRecord }

    private var todayStats: DailyStats { storage.todayStats() }

    private var topZikir: (name: String, count: Int)? {
        guard let item = todayStats.zikirDetails.max(by: { $0.value < $1.value }) else { return nil }
        return (name: item.key, count: item.value)
    }

    private var dailyWorshipProgress: Double {
        let dhikrFraction = min(Double(todayStats.totalCount) / Double(max(storage.profile.dailyGoal, 1)), 1.0) * 0.65
        let habitFraction = min(Double(record.completedHabits.count) / Double(max(allHabits.count, 1)), 1.0) * 0.20
        let noteFraction = record.shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.0 : 0.15
        return min(dhikrFraction + habitFraction + noteFraction, 1.0)
    }

    private var dailyWorshipCardTitle: String {
        L10n.string(.dailyWorshipsTitle)
    }

    private var dailyDhikrMetricValue: String {
        todayStats.totalCount > 0
            ? L10n.format(.numberFormat, Int64(todayStats.totalCount))
            : L10n.string(.eksik)
    }

    private var dailyHabitMetricValue: String {
        "\(record.completedHabits.count)/\(max(allHabits.count, 1))"
    }

    private var appLocale: Locale {
        Locale(identifier: RabiaAppLanguage.currentCode())
    }

    private var lastSevenDates: [Date] {
        (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -(6 - offset), to: Date())
        }
    }

    private var recentTrackedDates: [Date] {
        let statDates = storage.allStats.map { Calendar.current.startOfDay(for: $0.date) }
        let habitDates = storage.habitRecords.compactMap { record in
            habitRecordDateParser.date(from: record.dateString).map { Calendar.current.startOfDay(for: $0) }
        }

        let merged = Array(Set(statDates + habitDates + [Calendar.current.startOfDay(for: Date())]))
        return merged.sorted(by: >)
    }

    private var visibleTrackedDates: [Date] {
        Array(recentTrackedDates.prefix(3))
    }

    private let dailyCardCornerRadius: CGFloat = 32
    private let dailyCardPadding: CGFloat = 20
    private let dailySectionSpacing: CGFloat = 20

    private enum DailyCardKind {
        case hero(start: Color, end: Color, accent: Color)
        case info(tint: Color)
        case list(tint: Color)
    }

    private var allHabits: [String] {
        uniqueHabits(from: DailyHabitRecord.defaultHabits + customHabits)
    }

    private var prayerStatusColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }

    private enum DailyRoute: Hashable {
        case khutbah
        case prayer(PrayerName?)
    }

    private var showSmartSuggestion: Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= 20 && record.shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        f.dateFormat = "d MMM"
        return f
    }()

    private let timelineDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private let historyDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        f.dateFormat = "d MMM yyyy, EEE"
        return f
    }()

    private let habitRecordDateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var currentDaySeed: Date {
        Calendar.current.startOfDay(for: now)
    }

    private var nextReligiousDay: (day: ReligiousDay, date: Date, daysLeft: Int)? {
        let today = Calendar.current.startOfDay(for: Date())

        let upcoming = religiousDays.compactMap { day -> (ReligiousDay, Date, Int)? in
            let date = nextOccurrenceDate(for: day)
            let daysLeft = Calendar.current.dateComponents([.day], from: today, to: date).day ?? 0
            return daysLeft >= 0 ? (day, date, daysLeft) : nil
        }
        .sorted { $0.2 < $1.2 }

        return upcoming.first
    }

    var body: some View { themedScreenBody }

    private var themedScreenBody: some View {
        ThemedScreen {
            navigationScreen
        }
        .id(themeManager.navigationRefreshID)
    }

    private var navigationScreen: some View {
        navigationAlertScreen
    }

    private var baseNavigationScreen: some View {
        NavigationStack(path: $navigationPath) {
            navigationDestinationScreen
        }
    }

    private var navigationChromeScreen: some View {
        navigationContent
            .toolbar(.hidden, for: .navigationBar)
    }

    private var navigationDestinationScreen: some View {
        navigationChromeScreen
            .navigationDestination(for: DailyRoute.self) { route in
                switch route {
                case .khutbah:
                    KhutbahView()
                case .prayer(let selectedPrayer):
                    PrayerScreen(storage: storage, selectedPrayer: selectedPrayer)
                }
            }
            .navigationDestination(isPresented: $showExploreMap) {
                ManeviRehberView(authService: authService)
            }
            .navigationDestination(isPresented: $showDailyHadithDetail) {
                if let dailyHadith {
                    HadithDetailRouteView(hadith: dailyHadith, store: hadithStore)
                }
            }
    }

    private var navigationSheetScreen: some View {
        baseNavigationScreen
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfilView(storage: storage, authService: authService)
                }
                .id(themeManager.navigationRefreshID)
            }
            .sheet(isPresented: $showDailySharePreview) {
                NavigationStack {
                    SharePreviewScreen(
                        cardType: makeDailyShareCardType(),
                        initialTheme: .emerald,
                        showsThemePicker: true
                    )
                    .navigationTitle(L10n.string(.islamiGunluk))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(.commonClose) {
                                showDailySharePreview = false
                            }
                        }
                    }
                }
                .id(themeManager.navigationRefreshID)
            }
            .sheet(item: $dailyHadithShareItem) { hadith in
                HadithShareView(hadith: hadith)
                    .id(themeManager.navigationRefreshID)
            }
            .sheet(isPresented: $showNotesSheet) {
                notesEditorSheet(entry: nil)
                    .presentationDetents([.large])
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(item: $editingEntry) { entry in
                notesEditorSheet(entry: entry)
                    .presentationDetents([.large])
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $showHabitDetail) {
                if let selectedHabitDate {
                    habitDetailSheet(for: selectedHabitDate)
                        .presentationDetents([.medium, .large])
                        .presentationContentInteraction(.scrolls)
                }
            }
            .sheet(isPresented: $showAllHistory) {
                historyArchiveSheet
                    .presentationDetents([.large])
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(item: $selectedReligiousDay) { day in
                religiousDaySheet(day)
                    .presentationDetents([.fraction(0.34)])
            }
            .sheet(isPresented: $showSpiritualPopup) {
                spiritualAnswerSheet
                    .presentationDetents([.medium, .large])
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumView(authService: authService)
            }
    }

    private var navigationLifecycleScreen: some View {
        navigationSheetScreen
            .task {
                await khutbahService.fetch()
            }
            .task {
                prayerViewModel.refresh()
                await authService.refreshPremiumStatus()
            }
            .task {
                await diyanetStore.loadIfNeeded()
            }
            .task(id: RabiaAppLanguage.currentCode()) {
                await loadDailyHadith()
            }
            .onAppear {
                shukurDraft = record.shukurNote
                if let request = appState.dailyNavigationRequest {
                    handleDailyNavigationRequest(request)
                }
            }
            .onReceive(timer) { date in now = date }
            .onChange(of: currentDaySeed) { _, _ in
                Task {
                    await loadDailyHadith(force: true)
                }
            }
            .onChange(of: faithFlowDate) { _, newDate in
                loadFaithFlowDraft(for: newDate)
            }
            .onChange(of: appState.dailyNavigationRequest?.id) { _, requestID in
                guard let request = appState.dailyNavigationRequest, request.id == requestID else { return }
                handleDailyNavigationRequest(request)
            }
            .sensoryFeedback(.success, trigger: saveTrigger)
            .sensoryFeedback(.impact, trigger: prayerBounce)
    }

    private var navigationAlertScreen: some View {
        navigationLifecycleScreen
            .alert(L10n.string(.premiumRequiredTitle), isPresented: $spiritualQuestionPremiumAlert) {
                Button(L10n.string(.premiumAGec2)) {
                    showPremiumSheet = true
                }
                Button(L10n.string(.dahaSonra), role: .cancel) {}
            } message: {
                Text(.premiumDailySpiritualQuestionMessage)
            }
    }

    private var navigationContent: some View {
        ZStack(alignment: .bottomTrailing) {
            dailyCardsScrollView
            faithFlowFAB
        }
        .background(Color.clear)
    }

    private var activeTheme: ActiveTheme {
        themeManager.current
    }

    private var dailyPrayerExperience: PrayerViewModel? {
        PrayerViewModel(
            liveViewModel: prayerViewModel,
            settings: PrayerSettings(),
            now: now
        )
    }

    private var dailyPrayerHeroState: PrayerHeroBlockState {
        if let prayerState = dailyPrayerExperience {
            return .loaded(prayerState)
        } else if prayerViewModel.isLoading {
            return .loading
        } else if let errorMessage = prayerViewModel.errorMessage, !errorMessage.isEmpty {
            return .error(errorMessage)
        } else {
            return .loading
        }
    }

    private var dailyPrayerStyle: PrayerGradientProvider.Style {
        if let prayerState = dailyPrayerExperience {
            return PrayerGradientProvider.style(for: prayerState.currentPrayer.id, theme: activeTheme)
        }

        return PrayerGradientProvider.style(for: .night, theme: activeTheme)
    }

    private var dailyCardsScrollView: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: dailySectionSpacing) {
                    dailyImmersiveStage(minHeight: max(proxy.size.height * 0.68, 520))
                    erased(dailyGuidanceAndDuaCard)
                    erased(dailyHadithSection)
                    erased(dailyDiyanetCard)
                    erased(exploreDiscoverCard)
                    erased(upcomingIslamicDayCard)
                    erased(khutbahCard)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 104)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func erased<Content: View>(_ content: Content) -> AnyView {
        AnyView(content)
    }

    private func openPrayerScreen(selectedPrayer: PrayerName? = nil) {
        let route = DailyRoute.prayer(selectedPrayer)
        if navigationPath.last != route {
            navigationPath.append(route)
        }
    }

    private func handleDailyNavigationRequest(_ request: DailyNavigationRequest) {
        switch request.destination {
        case .prayer(let prayer):
            openPrayerScreen(selectedPrayer: prayer)
        }
        appState.consumeDailyNavigationRequest(request.id)
    }

    private func loadDailyHadith(force: Bool = false) async {
        let currentLanguageCode = RabiaAppLanguage.currentCode()

        if isLoadingDailyHadith {
            return
        }

        if !force,
           dailyHadith != nil,
           let dailyHadithDateSeed,
           dailyHadithLanguageCode == currentLanguageCode,
           dailyHadithDateSeed == currentDaySeed {
            return
        }

        isLoadingDailyHadith = true
        dailyHadithLoadFailed = false

        defer {
            isLoadingDailyHadith = false
        }

        do {
            let hadith = try await DailyHadithProvider.shared.shortHadithForDate(
                now,
                languageCode: currentLanguageCode
            )
            dailyHadith = hadith
            dailyHadithDateSeed = currentDaySeed
            dailyHadithLanguageCode = currentLanguageCode
        } catch {
            if dailyHadith == nil {
                dailyHadithLoadFailed = true
            }
        }
    }

    @ViewBuilder
    private func dailyCard<Content: View>(
        _ kind: DailyCardKind,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: .topLeading) {
            dailyCardBackground(kind)
            content()
                .padding(dailyCardPadding)
        }
        .clipShape(RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                .strokeBorder(dailyCardBorderColor(kind), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(systemColorScheme == .dark ? 0.08 : 0.24),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: dailyCardShadowColor(kind), radius: 24, x: 0, y: 14)
        .shadow(color: Color.white.opacity(systemColorScheme == .dark ? 0.02 : 0.05), radius: 8, x: 0, y: 2)
    }

    private func dailyCardBackground(_ kind: DailyCardKind) -> AnyView {
        switch kind {
        case let .hero(start, end, accent):
            return AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [start, end],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Circle()
                        .fill(accent.opacity(systemColorScheme == .dark ? 0.20 : 0.28))
                        .frame(width: 220, height: 220)
                        .blur(radius: 18)
                        .offset(x: -90, y: -110)

                    Circle()
                        .fill(Color.white.opacity(systemColorScheme == .dark ? 0.08 : 0.16))
                        .frame(width: 180, height: 180)
                        .blur(radius: 20)
                        .offset(x: 140, y: 120)

                    RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                        .fill(Color.white.opacity(systemColorScheme == .dark ? 0.04 : 0.10))
                }
            )

        case let .info(tint):
            return AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                        .fill(dailyBaseSurfaceColor)

                    RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(systemColorScheme == .dark ? 0.20 : 0.14),
                                    Color.white.opacity(systemColorScheme == .dark ? 0.02 : 0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Circle()
                        .fill(tint.opacity(systemColorScheme == .dark ? 0.10 : 0.12))
                        .frame(width: 180, height: 180)
                        .blur(radius: 24)
                        .offset(x: 120, y: -100)
                }
            )

        case let .list(tint):
            return AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                        .fill(dailyBaseSurfaceColor)

                    RoundedRectangle(cornerRadius: dailyCardCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(systemColorScheme == .dark ? 0.14 : 0.10),
                                    Color.clear,
                                    Color.white.opacity(systemColorScheme == .dark ? 0.01 : 0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
        }
    }

    private func dailyCardBorderColor(_ kind: DailyCardKind) -> Color {
        switch kind {
        case .hero:
            return .white.opacity(systemColorScheme == .dark ? 0.14 : 0.26)
        case .info:
            return .white.opacity(systemColorScheme == .dark ? 0.10 : 0.44)
        case .list:
            return .white.opacity(systemColorScheme == .dark ? 0.08 : 0.36)
        }
    }

    private func dailyCardShadowColor(_ kind: DailyCardKind) -> Color {
        switch kind {
        case .hero:
            return Color.black.opacity(systemColorScheme == .dark ? 0.28 : 0.16)
        case .info, .list:
            return Color.black.opacity(systemColorScheme == .dark ? 0.18 : 0.08)
        }
    }

    private var dailyBaseSurfaceColor: Color {
        Color(uiColor: systemColorScheme == .dark ? .secondarySystemGroupedBackground : .systemBackground)
    }

    private func dailyEyebrow(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint.opacity(0.92))
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func dailyTag(_ title: String, tint: Color, emphasis: Bool = false) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(emphasis ? dailyTagForegroundColor : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(dailyTagBackgroundColor(tint: tint, emphasis: emphasis))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(tint.opacity(systemColorScheme == .dark ? 0.32 : 0.20), lineWidth: 1)
            )
    }

    private var dailyTagForegroundColor: Color {
        systemColorScheme == .dark ? .white : Color(red: 0.12, green: 0.16, blue: 0.18)
    }

    private func dailyTagBackgroundColor(tint: Color, emphasis: Bool) -> Color {
        if emphasis {
            return tint.opacity(systemColorScheme == .dark ? 0.28 : 0.22)
        }
        return tint.opacity(systemColorScheme == .dark ? 0.14 : 0.10)
    }

    private func dailyImmersiveStage(minHeight: CGFloat) -> some View {
        let style = dailyPrayerStyle

        return ZStack(alignment: .bottom) {
            immersiveStageBackground(style: style)

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        dailyEyebrow(L10n.string(.gunluk), tint: style.accentSecondary)

                        HStack(spacing: 8) {
                            dailyStagePill(dayMonthString, tint: style.accent)
                            dailyStagePill(weekdayString.capitalized, tint: .white)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        if let prayerState = dailyPrayerExperience {
                            dailyStagePill(prayerState.hijriDateText, tint: style.accentSecondary)
                        }

                        stageProfileBubble(style: style)
                    }
                }

                Spacer(minLength: 14)

                immersivePrayerHeadline(style: style)

                immersiveProgressPanel(style: style)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minHeight)
        .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .strokeBorder(Color.white.opacity(systemColorScheme == .dark ? 0.12 : 0.24), lineWidth: 1)
        )
        .shadow(color: style.glow.opacity(systemColorScheme == .dark ? 0.34 : 0.20), radius: 32, x: 0, y: 20)
        .shadow(color: Color.black.opacity(systemColorScheme == .dark ? 0.28 : 0.12), radius: 18, x: 0, y: 12)
        .padding(.horizontal, -6)
        .padding(.top, -2)
        .padding(.bottom, 4)
        .contentShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
        .onTapGesture {
            openPrayerScreen()
        }
        .accessibilityAddTraits(.isButton)
    }

    private func immersiveStageBackground(style: PrayerGradientProvider.Style) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(style.heroGradient)

            AtmosphericBackgroundView(
                baseColors: [
                    Color.clear,
                    style.accent.opacity(systemColorScheme == .dark ? 0.18 : 0.12),
                    style.accentSecondary.opacity(systemColorScheme == .dark ? 0.12 : 0.08)
                ],
                primaryGlow: style.accent,
                secondaryGlow: style.accentSecondary,
                overlayTint: Color.white.opacity(systemColorScheme == .dark ? 0.02 : 0.05),
                isDarkMode: systemColorScheme == .dark,
                primaryAlignment: .topLeading,
                secondaryAlignment: .bottomTrailing,
                primaryOffsetRatio: CGSize(width: -0.12, height: -0.16),
                secondaryOffsetRatio: CGSize(width: 0.12, height: 0.16),
                glowIntensity: 1.1,
                ornamentOpacity: 1.04
            )
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))

            LinearGradient(
                colors: [
                    Color.white.opacity(systemColorScheme == .dark ? 0.08 : 0.16),
                    .clear,
                    Color.black.opacity(systemColorScheme == .dark ? 0.06 : 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(systemColorScheme == .dark ? 0.18 : 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private func immersivePrayerHeadline(style: PrayerGradientProvider.Style) -> some View {
        switch dailyPrayerHeroState {
        case .loading:
            VStack(alignment: .leading, spacing: 14) {
                Text(String(localized: "prayer_stage_calc_label", defaultValue: "Diyanet vakitleri"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: 180, height: 24)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.18))
                    .frame(maxWidth: 260)
                    .frame(height: 54)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .frame(width: 220, height: 18)
            }
        case .error(let message):
            VStack(alignment: .leading, spacing: 14) {
                Text(String(localized: "prayer_stage_calc_label", defaultValue: "Diyanet vakitleri"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))

                Text(String(localized: "prayer_hero_error_title", defaultValue: "Vakitler hazır değil"))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .loaded(let prayerState):
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(prayerState.heroEyebrow)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.80))

                        Text(prayerState.currentPrayer.localizedName)
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)

                        Text(prayerState.heroStatusText)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.86))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 10) {
                        PrayerIconView(assetName: prayerState.currentPrayer.iconType, size: 30)

                        Text(prayerState.currentPrayer.formattedTime)
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.70)
                            .contentTransition(.numericText())
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption.weight(.bold))
                    Text(prayerState.locationName)
                        .lineLimit(1)
                    Spacer()
                    Text(prayerState.gregorianDateText)
                        .lineLimit(1)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.76))
            }
        }
    }

    private func immersiveProgressPanel(style: PrayerGradientProvider.Style) -> some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 12)
                    .frame(width: 92, height: 92)

                Circle()
                    .trim(from: 0, to: dailyWorshipProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                style.accent.opacity(0.45),
                                style.accent,
                                style.ring,
                                Color.white.opacity(0.95)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.80), value: dailyWorshipProgress)

                VStack(spacing: 1) {
                    Text(L10n.format(.numberFormat, Int64(Int(dailyWorshipProgress * 100))))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text(L10n.string(.percentSymbol))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(style.accentSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    immersiveMetricCard(
                        label: String(localized: "daily_dhikr_metric_title", defaultValue: "Zikir"),
                        value: dailyDhikrMetricValue,
                        tint: style.accentSecondary
                    )

                    immersiveMetricCard(
                        label: String(localized: "daily_habit_metric_title", defaultValue: "Alışkanlık"),
                        value: dailyHabitMetricValue,
                        tint: style.accent
                    )
                }

                HStack(spacing: 10) {
                    immersiveMetricCard(
                        label: L10n.string(.widgetStreakTitle),
                        value: L10n.format(.daysCountFormat, Int64(storage.maneviStreak)),
                        tint: Color(red: 0.98, green: 0.81, blue: 0.46)
                    )

                    stageShareBubble(style: style)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(systemColorScheme == .dark ? 0.08 : 0.16), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(systemColorScheme == .dark ? 0.12 : 0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(systemColorScheme == .dark ? 0.22 : 0.10), radius: 18, x: 0, y: 10)
    }

    private func stageProfileBubble(style: PrayerGradientProvider.Style) -> some View {
        Button {
            showProfile = true
        } label: {
            profileAvatarView
                .frame(width: 38, height: 38)
                .padding(8)
                .background(
                    Circle()
                        .fill(.white.opacity(systemColorScheme == .dark ? 0.12 : 0.18))
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(systemColorScheme == .dark ? 0.12 : 0.22), lineWidth: 1)
                )
                .shadow(color: style.glow.opacity(systemColorScheme == .dark ? 0.28 : 0.18), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func stageShareBubble(style: PrayerGradientProvider.Style) -> some View {
        Button {
            generateAndShare()
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(systemColorScheme == .dark ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.10, green: 0.14, blue: 0.18))
                .frame(width: 50, height: 50)
                .background(style.accentSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(systemColorScheme == .dark ? 0.16 : 0.28), lineWidth: 1)
                )
                .shadow(color: style.accent.opacity(systemColorScheme == .dark ? 0.26 : 0.16), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func immersiveMetricCard(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func dailyStagePill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(tint.opacity(systemColorScheme == .dark ? 0.20 : 0.16))
            )
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(systemColorScheme == .dark ? 0.12 : 0.22), lineWidth: 1)
            )
    }

    // MARK: - Progress Hero Card

    private var progressHeroCard: some View {
        let accent = Color(red: 0.98, green: 0.81, blue: 0.46)

        return dailyCard(
            .hero(
                start: Color(red: 0.18, green: 0.16, blue: 0.42),
                end: Color(red: 0.07, green: 0.11, blue: 0.24),
                accent: Color(red: 0.41, green: 0.33, blue: 0.83)
            )
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        dailyEyebrow(dailyWorshipCardTitle, tint: accent)
                        Text(dayMonthString)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        Text(weekdayString)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer()

                    dailyTag("\(L10n.format(.numberFormat, Int64(storage.maneviStreak))) \(L10n.string(.gun))", tint: accent, emphasis: true)
                }

                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.12), lineWidth: 12)
                            .frame(width: 102, height: 102)

                        Circle()
                            .trim(from: 0, to: dailyWorshipProgress)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        accent.opacity(0.45),
                                        accent,
                                        Color.white.opacity(0.95)
                                    ],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 11, lineCap: .round)
                            )
                            .frame(width: 102, height: 102)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.78), value: dailyWorshipProgress)

                        VStack(spacing: 1) {
                            Text(L10n.format(.numberFormat, Int64(Int(dailyWorshipProgress * 100))))
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            Text(L10n.string(.percentSymbol))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        heroStatRow(
                            icon: "number.circle.fill",
                            label: String(localized: "daily_dhikr_metric_title", defaultValue: "Zikir"),
                            value: dailyDhikrMetricValue,
                            filled: todayStats.totalCount > 0
                        )
                        heroStatRow(
                            icon: "checklist.checked",
                            label: String(localized: "daily_habit_metric_title", defaultValue: "Alışkanlık"),
                            value: dailyHabitMetricValue,
                            filled: record.completedHabits.isEmpty == false
                        )
                        heroStatRow(
                            icon: "flame.fill",
                            label: L10n.string(.widgetStreakTitle),
                            value: L10n.format(.daysCountFormat, Int64(storage.maneviStreak)),
                            filled: storage.maneviStreak > 0
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    generateAndShare()
                } label: {
                    HStack(spacing: 10) {
                        if isGeneratingCard {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                            Text(.hazirlaniyor)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline.weight(.bold))
                            Text(.paylas)
                                .font(.subheadline.weight(.bold))
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .foregroundStyle(isGeneratingCard ? .white : accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func heroStatRow(icon: String, label: String, value: String, filled: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(filled ? Color(red: 0.98, green: 0.81, blue: 0.46) : .white.opacity(0.45))
                .frame(width: 20)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(filled ? Color(red: 0.98, green: 0.81, blue: 0.46) : .white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Upcoming Islamic Day Card

    private var upcomingIslamicDayCard: some View {
        dailyCard(
            .info(tint: Color(red: 0.88, green: 0.62, blue: 0.33))
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.88, blue: 0.72),
                                        Color(red: 0.94, green: 0.73, blue: 0.48)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(red: 0.48, green: 0.28, blue: 0.08))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        dailyEyebrow(L10n.string(.yaklasanIslamiGun), tint: Color(red: 0.76, green: 0.48, blue: 0.20))
                        Text(hijriDateString)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    dailyTag(weekdayString.capitalized, tint: Color.orange)
                }

                if let nextReligiousDay {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(nextReligiousDay.day.title)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)

                        Text(fullDateString(for: nextReligiousDay.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            dailyTag(
                                nextReligiousDay.daysLeft == 0
                                    ? L10n.string(.bugun)
                                    : L10n.format(.daysLeftFormat, Int64(nextReligiousDay.daysLeft)),
                                tint: Color(red: 0.93, green: 0.66, blue: 0.32),
                                emphasis: true
                            )
                            dailyTag(L10n.string(.enYakinOzelGun), tint: Color(red: 0.76, green: 0.52, blue: 0.29))
                        }

                        Button {
                            selectedReligiousDay = nextReligiousDay.day
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.subheadline.weight(.semibold))
                                Text(.oGunNeYapabilirim)
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(Color(red: 0.63, green: 0.38, blue: 0.08))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.60))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text(.yaklasanBirIslamiGunBilgisiBulunamadi)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func journalStatusPill(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemFill))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var hijriDateString: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }

    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private var dayMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: Date())
    }

    private var dailyDiyanetRecord: DiyanetKnowledgeRecord? {
        let records = diyanetStore.records
        guard !records.isEmpty else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: now)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let seed = abs((year * 397) + dayOfYear)
        return records[seed % records.count]
    }

    private var dailyDiyanetCard: some View {
        Group {
            if let record = dailyDiyanetRecord {
                NavigationLink {
                    DiyanetKnowledgeDetailView(record: record)
                } label: {
                    DailyDiyanetSpotlightCard(record: record)
                }
                .buttonStyle(.plain)
            } else if diyanetStore.isLoading {
                DailyDiyanetStateCard(
                    title: "Bugünün Diyanet seçkisi hazırlanıyor",
                    message: "Resmi içerikler yüklenirken günlük kartı kısa süre içinde görünecek."
                )
            } else if let errorMessage = diyanetStore.errorMessage, !errorMessage.isEmpty {
                DailyDiyanetStateCard(
                    title: "Bugünün Diyanet seçkisi şu an açılamadı",
                    message: errorMessage
                )
            }
        }
    }

    // MARK: - Faith Flow FAB

    private var faithFlowFAB: some View {
        EmptyView()
    }

    // MARK: - Prayer Hero

    private var prayerHeroCard: some View {
        return PrayerHeroBlock(state: dailyPrayerHeroState) {
            openPrayerScreen()
        }
    }

    // MARK: - Explore Card

    private var exploreCardState: ExploreCardView.DisplayState {
        guard exploreSummaryStore.hasLoadedSnapshot else { return .loading }
        return exploreSummaryStore.totalTrackedCount == 0 ? .empty : .loaded
    }

    private var exploreDiscoverCard: some View {
        ExploreCardView(
            state: exploreCardState,
            mosqueCount: exploreSummaryStore.mosquesCount,
            shrineCount: exploreSummaryStore.shrinesCount,
            historicalCount: exploreSummaryStore.historicalPlacesCount,
            onTap: {
                showExploreMap = true
            }
        )
    }

    // MARK: - Habits Card

    private var habitsCard: some View {
        let rowHeight: CGFloat = 44
        let listMaxHeight = min(CGFloat(allHabits.count) * rowHeight, 200)
        let completedHabits = record.completedHabits.filter { allHabits.contains($0) }.count

        return dailyCard(.list(tint: Color(red: 0.39, green: 0.58, blue: 0.78))) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        dailyEyebrow(L10n.string(.gunlukAliskanliklar), tint: Color(red: 0.30, green: 0.48, blue: 0.73))
                        Text(
                            L10n.format(
                                .countFractionFormat,
                                Int64(completedHabits),
                                Int64(max(allHabits.count, 1))
                            )
                        )
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    }

                    Spacer()

                    dailyTag(L10n.string(.aliskanlikEkle), tint: Color(red: 0.30, green: 0.48, blue: 0.73))
                }

                HStack(spacing: 10) {
                    TextField(.aliskanlikEkle, text: $customHabitText)
                        .textInputAutocapitalization(.sentences)
                        .focused($isCustomHabitFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { addCustomHabit() }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button {
                        addCustomHabit()
                    } label: {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 42, height: 42)
                            .foregroundStyle(.white)
                            .background(Color(red: 0.30, green: 0.48, blue: 0.73))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(allHabits, id: \.self) { habit in
                            let isCompleted = record.completedHabits.contains(habit)

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    storage.toggleHabit(habit)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isCompleted ? Color.teal : Color(uiColor: .tertiarySystemFill))
                                            .frame(width: 36, height: 36)
                                        if isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }

                                    Text(localizedHabitName(habit))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .strikethrough(isCompleted, color: .teal)
                                        .lineLimit(1)

                                    Spacer()

                                    if customHabits.contains(habit) {
                                        Button(role: .destructive) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                removeCustomHabit(habit)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.red)
                                                .frame(width: 30, height: 30)
                                                .background(Color.red.opacity(0.10))
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .tertiarySystemFill).opacity(0.75))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: listMaxHeight)
            }
        }
    }

    // MARK: - Khutbah Card

    private var khutbahCard: some View {
        NavigationLink(value: DailyRoute.khutbah) {
            dailyCard(
                .hero(
                    start: Color(red: 0.05, green: 0.19, blue: 0.28),
                    end: Color(red: 0.06, green: 0.33, blue: 0.34),
                    accent: Color(red: 0.24, green: 0.73, blue: 0.62)
                )
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.white.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(red: 0.76, green: 0.96, blue: 0.88))
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            dailyEyebrow(L10n.string(.haftaninHutbesi), tint: Color(red: 0.67, green: 0.92, blue: 0.83))
                            Text(khutbahService.content?.title ?? L10n.string(.haftaninHutbesi))
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }

                        Spacer()

                        if khutbahService.isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }

                    if let khutbah = khutbahService.content {
                        if !khutbah.date.isEmpty {
                            dailyTag(khutbah.date, tint: Color(red: 0.23, green: 0.72, blue: 0.62), emphasis: true)
                        }

                        Text(khutbahPreviewText(khutbah.content))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                            .lineSpacing(4)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if khutbahService.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                            Text(.hutbeYukleniyor)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.76))
                        }
                    } else if let error = khutbahService.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.74))
                            .lineLimit(3)
                    }

                    HStack(spacing: 10) {
                        Text(.hutbeyiOku)
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(Color(red: 0.79, green: 0.97, blue: 0.92))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Cards

    private var aiCards: some View {
        EmptyView()
    }

    private var maneviAssistantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(.rabiaYaSor2, systemImage: "bubble.left.and.sparkles.fill")
                    .font(.headline)
                Spacer()
                AIBadge()
            }

            TextField(.rabiaYaSorunuzuYazinVeEnterABasin, text: $spiritualQuestion, axis: .vertical)
                .focused($isSpiritualFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isSpiritualFieldFocused = false
                    askSpiritualQuestion()
                }
                .lineLimit(2...4)
                .padding(12)
                .background(Color(.tertiarySystemFill))
                .clipShape(.rect(cornerRadius: 12))

            Button {
                isSpiritualFieldFocused = false
                askSpiritualQuestion()
            } label: {
                HStack(spacing: 8) {
                    if isAskingSpiritualQuestion {
                        ProgressView().tint(.teal)
                        Text(.rabiaDusunuyor)
                            .font(.subheadline.bold())
                            .foregroundStyle(.teal)
                    } else {
                        Text(.sor2)
                            .font(.subheadline.bold())
                            .foregroundStyle(.teal)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.teal.opacity(0.12))
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isAskingSpiritualQuestion || spiritualQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !isPremium {
                Text(.ucretsizKullanicilarIcinRabiaDaGunde1SoruHakkiVardir)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.teal.opacity(0.22), lineWidth: 1)
        )
    }

    private var dailyGuidanceAndDuaCard: some View {
        Group {
            if let verse = DailyVerseProvider.shared.verseForDate(now) {
                DailyQuranVerseCard(verse: verse) {
                    appState.requestQuranNavigation(
                        .reader(
                            QuranReadingRoute(
                                surahId: verse.surahId,
                                ayahNumber: verse.ayahNumber
                            )
                        )
                    )
                }
                    .equatable()
            }
        }
    }

    @ViewBuilder
    private var dailyHadithSection: some View {
        if let dailyHadith {
            DailyHadithCard(
                hadith: dailyHadith,
                onOpen: {
                    showDailyHadithDetail = true
                },
                onShare: {
                    dailyHadithShareItem = dailyHadith
                }
            )
            .equatable()
        } else if isLoadingDailyHadith {
            DailyHadithLoadingCard()
        } else if dailyHadithLoadFailed {
            DailyHadithErrorCard {
                Task {
                    await loadDailyHadith(force: true)
                }
            }
        }
    }

    // MARK: - My Notes Card

    private var myNotesAndDuasCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(.gunlukNotlarim)
                    .font(.headline)
                Spacer()
                Button {
                    draftDua = ""
                    draftNote = ""
                    draftReflection = ""
                    showNotesSheet = true
                } label: {
                    Label(.ekle2, systemImage: "plus")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }

            if storage.journalEntries.isEmpty {
                Text(.duaSukurVeTefekkurNotlarinizBuradaGorunur)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(storage.journalEntries.prefix(8)) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(dayLabelFormatter.string(from: entry.createdAt))
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(timelineDateFormatter.string(from: entry.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !entry.duaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(L10n.format(.duaPrefixFormat, entry.duaText))
                                    .font(.caption)
                            }
                            if !entry.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(L10n.format(.notePrefixFormat, entry.noteText))
                                    .font(.caption)
                            }
                            if !entry.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(L10n.format(.reflectionPrefixFormat, entry.reflectionText))
                                    .font(.caption)
                            }
                            HStack(spacing: 10) {
                                Button(.duzenle) {
                                    draftDua = entry.duaText
                                    draftNote = entry.noteText
                                    draftReflection = entry.reflectionText
                                    editingEntry = entry
                                }
                                .font(.caption.bold())
                                Button(.sil2, role: .destructive) {
                                    Task { await deleteJournalEntry(entry.id) }
                                }
                                .font(.caption.bold())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
            }

            if let saveMessage {
                Text(saveMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    // MARK: - Favorites Chips

    private var favoriteChipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(.kisayollar)
                .font(.headline)

            if storage.favorites().isEmpty {
                Text(.favoriZikirVeDualarinizBuradaGorunur)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(storage.favorites().prefix(12)) { favorite in
                            Button {
                                switch favorite.type {
                                case .quran: onNavigateToTab(.quran)
                                case .zikir: onNavigateToTab(.dhikrs)
                                case .dua: onNavigateToTab(.guide)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: favoriteIcon(for: favorite.type))
                                        .font(.caption2)
                                        .foregroundStyle(favoriteColor(for: favorite.type))
                                    Text(favorite.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(.capsule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private func prayerHistorySummary(prayerCount: Int, dhikrCount: Int) -> String {
        L10n.format(.dailyPrayerHistorySummaryFormat, Int64(prayerCount), Int64(dhikrCount))
    }

    // MARK: - Helpers

    private func fullDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func khutbahPreviewText(_ content: String) -> String {
        let normalized = content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = normalized.prefix(150)
        return String(preview) + (normalized.count > preview.count ? "..." : "")
    }

    private func favoriteIcon(for type: FavoriteItemType) -> String {
        switch type {
        case .quran: return "book.closed.fill"
        case .zikir: return "circle.circle.fill"
        case .dua: return "moon.stars.fill"
        }
    }

    private func favoriteColor(for type: FavoriteItemType) -> Color {
        switch type {
        case .quran: return .teal
        case .zikir: return .yellow
        case .dua: return .indigo
        }
    }

    private var gregorianFlowDateText: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "d MMMM EEEE"
        return formatter.string(from: faithFlowDate)
    }

    private var hijriFlowDateText: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: faithFlowDate)
    }

    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func userInitials(_ user: AuthUser) -> String {
        if let name = user.displayName, !name.isEmpty {
            let parts = name.split(separator: " ")
            if parts.count >= 2 {
                let first = String(parts[0].first ?? " ")
                let second = String(parts[1].first ?? " ")
                return (first + second).uppercased()
            }
            return String(name.prefix(2)).uppercased()
        }
        if let email = user.email {
            return String(email.prefix(2)).uppercased()
        }
        return "ZK"
    }

    @ViewBuilder
    private var profileAvatarView: some View {
        if let base64 = storage.profile.avatarBase64,
           let data = Data(base64Encoded: base64),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        } else if authService.isLoggedIn, let user = authService.currentUser {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                Text(userInitials(user))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        } else {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var spiritualAnswerSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(.rabia)
                    .font(.title3.bold())

                Text(spiritualAnswer)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.teal.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 12))

                Button {
                    let item = FavoriteItem(
                        id: "ai_dua_\(UUID().uuidString)",
                        type: .dua,
                        title: L10n.string(.dailyRabiaAnswerTitle),
                        subtitle: Date().formatted(date: .abbreviated, time: .shortened),
                        detail: spiritualAnswer
                    )
                    storage.toggleFavorite(item)
                } label: {
                    Label(.favorilereKaydet2, systemImage: "moon.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    saveSpiritualAnswerImage()
                } label: {
                    Label(.gorselOlarakTelefonaKaydet, systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Faith Flow Sheet (Redesigned)

    private var faithFlowSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    faithFlowDateHeader
                    faithFlowCompactCalendar
                    faithFlowReligiousEventsList
                    faithFlowNoteSection
                    faithFlowHistorySection
                }
                .padding(16)
            }
            .navigationTitle(L10n.string(.islamiGunluk))
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var faithFlowDateHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Label(.miladi2, systemImage: "calendar")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(gregorianFlowDateText)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Label(.hicri2, systemImage: "moon.stars.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(hijriFlowDateText)
                    .font(.subheadline.bold())
                    .foregroundStyle(.teal)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.10), Color.blue.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 14))
    }

    private var faithFlowCompactCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker("tarih", selection: $faithFlowDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .frame(maxHeight: 300)
                .overlay(alignment: .topLeading) {
                    religiousDayDotOverlay
                }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private var religiousDayDotOverlay: some View {
        EmptyView()
    }

    private var faithFlowReligiousEventsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(.diniGunlerKandiller, systemImage: "star.fill")
                    .font(.headline)
                Spacer()
            }

            let currentMonth = Calendar.current.component(.month, from: faithFlowDate)
            let monthEvents = religiousDays.filter { $0.month == currentMonth }
            let otherEvents = religiousDays.filter { $0.month != currentMonth }

            if !monthEvents.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(monthEvents.enumerated()), id: \.element.id) { index, day in
                        religiousEventRow(day: day, isHighlighted: true)
                        if index < monthEvents.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 14))
            }

            if monthEvents.isEmpty {
                Text(.buAydaOzelBirDiniGunBulunmuyor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Text(.yaklasanDigerGunler)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            VStack(spacing: 0) {
                ForEach(Array(otherEvents.enumerated()), id: \.element.id) { index, day in
                    religiousEventRow(day: day, isHighlighted: false)
                    if index < otherEvents.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
    }

    private func religiousEventRow(day: ReligiousDay, isHighlighted: Bool) -> some View {
        Button {
            faithFlowDate = dateForCurrentYear(month: day.month, day: day.day)
            Task { await fetchFaithFlowAdvice(for: day) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHighlighted ? Color.teal.opacity(0.15) : Color(.tertiarySystemFill))
                        .frame(width: 40, height: 40)
                    VStack(spacing: 0) {
                        Text("\(day.day)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isHighlighted ? .teal : .primary)
                        Text(monthAbbreviation(day.month))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isHighlighted ? .teal.opacity(0.7) : .secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(day.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(daysUntilText(month: day.month, day: day.day))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isHighlighted {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func monthAbbreviation(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        let symbols = formatter.shortMonthSymbols ?? []
        guard month >= 1, month <= symbols.count else { return "" }
        return symbols[month - 1].uppercased()
    }

    private func daysUntilText(month: Int, day: Int) -> String {
        let target = dateForCurrentYear(month: month, day: day)
        let today = Calendar.current.startOfDay(for: Date())
        let targetDay = Calendar.current.startOfDay(for: target)
        let diff = Calendar.current.dateComponents([.day], from: today, to: targetDay).day ?? 0
        if diff == 0 { return L10n.string(.bugun) }
        if diff < 0 { return L10n.string(.gecti) }
        return L10n.format(.daysLaterFormat, Int64(diff))
    }

    private var faithFlowNoteSection: some View {
        Group {
            if !canAccessFaithFlow(for: faithFlowDate) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.buGunIcinKilitli)
                        .font(.headline)
                    Text(.premiumFaithFlowMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(.premiumAGec2) {
                        showPremiumSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(14)
                .background(Color.orange.opacity(0.12))
                .clipShape(.rect(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(.bugunAllahIcinNeYaptin)
                        .font(.title3.bold())

                    TextField(.niyetiniVeYaptiginiYaz, text: $faithFlowNoteDraft, axis: .vertical)
                        .focused($isFaithFlowNoteFocused)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(.rect(cornerRadius: 12))

                    faithFlowJournalCard(icon: "sparkle", title: L10n.string(.bugununNiyeti), placeholder: L10n.string(.bugunNeIcinNiyetEttim), text: $faithFlowNiyetDraft)

                    faithFlowJournalCard(icon: "heart.fill", title: L10n.string(.bugunSukrettiginBirSey), placeholder: L10n.string(.bugunSukrettigimSey), text: $faithFlowShukurDraft)

                    faithFlowJournalCard(icon: "book.closed.fill", title: L10n.string(.bugunOkudugunBirZikir), placeholder: L10n.string(.okudugumZikirVeyaDua), text: $faithFlowZikirDraft)

                    Button {
                        saveFaithFlow()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(.kaydet2)
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .disabled(faithFlowNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && faithFlowNiyetDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && faithFlowShukurDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && faithFlowZikirDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    private var faithFlowHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(.gecmisAkis)
                .font(.headline)
            if storage.faithLogs.isEmpty {
                Text(.henuzKayitYok)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(storage.faithLogs.prefix(30)) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(faithLogDateString(item.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.note)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
    }

    private var customHabits: [String] {
        uniqueHabits(
            from: customHabitsRaw
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    private func addCustomHabit() {
        let trimmed = customHabitText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalizedTrimmed = normalizedHabitKey(trimmed)
        guard !DailyHabitRecord.defaultHabits.contains(where: { normalizedHabitKey($0) == normalizedTrimmed }) else {
            customHabitText = ""
            return
        }
        var habits = customHabits
        guard !habits.contains(where: { normalizedHabitKey($0) == normalizedTrimmed }) else {
            customHabitText = ""
            return
        }
        habits.append(trimmed)
        customHabitsRaw = habits.joined(separator: "\n")
        customHabitText = ""
        isCustomHabitFieldFocused = false
    }

    private func removeCustomHabit(_ habit: String) {
        var habits = customHabits
        habits.removeAll { $0 == habit }
        customHabitsRaw = habits.joined(separator: "\n")
    }

    private func normalizedHabitKey(_ habit: String) -> String {
        habit
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: appLocale)
    }

    private func uniqueHabits(from habits: [String]) -> [String] {
        var seen: Set<String> = []

        return habits.filter { habit in
            let key = normalizedHabitKey(habit)
            guard !key.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private nonisolated struct ReligiousDay: Identifiable, Sendable {
        let id: String
        let title: String
        let day: Int
        let month: Int
        let worshipSuggestion: String
        let duaSuggestion: String
    }

    private var religiousDays: [ReligiousDay] {
        [
            ReligiousDay(
                id: "regaib",
                title: L10n.string(.religiousRegaibKandiliTitle),
                day: 1,
                month: 7,
                worshipSuggestion: L10n.string(.religiousRegaibKandiliWorship),
                duaSuggestion: L10n.string(.religiousRegaibKandiliDua)
            ),
            ReligiousDay(
                id: "mirac",
                title: L10n.string(.religiousMiracKandiliTitle),
                day: 27,
                month: 7,
                worshipSuggestion: L10n.string(.religiousMiracKandiliWorship),
                duaSuggestion: L10n.string(.religiousMiracKandiliDua)
            ),
            ReligiousDay(
                id: "berat",
                title: L10n.string(.religiousBeratKandiliTitle),
                day: 15,
                month: 8,
                worshipSuggestion: L10n.string(.religiousBeratKandiliWorship),
                duaSuggestion: L10n.string(.religiousBeratKandiliDua)
            ),
            ReligiousDay(
                id: "kadir",
                title: L10n.string(.religiousKadirGecesiTitle),
                day: 27,
                month: 9,
                worshipSuggestion: L10n.string(.religiousKadirGecesiWorship),
                duaSuggestion: L10n.string(.religiousKadirGecesiDua)
            ),
            ReligiousDay(
                id: "ramazan_bayrami",
                title: L10n.string(.religiousRamazanBayramiTitle),
                day: 1,
                month: 10,
                worshipSuggestion: L10n.string(.religiousRamazanBayramiWorship),
                duaSuggestion: L10n.string(.religiousRamazanBayramiDua)
            ),
            ReligiousDay(
                id: "kurban_bayrami",
                title: L10n.string(.religiousKurbanBayramiTitle),
                day: 10,
                month: 12,
                worshipSuggestion: L10n.string(.religiousKurbanBayramiWorship),
                duaSuggestion: L10n.string(.religiousKurbanBayramiDua)
            ),
            ReligiousDay(
                id: "mevlid",
                title: L10n.string(.religiousMevlidKandiliTitle),
                day: 12,
                month: 3,
                worshipSuggestion: L10n.string(.religiousMevlidKandiliWorship),
                duaSuggestion: L10n.string(.religiousMevlidKandiliDua)
            )
        ]
    }

    private var currentReligiousDay: ReligiousDay {
        let day = Calendar.current.component(.day, from: faithFlowDate)
        let month = Calendar.current.component(.month, from: faithFlowDate)
        return religiousDays.first(where: { $0.day == day && $0.month == month }) ?? ReligiousDay(
            id: "today_default",
            title: L10n.string(.religiousTodayTitle),
            day: day,
            month: month,
            worshipSuggestion: L10n.string(.religiousTodayWorship),
            duaSuggestion: L10n.string(.religiousTodayDua)
        )
    }

    private func dateForCurrentYear(month: Int, day: Int) -> Date {
        nextOccurrenceDate(for: ReligiousDay(
            id: "temp_\(month)_\(day)",
            title: "",
            day: day,
            month: month,
            worshipSuggestion: "",
            duaSuggestion: ""
        ))
    }

    private func faithLogDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    private func nextOccurrenceDate(for religiousDay: ReligiousDay) -> Date {
        let gregorian = Calendar.current
        let currentYear = gregorian.component(.year, from: Date())
        if let overriddenDate = gregorianReligiousDate(for: religiousDay, year: currentYear),
           gregorian.startOfDay(for: overriddenDate) >= gregorian.startOfDay(for: Date()) {
            return gregorian.startOfDay(for: overriddenDate)
        }

        if let overriddenNextYear = gregorianReligiousDate(for: religiousDay, year: currentYear + 1),
           gregorian.startOfDay(for: overriddenNextYear) >= gregorian.startOfDay(for: Date()) {
            return gregorian.startOfDay(for: overriddenNextYear)
        }

        let hijri = Calendar(identifier: .islamicUmmAlQura)
        let today = gregorian.startOfDay(for: Date())
        let currentHijriYear = hijri.component(.year, from: today)

        var components = DateComponents()
        components.calendar = hijri
        components.year = currentHijriYear
        components.month = religiousDay.month
        components.day = religiousDay.day

        let thisYearDate = hijri.date(from: components).map { gregorian.startOfDay(for: $0) } ?? today
        if thisYearDate >= today {
            return thisYearDate
        }

        components.year = currentHijriYear + 1
        return hijri.date(from: components).map { gregorian.startOfDay(for: $0) } ?? thisYearDate
    }

    private func gregorianReligiousDate(for religiousDay: ReligiousDay, year: Int) -> Date? {
        let overrides: [Int: [String: DateComponents]] = [
            2026: [
                "mirac": DateComponents(year: 2026, month: 1, day: 15),
                "berat": DateComponents(year: 2026, month: 2, day: 2),
                "kadir": DateComponents(year: 2026, month: 3, day: 14),
                "ramazan_bayrami": DateComponents(year: 2026, month: 3, day: 20),
                "kurban_bayrami": DateComponents(year: 2026, month: 5, day: 27),
                "mevlid": DateComponents(year: 2026, month: 8, day: 24),
                "regaib": DateComponents(year: 2026, month: 12, day: 17)
            ]
        ]

        guard let components = overrides[year]?[religiousDay.id] else {
            return nil
        }

        return Calendar(identifier: .gregorian).date(from: components)
    }

    private func infoChip(title: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.caption.bold())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.10))
        .clipShape(.capsule)
    }

    private func faithFlowJournalCard(icon: String, title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(.teal)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color(.tertiarySystemFill))
                .clipShape(.rect(cornerRadius: 10))
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func canAccessFaithFlow(for _: Date) -> Bool {
        isPremium
    }

    private func loadFaithFlowDraft(for date: Date) {
        if !canAccessFaithFlow(for: date) {
            faithFlowNoteDraft = ""
            faithFlowAdvice = ""
            return
        }
        if let entry = storage.faithLog(for: date) {
            faithFlowNoteDraft = entry.note
        } else {
            faithFlowNoteDraft = ""
        }
    }

    private func saveFaithFlow() {
        guard canAccessFaithFlow(for: faithFlowDate) else {
            showPremiumSheet = true
            return
        }
        var parts: [String] = []
        let mainNote = faithFlowNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let niyet = faithFlowNiyetDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let shukur = faithFlowShukurDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let zikir = faithFlowZikirDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !mainNote.isEmpty { parts.append(mainNote) }
        if !niyet.isEmpty { parts.append(L10n.format(.faithFlowNiyetLineFormat, niyet)) }
        if !shukur.isEmpty { parts.append(L10n.format(.faithFlowShukurLineFormat, shukur)) }
        if !zikir.isEmpty { parts.append(L10n.format(.faithFlowDhikrLineFormat, zikir)) }
        guard !parts.isEmpty else { return }

        isFaithFlowNoteFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        storage.upsertFaithLog(for: faithFlowDate, note: parts.joined(separator: "\n"), photoBase64: nil)
        saveTrigger.toggle()
    }

    private func fetchFaithFlowAdvice(for day: ReligiousDay, userNote: String? = nil) async {
        guard canAccessFaithFlow(for: faithFlowDate) else {
            showPremiumSheet = true
            return
        }
        isLoadingFaithFlowAdvice = true
        defer { isLoadingFaithFlowAdvice = false }
        let gregorian = faithFlowDate.formatted(date: .abbreviated, time: .omitted)
        let prompt = """
        Tarih: \(gregorian)
        Gün: \(day.title)
        Kullanıcının bugün yaptığı: \(userNote ?? faithFlowNoteDraft)

        Bu güne uygun, güncel İslami pratiklerle bağlantılı kısa bir tavsiye ver.
        Cevap yapısı:
        1) Bugün için tek cümlelik manevi değerlendirme
        2) Hemen uygulanabilir 2 somut öneri
        Türkçe, samimi, kısa.
        """
        let response = try? await geminiService.answerSpiritualQuestion(prompt)
        faithFlowAdvice = response ?? L10n.string(.faithFlowAdviceUnavailable)
    }

    private func saveShukurNote() {
        let trimmed = shukurDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        storage.saveShukurNote(trimmed)
        isShukurFieldFocused = false
        withAnimation(.spring(response: 0.4)) {
            isEditingShukur = false
            noteSparkle.toggle()
            saveTrigger.toggle()
        }
    }

    private func askSpiritualQuestion() {
        let trimmed = spiritualQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSpiritualFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        Task {
            if !isPremium {
                await authService.refreshPremiumStatus(force: true)
            }

            let hasPremium = authService.isPremium
            if !hasPremium {
                spiritualQuestionPremiumAlert = true
                return
            }

            await submitSpiritualQuestion(trimmed, countsTowardDailyFreeLimit: false)
        }
    }

    @MainActor
    private func submitSpiritualQuestion(_ question: String, countsTowardDailyFreeLimit: Bool) async {
        isAskingSpiritualQuestion = true
        let response = try? await geminiService.answerSpiritualQuestion(question)
        spiritualAnswer = response ?? L10n.string(.responseUnavailableTryAgain)
        showSpiritualPopup = true
        if countsTowardDailyFreeLimit {
            geminiService.markDailySpiritualQuestionAsked()
        }
        isAskingSpiritualQuestion = false
        spiritualQuestion = ""
    }

    private func saveSpiritualAnswerImage() {
        let card = VStack(alignment: .leading, spacing: 18) {
            Text(.rabia)
                .font(.system(size: 62, weight: .bold))
                .foregroundStyle(.white)
            Text(spiritualAnswer)
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
            Spacer()
            Text(AppName.fullTextKey)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.teal)
        }
        .padding(24)
        .frame(width: 1080, height: 1920, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.14, blue: 0.3), Color(red: 0.05, green: 0.35, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 0))

        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0
        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }

    // MARK: - Sheet Views

    private func notesEditorSheet(entry: DailyJournalEntry?) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(entry == nil ? "notlarim_ve_dualarim" : "notu_duzenle")
                    .font(.title3.bold())

                Group {
                    TextField(.kisiselDua, text: $draftDua, axis: .vertical)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .lineLimit(2...4)
                    TextField(.sukurNotu2, text: $draftNote, axis: .vertical)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .lineLimit(2...4)
                    TextField(.gunlukTefekkur, text: $draftReflection, axis: .vertical)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .lineLimit(3...6)
                }
                .padding(12)
                .background(Color(.tertiarySystemFill))
                .clipShape(.rect(cornerRadius: 10))

                Button {
                    Task { await saveJournalEntry(editing: entry) }
                } label: {
                    if isSavingEntry {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label(entry == nil ? "kaydet_2" : "guncelle", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSaveJournalEntry || isSavingEntry)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func habitDetailSheet(for date: Date) -> some View {
        let stats = storage.stats(for: date)
        let habitRec = storage.habitRecord(for: date)
        let displayedZikirCount = max(stats.totalCount, 0)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(fullDateString(for: date))
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    detailStatRow(
                        icon: "moon.stars.fill",
                        title: L10n.format(.dailyHabitDetailPrayersCountFormat, Int64(habitRec.completedPrayerCount)),
                        subtitle: L10n.string(.dailyHabitDetailPrayerTracking)
                    )
                    detailStatRow(
                        icon: "number.circle.fill",
                        title: L10n.format(.dailyHabitDetailDhikrCountFormat, Int64(displayedZikirCount)),
                        subtitle: L10n.string(.dailyHabitDetailTotalDhikr)
                    )
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text(.namazDetayi)
                        .font(.headline)
                    ForEach(DailyHabitRecord.prayerNames, id: \.self) { prayer in
                        HStack {
                            Text(localizedPrayerName(prayer))
                                .font(.subheadline)
                            Spacer()
                            Label(
                                habitRec.prayerStatus[prayer] == true ? "kilindi" : "eksik",
                                systemImage: habitRec.prayerStatus[prayer] == true ? "checkmark.circle.fill" : "circle"
                            )
                            .font(.subheadline)
                            .foregroundStyle(habitRec.prayerStatus[prayer] == true ? .teal : .secondary)
                        }
                    }
                }

                if !habitRec.shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.sukurNotu)
                            .font(.headline)
                        Text(habitRec.shukurNote)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(18)
        }
    }

    private var historyArchiveSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(recentTrackedDates, id: \.self) { date in
                        let stats = storage.stats(for: date)
                        let habitRec = storage.habitRecord(for: date)
                        let displayedZikirCount = max(stats.totalCount, 0)

                        Button {
                            selectedHabitDate = date
                            showAllHistory = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showHabitDetail = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(historyDateFormatter.string(from: date))
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(L10n.format(.historyPrayerSummaryCountsFormat, Int64(habitRec.completedPrayerCount), Int64(displayedZikirCount)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.string(.gecmisKayitlar))
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func religiousDaySheet(_ day: ReligiousDay) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(verbatim: "☪️")
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.title)
                        .font(.title3.bold())
                    Text(fullDateString(for: nextOccurrenceDate(for: day)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(.oGunNeYapabilirsin)
                    .font(.headline)
                Text(day.worshipSuggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(.kisaDua)
                    .font(.headline)
                Text(day.duaSuggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private func detailStatRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
            Spacer()
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func localizedPrayerName(_ prayer: String) -> String {
        switch prayer.lowercased() {
        case "sabah", "imsak", "fajr": return L10n.string(.prayerFajr)
        case "güneş", "gunes", "sunrise": return L10n.string(.prayerSunrise)
        case "öğle", "ogle", "dhuhr": return L10n.string(.prayerDhuhr)
        case "ikindi", "asr": return L10n.string(.prayerAsr)
        case "akşam", "aksam", "maghrib": return L10n.string(.prayerMaghrib)
        case "yatsı", "yatsi", "isha": return L10n.string(.prayerIsha)
        default: return prayer
        }
    }

    private func localizedHabitName(_ habit: String) -> String {
        switch habit.lowercased() {
        case "kur'an oku", "kuran oku": return L10n.string(.habitKuranOku)
        case "günlük zikir", "gunluk zikir": return L10n.string(.habitGunlukZikir)
        case "dua et": return L10n.string(.habitDuaEt)
        case "sadaka ver": return L10n.string(.habitSadakaVer)
        case "istiğfar", "istigfar": return L10n.string(.habitIstigfar)
        default: return habit
        }
    }

    private var canSaveJournalEntry: Bool {
        !draftDua.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !draftReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveJournalEntry(editing entry: DailyJournalEntry? = nil) async {
        guard canSaveJournalEntry else { return }
        isSavingEntry = true
        saveMessage = nil

        if let entry {
            var updatedEntry = entry
            updatedEntry.duaText = draftDua.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedEntry.noteText = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedEntry.reflectionText = draftReflection.trimmingCharacters(in: .whitespacesAndNewlines)
            storage.updateJournalEntry(updatedEntry)
        } else {
            storage.addJournalEntry(
                duaText: draftDua.trimmingCharacters(in: .whitespacesAndNewlines),
                noteText: draftNote.trimmingCharacters(in: .whitespacesAndNewlines),
                reflectionText: draftReflection.trimmingCharacters(in: .whitespacesAndNewlines),
                mood: .huzurlu,
                attachedCounterID: storage.counters.first?.id
            )
        }

        draftDua = ""
        draftNote = ""
        draftReflection = ""
        saveMessage = entry == nil
            ? L10n.string(.dailyJournalEntryAdded)
            : L10n.string(.dailyJournalEntryUpdated)
        saveTrigger.toggle()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        showNotesSheet = false
        editingEntry = nil

        if isPremium && storage.profile.cloudSyncEnabled {
            await CloudSyncService.shared.uploadToCloud(storage: storage)
        }

        isSavingEntry = false
    }

    private func deleteJournalEntry(_ id: String) async {
        storage.deleteJournalEntry(id: id)
        saveMessage = L10n.string(.dailyJournalEntryDeleted)
        if isPremium && storage.profile.cloudSyncEnabled {
            await CloudSyncService.shared.uploadToCloud(storage: storage)
        }
    }

    // MARK: - Achievement Card

    private func generateAndShare() {
        Task {
            guard !isGeneratingCard else { return }
            isGeneratingCard = true
            dailyShareQuote = IslamicWorkCompletionQuotePool.quote(for: Date())
            isGeneratingCard = false
            showDailySharePreview = true
        }
    }

    private func makeDailyShareCardType() -> ShareCardType {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        return .islamicDaily(
            IslamicDailyShareCardContent(
                title: L10n.string(.islamiGunluk),
                dateText: dateFormatter.string(from: Date()),
                progress: dailyWorshipProgress,
                progressLabel: L10n.string(.dhikrDailyProgressTitle),
                metrics: [
                    ShareMetric(value: dailyDhikrMetricValue, label: String(localized: "daily_dhikr_metric_title", defaultValue: "Zikir"), icon: "number.circle.fill"),
                    ShareMetric(value: dailyHabitMetricValue, label: String(localized: "daily_habit_metric_title", defaultValue: "Alışkanlık"), icon: "checklist.checked"),
                    ShareMetric(value: L10n.format(.daysCountFormat, Int64(storage.maneviStreak)), label: L10n.string(.widgetStreakTitle), icon: "flame.fill")
                ],
                quoteText: dailyShareQuote.text,
                quoteReference: dailyShareQuote.reference,
                brandingTitle: AppName.full,
                brandingSubtitle: ShareCardBranding.storeSubtitle
            )
        )
    }
}

struct ExploreCardView: View {
    enum DisplayState: Equatable {
        case loading
        case empty
        case loaded
    }

    let state: DisplayState
    let mosqueCount: Int
    let shrineCount: Int
    let historicalCount: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var didAppear: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.string(.exploreCardTitle))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Group {
                        switch state {
                        case .loading:
                            Text(L10n.string(.exploreCardLoading))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        case .empty:
                            Text(L10n.string(.exploreCardEmpty))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        case .loaded:
                            VStack(alignment: .leading, spacing: 6) {
                                exploreCountRow("🕌", count: mosqueCount, title: L10n.string(.exploreCardCategoryMosques))
                                exploreCountRow("🪦", count: shrineCount, title: L10n.string(.exploreCardCategoryShrines))
                                exploreCountRow("🏛️", count: historicalCount, title: L10n.string(.exploreCardCategoryHistoricalPlaces))
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Text(L10n.string(.exploreCardCTA))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(ctaColor)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ctaColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer(minLength: 10)

                ZStack {
                    Circle()
                        .fill(Color(red: 0.77, green: 0.91, blue: 0.86).opacity(0.38))
                        .frame(width: 52, height: 52)
                    Circle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.56))
                        .frame(width: 36, height: 36)
                    Image(systemName: "map.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ctaColor)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.66), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .scaleEffect(didAppear ? 1 : 0.98)
        .opacity(didAppear ? 1 : 0)
        .onAppear {
            guard !didAppear else { return }
            withAnimation(.easeOut(duration: 0.24)) {
                didAppear = true
            }
        }
    }

    private func exploreCountRow(_ icon: String, count: Int, title: String) -> some View {
        Text("\(icon) \(L10n.format(.exploreCardCountFormat, Int64(count), title))")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var cardGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.24, blue: 0.22).opacity(0.92),
                    Color(red: 0.10, green: 0.18, blue: 0.20).opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.84, green: 0.95, blue: 0.91).opacity(0.92),
                Color(red: 0.95, green: 0.98, blue: 0.97).opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var ctaColor: Color {
        colorScheme == .dark
            ? Color(red: 0.52, green: 0.86, blue: 0.76)
            : Color(red: 0.12, green: 0.49, blue: 0.40)
    }
}

private struct DailyDiyanetSpotlightCard: View, Equatable {
    let record: DiyanetKnowledgeRecord

    @Environment(\.colorScheme) private var colorScheme
    private let cornerRadius: CGFloat = 28
    private let contentPadding: CGFloat = 22

    static func == (lhs: DailyDiyanetSpotlightCard, rhs: DailyDiyanetSpotlightCard) -> Bool {
        lhs.record == rhs.record
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundGradient)

            decorativeGlow

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.16))

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(colorScheme == .dark ? 0.14 : 0.42))
                            .frame(width: 46, height: 46)

                        Image("diyanetlogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bugünün Diyanet seçkisi")
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(primaryTextColor)

                        Text("Resmi kaynak • her gün yenilenir")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(secondaryTextColor)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(secondaryTextColor)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        spotlightTag(record.type.displayName, tint: accentColor, emphasis: true)

                        if !record.topCategory.isEmpty {
                            spotlightTag(record.topCategory, tint: accentColor.opacity(0.82), emphasis: false)
                        }
                    }

                    Text(record.displayTitle)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(primaryTextColor)
                        .lineLimit(3)

                    Text(record.previewText)
                        .font(.system(.body, design: .serif).weight(.medium))
                        .foregroundStyle(primaryTextColor)
                        .lineSpacing(5)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    Capsule()
                        .fill(accentColor.opacity(colorScheme == .dark ? 0.84 : 0.70))
                        .frame(width: 24, height: 4)

                    Text("Dokununca resmi içeriğin detayına gider.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryTextColor)
                }
            }
            .padding(contentPadding)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(colorScheme == .dark ? 0.14 : 0.38), lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: 22, x: 0, y: 14)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.06, green: 0.12, blue: 0.18),
                    Color(red: 0.07, green: 0.24, blue: 0.30),
                    Color(red: 0.17, green: 0.15, blue: 0.10)
                ]
                : [
                    Color(red: 0.93, green: 0.98, blue: 0.99),
                    Color(red: 0.84, green: 0.94, blue: 0.95),
                    Color(red: 0.97, green: 0.93, blue: 0.84)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var decorativeGlow: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.45, green: 0.84, blue: 0.84).opacity(colorScheme == .dark ? 0.20 : 0.34))
                .frame(width: 220, height: 220)
                .blur(radius: 20)
                .offset(x: -80, y: -96)

            Circle()
                .fill(Color(red: 0.99, green: 0.84, blue: 0.55).opacity(colorScheme == .dark ? 0.16 : 0.28))
                .frame(width: 180, height: 180)
                .blur(radius: 22)
                .offset(x: 150, y: 110)
        }
    }

    private var accentColor: Color {
        colorScheme == .dark
            ? Color(red: 0.84, green: 0.94, blue: 0.84)
            : Color(red: 0.09, green: 0.45, blue: 0.44)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.10, green: 0.16, blue: 0.18)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.78)
            : Color(red: 0.16, green: 0.27, blue: 0.28).opacity(0.78)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.28)
            : Color(red: 0.33, green: 0.48, blue: 0.50).opacity(0.18)
    }

    private func spotlightTag(_ title: String, tint: Color, emphasis: Bool) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(emphasis ? dailyTagForegroundColor : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                (emphasis ? tint.opacity(colorScheme == .dark ? 0.26 : 0.18) : tint.opacity(colorScheme == .dark ? 0.12 : 0.08))
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.28 : 0.16), lineWidth: 1)
            )
    }

    private var dailyTagForegroundColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.10, green: 0.16, blue: 0.18)
    }
}

private struct DailyDiyanetStateCard: View {
    let title: String
    let message: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemBackground))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.teal.opacity(colorScheme == .dark ? 0.16 : 0.10),
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.02 : 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .padding(22)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(colorScheme == .dark ? 0.10 : 0.34), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 20, x: 0, y: 12)
    }
}
