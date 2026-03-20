import SwiftUI
import WidgetKit

struct RootTabContainer: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase

    let authService: AuthService
    let subscriptionAccess: SubscriptionStore.AccessLevel
    let subscriptionStore: SubscriptionStore

    @State private var storage = StorageService()
    @StateObject private var ayahAudioPlayerService: AyahAudioPlayerService

    private var theme: ActiveTheme { themeManager.current }

    init(
        authService: AuthService,
        subscriptionAccess: SubscriptionStore.AccessLevel,
        subscriptionStore: SubscriptionStore
    ) {
        self.authService = authService
        self.subscriptionAccess = subscriptionAccess
        self.subscriptionStore = subscriptionStore
        _ayahAudioPlayerService = StateObject(
            wrappedValue: AyahAudioPlayerService(isPremiumUser: subscriptionAccess == .premium)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let bottomAdOffset = currentBottomAdOffset
            let rabiaBottomPadding = proxy.safeAreaInsets.bottom + 72 + bottomAdOffset

            ZStack(alignment: .bottomTrailing) {
                theme.backgroundView
                    .ignoresSafeArea()

                FloatingTabBarBackdrop(
                    theme: theme,
                    containerWidth: proxy.size.width,
                    bottomInset: proxy.safeAreaInsets.bottom
                )

                TabView(selection: $appState.selectedTab) {
                    Tab(AppTab.daily.title, systemImage: AppTab.daily.systemImage, value: .daily) {
                        GunlukView(
                            storage: storage,
                            authService: authService,
                            onNavigateToTab: { appState.selectTab($0) }
                        )
                    }

                    Tab(AppTab.dhikrs.title, systemImage: AppTab.dhikrs.systemImage, value: .dhikrs) {
                        DhikrView(
                            storage: storage,
                            authService: authService,
                            onGoHome: { appState.selectTab(.daily) }
                        )
                    }

                    Tab(AppTab.guide.title, systemImage: AppTab.guide.systemImage, value: .guide) {
                        ZikirRehberiView(storage: storage, authService: authService) {
                            appState.selectTab(.dhikrs)
                        }
                    }

                    Tab(AppTab.quran.title, systemImage: AppTab.quran.systemImage, value: .quran) {
                        KuranView(storage: storage, authService: authService)
                    }

                    Tab(AppTab.more.title, systemImage: AppTab.more.systemImage, value: .more) {
                        MoreDashboardView(
                            storage: storage,
                            authService: authService,
                            subscriptionStore: subscriptionStore
                        )
                    }
                }
                .background(Color.clear)
                .tint(theme.accent)
                .toolbarBackground(theme.navBarBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
                .toolbarBackground(.hidden, for: .tabBar)
                .toolbarColorScheme(theme.colorScheme, for: .tabBar)
                .animation(.easeInOut(duration: 0.18), value: theme.runtimeSignature)

                if appState.selectedTab != .quran {
                    ManeviAssistantOverlayView(
                        authService: authService,
                        bottomPadding: rabiaBottomPadding
                    )
                }
            }
        }
        .environmentObject(ayahAudioPlayerService)
        .sheet(item: premiumPromptBinding) { prompt in
            QuranAudioPremiumUpsellSheet(prompt: prompt, authService: authService)
        }
        .sheet(item: $appState.presentedLegalDocument) { documentType in
            NavigationStack {
                LegalDocumentView(documentType: documentType)
            }
            .id(themeManager.navigationRefreshID)
            .tint(theme.accent)
            .toolbarBackground(theme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        }
        .sheet(item: $appState.presentedNotificationDestination) { destination in
            NavigationStack {
                notificationDestinationView(destination)
            }
            .id(themeManager.navigationRefreshID)
            .tint(theme.accent)
            .toolbarBackground(theme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        }
        .onAppear {
            storage.switchToUserScope(authService.currentUser?.id)
            WatchConnectivityService.shared.connect(storage: storage)
            ayahAudioPlayerService.updatePremiumAccess(isPremium: authService.isPremium)
            ayahAudioPlayerService.handleScenePhaseChange(scenePhase)
        }
        .onChange(of: theme.runtimeSignature) { _, _ in
            themeManager.applyGlobalAppearance(using: systemColorScheme)
        }
        .onChange(of: authService.isLoggedIn) { _, isLoggedIn in
            storage.switchToUserScope(authService.currentUser?.id)
            if isLoggedIn && authService.isPremium && storage.profile.cloudSyncEnabled {
                Task { await CloudSyncService.shared.syncFromCloud(storage: storage) }
            }
        }
        .onChange(of: authService.currentUser?.id) { _, newUserID in
            storage.switchToUserScope(newUserID)
            if authService.isLoggedIn && authService.isPremium && storage.profile.cloudSyncEnabled {
                Task { await CloudSyncService.shared.syncFromCloud(storage: storage) }
            }
        }
        .onChange(of: authService.isPremium) { _, isPremium in
            ayahAudioPlayerService.updatePremiumAccess(isPremium: isPremium)
        }
        .onChange(of: scenePhase) { _, newPhase in
            ayahAudioPlayerService.handleScenePhaseChange(newPhase)
            if newPhase == .active {
                WatchConnectivityService.shared.syncNow()
                Task {
                    await syncWidgetData()
                }
            }
        }
        .onChange(of: storage.counters) { _, _ in
            WatchConnectivityService.shared.syncNow()
        }
        .onChange(of: storage.selectedCounterID) { _, _ in
            WatchConnectivityService.shared.syncNow()
        }
        .onChange(of: storage.todayStats().totalCount) { _, _ in
            WatchConnectivityService.shared.syncNow()
        }
        .onChange(of: storage.profile.dailyGoal) { _, _ in
            WatchConnectivityService.shared.syncNow()
        }
        .onChange(of: storage.profile.currentStreak) { _, _ in
            WatchConnectivityService.shared.syncNow()
        }
        .onChange(of: storage.activeZikrSession) { _, _ in
            WatchConnectivityService.shared.syncNow()
        }
        .task {
            await ServiceContainer.shared.notificationLifecycleCoordinator.handleSceneDidBecomeActive(premiumEnabled: authService.isPremium)
            await syncWidgetData()
            WatchConnectivityService.shared.syncNow()
            if authService.isPremium && storage.profile.cloudSyncEnabled {
                await CloudSyncService.shared.syncFromCloud(storage: storage)
            }
        }
    }

    private var premiumPromptBinding: Binding<QuranAudioPremiumPrompt?> {
        Binding(
            get: { ayahAudioPlayerService.premiumPrompt },
            set: { if $0 == nil { ayahAudioPlayerService.dismissPremiumPrompt() } }
        )
    }

    private var currentBottomAdOffset: CGFloat {
        0
    }

    @ViewBuilder
    private func notificationDestinationView(_ destination: AppNotificationDestination) -> some View {
        switch destination {
        case .dailyDua:
            ListelerView(storage: storage, authService: authService)
        case .fridayContent:
            KhutbahView()
        case .specialDay(_, let title):
            NotificationSpecialDayView(title: title ?? "Özel Gün")
        case .notificationSettings:
            NotificationSettingsView()
        }
    }

    private func syncWidgetData() async {
        SharedDefaults.updateZikirProgress(
            dailyCount: storage.todayStats().totalCount,
            dailyGoal: storage.profile.dailyGoal,
            streak: storage.profile.currentStreak
        )

        let wisdoms = [
            L10n.string(.dailyWisdom1),
            L10n.string(.dailyWisdom2),
            L10n.string(.dailyWisdom3),
            L10n.string(.dailyWisdom4),
            L10n.string(.dailyWisdom5),
            L10n.string(.dailyWisdom6),
            L10n.string(.dailyWisdom7),
            L10n.string(.dailyWisdom8),
            L10n.string(.dailyWisdom9),
            L10n.string(.dailyWisdom10)
        ]
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        SharedDefaults.updateDailyWisdom(wisdoms[dayIndex % wisdoms.count])

        if let verse = DailyVerseProvider.shared.verseForDate(Date()) {
            SharedDefaults.updateDailyVerse(
                metadata: verse.metadataText,
                text: normalizeWidgetText(verse.translation),
                source: normalizedOptionalText(verse.translationSource)
            )
        }

        do {
            let hadith = try await DailyHadithProvider.shared.shortHadithForDate(Date())
            SharedDefaults.updateDailyHadith(
                title: hadith.title,
                text: normalizeWidgetText(hadith.shortCardText ?? hadith.title),
                attribution: normalizedOptionalText(hadith.attribution ?? hadith.grade),
                language: hadith.language
            )
        } catch {
            #if DEBUG
            print("Daily hadith widget sync failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func normalizeWidgetText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedOptionalText(_ text: String?) -> String? {
        guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return normalizeWidgetText(value)
    }
}

private struct FloatingTabBarBackdrop: View {
    let theme: ActiveTheme
    let containerWidth: CGFloat
    let bottomInset: CGFloat

    var body: some View {
        let width = min(max(containerWidth - 18, 0), 520)

        ZStack(alignment: .bottom) {
            Capsule()
                .fill(theme.glow.opacity(theme.isDarkMode ? 0.20 : 0.12))
                .frame(width: width * 0.84, height: 58)
                .blur(radius: 26)
                .offset(y: -max(bottomInset, 10) - 6)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.elevatedBackground.opacity(theme.isDarkMode ? 0.78 : 0.74),
                            theme.cardBackground.opacity(theme.isDarkMode ? 0.62 : 0.68)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.22), lineWidth: 1)
                )
                .frame(width: width, height: 74 + bottomInset)
                .padding(.horizontal, max((containerWidth - width) / 2, 0))
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
}
