import SwiftUI
import UIKit

struct DhikrView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var viewModel: CounterViewModel

    let storage: StorageService
    let authService: AuthService
    let onGoHome: () -> Void

    @State private var activeSession: ZikrSession?
    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showDetailsSheet = false
    @State private var showCalendarSheet = false
    @State private var calendarSelectedDate = Date()
    @State private var geminiService = GroqService()

    init(
        storage: StorageService,
        authService: AuthService,
        onGoHome: @escaping () -> Void
    ) {
        self.storage = storage
        self.authService = authService
        self.onGoHome = onGoHome
        _viewModel = State(initialValue: CounterViewModel(storage: storage))
    }

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        ZStack {
            ThemedSacredBackground(theme: theme)

            GeometryReader { proxy in
                let safeTop = max(proxy.safeAreaInsets.top, 12)
                let topBarLift: CGFloat = 24
                let topBarTopPadding = max(safeTop - topBarLift, 6)
                let topBarHeight: CGFloat = 44
                let topContentSpacing: CGFloat = 10
                let bottomUtilityReserve: CGFloat = 128
                let counterSize = min(proxy.size.width * 0.78, proxy.size.height * 0.40)
                let minContentHeight = max(
                    proxy.size.height - safeTop - topBarHeight - topContentSpacing - bottomUtilityReserve,
                    counterSize + 220
                )

                ZStack(alignment: .top) {
                    ScrollView(.vertical, showsIndicators: false) {
                        Group {
                            if let counter = viewModel.selectedCounter {
                                content(counter: counter, counterSize: counterSize)
                            } else {
                                DhikrEmptyState(
                                    theme: theme,
                                    onCreate: { viewModel.showNewCounterSheet = true },
                                    onOpenCalendar: { showCalendarSheet = true }
                                )
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: minContentHeight, alignment: .top)
                        .padding(.top, safeTop + topBarHeight + topContentSpacing)
                        .padding(.bottom, bottomUtilityReserve)
                    }

                    topBar
                        .padding(.top, topBarTopPadding)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $viewModel.showNewCounterSheet) {
            NewCounterSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showDetailsSheet) {
            if let counter = viewModel.selectedCounter {
                DhikrDetailsSheet(
                    motivationText: geminiService.zikirProgressAdvice(progress: counter.isFreeMode ? 0 : counter.progress),
                    dailyCount: storage.todayStats().totalCount,
                    dailyGoal: max(storage.profile.dailyGoal, 1),
                    streakCount: storage.profile.currentStreak,
                    streakMilestone: DhikrStreakService.shared.milestoneMessage()
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showCalendarSheet) {
            NavigationStack {
                DhikrCalendarView(selectedDate: $calendarSelectedDate, storage: storage)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert(
            DhikrScreenText.string(.resetConfirmationTitle),
            isPresented: $showResetConfirmation
        ) {
            Button(L10n.string(.commonClose), role: .cancel) {}
            Button(L10n.string(.dhikrReset), role: .destructive) {
                viewModel.reset()
            }
        } message: {
            Text(DhikrScreenText.string(.resetConfirmationMessage))
        }
        .alert(
            DhikrScreenText.string(.deleteConfirmationTitle),
            isPresented: $showDeleteConfirmation
        ) {
            Button(L10n.string(.commonClose), role: .cancel) {}
            Button(L10n.string(.sil2), role: .destructive) {
                viewModel.deleteSelected()
            }
        } message: {
            Text(DhikrScreenText.string(.deleteConfirmationMessage))
        }
        .overlay {
            if viewModel.showCompletionCard, let completed = viewModel.completedCounter {
                ZikirCompletionView(
                    counter: completed,
                    session: activeSession,
                    todayCount: storage.todayStats().totalCount,
                    streak: storage.profile.currentStreak,
                    onGoHome: {
                        viewModel.dismissCompletion()
                        onGoHome()
                    },
                    onDismiss: { viewModel.dismissCompletion() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: viewModel.showCompletionCard)
        .task {
            await authService.refreshPremiumStatus()
        }
        .onAppear {
            syncActiveSession()
        }
        .onChange(of: viewModel.selectedCounter?.id) { _, _ in
            syncActiveSession()
        }
        .onChange(of: storage.pendingSelectedCounterId) { _, newID in
            guard let newID, let counter = storage.counters.first(where: { $0.id == newID }) else { return }
            viewModel.selectCounter(counter)
            syncActiveSession()
            storage.pendingSelectedCounterId = nil
        }
        .onChange(of: storage.selectedCounterID) { _, _ in
            viewModel.refreshSelected()
            syncActiveSession()
        }
        .id(themeManager.navigationRefreshID)
    }

    @ViewBuilder
    private func content(counter: CounterModel, counterSize: CGFloat) -> some View {
        let context = presentationContext(for: counter)

        VStack(spacing: 0) {
            DhikrHeader(
                theme: theme,
                context: context,
                onInfo: { showDetailsSheet = true }
            )
            .padding(.horizontal, 20)
            .padding(.top, 6)

            Spacer(minLength: 12)

            DhikrCounterButton(
                theme: theme,
                counter: counter,
                context: context,
                diameter: counterSize,
                milestoneValue: viewModel.lastMilestoneValue,
                milestoneTrigger: viewModel.milestoneTrigger,
                onTap: { incrementCounter() }
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            VStack(spacing: 16) {
                DhikrStatsRow(
                    theme: theme,
                    todayCount: storage.todayStats().totalCount,
                    totalCount: storage.profile.totalLifetimeCount,
                    streakCount: storage.profile.currentStreak
                )
                .padding(.horizontal, 20)
                .padding(.top, 22)

                Spacer(minLength: 12)
            }

            Spacer(minLength: 0)
        }
        .safeAreaInset(edge: .bottom) {
            DhikrUtilityBar(
                theme: theme,
                selectedTarget: targetChoice(for: counter),
                isTargetSelectionEnabled: !counter.isMultiStep,
                vibrationEnabled: storage.profile.vibrationEnabled,
                soundEnabled: storage.profile.soundEnabled,
                onSelectTarget: { updateTarget($0, for: counter) },
                onReset: { requestReset(for: counter) },
                onToggleVibration: { toggleVibration() },
                onToggleSound: { toggleSound() }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            DhikrManageMenu(
                theme: theme,
                counters: storage.counters,
                selectedCounterID: viewModel.selectedCounter?.id,
                canUndo: (viewModel.selectedCounter?.totalStepsCompleted ?? 0) > 0,
                onSelectCounter: { viewModel.selectCounter($0) },
                onCreateNew: { viewModel.showNewCounterSheet = true },
                onUndo: { viewModel.undo() },
                onDeleteCurrent: {
                    if viewModel.selectedCounter != nil {
                        showDeleteConfirmation = true
                    }
                }
            )

            Spacer()

            DhikrCalendarButton(theme: theme, action: { showCalendarSheet = true })
        }
    }

    private func presentationContext(for counter: CounterModel) -> DhikrPresentationContext {
        if counter.isMultiStep, let step = counter.currentStep {
            return DhikrPresentationContext(
                eyebrow: String.localizedStringWithFormat(
                    DhikrScreenText.string(.stepHeaderFormat),
                    counter.currentStepIndex + 1,
                    counter.steps.count
                ),
                title: step.name,
                arabicText: step.arabicText,
                transliteration: step.transliteration,
                meaning: step.meaning,
                progressText: String.localizedStringWithFormat(
                    DhikrScreenText.string(.countFractionFormat),
                    counter.currentCount,
                    counter.currentStepTarget
                ),
                targetText: counter.currentStepTarget.formatted(.number),
                targetLabel: counter.currentStepTarget.formatted(.number),
                accessibilityTargetLabel: counter.currentStepTarget.formatted(.number)
            )
        }

        let session = activeSession ?? storage.session(for: counter)
        let title = session?.zikrTitle ?? counter.name
        let progressText: String
        let targetLabel: String
        let accessibilityTargetLabel: String

        if counter.isFreeMode {
            progressText = DhikrScreenText.string(.freeModeActive)
            targetLabel = DhikrScreenText.string(.freeTargetShort)
            accessibilityTargetLabel = DhikrScreenText.string(.freeTargetAccessibility)
        } else {
            progressText = String.localizedStringWithFormat(
                DhikrScreenText.string(.countFractionFormat),
                counter.currentCount,
                counter.targetCount
            )
            targetLabel = counter.targetCount.formatted(.number)
            accessibilityTargetLabel = counter.targetCount.formatted(.number)
        }

        return DhikrPresentationContext(
            eyebrow: session?.category,
            title: title,
            arabicText: session?.arabicText ?? "",
            transliteration: session?.transliteration ?? title,
            meaning: session?.meaning ?? "",
            progressText: progressText,
            targetText: targetLabel,
            targetLabel: targetLabel,
            accessibilityTargetLabel: accessibilityTargetLabel
        )
    }

    private func syncActiveSession() {
        if let counter = viewModel.selectedCounter {
            let session = storage.resolvedSession(for: counter)
            activeSession = session
            storage.setActiveZikrSession(session)
        } else {
            activeSession = nil
            storage.setActiveZikrSession(nil)
        }
    }

    private func incrementCounter() {
        viewModel.increment()
    }

    private func requestReset(for counter: CounterModel) {
        if counter.totalStepsCompleted > 0 {
            showResetConfirmation = true
        }
    }

    private func toggleVibration() {
        storage.profile.vibrationEnabled.toggle()
        storage.saveProfile()
    }

    private func toggleSound() {
        storage.profile.soundEnabled.toggle()
        storage.saveProfile()
    }

    private func targetChoice(for counter: CounterModel) -> DhikrTargetChoice {
        guard !counter.isMultiStep else { return .target(counter.targetCount) }
        if counter.isFreeMode {
            return .free
        }
        return .target(counter.targetCount)
    }

    private func updateTarget(_ choice: DhikrTargetChoice, for counter: CounterModel) {
        guard !counter.isMultiStep else { return }

        var updatedCounter = counter
        updatedCounter.targetCount = choice.persistedValue

        if choice.persistedValue > 0 {
            updatedCounter.isCompleted = updatedCounter.currentCount >= choice.persistedValue
        } else {
            updatedCounter.isCompleted = false
        }

        storage.updateCounter(updatedCounter)
        viewModel.refreshSelected()
    }
}

struct DhikrPresentationContext {
    let eyebrow: String?
    let title: String
    let arabicText: String
    let transliteration: String
    let meaning: String
    let progressText: String
    let targetText: String
    let targetLabel: String
    let accessibilityTargetLabel: String
}

enum DhikrTargetChoice: Hashable, CaseIterable {
    case target(Int)
    case free

    static var allCases: [DhikrTargetChoice] {
        [.target(33), .target(99), .target(100), .free]
    }

    var persistedValue: Int {
        switch self {
        case .target(let value):
            return value
        case .free:
            return 0
        }
    }

    func title(locale: Locale = .current) -> String {
        switch self {
        case .target(let value):
            return value.formatted(.number.locale(locale))
        case .free:
            return DhikrScreenText.string(.freeTargetShort)
        }
    }
}

struct ThemedSacredBackground: View {
    let theme: AppTheme

    var body: some View {
        let tokens = theme.dhikrTokens

        ZStack {
            LinearGradient(
                colors: tokens.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [tokens.centerGlow.opacity(theme.isDarkMode ? 0.60 : 0.38), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .blendMode(.screen)

            SacredGeometryOverlay(theme: theme, tokens: tokens)
                .opacity(theme.isDarkMode ? 0.92 : 0.74)

            LinearGradient(
                colors: [
                    Color.black.opacity(theme.isDarkMode ? 0.18 : 0.02),
                    .clear,
                    Color.black.opacity(theme.isDarkMode ? 0.32 : 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [.clear, Color.black.opacity(theme.isDarkMode ? 0.26 : 0.10)],
                center: .center,
                startRadius: 120,
                endRadius: 540
            )
        }
        .ignoresSafeArea()
    }
}

struct DhikrHeader: View {
    let theme: AppTheme
    let context: DhikrPresentationContext
    let onInfo: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    if let eyebrow = clean(context.eyebrow) {
                        Text(eyebrow.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(theme.secondaryText.opacity(0.82))
                    }

                    Text(context.progressText)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.primaryText.opacity(0.88))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(theme.dhikrTokens.surfaceFill)
                                .overlay {
                                    Circle().stroke(theme.dhikrTokens.surfaceStroke, lineWidth: 1)
                                }
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(DhikrScreenText.string(.detailsAccessibility))
            }

            VStack(spacing: 10) {
                if let arabic = clean(context.arabicText) {
                    Text(arabic)
                        .font(QuranFontResolver.arabicFont(for: .classicMushaf, size: 26, relativeTo: .largeTitle))
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .environment(\.layoutDirection, .rightToLeft)
                }

                Text(clean(context.transliteration) ?? context.title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let meaning = clean(context.meaning) {
                    Text(meaning)
                        .font(.system(.body, design: .default, weight: .regular))
                        .foregroundStyle(theme.secondaryText.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
        }
    }

    private func clean(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct DhikrCalendarButton: View {
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.primaryText.opacity(0.92))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(theme.dhikrTokens.surfaceFill)
                        .overlay {
                            Circle().stroke(theme.dhikrTokens.surfaceStroke, lineWidth: 1)
                        }
                )
                .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.40 : 0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(DhikrScreenText.string(.calendarAccessibility))
    }
}

struct DhikrCounterButton: View {
    let theme: AppTheme
    let counter: CounterModel
    let context: DhikrPresentationContext
    let diameter: CGFloat
    let milestoneValue: Int?
    let milestoneTrigger: Int
    let onTap: () -> Void

    @State private var pressScale: CGFloat = 1
    @State private var rippleScale: CGFloat = 0.82
    @State private var rippleOpacity: Double = 0
    @State private var milestoneOpacity: Double = 0
    @State private var milestoneScale: CGFloat = 0.88
    @State private var isPressingCounter = false

    private var tokens: DhikrThemeTokens { theme.dhikrTokens }
    private var progress: Double { counter.isFreeMode ? 0 : (counter.isMultiStep ? counter.overallProgress : counter.progress) }
    private var ringWidth: CGFloat { max(18, diameter * 0.075) }
    private var innerSize: CGFloat { diameter - (ringWidth * 2.15) }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tokens.centerGlow.opacity(theme.isDarkMode ? 0.28 : 0.18), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: diameter * 0.62
                    )
                )
                .frame(width: diameter * 1.24, height: diameter * 1.24)
                .blur(radius: 26)

            if progress > 0 {
                Circle()
                    .stroke(tokens.progressTrack, lineWidth: ringWidth)
                    .frame(width: diameter, height: diameter)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [tokens.progressStart, tokens.progressEnd, tokens.progressStart],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: diameter, height: diameter)
                    .shadow(color: tokens.progressEnd.opacity(theme.isDarkMode ? 0.40 : 0.18), radius: 12, y: 6)
            } else {
                Circle()
                    .stroke(tokens.progressTrack.opacity(0.72), lineWidth: ringWidth)
                    .frame(width: diameter, height: diameter)
            }

            Circle()
                .stroke(tokens.rippleColor.opacity(rippleOpacity), lineWidth: 2)
                .frame(width: diameter * rippleScale, height: diameter * rippleScale)

            Circle()
                .stroke(tokens.rippleColor.opacity(milestoneOpacity), lineWidth: 3)
                .frame(width: diameter * milestoneScale, height: diameter * milestoneScale)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [tokens.counterOuterTop, tokens.counterOuterBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: innerSize, height: innerSize)
                .overlay {
                    Circle()
                        .stroke(tokens.counterStroke, lineWidth: 1.1)
                }
                .shadow(color: tokens.counterShadow, radius: 20, y: 14)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [tokens.counterInnerTop, tokens.counterInnerBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: innerSize * 0.88, height: innerSize * 0.88)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(theme.isDarkMode ? 0.18 : 0.55), lineWidth: 1)
                }
                .overlay(alignment: .top) {
                    Circle()
                        .fill(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.42))
                        .frame(width: innerSize * 0.58, height: innerSize * 0.22)
                        .blur(radius: 12)
                        .offset(y: innerSize * 0.04)
                }

            VStack(spacing: 8) {
                Text(counter.currentCount.formatted(.number))
                    .font(.system(size: max(54, diameter * 0.18), weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .contentTransition(.numericText())

                Text(context.targetText)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(tokens.innerBadgeFill)
                            .overlay {
                                Capsule().stroke(tokens.innerBadgeStroke, lineWidth: 1)
                            }
                    )

                if let milestoneValue, [33, 99, 100].contains(milestoneValue) {
                    Text(String.localizedStringWithFormat(
                        DhikrScreenText.string(.milestoneReachedFormat),
                        milestoneValue
                    ))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 18)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isPressingCounter ? 0.965 : pressScale)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressingCounter else { return }
                    isPressingCounter = true
                    animateTap()
                    onTap()
                }
                .onEnded { _ in
                    isPressingCounter = false
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            String.localizedStringWithFormat(
                DhikrScreenText.string(.counterAccessibilityFormat),
                counter.currentCount,
                context.accessibilityTargetLabel
            )
        )
        .accessibilityHint(DhikrScreenText.string(.counterAccessibilityHint))
        .onChange(of: milestoneTrigger) { _, _ in
            animateMilestone()
        }
    }

    private func animateTap() {
        pressScale = 0.965
        rippleScale = 0.82
        rippleOpacity = 0.34

        withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
            pressScale = 1
            rippleScale = 1.2
            rippleOpacity = 0
        }
    }

    private func animateMilestone() {
        milestoneScale = 0.90
        milestoneOpacity = 0.55

        withAnimation(.easeOut(duration: 0.85)) {
            milestoneScale = 1.22
            milestoneOpacity = 0
        }
    }
}

struct DhikrUtilityBar: View {
    let theme: AppTheme
    let selectedTarget: DhikrTargetChoice
    let isTargetSelectionEnabled: Bool
    let vibrationEnabled: Bool
    let soundEnabled: Bool
    let onSelectTarget: (DhikrTargetChoice) -> Void
    let onReset: () -> Void
    let onToggleVibration: () -> Void
    let onToggleSound: () -> Void

    var body: some View {
        let tokens = theme.dhikrTokens

        VStack(spacing: 14) {
            HStack(spacing: 10) {
                DhikrSecondaryControl(
                    theme: theme,
                    title: L10n.string(.dhikrReset),
                    systemImage: "arrow.counterclockwise",
                    isActive: false,
                    action: onReset
                )

                DhikrSecondaryControl(
                    theme: theme,
                    title: L10n.string(.dhikrSettingsVibration),
                    systemImage: vibrationEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                    isActive: vibrationEnabled,
                    action: onToggleVibration
                )

                DhikrSecondaryControl(
                    theme: theme,
                    title: L10n.string(.dhikrSettingsSound),
                    systemImage: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    isActive: soundEnabled,
                    action: onToggleSound
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DhikrTargetChoice.allCases, id: \.self) { option in
                        let isSelected = option == selectedTarget && isTargetSelectionEnabled

                        Button {
                            onSelectTarget(option)
                        } label: {
                            Text(option.title())
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(isSelected ? theme.foregroundColor(forBackground: tokens.activeChipFill) : theme.primaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? tokens.activeChipFill : tokens.inactiveChipFill)
                                        .overlay {
                                            Capsule().stroke(isSelected ? tokens.activeChipStroke : tokens.inactiveChipStroke, lineWidth: 1)
                                        }
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isTargetSelectionEnabled)
                        .opacity(isTargetSelectionEnabled ? 1 : 0.45)
                    }
                }
                .padding(.horizontal, 2)
            }
            .accessibilityElement(children: .contain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(tokens.surfaceFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(tokens.surfaceStroke, lineWidth: 1)
                }
                .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.35 : 0.12), radius: 20, y: 12)
        )
    }
}

struct DhikrStatsRow: View {
    let theme: AppTheme
    let todayCount: Int
    let totalCount: Int
    let streakCount: Int

    var body: some View {
        ViewThatFits {
            HStack(spacing: 10) {
                statCard(
                    icon: "sun.max.fill",
                    title: L10n.string(.bugun),
                    value: todayCount.formatted(.number)
                )
                statCard(
                    icon: "circle.grid.3x3.fill",
                    title: L10n.string(.istatistikToplamZikir),
                    value: totalCount.formatted(.number)
                )
                statCard(
                    icon: "flame.fill",
                    title: L10n.string(.zikirSerisi2),
                    value: streakCount.formatted(.number)
                )
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    statCard(
                        icon: "sun.max.fill",
                        title: L10n.string(.bugun),
                        value: todayCount.formatted(.number)
                    )
                    statCard(
                        icon: "circle.grid.3x3.fill",
                        title: L10n.string(.istatistikToplamZikir),
                        value: totalCount.formatted(.number)
                    )
                }
                statCard(
                    icon: "flame.fill",
                    title: L10n.string(.zikirSerisi2),
                    value: streakCount.formatted(.number)
                )
            }
        }
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        let tokens = theme.dhikrTokens

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.primaryText.opacity(0.84))
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(tokens.innerBadgeFill)
                        .overlay {
                            Circle().stroke(tokens.innerBadgeStroke, lineWidth: 1)
                        }
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                Text(value)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tokens.surfaceFill.opacity(theme.isDarkMode ? 0.90 : 0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tokens.surfaceStroke.opacity(0.92), lineWidth: 1)
                }
        )
    }
}

private struct DhikrManageMenu: View {
    let theme: AppTheme
    let counters: [CounterModel]
    let selectedCounterID: String?
    let canUndo: Bool
    let onSelectCounter: (CounterModel) -> Void
    let onCreateNew: () -> Void
    let onUndo: () -> Void
    let onDeleteCurrent: () -> Void

    var body: some View {
        Menu {
            Button {
                onCreateNew()
            } label: {
                Label(L10n.string(.yeniZikir2), systemImage: "plus")
            }

            if canUndo {
                Button {
                    onUndo()
                } label: {
                    Label(L10n.string(.geriAl2), systemImage: "arrow.uturn.backward")
                }
            }

            if !counters.isEmpty {
                Section(L10n.string(.tabMyDhikr)) {
                    ForEach(counters) { counter in
                        Button {
                            onSelectCounter(counter)
                        } label: {
                            Label(
                                counter.name,
                                systemImage: counter.id == selectedCounterID ? "checkmark.circle.fill" : "circle"
                            )
                        }
                    }
                }
            }

            if selectedCounterID != nil {
                Button(role: .destructive) {
                    onDeleteCurrent()
                } label: {
                    Label(L10n.string(.sil2), systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "circle.grid.2x1.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.primaryText.opacity(0.92))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(theme.dhikrTokens.surfaceFill)
                        .overlay {
                            Circle().stroke(theme.dhikrTokens.surfaceStroke, lineWidth: 1)
                        }
                )
                .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.40 : 0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(DhikrScreenText.string(.manageAccessibility))
    }
}

private struct DhikrSecondaryControl: View {
    let theme: AppTheme
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? theme.foregroundColor(forBackground: theme.dhikrTokens.activeChipFill) : theme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? theme.dhikrTokens.activeChipFill : theme.dhikrTokens.inactiveChipFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isActive ? theme.dhikrTokens.activeChipStroke : theme.dhikrTokens.inactiveChipStroke, lineWidth: 1)
                    }
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 52)
    }
}

private struct DhikrEmptyState: View {
    let theme: AppTheme
    let onCreate: () -> Void
    let onOpenCalendar: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .stroke(theme.dhikrTokens.surfaceStroke.opacity(0.55), lineWidth: 1)
                    .frame(width: 180, height: 180)

                HexagonShape()
                    .stroke(theme.dhikrTokens.geometryStroke, style: StrokeStyle(lineWidth: 1, dash: [5, 8]))
                    .frame(width: 132, height: 118)

                Circle()
                    .fill(theme.dhikrTokens.innerBadgeFill)
                    .frame(width: 98, height: 98)
                    .overlay {
                        Image(systemName: "circle.hexagongrid.circle.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }
            }

            VStack(spacing: 10) {
                Text(DhikrScreenText.string(.emptyStateTitle))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)

                Text(DhikrScreenText.string(.emptyStateMessage))
                    .font(.system(.body, design: .default, weight: .regular))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                Button(action: onCreate) {
                    Label(L10n.string(.yeniZikir2), systemImage: "plus.circle.fill")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(theme.dhikrTokens.activeChipFill)
                        )
                        .foregroundStyle(theme.foregroundColor(forBackground: theme.dhikrTokens.activeChipFill))
                }
                .buttonStyle(.plain)

                Button(action: onOpenCalendar) {
                    Label(DhikrScreenText.string(.openCalendarAction), systemImage: "calendar")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(theme.dhikrTokens.surfaceFill)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(theme.dhikrTokens.surfaceStroke, lineWidth: 1)
                                }
                        )
                        .foregroundStyle(theme.primaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(theme.dhikrTokens.surfaceFill.opacity(theme.isDarkMode ? 0.94 : 0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(theme.dhikrTokens.surfaceStroke, lineWidth: 1)
                }
        )
    }
}

private struct SacredGeometryOverlay: View {
    let theme: AppTheme
    let tokens: DhikrThemeTokens

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let large = min(width, height) * 0.86
            let medium = large * 0.58

            ZStack {
                Circle()
                    .stroke(tokens.geometryStroke, lineWidth: 1)
                    .frame(width: large, height: large)
                    .offset(y: height * 0.02)

                Circle()
                    .stroke(tokens.geometryStroke.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [4, 10]))
                    .frame(width: medium, height: medium)
                    .offset(y: -height * 0.02)

                HexagonShape()
                    .stroke(tokens.geometryStroke.opacity(0.78), lineWidth: 1)
                    .frame(width: large * 0.56, height: large * 0.48)

                HexagonShape()
                    .stroke(tokens.geometryStroke.opacity(0.46), style: StrokeStyle(lineWidth: 1, dash: [6, 8]))
                    .frame(width: large * 0.76, height: large * 0.66)
                    .rotationEffect(.degrees(30))

                Circle()
                    .fill(tokens.geometryGlow)
                    .frame(width: width * 0.14, height: width * 0.14)
                    .blur(radius: 28)
                    .offset(x: -width * 0.26, y: -height * 0.18)

                Circle()
                    .fill(tokens.geometryGlow.opacity(theme.isDarkMode ? 0.72 : 0.42))
                    .frame(width: width * 0.10, height: width * 0.10)
                    .blur(radius: 22)
                    .offset(x: width * 0.25, y: height * 0.20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let points = [
            CGPoint(x: width * 0.50, y: 0),
            CGPoint(x: width, y: height * 0.25),
            CGPoint(x: width, y: height * 0.75),
            CGPoint(x: width * 0.50, y: height),
            CGPoint(x: 0, y: height * 0.75),
            CGPoint(x: 0, y: height * 0.25)
        ]

        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct DhikrThemeTokens {
    let backgroundGradient: [Color]
    let centerGlow: Color
    let surfaceFill: Color
    let surfaceStroke: Color
    let geometryStroke: Color
    let geometryGlow: Color
    let progressTrack: Color
    let progressStart: Color
    let progressEnd: Color
    let counterOuterTop: Color
    let counterOuterBottom: Color
    let counterInnerTop: Color
    let counterInnerBottom: Color
    let counterStroke: Color
    let counterShadow: Color
    let innerBadgeFill: Color
    let innerBadgeStroke: Color
    let activeChipFill: Color
    let activeChipStroke: Color
    let inactiveChipFill: Color
    let inactiveChipStroke: Color
    let rippleColor: Color
}

private extension AppTheme {
    // The screen derives its premium atmosphere from the active app theme instead of replacing it.
    var dhikrTokens: DhikrThemeTokens {
        let deepBase = appBackground.mixed(with: accent, amount: isDarkMode ? 0.18 : 0.08)
        let lowerBase = secondaryBackground.mixed(with: .black, amount: isDarkMode ? 0.24 : 0.06)
        let elevatedGlow = glow.mixed(with: accentSoft, amount: isDarkMode ? 0.48 : 0.34)

        return DhikrThemeTokens(
            backgroundGradient: [
                deepBase.mixed(with: accentSoft, amount: isDarkMode ? 0.22 : 0.14),
                secondaryBackground,
                lowerBase
            ],
            centerGlow: elevatedGlow,
            surfaceFill: isDarkMode
                ? elevatedCardBackground.opacity(0.62)
                : Color.white.opacity(0.62),
            surfaceStroke: isDarkMode
                ? Color.white.opacity(0.10)
                : accent.mixed(with: .white, amount: 0.72).opacity(0.42),
            geometryStroke: accentSoft.opacity(isDarkMode ? 0.11 : 0.09),
            geometryGlow: accentSoft.opacity(isDarkMode ? 0.18 : 0.10),
            progressTrack: Color.white.opacity(isDarkMode ? 0.08 : 0.22),
            progressStart: accentSoft.mixed(with: .white, amount: isDarkMode ? 0.12 : 0.20),
            progressEnd: accent.mixed(with: .white, amount: isDarkMode ? 0.16 : 0.05),
            counterOuterTop: elevatedCardBackground.mixed(with: accentSoft, amount: isDarkMode ? 0.10 : 0.08),
            counterOuterBottom: cardBackground.mixed(with: .black, amount: isDarkMode ? 0.08 : 0.02),
            counterInnerTop: Color.white.opacity(isDarkMode ? 0.06 : 0.76).mixed(with: elevatedCardBackground, amount: isDarkMode ? 0.82 : 0.24),
            counterInnerBottom: elevatedCardBackground.mixed(with: accent, amount: isDarkMode ? 0.05 : 0.03),
            counterStroke: Color.white.opacity(isDarkMode ? 0.10 : 0.62),
            counterShadow: accent.opacity(isDarkMode ? 0.24 : 0.10),
            innerBadgeFill: isDarkMode
                ? Color.white.opacity(0.06)
                : accentSoft.opacity(0.16),
            innerBadgeStroke: isDarkMode
                ? Color.white.opacity(0.08)
                : accent.opacity(0.12),
            activeChipFill: accent.mixed(with: accentSoft, amount: isDarkMode ? 0.18 : 0.08),
            activeChipStroke: Color.white.opacity(isDarkMode ? 0.12 : 0.50),
            inactiveChipFill: isDarkMode
                ? Color.white.opacity(0.05)
                : Color.white.opacity(0.54),
            inactiveChipStroke: isDarkMode
                ? Color.white.opacity(0.08)
                : accent.opacity(0.10),
            rippleColor: elevatedGlow
        )
    }
}

private extension Color {
    func mixed(with color: Color, amount: CGFloat) -> Color {
        let lhs = UIColor(self)
        let rhs = UIColor(color)

        var lRed: CGFloat = 0
        var lGreen: CGFloat = 0
        var lBlue: CGFloat = 0
        var lAlpha: CGFloat = 0
        var rRed: CGFloat = 0
        var rGreen: CGFloat = 0
        var rBlue: CGFloat = 0
        var rAlpha: CGFloat = 0

        guard lhs.getRed(&lRed, green: &lGreen, blue: &lBlue, alpha: &lAlpha),
              rhs.getRed(&rRed, green: &rGreen, blue: &rBlue, alpha: &rAlpha) else {
            return self
        }

        let clampedAmount = min(max(amount, 0), 1)
        let inverse = 1 - clampedAmount

        return Color(
            red: (lRed * inverse) + (rRed * clampedAmount),
            green: (lGreen * inverse) + (rGreen * clampedAmount),
            blue: (lBlue * inverse) + (rBlue * clampedAmount),
            opacity: (lAlpha * inverse) + (rAlpha * clampedAmount)
        )
    }
}

#Preview("Dhikr Premium") {
    let storage = StorageService()
    let counter = CounterModel(
        name: "Sübhanallah",
        targetCount: 99,
        currentCount: 27,
        sessionSnapshot: ZikrSession(
            zikrTitle: "Sübhanallah",
            arabicText: "سُبْحَانَ اللَّهِ",
            transliteration: "Subhanallah",
            meaning: "Allah her türlü eksiklikten münezzehtir.",
            recommendedCount: 99,
            category: "Tesbih"
        )
    )

    storage.counters = [counter]
    storage.selectedCounterID = counter.id
    storage.profile.currentStreak = 7
    storage.profile.totalLifetimeCount = 12840
    storage.profile.dailyGoal = 100
    storage.allStats = [DailyStats(date: Date())]
    storage.setActiveZikrSession(counter.sessionSnapshot)

    return DhikrView(
        storage: storage,
        authService: AuthService(),
        onGoHome: {}
    )
    .environmentObject(ThemeManager.preview(theme: .deepSpiritual, appearanceMode: .dark))
}
