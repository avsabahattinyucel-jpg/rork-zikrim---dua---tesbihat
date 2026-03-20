import SwiftUI

struct CounterView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var viewModel: CounterViewModel
    let storage: StorageService
    let authService: AuthService
    let onGoHome: () -> Void
    @State private var customTargetValue: Double = 33
    @State private var customTargetText: String = "33"
    @State private var activeSession: ZikrSession? = nil
    @State private var showCelebration: Bool = false
    @State private var celebrationOpacity: Double = 0
    @State private var sparkleRadius: CGFloat = 80
    @State private var geminiService = GroqService()
    @State private var dhikrStreak: Int = 0
    @State private var streakMilestone: String? = nil
    @State private var pulse: Bool = false
    @State private var beadRotation: Double = 0
    @State private var showDetailsSheet: Bool = false

    private var isPremium: Bool { authService.isPremium }
    private var theme: ActiveTheme { themeManager.current }

    init(storage: StorageService, authService: AuthService, onGoHome: @escaping () -> Void) {
        self.storage = storage
        self.authService = authService
        self.onGoHome = onGoHome
        self._viewModel = State(initialValue: CounterViewModel(storage: storage))
    }

    var body: some View {
        let palette = themeManager.palette(using: systemColorScheme)

        NavigationStack {
            ZStack {
                palette.pageBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if let counter = viewModel.selectedCounter {
                        counterContent(counter)
                    } else {
                        emptyState
                    }
                }
            }
            .navigationTitle(L10n.string(.dhikrScreenTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.resolvedIsDarkMode(using: systemColorScheme) ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showNewCounterSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if storage.counters.count > 1 {
                        Menu {
                            ForEach(storage.counters) { c in
                                Button {
                                    viewModel.selectCounter(c)
                                } label: {
                                    Label(c.name, systemImage: c.id == viewModel.selectedCounter?.id ? "checkmark.circle.fill" : "circle")
                                }
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewCounterSheet) {
                NewCounterSheet(viewModel: viewModel)
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
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(duration: 0.4), value: viewModel.showCompletionCard)
            .task {
                await authService.refreshPremiumStatus()
            }
            .onChange(of: storage.pendingSelectedCounterId) { _, newId in
                if let id = newId, let counter = storage.counters.first(where: { $0.id == id }) {
                    viewModel.selectCounter(counter)
                    activeSession = storage.resolvedSession(for: counter)
                    storage.setActiveZikrSession(activeSession)
                    storage.pendingSelectedCounterId = nil
                }
            }
            .onChange(of: viewModel.showCompletionCard) { oldValue, newValue in
                if newValue && !oldValue {
                    refreshStreak()
                }
            }
            .onChange(of: storage.selectedCounterID) { _, _ in
                viewModel.refreshSelected()
            }
        }
        .id(themeManager.navigationRefreshID)
        .onAppear {
            if let counter = viewModel.selectedCounter {
                activeSession = storage.resolvedSession(for: counter)
                storage.setActiveZikrSession(activeSession)
            }
            refreshStreak()
        }
        .onChange(of: viewModel.selectedCounter?.id) { _, _ in
            if let counter = viewModel.selectedCounter {
                activeSession = storage.resolvedSession(for: counter)
                storage.setActiveZikrSession(activeSession)
            } else {
                activeSession = nil
                storage.setActiveZikrSession(nil)
            }
        }
    }

    private func counterContent(_ counter: CounterModel) -> some View {
        VStack(spacing: 0) {
            DhikrHeaderCompact(
                title: L10n.string(.dhikrScreenTitle),
                dhikrTitle: activeSession?.zikrTitle ?? counter.name,
                subtitle: counterSubtitle(counter),
                streakCount: dhikrStreak
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            GeometryReader { proxy in
                VStack {
                    Spacer(minLength: 8)
                    DhikrCounterView(
                        counter: counter,
                        maxRingSize: min(proxy.size.width * 0.86, proxy.size.height * 0.72),
                        pulse: $pulse,
                        beadRotation: $beadRotation,
                        showCelebration: $showCelebration,
                        celebrationOpacity: $celebrationOpacity,
                        sparkleRadius: $sparkleRadius,
                        onIncrement: {
                            pulse.toggle()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                beadRotation += 8
                            }
                            viewModel.increment()
                        }
                    )
                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)

            DhikrBottomActions(
                onReset: { viewModel.reset() },
                onDelete: { viewModel.deleteSelected() },
                onDetails: { showDetailsSheet = true }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
        }
        .sheet(isPresented: $viewModel.showTargetPicker) {
            TargetEditorSheet(
                initialTarget: viewModel.selectedCounter?.targetCount ?? 33,
                customTargetValue: $customTargetValue,
                customTargetText: $customTargetText
            ) { target in
                updateTarget(target)
                viewModel.showTargetPicker = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.showTargetPicker) { _, newValue in
            if newValue {
                let target = Double(viewModel.selectedCounter?.targetCount ?? 33)
                customTargetValue = target
                customTargetText = "\(Int(target))"
            }
        }
        .sheet(isPresented: $showDetailsSheet) {
            DhikrDetailsSheet(
                motivationText: geminiService.zikirProgressAdvice(progress: counter.progress),
                dailyCount: storage.todayStats().totalCount,
                dailyGoal: max(storage.profile.dailyGoal, 1),
                streakCount: dhikrStreak,
                streakMilestone: streakMilestone
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func updateTarget(_ target: Int) {
        guard var counter = viewModel.selectedCounter else { return }
        counter.targetCount = target
        if counter.currentCount >= target {
            counter.isCompleted = true
        } else {
            counter.isCompleted = false
        }
        storage.updateCounter(counter)
        viewModel.refreshSelected()
    }

    private func counterDetails(_ counter: CounterModel) -> some View {
        VStack(spacing: 8) {
            if counter.isMultiStep, let step = counter.currentStep {
                HStack(spacing: 6) {
                    ForEach(Array(counter.steps.indices), id: \.self) { i in
                        Capsule()
                            .fill(i < counter.currentStepIndex ? theme.accent : (i == counter.currentStepIndex ? theme.accent.opacity(0.7) : theme.selectionBackground))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 28)

                Text(step.name)
                    .font(.title2.bold())
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: counter.currentStepIndex)

                zikrTextBlock(
                    arabicText: step.arabicText,
                    transliteration: step.transliteration,
                    meaning: step.meaning
                )

                Text(L10n.format(.counterStepProgressFormat, counter.currentStepIndex + 1, counter.steps.count, counter.currentCount, counter.currentStepTarget))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            } else {
                Text(activeSession?.zikrTitle ?? counter.name)
                    .font(.title2.bold())
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                if let session = activeSession {
                    zikrTextBlock(
                        arabicText: session.arabicText,
                        transliteration: session.transliteration,
                        meaning: session.meaning
                    )
                } else {
                    Text(L10n.string(.zikirSecilmedi))
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                    Button(L10n.string(.zikirSec)) {
                        viewModel.showNewCounterSheet = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .themedSecondaryButton(cornerRadius: 16)
                    .buttonStyle(.plain)
                }

                Text(L10n.format(.countFractionFormat, Int64(counter.currentCount), Int64(counter.targetCount)))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private func counterSubtitle(_ counter: CounterModel) -> String {
        if counter.isMultiStep, counter.currentStep != nil {
            return L10n.format(.counterStepProgressFormat, counter.currentStepIndex + 1, counter.steps.count, counter.currentCount, counter.currentStepTarget)
        }
        return L10n.format(.countFractionFormat, Int64(counter.currentCount), Int64(counter.targetCount))
    }

    private func zikrTextBlock(arabicText: String, transliteration: String, meaning: String) -> some View {
        VStack(spacing: 6) {
            if !arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(arabicText)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            if !transliteration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(transliteration)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(meaning)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    private func refreshStreak() {
        dhikrStreak = DhikrStreakService.shared.getCurrentStreak()
        streakMilestone = DhikrStreakService.shared.milestoneMessage()
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 22) {
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        let angle = Angle(degrees: Double(i) / 12.0 * 360.0 - 90)
                        Circle()
                            .fill(theme.selectionBackground.opacity(0.88))
                            .frame(width: 10, height: 10)
                            .offset(y: -70)
                            .rotationEffect(angle)
                    }
                    Circle()
                        .stroke(theme.divider.opacity(0.85), lineWidth: 5)
                        .frame(width: 120, height: 120)

                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                VStack(spacing: 10) {
                    Text(L10n.string(.tesbihYok2))
                        .font(.title3.bold())
                        .foregroundStyle(theme.textPrimary)
                    Text(L10n.string(.tesbihCekerekIbadetRutininiOlustur))
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    viewModel.showNewCounterSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                        Text(L10n.string(.yeniTesbihEkle2))
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .themedPrimaryButton(cornerRadius: 18)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .themedSecondaryCard(cornerRadius: 26)
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

struct DhikrHeaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let streakCount: Int
    let milestone: String?

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(theme.textPrimary)

            if streakCount > 0 {
                DhikrStreakCard(streakCount: streakCount, milestone: milestone)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DhikrHeaderCompact: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let dhikrTitle: String
    let subtitle: String
    let streakCount: Int

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if streakCount > 0 {
                    DhikrStreakChip(streakCount: streakCount)
                }
                Spacer()
            }

            Text(dhikrTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(subtitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DhikrStreakChip: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let streakCount: Int

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.caption2.bold())
                .foregroundStyle(theme.accent)
            Text(L10n.string(.zikirSerisi2))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.textPrimary)
            Text(L10n.format(.daysCountFormat, streakCount))
                .font(.caption2.weight(.heavy))
                .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(theme.selectionBackground)
        .clipShape(.capsule)
    }
}

struct DhikrStreakCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let streakCount: Int
    let milestone: String?

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accent, theme.accent.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: theme.accent.opacity(0.30), radius: 6, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(L10n.string(.zikirSerisi2))
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.textPrimary)
                    Text(L10n.format(.daysCountFormat, streakCount))
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(theme.accent)
                }

                if let milestone {
                    Text(milestone)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                } else {
                    Text(L10n.format(.dhikrStreakConsecutiveDaysFormat, streakCount))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [theme.selectionBackground, theme.cardBackground],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.divider.opacity(0.55), lineWidth: 1)
        )
    }
}

struct DhikrMotivationCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let text: String

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles.bubble.fill")
                .font(.subheadline)
                .foregroundStyle(theme.accent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
            Spacer()
        }
        .padding(14)
        .background(theme.selectionBackground)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.divider.opacity(0.55), lineWidth: 1)
        )
    }
}

struct DhikrProgressSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let dailyCount: Int
    let dailyGoal: Int
    let streakCount: Int

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string(.dhikrDailyProgressTitle))
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            ProgressView(value: min(Double(dailyCount) / Double(max(dailyGoal, 1)), 1.0))
                .tint(theme.accent)
                .frame(maxWidth: .infinity)
            HStack {
                Text(L10n.format(.dailyGoalProgressFormat, Int64(dailyCount), Int64(max(dailyGoal, 1))))
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Label(L10n.format(.daysCountFormat, streakCount), systemImage: "flame.fill")
                    .font(.caption.bold())
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(14)
        .background(theme.cardBackground.opacity(0.96))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.divider.opacity(0.55), lineWidth: 1)
        )
    }
}

struct DhikrCounterView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let counter: CounterModel
    let maxRingSize: CGFloat
    @Binding var pulse: Bool
    @Binding var beadRotation: Double
    @Binding var showCelebration: Bool
    @Binding var celebrationOpacity: Double
    @Binding var sparkleRadius: CGFloat
    let onIncrement: () -> Void
    @State private var isPressingCounter: Bool = false

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        let ringSize = min(maxRingSize, 300)
        let innerSize = ringSize * 0.72
        let glowSize = ringSize * 0.94
        let beadRadius = ringSize / 2 - 12
        let beadDiameter = max(6, ringSize * 0.03)

        ZStack {
            let beadCount = max(min(counter.currentStepTarget, 99), 33)

            Group {
                ForEach(Array(0..<beadCount), id: \.self) { index in
                    let normalizedProgress = counter.progress * Double(beadCount)
                    let isActive = Double(index) < normalizedProgress
                    let angle = Angle(degrees: (Double(index) / Double(beadCount)) * 360.0 - 90.0)

                    Circle()
                        .fill(isActive ? theme.accent.opacity(0.88) : theme.selectionBackground.opacity(0.92))
                        .overlay {
                            Circle()
                                .stroke(isActive ? Color.white.opacity(0.75) : Color.clear, lineWidth: 1)
                        }
                        .frame(width: beadDiameter, height: beadDiameter)
                        .offset(y: -beadRadius)
                        .rotationEffect(angle)
                        .scaleEffect(isActive ? 1.12 : 1.0)
                        .shadow(color: isActive ? theme.accent.opacity(0.32) : .clear, radius: isActive ? 4 : 0)
                        .animation(.easeInOut(duration: 0.2), value: counter.currentCount)
                }
            }
            .rotationEffect(.degrees(beadRotation))

            Circle()
                .stroke(theme.divider.opacity(0.85), lineWidth: 6)
                .frame(width: ringSize, height: ringSize)
                .shadow(color: theme.accent.opacity(0.24), radius: 18)
                .shadow(color: theme.accent.opacity(0.10), radius: 36)

            if counter.progress > 0.85 {
                Circle()
                    .fill(theme.accent.opacity(0.14))
                    .frame(width: glowSize, height: glowSize)
                    .blur(radius: 16)
            }

            if showCelebration {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [theme.accent.opacity(0.30), theme.accent.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 130
                            )
                        )
                        .frame(width: ringSize * 0.88, height: ringSize * 0.88)
                        .blur(radius: 10)
                        .opacity(celebrationOpacity)

                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: i % 2 == 0 ? "sparkle" : "star.fill")
                            .font(.system(size: i % 2 == 0 ? 14 : 10, weight: .bold))
                            .foregroundStyle(
                                i % 3 == 0 ? theme.accent.opacity(0.95) :
                                i % 3 == 1 ? theme.textPrimary : theme.textSecondary
                            )
                            .offset(y: -sparkleRadius)
                            .rotationEffect(.degrees(Double(i) * 45))
                            .opacity(celebrationOpacity)
                            .scaleEffect(celebrationOpacity)
                    }
                }
            }

            Circle()
                .fill(theme.elevatedCardBackground.opacity(0.96))
                .frame(width: innerSize, height: innerSize)
                .scaleEffect(isPressingCounter ? 0.97 : (pulse ? 1.08 : 1.0))
                .animation(.easeOut(duration: 0.12), value: isPressingCounter)
                .animation(.easeOut(duration: 0.15), value: pulse)
                .overlay(
                    Circle()
                        .stroke(theme.divider.opacity(0.55), lineWidth: 1)
                )
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "circle.hexagongrid.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.accent, theme.accent.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: theme.accent.opacity(0.24), radius: 8, y: 3)

                        Text("\(counter.currentCount)")
                            .font(.system(size: max(36, ringSize * 0.16), weight: .bold, design: .rounded))
                            .foregroundStyle(counter.isCompleted ? theme.accent : theme.textPrimary)
                            .contentTransition(.numericText())
                            .scaleEffect(counter.currentCount > 0 ? 1.0 + min(counter.progress * 0.05, 0.05) : 1)
                            .animation(.spring(duration: 0.25), value: counter.currentStepIndex)

                        if counter.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .allowsHitTesting(false)
                }
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressingCounter else { return }
                    isPressingCounter = true
                    onIncrement()
                }
                .onEnded { _ in
                    isPressingCounter = false
                }
        )
        .accessibilityAddTraits(.isButton)
        .animation(.spring(duration: 0.25), value: counter.currentCount)
        .animation(.spring(duration: 0.3), value: counter.currentStepIndex)
        .onChange(of: counter.isCompleted) { _, isCompleted in
            if isCompleted {
                showCelebration = true
                sparkleRadius = 60
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    celebrationOpacity = 1
                    sparkleRadius = 120
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(1400))
                    withAnimation(.easeOut(duration: 0.6)) {
                        celebrationOpacity = 0
                    }
                    try? await Task.sleep(for: .milliseconds(700))
                    showCelebration = false
                    sparkleRadius = 80
                }
            }
        }
    }
}

struct DhikrBottomActions: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let onReset: () -> Void
    let onDelete: () -> Void
    let onDetails: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onReset) {
                Label(L10n.string(.dhikrReset), systemImage: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .themedSecondaryButton(cornerRadius: 16)
            }
            .buttonStyle(.plain)

            Button(role: .destructive, action: onDelete) {
                Label(L10n.string(.sil2), systemImage: "trash")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .themedSecondaryButton(
                        cornerRadius: 16,
                        fill: theme.cardBackground,
                        foreground: Color.red.opacity(theme.isDarkMode ? 0.9 : 0.8),
                        border: Color.red.opacity(theme.isDarkMode ? 0.35 : 0.22)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onDetails) {
                Label(L10n.string(.dhikrDetailsButton), systemImage: "info.circle")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .themedSecondaryButton(cornerRadius: 16)
            }
            .buttonStyle(.plain)
        }
    }
}

struct DhikrDetailsSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let motivationText: String
    let dailyCount: Int
    let dailyGoal: Int
    let streakCount: Int
    let streakMilestone: String?

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if streakCount > 0 {
                        DhikrStreakCard(streakCount: streakCount, milestone: streakMilestone)
                    }

                    DhikrMotivationCard(text: motivationText)

                    DhikrProgressSection(
                        dailyCount: dailyCount,
                        dailyGoal: max(dailyGoal, 1),
                        streakCount: streakCount
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .appScreenBackground(theme)
            .navigationTitle(L10n.string(.dhikrDetailsTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        }
    }
}

struct DhikrActionMenu: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let counter: CounterModel
    let onUndo: () -> Void
    let onReset: () -> Void
    let onEditTarget: () -> Void
    let onDelete: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Menu {
            Button {
                onUndo()
            } label: {
                Label(L10n.string(.geriAl2), systemImage: "arrow.uturn.backward")
            }
            .disabled(counter.currentCount == 0 && counter.currentStepIndex == 0)

            Button {
                onReset()
            } label: {
                Label(L10n.string(.dhikrReset), systemImage: "arrow.counterclockwise")
            }

            if !counter.isMultiStep {
                Button {
                    onEditTarget()
                } label: {
                    Label(L10n.string(.hedef2), systemImage: "target")
                }
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.string(.sil2), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.title2)
                .foregroundStyle(theme.textSecondary)
                .padding(10)
        }
        .padding(.top, 6)
    }
}

struct NewCounterSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let viewModel: CounterViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var arabicText: String = ""
    @State private var meaning: String = ""
    @State private var category: String = L10n.string(.dhikrCustomCategoryDefault)
    @State private var selectedTarget: Int = 33
    @State private var customTargetText: String = "33"
    @State private var isFavorite: Bool = false
    private let targets = [33, 99, 100, 500, 1000]
    private var theme: ActiveTheme { themeManager.current }
    private let targetColumns = [GridItem(.adaptive(minimum: 64), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    sheetSection(L10n.string(.zikriniOlustur)) {
                        VStack(spacing: 12) {
                            singleLineField(L10n.string(.zikirAdiOrnKelimeITevhid), text: $name)
                            multiLineField(L10n.string(.arapcaMetinOpsiyonel2), text: $arabicText)
                            multiLineField(L10n.string(.anlamOpsiyonel), text: $meaning)
                            singleLineField(L10n.string(.kategori), text: $category)

                            Toggle(isOn: $isFavorite) {
                                Text(L10n.string(.favoriOlarakEkle))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.textPrimary)
                            }
                            .tint(theme.accent)
                            .padding(.horizontal, 4)
                        }
                    }

                    sheetSection(L10n.string(.hedefSayisi2)) {
                        VStack(alignment: .leading, spacing: 14) {
                            LazyVGrid(columns: targetColumns, alignment: .leading, spacing: 10) {
                                ForEach(targets, id: \.self) { target in
                                    Button {
                                        selectedTarget = target
                                        customTargetText = "\(target)"
                                    } label: {
                                        Text("\(target)")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedTarget == target ? theme.accent : theme.selectionBackground, in: Capsule())
                                            .foregroundStyle(selectedTarget == target ? theme.foregroundColor(forBackground: theme.accent) : theme.textPrimary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Slider(value: Binding(
                                get: { Double(selectedTarget) },
                                set: { newValue in
                                    let rounded = max(Int(newValue.rounded()), 1)
                                    selectedTarget = rounded
                                    customTargetText = "\(rounded)"
                                }
                            ), in: 1...5000, step: 1)
                            .tint(theme.accent)

                            singleLineField(L10n.string(.manuelHedef), text: $customTargetText, keyboardType: .numberPad)
                                .onChange(of: customTargetText) { _, newValue in
                                    if let value = Int(newValue), value > 0 {
                                        selectedTarget = value
                                    }
                                }
                        }
                    }

                    sheetSection(L10n.string(.tesbihatSetleri2)) {
                        VStack(spacing: 10) {
                            ForEach(Array(multiStepPresets.enumerated()), id: \.offset) { _, preset in
                                Button {
                                    viewModel.createMultiStepCounter(name: preset.name, steps: preset.steps)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                                            Text(preset.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(theme.textPrimary)
                                            Spacer()
                                            Text(L10n.format(.stepsCountFormat, preset.steps.count))
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(theme.selectionBackground, in: Capsule())
                                                .foregroundStyle(theme.accent)
                                        }

                                        Text(preset.steps.map { "\($0.targetCount)x \($0.name)" }.joined(separator: " • "))
                                            .font(.caption)
                                            .foregroundStyle(theme.textSecondary)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(theme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(theme.divider.opacity(0.5), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    sheetSection(L10n.string(.hazirZikirler)) {
                        VStack(spacing: 10) {
                            ForEach(ZikirData.categories.flatMap(\.items).prefix(8), id: \.id) { item in
                                Button {
                                    name = item.localizedPronunciation
                                    arabicText = item.arabicText
                                    meaning = item.localizedMeaning
                                    selectedTarget = item.recommendedCount
                                    customTargetText = "\(item.recommendedCount)"
                                    category = item.category
                                } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.localizedPronunciation)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(theme.textPrimary)
                                        Text(item.localizedMeaning)
                                            .font(.caption)
                                            .foregroundStyle(theme.textSecondary)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(theme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(theme.divider.opacity(0.5), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .appScreenBackground(theme)
            .navigationTitle(L10n.string(.yeniZikir2))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string(.iptal)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string(.kaydet2)) {
                        saveTemplateAndCounter()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func sheetSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .modifier(AppSectionHeaderStyle(theme: theme))

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .themedSecondaryCard(cornerRadius: 22)
    }

    private func singleLineField(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .padding(12)
            .background(theme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.divider.opacity(0.55), lineWidth: 1)
            )
            .foregroundStyle(theme.textPrimary)
    }

    private func multiLineField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(2...4)
            .padding(12)
            .background(theme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.divider.opacity(0.55), lineWidth: 1)
            )
            .foregroundStyle(theme.textPrimary)
    }

    private var multiStepPresets: [(name: String, steps: [DhikrStep])] {
        let tesbihat = ZikirData.categories.first(where: { $0.id == "namaz_tesbihat" })
        let tesbihatSteps: [DhikrStep] = (tesbihat?.items.prefix(3) ?? []).map { DhikrStep.from($0) }
        let subhanallahName = L10n.string(.dhikrStepSubhanallahName)
        let subhanallahMeaning = L10n.string(.dhikrStepSubhanallahMeaning)
        let alhamdulillahName = L10n.string(.dhikrStepAlhamdulillahName)
        let alhamdulillahMeaning = L10n.string(.dhikrStepAlhamdulillahMeaning)
        let allahuAkbarName = L10n.string(.dhikrStepAllahuAkbarName)
        let allahuAkbarMeaning = L10n.string(.dhikrStepAllahuAkbarMeaning)
        let astaghfirullahName = L10n.string(.dhikrStepAstaghfirullahName)
        let astaghfirullahMeaning = L10n.string(.dhikrStepAstaghfirullahMeaning)
        let subhanallahWabihamdihiName = L10n.string(.dhikrStepSubhanallahWabihamdihiName)
        let subhanallahWabihamdihiMeaning = L10n.string(.dhikrStepSubhanallahWabihamdihiMeaning)
        let subhanallahilAzimName = L10n.string(.dhikrStepSubhanallahilAzimName)
        let subhanallahilAzimMeaning = L10n.string(.dhikrStepSubhanallahilAzimMeaning)

        return [
            (
                name: L10n.string(.dhikrPresetNamazTesbihat),
                steps: tesbihatSteps.isEmpty ? [
                    DhikrStep(name: subhanallahName, arabicText: "سُبْحَانَ اللَّهِ", transliteration: "Sübhânallâh", meaning: subhanallahMeaning, targetCount: 33),
                    DhikrStep(name: alhamdulillahName, arabicText: "الْحَمْدُ لِلَّهِ", transliteration: "Elhamdülillâh", meaning: alhamdulillahMeaning, targetCount: 33),
                    DhikrStep(name: allahuAkbarName, arabicText: "اللَّهُ أَكْبَرُ", transliteration: "Allâhu Ekber", meaning: allahuAkbarMeaning, targetCount: 33)
                ] : tesbihatSteps
            ),
            (
                name: L10n.string(.dhikrPresetIstigfarTesbih),
                steps: [
                    DhikrStep(name: astaghfirullahName, arabicText: "أَسْتَغْفِرُ اللَّهَ", transliteration: "Estağfirullâh", meaning: astaghfirullahMeaning, targetCount: 33),
                    DhikrStep(name: subhanallahName, arabicText: "سُبْحَانَ اللَّهِ", transliteration: "Sübhânallâh", meaning: subhanallahMeaning, targetCount: 33),
                    DhikrStep(name: alhamdulillahName, arabicText: "الْحَمْدُ لِلَّهِ", transliteration: "Elhamdülillâh", meaning: alhamdulillahMeaning, targetCount: 33),
                    DhikrStep(name: allahuAkbarName, arabicText: "اللَّهُ أَكْبَرُ", transliteration: "Allâhu Ekber", meaning: allahuAkbarMeaning, targetCount: 33)
                ]
            ),
            (
                name: L10n.string(.dhikrPresetMorningEvening),
                steps: [
                    DhikrStep(name: subhanallahWabihamdihiName, arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", transliteration: "Sübhânallâhi ve bihamdihî", meaning: subhanallahWabihamdihiMeaning, targetCount: 33),
                    DhikrStep(name: subhanallahilAzimName, arabicText: "سُبْحَانَ اللَّهِ الْعَظِيمِ", transliteration: "Sübhânallâhil-azîm", meaning: subhanallahilAzimMeaning, targetCount: 33)
                ]
            )
        ]
    }

    private func saveTemplateAndCounter() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let resolvedCategory = category.isEmpty ? "Kişisel" : category
        let itemID = "custom_\(UUID().uuidString)"
        let snapshot = ZikrSession(
            zikrTitle: cleanName,
            arabicText: arabicText,
            transliteration: cleanName,
            meaning: meaning,
            recommendedCount: selectedTarget,
            category: resolvedCategory
        )

        if isFavorite {
            let item = ZikirItem(
                id: itemID,
                category: resolvedCategory,
                arabicText: arabicText,
                turkishPronunciation: cleanName,
                turkishMeaning: meaning,
                recommendedCount: selectedTarget,
                source: L10n.string(.dhikrCustomSourceUser)
            )
            viewModel.storage.addCustomZikir(item)
            viewModel.storage.toggleFavorite(item.id)
            viewModel.createCounter(
                name: cleanName,
                target: selectedTarget,
                zikirItemId: item.id,
                sessionSnapshot: snapshot
            )
            return
        }

        viewModel.createCounter(
            name: cleanName,
            target: selectedTarget,
            sessionSnapshot: snapshot
        )
    }
}

struct TargetEditorSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let initialTarget: Int
    @Binding var customTargetValue: Double
    @Binding var customTargetText: String
    let onSave: (Int) -> Void

    private let presets: [Int] = [33, 99, 100, 500, 1000]
    private var theme: ActiveTheme { themeManager.current }
    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L10n.string(.hedefSayisi))
                            .modifier(AppSectionHeaderStyle(theme: theme))

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(presets, id: \.self) { preset in
                                Button {
                                    customTargetValue = Double(preset)
                                    customTargetText = "\(preset)"
                                } label: {
                                    let isActive = Int(customTargetValue) == preset
                                    Text("\(preset)")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(isActive ? theme.accent : theme.selectionBackground, in: Capsule())
                                        .foregroundStyle(isActive ? theme.foregroundColor(forBackground: theme.accent) : theme.textPrimary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Slider(value: $customTargetValue, in: 1...5000, step: 1)
                            .tint(theme.accent)
                            .onChange(of: customTargetValue) { _, newValue in
                                customTargetText = "\(Int(newValue))"
                            }

                        TextField(L10n.string(.manuelHedef), text: $customTargetText)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(theme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(theme.divider.opacity(0.55), lineWidth: 1)
                            )
                            .foregroundStyle(theme.textPrimary)
                            .onChange(of: customTargetText) { _, newValue in
                                if let value = Int(newValue), value > 0 {
                                    customTargetValue = Double(value)
                                }
                            }

                        Text(L10n.format(.selectedTargetFormat, Int(customTargetValue)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.textPrimary)

                        Button {
                            onSave(max(Int(customTargetValue), 1))
                        } label: {
                            Text(L10n.string(.uygula))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .themedPrimaryButton(cornerRadius: 18)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .themedSecondaryCard(cornerRadius: 22)
                }
                .padding(16)
            }
            .appScreenBackground(theme)
            .onAppear {
                customTargetValue = Double(initialTarget)
                customTargetText = "\(initialTarget)"
            }
        }
    }
}
