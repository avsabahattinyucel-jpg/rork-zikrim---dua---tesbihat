import SwiftUI

struct CounterView: View {
    @State private var viewModel: CounterViewModel
    let storage: StorageService
    let onGoHome: () -> Void
    @State private var isPremium: Bool = false
    @State private var customTargetValue: Double = 33
    @State private var customTargetText: String = "33"
    @State private var activeSession: ZikrSession? = nil
    @State private var showCelebration: Bool = false
    @State private var celebrationOpacity: Double = 0
    @State private var sparkleRadius: CGFloat = 80
    @State private var geminiService = GroqService()

    init(storage: StorageService, onGoHome: @escaping () -> Void) {
        self.storage = storage
        self.onGoHome = onGoHome
        self._viewModel = State(initialValue: CounterViewModel(storage: storage))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if let counter = viewModel.selectedCounter {
                        counterContent(counter)
                    } else {
                        emptyState
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Zikirlerim")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showNewCounterSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
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
                .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.hapticTrigger)

                if viewModel.showCompletionCard, let completed = viewModel.completedCounter {
                    ZikirCompletionView(
                        counter: completed,
                        session: activeSession,
                        todayCount: storage.todayStats().totalCount,
                        streak: storage.profile.currentStreak,
                        onRepeat: { viewModel.repeatCounter() },
                        onNext: { viewModel.nextCounter() },
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
            do {
                let info = try await RevenueCatService.shared.customerInfo()
                isPremium = RevenueCatService.shared.hasActiveEntitlement(info)
                AdService.shared.updatePremiumStatus(isPremium)
            } catch {}
        }
        .onChange(of: storage.pendingSelectedCounterId) { _, newId in
            if let id = newId, let counter = storage.counters.first(where: { $0.id == id }) {
                viewModel.selectCounter(counter)
                activeSession = storage.session(for: counter)
                storage.setActiveSession(from: counter)
                storage.pendingSelectedCounterId = nil
            }
        }
        .onChange(of: viewModel.showCompletionCard) { oldValue, newValue in
            if newValue && !oldValue && !isPremium {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(800))
                    AdService.shared.showInterstitial()
                }
            }
        }
        }
        .onAppear {
            if let counter = viewModel.selectedCounter {
                activeSession = storage.session(for: counter)
                storage.setActiveSession(from: counter)
            }
        }
        .safeAreaInset(edge: .bottom) {
            ConditionalBannerAd(isPremium: isPremium)
        }
        .onChange(of: viewModel.selectedCounter?.id) { _, _ in
            if let counter = viewModel.selectedCounter {
                activeSession = storage.session(for: counter)
                storage.setActiveSession(from: counter)
            } else {
                activeSession = nil
                storage.setActiveZikrSession(nil)
            }
        }
    }

    private func counterContent(_ counter: CounterModel) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles.bubble.fill")
                        .font(.subheadline)
                        .foregroundStyle(.teal)
                    Text(geminiService.zikirProgressAdvice(progress: counter.progress))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(14)
                .background(Color.teal.opacity(0.1))
                .clipShape(.rect(cornerRadius: 16))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Günlük İlerleme")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: min(Double(storage.todayStats().totalCount) / Double(max(storage.profile.dailyGoal, 1)), 1.0))
                            .tint(.accentColor)
                            .frame(width: 140)
                    }
                    Spacer()
                    Label("\(storage.profile.currentStreak) gün", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }

                if !favoriteQuickItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(favoriteQuickItems, id: \.id) { item in
                                Button {
                                    let existing = storage.counters.first(where: { $0.zikirItemId == item.id })
                                    if let existing {
                                        viewModel.selectCounter(existing)
                                    } else {
                                        viewModel.createCounter(name: item.turkishPronunciation, target: item.recommendedCount, zikirItemId: item.id)
                                    }
                                } label: {
                                    Text(item.turkishPronunciation)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(.capsule)
                                }
                            }
                        }
                    }
                }

                if !storage.customZikirs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(storage.customZikirs, id: \.id) { item in
                                Button {
                                    let existing = storage.counters.first(where: { $0.zikirItemId == item.id })
                                    if let existing {
                                        viewModel.selectCounter(existing)
                                    } else {
                                        viewModel.createCounter(name: item.turkishPronunciation, target: item.recommendedCount, zikirItemId: item.id)
                                    }
                                } label: {
                                    Label(item.turkishPronunciation, systemImage: "sparkles")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.14))
                                        .clipShape(.capsule)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()

            VStack(spacing: 8) {
                Text(activeSession?.zikrTitle ?? counter.name)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                if let session = activeSession {
                    VStack(spacing: 4) {
                        Text(session.arabicText)
                            .font(.title3)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .multilineTextAlignment(.center)
                            .environment(\.layoutDirection, .rightToLeft)
                        Text(session.transliteration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(session.meaning)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                } else {
                    Text("Zikir seçilmedi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Zikir seç") {
                        viewModel.showNewCounterSheet = true
                    }
                    .buttonStyle(.bordered)
                }

                Text("\(counter.currentCount) / \(counter.targetCount)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            ZStack {
                let beadCount = max(min(counter.targetCount, 99), 33)
                let beadDiameter: CGFloat = 10
                let beadRadius: CGFloat = 126

                ForEach(0..<beadCount, id: \.self) { index in
                    let normalizedProgress = counter.progress * Double(beadCount)
                    let isActive = Double(index) < normalizedProgress
                    let angle = Angle(degrees: (Double(index) / Double(beadCount)) * 360.0 - 90.0)

                    Circle()
                        .fill(isActive ? Color.accentColor.opacity(0.9) : Color(.tertiarySystemFill))
                        .overlay {
                            Circle()
                                .stroke(isActive ? Color.white.opacity(0.75) : Color.clear, lineWidth: 1)
                        }
                        .frame(width: beadDiameter, height: beadDiameter)
                        .offset(y: -beadRadius)
                        .rotationEffect(angle)
                        .scaleEffect(isActive ? 1.12 : 1.0)
                        .shadow(color: isActive ? Color.accentColor.opacity(0.35) : .clear, radius: isActive ? 4 : 0)
                        .animation(.easeInOut(duration: 0.2), value: counter.currentCount)
                }

                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 6)
                    .frame(width: 244, height: 244)

                if counter.progress > 0.85 {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .blur(radius: 16)
                }

                if showCelebration {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.green.opacity(0.35), Color.teal.opacity(0.15), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 130
                                )
                            )
                            .frame(width: 260, height: 260)
                            .blur(radius: 10)
                            .opacity(celebrationOpacity)

                        ForEach(0..<8, id: \.self) { i in
                            Image(systemName: i % 2 == 0 ? "sparkle" : "star.fill")
                                .font(.system(size: i % 2 == 0 ? 14 : 10, weight: .bold))
                                .foregroundStyle(
                                    i % 3 == 0 ? Color.yellow :
                                    i % 3 == 1 ? Color.teal : Color.green
                                )
                                .offset(y: -sparkleRadius)
                                .rotationEffect(.degrees(Double(i) * 45))
                                .opacity(celebrationOpacity)
                                .scaleEffect(celebrationOpacity)
                        }
                    }
                }

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 204, height: 204)
                    .overlay {
                        Button {
                            viewModel.increment()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "circle.hexagongrid.circle.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.95), Color.yellow.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .orange.opacity(0.25), radius: 8, y: 3)

                                Text("\(counter.currentCount)")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(counter.isCompleted ? .green : .primary)
                                    .contentTransition(.numericText())
                                    .scaleEffect(counter.currentCount > 0 ? 1.0 + min(counter.progress * 0.05, 0.05) : 1)

                                if counter.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 192, height: 192)
                        .contentShape(Circle())
                    }
            }
            .animation(.spring(duration: 0.25), value: counter.currentCount)
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

            HStack(spacing: 32) {
                Button {
                    viewModel.undo()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.title2)
                        Text("Geri Al")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .disabled(counter.currentCount == 0)

                Button {
                    viewModel.reset()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2)
                        Text("Sıfırla")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

                Button {
                    viewModel.showTargetPicker = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.title2)
                        Text("Hedef")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    viewModel.deleteSelected()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                        Text("Sil")
                            .font(.caption2)
                    }
                    .foregroundStyle(.red.opacity(0.7))
                }
            }
            .padding(.top, 8)

            Spacer()

            settingsRow
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
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

    private var settingsRow: some View {
        HStack(spacing: 16) {
            Toggle(isOn: Binding(
                get: { storage.profile.vibrationEnabled },
                set: {
                    storage.profile.vibrationEnabled = $0
                    storage.saveProfile()
                }
            )) {
                Label("Titreşim", systemImage: "iphone.radiowaves.left.and.right")
                    .font(.subheadline)
            }
            .toggleStyle(.switch)
            .tint(.accentColor)

            Divider().frame(height: 24)

            Toggle(isOn: Binding(
                get: { storage.profile.soundEnabled },
                set: {
                    storage.profile.soundEnabled = $0
                    storage.saveProfile()
                }
            )) {
                Label("Ses", systemImage: "speaker.wave.2")
                    .font(.subheadline)
            }
            .toggleStyle(.switch)
            .tint(.accentColor)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var favoriteQuickItems: [ZikirItem] {
        let all = ZikirData.categories.flatMap(\.items)
        return all.filter { storage.profile.favoriteZikirIds.contains($0.id) }.prefix(5).map { $0 }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        let angle = Angle(degrees: Double(i) / 12.0 * 360.0 - 90)
                        Circle()
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 11, height: 11)
                            .offset(y: -70)
                            .rotationEffect(angle)
                    }
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 5)
                        .frame(width: 120, height: 120)

                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                VStack(spacing: 10) {
                    Text("Zikir sayacı yok")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Tesbih çekerek manevi rutinini oluştur")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    viewModel.showNewCounterSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                        Text("Yeni Sayaç Ekle")
                            .font(.headline)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.04, green: 0.22, blue: 0.38), Color(red: 0.04, green: 0.38, blue: 0.42)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(.capsule)
                    .shadow(color: Color(red: 0.04, green: 0.38, blue: 0.42).opacity(0.4), radius: 12, y: 5)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

struct NewCounterSheet: View {
    let viewModel: CounterViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var arabicText: String = ""
    @State private var meaning: String = ""
    @State private var category: String = "Kişisel"
    @State private var selectedTarget: Int = 33
    @State private var customTargetText: String = "33"
    @State private var isFavorite: Bool = false
    private let targets = [33, 99, 100, 500, 1000]

    var body: some View {
        NavigationStack {
            Form {
                Section("Zikrini oluştur") {
                    TextField("Zikir Adı (Örn: Kelime-i Tevhid)", text: $name)
                    TextField("Arapça metin (opsiyonel)", text: $arabicText, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Anlam (opsiyonel)", text: $meaning, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Kategori", text: $category)
                    Toggle("Favori olarak ekle", isOn: $isFavorite)
                }

                Section("Hedef sayısı") {
                    Picker("Hazır", selection: $selectedTarget) {
                        ForEach(targets, id: \.self) { t in
                            Text("\(t)").tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.accentColor)

                    Slider(value: Binding(
                        get: { Double(selectedTarget) },
                        set: { newValue in
                            let rounded = max(Int(newValue.rounded()), 1)
                            selectedTarget = rounded
                            customTargetText = "\(rounded)"
                        }
                    ), in: 1...5000, step: 1)
                    .tint(.accentColor)

                    TextField("Manuel hedef", text: $customTargetText)
                        .keyboardType(.numberPad)
                        .onChange(of: customTargetText) { _, newValue in
                            if let value = Int(newValue), value > 0 {
                                selectedTarget = value
                            }
                        }
                }

                Section("Hazır zikirler") {
                    ForEach(ZikirData.categories.flatMap(\.items).prefix(8), id: \.id) { item in
                        Button {
                            name = item.turkishPronunciation
                            arabicText = item.arabicText
                            meaning = item.turkishMeaning
                            selectedTarget = item.recommendedCount
                            customTargetText = "\(item.recommendedCount)"
                            category = item.category
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.turkishPronunciation)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(item.turkishMeaning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Yeni Zikir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveTemplateAndCounter()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveTemplateAndCounter() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let item = ZikirItem(
            id: "custom_\(UUID().uuidString)",
            category: category.isEmpty ? "Kişisel" : category,
            arabicText: arabicText,
            turkishPronunciation: cleanName,
            turkishMeaning: meaning,
            recommendedCount: selectedTarget,
            source: "Kullanıcı"
        )

        viewModel.storage.addCustomZikir(item)
        if isFavorite {
            viewModel.storage.toggleFavorite(item.id)
        }
        viewModel.createCounter(name: cleanName, target: selectedTarget, zikirItemId: item.id)
    }
}

struct TargetEditorSheet: View {
    let initialTarget: Int
    @Binding var customTargetValue: Double
    @Binding var customTargetText: String
    let onSave: (Int) -> Void

    private let presets: [Int] = [33, 99, 100, 500, 1000]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Hedef Sayısı")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            customTargetValue = Double(preset)
                            customTargetText = "\(preset)"
                        } label: {
                            let isActive = Int(customTargetValue) == preset
                            Text("\(preset)")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isActive ? Color.accentColor : Color(.tertiarySystemFill))
                                .foregroundStyle(isActive ? .white : .primary)
                                .clipShape(.capsule)
                                .shadow(color: isActive ? Color.accentColor.opacity(0.5) : .clear, radius: isActive ? 6 : 0, y: isActive ? 2 : 0)
                                .animation(.spring(duration: 0.25), value: isActive)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Slider(value: $customTargetValue, in: 1...5000, step: 1)
                    .tint(.accentColor)
                    .onChange(of: customTargetValue) { _, newValue in
                        customTargetText = "\(Int(newValue))"
                    }

                TextField("Manuel hedef", text: $customTargetText)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(.rect(cornerRadius: 10))
                    .onChange(of: customTargetText) { _, newValue in
                        if let value = Int(newValue), value > 0 {
                            customTargetValue = Double(value)
                        }
                    }

                Text("Seçili: \(Int(customTargetValue))")
                    .font(.headline)

                Button {
                    onSave(max(Int(customTargetValue), 1))
                } label: {
                    Text("Uygula")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(16)
            .onAppear {
                customTargetValue = Double(initialTarget)
                customTargetText = "\(initialTarget)"
            }
        }
    }
}
