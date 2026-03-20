import SwiftUI
import UIKit

struct PrayerScreen: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let storage: StorageService

    @State private var viewModel = PrayerTimesViewModel.shared
    @State private var settings = PrayerSettings()
    @State private var showLocationPicker: Bool = false
    @State private var showPreferences: Bool = false
    @State private var showQibla: Bool = false
    @State private var qadaCenterContext: PrayerQadaCenterContext?
    @State private var selectedPrayer: PrayerName?
    @State private var spiritualRoute: PrayerSpiritualContentRoute?
    @Namespace private var spiritualTransition

    private let initialSelectedPrayer: PrayerName?

    init(storage: StorageService, selectedPrayer: PrayerName? = nil) {
        self.storage = storage
        self.initialSelectedPrayer = selectedPrayer
        _selectedPrayer = State(initialValue: selectedPrayer)
    }

    private var theme: ActiveTheme { themeManager.current }
    private var tokens: PrayerTimesThemeTokens { theme.prayerTimesTokens }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.navBarBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        .navigationDestination(item: $spiritualRoute) { route in
            PrayerSpiritualContentView(route: route)
                .navigationTransition(.zoom(sourceID: route.prayer, in: spiritualTransition))
        }
        .navigationDestination(item: $qadaCenterContext) { context in
            PrayerQadaCenterView(storage: storage, context: context)
        }
        .sheet(isPresented: $showLocationPicker) {
            PrayerLocationPickerView(viewModel: viewModel)
        }
        .sheet(isPresented: $showPreferences) {
            PrayerPreferencesView(settings: settings)
        }
        .sheet(isPresented: $showQibla) {
            QiblaView()
        }
        .task {
            viewModel.refresh()
            _ = SpiritualContentProvider.prefetchDailyContent(
                for: PrayerName.allCases,
                date: Date()
            )
            await viewModel.rescheduleNotificationsIfPossible()
        }
        .task(id: viewModel.tomorrowPrayerTimes?.fajr) {
            scheduleQadaReminderIfNeeded()
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        GeometryReader { proxy in
            let prayerState = PrayerViewModel(
                liveViewModel: viewModel,
                settings: settings,
                now: now,
                selectedPrayer: selectedPrayer
            )
            let heroHeight = min(max(proxy.size.height * 0.54, 420), 540)
            let completionStatuses = storage.prayerCompletionMap(for: now)
            let dailyProgress = storage.dailyPrayerProgress(on: now)
            let weeklyHistory = storage.weeklyPrayerHistory(endingOn: now)

            ScrollView(showsIndicators: false) {
                VStack(spacing: PrayerTimesThemeMetrics.sectionSpacing) {
                    if let prayerState {
                        PrayerHeroStageView(
                            viewModel: prayerState,
                            now: now,
                            heroHeight: heroHeight,
                            selectedPrayer: $selectedPrayer,
                            transitionNamespace: spiritualTransition,
                            onTap: { prayer in
                                openSpiritualContent(for: prayer, in: prayerState, date: now)
                            }
                        )

                        PrayerDayRhythmStripSection(
                            items: prayerState.items,
                            selectedPrayer: selectedPrayer,
                            onSelectPrayer: selectPrayer
                        )

                        PrayerDailyProgressSection(progress: dailyProgress)

                        PrayerTodayPrayerListSection(
                            viewModel: prayerState,
                            selectedPrayer: selectedPrayer,
                            completionStatuses: completionStatuses,
                            onSelectPrayer: selectPrayer,
                            onChangeCompletion: updateCompletionStatus
                        )

                        PrayerWeeklyHistorySection(
                            days: weeklyHistory,
                            onOpenQada: openQadaCenter
                        )
                        
                        PrayerExpandedExtrasSection(
                            title: prayerState.extrasSectionTitle,
                            subtitle: prayerState.extrasSectionSubtitle,
                            modules: prayerState.extraModules,
                            onTapModule: openExtraModule
                        )

                        PrayerSecondaryToolsSection(
                            items: prayerState.toolItems,
                            onOpenPreferences: { showPreferences = true },
                            onOpenQibla: { showQibla = true },
                            onOpenLocation: { showLocationPicker = true }
                        )
                    } else if viewModel.isLoading {
                        loadingState
                    } else if let message = viewModel.errorMessage {
                        errorState(message)
                    } else {
                        loadingState
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 36)
            }
            .background(
                PrayerExperienceBackground(
                    theme: theme,
                    tokens: tokens,
                    accentPrayer: prayerState?.displayedPrayer.id ?? .isha
                )
                .ignoresSafeArea()
            )
        }
        .onAppear {
            if let initialSelectedPrayer {
                selectedPrayer = initialSelectedPrayer
            }
        }
    }

    private func selectPrayer(_ prayer: PrayerName) {
        withAnimation(.easeInOut(duration: 0.24)) {
            selectedPrayer = prayer
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func openSpiritualContent(for prayer: PrayerName, in viewModel: PrayerViewModel, date: Date) {
        guard let item = viewModel.items.first(where: { $0.id == prayer }) else { return }
        selectedPrayer = prayer
        spiritualRoute = PrayerSpiritualContentRoute(item: item, date: date)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func updateCompletionStatus(for prayer: PrayerName, status: PrayerCompletionStatus) {
        guard prayer.isObligatory else { return }

        withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
            storage.setPrayerCompletionStatus(status, for: prayer)
        }

        scheduleQadaReminderIfNeeded()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func openQadaCenter(for day: PrayerHistoryDay? = nil) {
        let context = PrayerQadaCenterContext(
            sourceDate: day?.date,
            suggestedPrayers: day?.missedPrayers ?? []
        )
        qadaCenterContext = context
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func openExtraModule(_ module: PrayerExtraModule) {
        switch module.id {
        case "qada":
            openQadaCenter()
        default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func scheduleQadaReminderIfNeeded() {
        let missedPrayers = storage.missedPrayers()
        let tomorrowFajr = viewModel.tomorrowPrayerTimes?.fajr

        Task {
            await PrayerQadaReminderScheduler().rescheduleReminder(
                for: Date(),
                missedPrayers: missedPrayers,
                nextMorningDate: tomorrowFajr
            )
        }
    }

    private var loadingState: some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens, padding: 28) {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(tokens.actionIconTint)
                    .scaleEffect(1.2)
                Text(L10n.string(.namazVakitleriYukleniyor))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }

    private func errorState(_ message: String) -> some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens, padding: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Label(
                    String(localized: "prayer_error_title", defaultValue: "Namaz alanı şu an açılamadı"),
                    systemImage: "antenna.radiowaves.left.and.right.slash"
                )
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(theme.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)

                Button {
                    viewModel.refresh()
                } label: {
                    Text(L10n.string(.tekrarDene2))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
        }
    }
}

struct PrayerHeaderView: View {
    let viewModel: PrayerViewModel
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption.weight(.semibold))
                    Text(viewModel.locationName)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(.primary)

                Text(viewModel.gregorianDateText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(viewModel.weekdayText)
                    if !viewModel.hijriDateText.isEmpty {
                        Text("•")
                        Text(viewModel.hijriDateText)
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onOpenSettings) {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(viewModel.sourceText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text(viewModel.calculationText)
                            .font(.caption)
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

struct PrayerMainHeroCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let viewModel: PrayerViewModel
    let onOpenQibla: () -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: viewModel.displayedPrayer.id, theme: theme)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(style.heroGradient)

            Circle()
                .fill(style.glow)
                .frame(width: 240, height: 240)
                .blur(radius: 28)
                .offset(x: -90, y: -120)

            Circle()
                .fill(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.14))
                .frame(width: 200, height: 200)
                .blur(radius: 28)
                .offset(x: 170, y: 110)

            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.heroEyebrow)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.82))
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(viewModel.displayedPrayer.localizedName)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(viewModel.heroStatusText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.84))
                            .contentTransition(.numericText())
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 10) {
                        Text(viewModel.displayedPrayer.formattedTime)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        PrayerIconView(assetName: viewModel.displayedPrayer.iconType, size: 28)
                            .opacity(0.96)
                    }
                }

                PrayerMicroMessageView(
                    text: viewModel.heroMessage,
                    foregroundStyle: Color.white.opacity(0.92),
                    backgroundStyle: Color.white.opacity(0.10)
                )

                HStack(spacing: 10) {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        PrayerHeroActionCapsule(
                            title: String(localized: "prayer_action_notifications", defaultValue: "Hatırlatıcılar"),
                            icon: "bell.badge"
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onOpenQibla) {
                        PrayerHeroActionCapsule(
                            title: String(localized: "prayer_action_qibla", defaultValue: "Kıble"),
                            icon: "location.north.line"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.16 : 0.28), lineWidth: 1)
        )
        .shadow(color: style.glow.opacity(theme.isDarkMode ? 0.30 : 0.18), radius: 24, x: 0, y: 16)
    }
}

struct PrayerDayProgressView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let items: [PrayerDisplayItem]
    let currentPrayerID: PrayerName

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens) {
            VStack(alignment: .leading, spacing: 18) {
                Text(String(localized: "prayer_day_progress_title", defaultValue: "Günün ritmi"))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)

                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        PrayerProgressNode(
                            item: item,
                            isCurrent: item.id == currentPrayerID
                        )

                        if index < items.count - 1 {
                            Rectangle()
                                .fill(connectorColor(after: item))
                                .frame(maxWidth: .infinity)
                                .frame(height: 2)
                                .padding(.horizontal, 4)
                        }
                    }
                }
            }
        }
    }

    private func connectorColor(after item: PrayerDisplayItem) -> Color {
        switch item.state {
        case .past:
            return theme.textSecondary.opacity(0.28)
        case .current:
            return Color.white.opacity(theme.isDarkMode ? 0.55 : 0.48)
        case .upcoming:
            return theme.textSecondary.opacity(0.16)
        }
    }
}

struct PrayerListSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let viewModel: PrayerViewModel
    let selectedPrayer: PrayerName?
    let onSelectPrayer: (PrayerName) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.listSectionTitle)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text(viewModel.listSectionSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.items) { item in
                        PrayerRowView(
                            item: item,
                            isSelected: selectedPrayer == item.id,
                            onTap: { onSelectPrayer(item.id) }
                        )
                    }
                }
            }
        }
    }
}

struct PrayerRowView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let item: PrayerDisplayItem
    let isSelected: Bool
    let onTap: () -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: item.id, theme: theme)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 52, height: 52)

                    PrayerIconView(assetName: item.iconType, size: 28)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.localizedName)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(labelColor)

                    Text(stateLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(item.formattedTime)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(labelColor)

                    if item.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(style.accent.opacity(0.92))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(backgroundShape)
            .overlay(borderShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.localizedName), \(item.formattedTime), \(stateLabel)")
    }

    private var labelColor: Color {
        item.state == .current ? .white : theme.textPrimary
    }

    private var iconForeground: Color {
        item.state == .current ? .white : style.accent
    }

    private var iconBackground: Color {
        item.state == .current
            ? Color.white.opacity(0.14)
            : style.glow.opacity(theme.isDarkMode ? 0.22 : 0.18)
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                item.state == .current
                    ? AnyShapeStyle(style.heroGradient)
                    : AnyShapeStyle(theme.cardBackground.opacity(theme.isDarkMode ? 0.72 : 0.92))
            )
    }

    private var borderShape: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(
                isSelected
                    ? style.ring.opacity(theme.isDarkMode ? 0.92 : 0.76)
                    : theme.border.opacity(theme.isDarkMode ? 0.36 : 0.48),
                lineWidth: isSelected ? 1.2 : 1
            )
    }

    private var stateLabel: String {
        switch item.state {
        case .past:
            return String(localized: "prayer_row_state_past", defaultValue: "Geçti")
        case .current:
            return String(localized: "prayer_row_state_current", defaultValue: "Şu an aktif")
        case .upcoming:
            return String(localized: "prayer_row_state_upcoming", defaultValue: "Yaklaşıyor")
        }
    }
}

struct PrayerToolShortcutRow: View {
    let items: [PrayerToolItem]
    let theme: ActiveTheme
    let tokens: PrayerTimesThemeTokens
    let onOpenPreferences: () -> Void
    let onOpenQibla: () -> Void
    let onOpenLocation: () -> Void

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens) {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "prayer_tools_section_title", defaultValue: "Araçlar ve ayarlar"))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            switch item.kind {
                            case .notifications:
                                NavigationLink {
                                    NotificationSettingsView()
                                } label: {
                                    PrayerToolShortcutCard(item: item, theme: theme)
                                }
                                .buttonStyle(.plain)
                            case .qibla:
                                Button(action: onOpenQibla) {
                                    PrayerToolShortcutCard(item: item, theme: theme)
                                }
                                .buttonStyle(.plain)
                            case .location:
                                Button(action: onOpenLocation) {
                                    PrayerToolShortcutCard(item: item, theme: theme)
                                }
                                .buttonStyle(.plain)
                            case .calculation:
                                Button(action: onOpenPreferences) {
                                    PrayerToolShortcutCard(item: item, theme: theme)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PrayerExtrasSection: View {
    let title: String
    let subtitle: String
    let modules: [PrayerExtraModule]
    let theme: ActiveTheme
    let tokens: PrayerTimesThemeTokens

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(modules) { module in
                        PrayerExtraModuleCard(module: module, theme: theme)
                    }
                }
            }
        }
    }
}

struct PrayerPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @Bindable var settings: PrayerSettings

    private var theme: ActiveTheme { themeManager.current }
    private var tokens: PrayerTimesThemeTokens { theme.prayerTimesTokens }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    PrayerSurfaceCard(theme: theme, tokens: tokens, padding: 22) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(String(localized: "prayer_preferences_title", defaultValue: "Namaz tercihleri"))
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(theme.textPrimary)

                            Text(String(localized: "prayer_preferences_subtitle", defaultValue: "Hesaplama yöntemi ve mezhep seçimi vakit görünümünü anında yeniler."))
                                .font(.subheadline)
                                .foregroundStyle(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    PrayerSurfaceCard(theme: theme, tokens: tokens) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(String(localized: "prayer_preferences_method_section", defaultValue: "Hesaplama yöntemi"))
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(theme.textPrimary)

                            PrayerPreferenceOptionRow(
                                title: String(localized: "prayer_preferences_diyanet_title", defaultValue: "Diyanet vakitleri"),
                                subtitle: String(localized: "prayer_preferences_diyanet_subtitle", defaultValue: "Türkiye odağındaki namaz alanında vakitler Diyanet çizgisine göre gösterilir."),
                                isSelected: true,
                                action: {}
                            )
                        }
                    }

                    PrayerSurfaceCard(theme: theme, tokens: tokens) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(String(localized: "prayer_preferences_madhab_section", defaultValue: "İkindi hesabı"))
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(theme.textPrimary)

                            VStack(spacing: 10) {
                                ForEach(PrayerMadhab.allCases, id: \.self) { madhab in
                                    PrayerPreferenceOptionRow(
                                        title: madhab == .shafi
                                            ? String(localized: "prayer_preferences_madhab_shafi", defaultValue: "Şafii")
                                            : String(localized: "prayer_preferences_madhab_hanafi", defaultValue: "Hanefi"),
                                        subtitle: madhab == .shafi
                                            ? String(localized: "prayer_preferences_madhab_shafi_subtitle", defaultValue: "Standart ikindi hesabı")
                                            : String(localized: "prayer_preferences_madhab_hanafi_subtitle", defaultValue: "Hanefi ikindi hesabı"),
                                        isSelected: madhab == settings.madhab,
                                        action: { settings.madhab = madhab }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .background(
                PrayerExperienceBackground(
                    theme: theme,
                    tokens: tokens,
                    accentPrayer: .isha
                )
                .ignoresSafeArea()
            )
            .navigationTitle(String(localized: "prayer_preferences_nav_title", defaultValue: "Tercihler"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common_done", defaultValue: "Bitti")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PrayerPreferenceOptionRow: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.accent : theme.textSecondary.opacity(0.56))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                theme.cardBackground.opacity(theme.isDarkMode ? 0.72 : 0.94),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected
                            ? theme.accent.opacity(theme.isDarkMode ? 0.72 : 0.56)
                            : theme.border.opacity(theme.isDarkMode ? 0.28 : 0.44),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PrayerProgressNode: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let item: PrayerDisplayItem
    let isCurrent: Bool

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: item.id, theme: theme)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(nodeBackground)
                    .frame(width: isCurrent ? 18 : 12, height: isCurrent ? 18 : 12)

                if isCurrent {
                    Circle()
                        .stroke(style.ring.opacity(0.85), lineWidth: 3)
                        .frame(width: 28, height: 28)
                }
            }

            Text(item.localizedName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(labelColor)
                .lineLimit(1)

            Text(item.formattedTime)
                .font(.caption2)
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var nodeBackground: Color {
        switch item.state {
        case .past:
            return theme.textSecondary.opacity(0.32)
        case .current:
            return style.ring
        case .upcoming:
            return theme.textSecondary.opacity(0.18)
        }
    }

    private var labelColor: Color {
        item.state == .current ? theme.textPrimary : theme.textSecondary
    }
}

private struct PrayerHeroActionCapsule: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.10), in: Capsule())
    }
}

private struct PrayerToolShortcutCard: View {
    let item: PrayerToolItem
    let theme: ActiveTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.selectionBackground.opacity(theme.isDarkMode ? 0.72 : 0.88))
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }

            Text(item.title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)

            Text(item.subtitle)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(width: 184, alignment: .leading)
        .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.72 : 0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.30 : 0.48), lineWidth: 1)
        )
    }
}

private struct PrayerExtraModuleCard: View {
    let module: PrayerExtraModule
    let theme: ActiveTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.selectionBackground.opacity(theme.isDarkMode ? 0.68 : 0.86))
                    .frame(width: 42, height: 42)
                Image(systemName: module.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }

            Text(module.title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)

            Text(module.subtitle)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.72 : 0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.30 : 0.46), lineWidth: 1)
        )
    }
}

private struct PrayerExperienceBackground: View {
    let theme: ActiveTheme
    let tokens: PrayerTimesThemeTokens
    let accentPrayer: PrayerName

    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: accentPrayer, theme: theme)
    }

    var body: some View {
        ZStack {
            PrayerScreenBackground(theme: theme, tokens: tokens)

            LinearGradient(
                colors: [style.glow.opacity(0.34), .clear],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            Circle()
                .fill(style.glow)
                .frame(width: 280, height: 280)
                .blur(radius: 42)
                .offset(x: 130, y: -250)

            Circle()
                .fill(style.accent.opacity(theme.isDarkMode ? 0.14 : 0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: -120, y: 120)
        }
    }
}

struct NamazVakitleriView: View {
    @State private var storage = StorageService()

    var body: some View {
        PrayerScreen(storage: storage)
    }
}

#Preview("PrayerScreen Fajr") {
    NavigationStack {
        PrayerScreen(storage: StorageService(), selectedPrayer: .fajr)
    }
    .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}

#Preview("PrayerScreen Asr") {
    NavigationStack {
        PrayerScreen(storage: StorageService(), selectedPrayer: .asr)
    }
    .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}

#Preview("PrayerScreen Isha") {
    NavigationStack {
        PrayerScreen(storage: StorageService(), selectedPrayer: .isha)
    }
    .environmentObject(ThemeManager.preview(theme: .nightMosque, appearanceMode: .dark))
}

#Preview("PrayerScreen Light") {
    NavigationStack {
        PrayerScreen(storage: StorageService(), selectedPrayer: .dhuhr)
    }
    .environmentObject(ThemeManager.preview(theme: .nightMosque, appearanceMode: .light))
}

#Preview("Prayer Row Current") {
    PrayerRowView(
        item: PrayerDisplayItem(
            id: .asr,
            localizedName: "İkindi",
            time: .now,
            formattedTime: "16:42",
            state: .current,
            endTime: nil,
            iconType: "prayer_icon_asr",
            reminderEnabled: true,
            gradientProfile: .afternoon,
            contextualMessageCandidates: ["Kalan vakti zikir ve şükürle tamamla"],
            completionState: nil
        ),
        isSelected: true,
        onTap: {}
    )
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}

#Preview("Prayer Row Upcoming Reminder Off") {
    PrayerRowView(
        item: PrayerDisplayItem(
            id: .isha,
            localizedName: "Yatsı",
            time: .now,
            formattedTime: "20:38",
            state: .upcoming,
            endTime: nil,
            iconType: "prayer_icon_isha",
            reminderEnabled: false,
            gradientProfile: .night,
            contextualMessageCandidates: ["Geceyi zikirle yumuşat"],
            completionState: nil
        ),
        isSelected: false,
        onTap: {}
    )
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager.preview(theme: .nightMosque, appearanceMode: .dark))
}
