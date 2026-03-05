import SwiftUI
import UIKit
import Combine
import CoreLocation

struct GunlukView: View {
    let storage: StorageService
    let authService: AuthService
    let onOpenPrayer: () -> Void
    let onNavigateToTab: (Int) -> Void

    @State private var prayerService = PrayerTimeService()
    @State private var dailyDuaIndex: Int = {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return day % ZikirData.dailyDuas.count
    }()
    @State private var showProfile: Bool = false
    @State private var isPremium: Bool = false
    @State private var now: Date = Date()
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var saveMessage: String? = nil
    @State private var isSavingEntry: Bool = false
    @State private var saveTrigger: Bool = false
    @State private var showNotesSheet: Bool = false
    @State private var editingEntry: DailyJournalEntry? = nil
    @State private var selectedHabitDate: Date? = nil
    @State private var showHabitDetail: Bool = false
    @State private var khutbahService = KhutbahService()
    @State private var qiblaService = QiblaService()
    @State private var showQiblaSheet: Bool = false
    @State private var geminiService = GroqService()
    @State private var isGeneratingCard: Bool = false
    @State private var showAIAdAlert: Bool = false
    @State private var spiritualQuestion: String = ""
    @State private var spiritualAnswer: String = ""
    @State private var showSpiritualPopup: Bool = false
    @State private var isAskingSpiritualQuestion: Bool = false
    @FocusState private var isSpiritualFieldFocused: Bool
    @State private var customHabitText: String = ""
    @FocusState private var isCustomHabitFieldFocused: Bool
    @AppStorage("daily_custom_habits_v1") private var customHabitsRaw: String = ""

    @State private var shukurDraft: String = ""
    @State private var isEditingShukur: Bool = false
    @FocusState private var isShukurFieldFocused: Bool
    @State private var noteSparkle: Bool = false
    @State private var showFaithFlowSheet: Bool = false
    @State private var faithFlowDate: Date = Date()
    @State private var faithFlowNoteDraft: String = ""
    @State private var faithFlowAdvice: String = ""
    @FocusState private var isFaithFlowNoteFocused: Bool
    @State private var isLoadingFaithFlowAdvice: Bool = false
    @State private var showFaithFlowAdGateAlert: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var achievementImage: UIImage? = nil
    @State private var prayerBounce: String? = nil

    @AppStorage("daily_draft_note") private var draftNote: String = ""
    @AppStorage("daily_draft_dua") private var draftDua: String = ""
    @AppStorage("daily_draft_reflection") private var draftReflection: String = ""
    @AppStorage("faith_flow_free_unlocked_day_v1") private var faithFlowUnlockedDay: Double = 0

    private var record: DailyHabitRecord { storage.todayHabitRecord }

    private var todayStats: DailyStats { storage.todayStats() }

    private var dailyDua: ZikirItem {
        ZikirData.dailyDuas[dailyDuaIndex % ZikirData.dailyDuas.count]
    }

    private var topZikir: (name: String, count: Int)? {
        guard let item = todayStats.zikirDetails.max(by: { $0.value < $1.value }) else { return nil }
        return (name: item.key, count: item.value)
    }

    private var lastSevenDates: [Date] {
        (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -(6 - offset), to: Date())
        }
    }

    private var showSmartSuggestion: Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= 20 && record.shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM"
        return f
    }()

    private let timelineDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 18) {
                        progressHeroCard
                        spiritualFlowCard
                        prayerTrackerCard
                        nextPrayerMiniCard
                        qiblaCard
                        habitsCard
                        khutbahCard
                        aiCards
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .padding(.bottom, 72)
                }
                .background(
                    LinearGradient(
                        colors: [Color(.systemGroupedBackground), Color.teal.opacity(0.04), Color(.systemGroupedBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                faithFlowFAB
            }
            .navigationTitle("Günlük")
            .navigationDestination(for: String.self) { route in
                if route == "khutbah" { KhutbahView() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: { profileAvatarView }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfilView(storage: storage, authService: authService)
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
                        .presentationDetents([.fraction(0.35)])
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = achievementImage {
                    ShareSheetView(items: [image])
                }
            }
            .sheet(isPresented: $showQiblaSheet) {
                QiblaView()
            }
            .sheet(isPresented: $showFaithFlowSheet) {
                faithFlowSheet
                    .presentationDetents([.large])
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $showSpiritualPopup) {
                spiritualAnswerSheet
                    .presentationDetents([.medium, .large])
                    .presentationContentInteraction(.scrolls)
            }
            .safeAreaInset(edge: .bottom) {
                ConditionalBannerAd(isPremium: isPremium)
            }
            .task {
                await khutbahService.fetch()
            }
            .task {
                await geminiService.fetchDailyWisdom()
            }
            .task {
                await prayerService.fetchPrayerTimes()
                do {
                    let info = try await RevenueCatService.shared.customerInfo()
                    isPremium = RevenueCatService.shared.hasActiveEntitlement(info)
                    AdService.shared.updatePremiumStatus(isPremium)
                } catch {}
            }
            .onAppear {
                shukurDraft = record.shukurNote
                if qiblaService.authorizationStatus == .authorizedWhenInUse || qiblaService.authorizationStatus == .authorizedAlways {
                    qiblaService.startUpdates()
                }
            }
            .onDisappear {
                qiblaService.stopUpdates()
            }
            .onReceive(timer) { date in now = date }
            .onChange(of: faithFlowDate) { _, newDate in
                loadFaithFlowDraft(for: newDate)
            }
            .sensoryFeedback(.success, trigger: saveTrigger)
            .sensoryFeedback(.impact, trigger: prayerBounce)
            .alert("Rabia Özelliği", isPresented: $showAIAdAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Premium ile Rabia'yı sınırsız kullanabilirsiniz. Ücretsiz kullanımda reklam gösterilir.")
            }
            .alert("Günlük Akış Kilidi", isPresented: $showFaithFlowAdGateAlert) {
                Button("Reklamı İzle ve Günü Aç") {
                    AdService.shared.showInterstitial()
                    faithFlowUnlockedDay = Calendar.current.startOfDay(for: faithFlowDate).timeIntervalSince1970
                    loadFaithFlowDraft(for: faithFlowDate)
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Ücretsiz planda günlük akışta bir gün açmak için reklam izleyebilirsiniz.")
            }
        }
    }

    // MARK: - Progress Hero Card

    private var progressHeroCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Date(), format: .dateTime.weekday(.wide))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.60))
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text(Date(), format: .dateTime.day().month(.wide))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .shadow(color: .orange.opacity(0.6), radius: 4)
                    Text("\(storage.maneviStreak)")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("gün")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.12))
                .clipShape(.capsule)
                .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
            }

            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 12)
                        .frame(width: 108, height: 108)
                    Circle()
                        .trim(from: 0, to: record.progress)
                        .stroke(
                            AngularGradient(colors: [Color.teal.opacity(0.5), Color.cyan, Color.teal], center: .center),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 108, height: 108)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: record.progress)
                        .shadow(color: Color.teal.opacity(0.5), radius: 6)
                    VStack(spacing: 0) {
                        Text("\(Int(record.progress * 100))")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.5), value: Int(record.progress * 100))
                        Text("%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.teal)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    heroStatRow(icon: "moon.stars.fill", label: "Namaz", value: "\(record.completedPrayerCount)/5", filled: record.completedPrayerCount == 5)
                    heroStatRow(icon: "checkmark.circle.fill", label: "Alışkanlık", value: "\(record.completedHabits.count)/\(DailyHabitRecord.defaultHabits.count)", filled: record.completedHabits.count == DailyHabitRecord.defaultHabits.count)
                    heroStatRow(icon: "heart.text.square.fill", label: "Şükür notu", value: record.shukurNote.isEmpty ? "Eksik" : "✓", filled: !record.shukurNote.isEmpty)
                }
            }

            Button {
                generateAndShare()
            } label: {
                if isGeneratingCard {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.75).tint(.white)
                        Text("Hazırlanıyor…")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(.white.opacity(0.13))
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.15), lineWidth: 1))
                } else {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(.white.opacity(0.13))
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.15), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .background {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.4, 0.6], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color(red: 0.03, green: 0.10, blue: 0.28),
                        Color(red: 0.03, green: 0.18, blue: 0.34),
                        Color(red: 0.04, green: 0.14, blue: 0.32),
                        Color(red: 0.04, green: 0.22, blue: 0.38),
                        Color(red: 0.03, green: 0.32, blue: 0.40),
                        Color(red: 0.04, green: 0.28, blue: 0.38),
                        Color(red: 0.04, green: 0.26, blue: 0.36),
                        Color(red: 0.04, green: 0.38, blue: 0.42),
                        Color(red: 0.04, green: 0.30, blue: 0.38)
                    ]
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.14, blue: 0.32), Color(red: 0.04, green: 0.36, blue: 0.40)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(.rect(cornerRadius: 24))
    }

    private func heroStatRow(icon: String, label: String, value: String, filled: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(filled ? .teal : .white.opacity(0.4))
                .frame(width: 18)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(filled ? .teal : .white)
        }
    }

    // MARK: - Spiritual Flow Card (Redesigned)

    private var spiritualFlowCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.3), Color.teal.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.85, green: 0.70, blue: 0.20), .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Manevi Akış")
                        .font(.headline)
                    Text(hijriDateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !record.shukurNote.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                        .symbolEffect(.bounce, value: noteSparkle)
                }
            }

            if isEditingShukur {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 0) {
                        Image(systemName: "quote.opening")
                            .font(.caption)
                            .foregroundStyle(.teal.opacity(0.5))
                            .padding(.trailing, 6)
                        TextField("Bugün Allah için ne yaptığını paylaş…", text: $shukurDraft, axis: .vertical)
                            .focused($isShukurFieldFocused)
                            .submitLabel(.done)
                            .onSubmit { saveShukurNote() }
                            .lineLimit(3...6)
                            .font(.subheadline)
                    }
                    .padding(14)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(.rect(cornerRadius: 14))

                    HStack(spacing: 10) {
                        Button {
                            saveShukurNote()
                        } label: {
                            Label("Kaydet", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .disabled(shukurDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button("İptal") {
                            isShukurFieldFocused = false
                            withAnimation { isEditingShukur = false }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            } else if record.shukurNote.isEmpty {
                Button {
                    shukurDraft = ""
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isEditingShukur = true
                        isShukurFieldFocused = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.line")
                            .font(.subheadline.bold())
                            .foregroundStyle(.teal)
                            .frame(width: 36, height: 36)
                            .background(Color.teal.opacity(0.12))
                            .clipShape(.rect(cornerRadius: 10))
                        Text("Bugün Allah için ne yaptığını yaz…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption.bold())
                            .foregroundStyle(.teal.opacity(0.6))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.teal.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    shukurDraft = record.shukurNote
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isEditingShukur = true
                        isShukurFieldFocused = true
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.caption)
                            .foregroundStyle(.teal.opacity(0.5))
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.shukurNote)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                            Text("Düzenlemek için dokun")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.caption.bold())
                            .foregroundStyle(.teal.opacity(0.5))
                    }
                    .padding(14)
                    .background(Color.teal.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            if showSmartSuggestion && !isEditingShukur && record.shukurNote.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Gün bitmeden şükür notunu yazmayı unutma")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
                .clipShape(.rect(cornerRadius: 10))
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.15), Color(red: 0.85, green: 0.70, blue: 0.20).opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var hijriDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Faith Flow FAB

    private var faithFlowFAB: some View {
        Button {
            faithFlowDate = Date()
            loadFaithFlowDraft(for: faithFlowDate)
            showFaithFlowSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.04, green: 0.28, blue: 0.50), Color(red: 0.04, green: 0.45, blue: 0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: Color(red: 0.04, green: 0.36, blue: 0.40).opacity(0.45), radius: 14, x: 0, y: 6)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 18)
        .padding(.bottom, 76)
    }

    // MARK: - Prayer Tracker Card

    private var prayerTrackerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Namaz Takibi", systemImage: "moon.stars.fill")
                    .font(.headline)
                Spacer()
                Text("\(record.completedPrayerCount)/5 tamamlandı")
                    .font(.caption.bold())
                    .foregroundStyle(record.completedPrayerCount == 5 ? .teal : .secondary)
            }

            HStack(spacing: 0) {
                ForEach(DailyHabitRecord.prayerNames, id: \.self) { prayer in
                    let isCompleted = record.prayerStatus[prayer] == true
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            storage.togglePrayer(prayer)
                            prayerBounce = prayer
                        }
                    } label: {
                        VStack(spacing: 7) {
                            ZStack {
                                Circle()
                                    .fill(isCompleted ? Color.teal : Color(.tertiarySystemFill))
                                    .frame(width: 50, height: 50)
                                    .shadow(color: isCompleted ? Color.teal.opacity(0.55) : .clear, radius: 10, x: 0, y: 4)
                                Image(systemName: DailyHabitRecord.prayerIcons[prayer] ?? "moon.fill")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(isCompleted ? .white : .secondary)
                                    .symbolEffect(.bounce, value: isCompleted)
                            }
                            Text(prayer)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(isCompleted ? .teal : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }

            if record.completedPrayerCount == 5 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.teal)
                    Text("Tüm namazlar tamamlandı! Maşallah 🤲")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.teal.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    // MARK: - Next Prayer Card

    private var nextPrayerMiniCard: some View {
        Button {
            onOpenPrayer()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: prayerService.nextPrayer()?.systemImage ?? "clock.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sıradaki Namaz")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(prayerService.nextPrayer()?.name ?? "Yükleniyor")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(prayerService.nextPrayer()?.time ?? "--:--")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(remainingPrayerText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .contentTransition(.numericText())
                    }
                }

                if let times = prayerService.prayerTimes {
                    HStack(spacing: 10) {
                        prayerPill(icon: "moon.stars.fill", title: "Sabah", time: times.fajr)
                        prayerPill(icon: "sun.max.fill", title: "Öğle", time: times.dhuhr)
                        prayerPill(icon: "sun.haze.fill", title: "İkindi", time: times.asr)
                        prayerPill(icon: "sunset.fill", title: "Akşam", time: times.maghrib)
                        prayerPill(icon: "moon.fill", title: "Yatsı", time: times.isha)
                    }
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.26, blue: 0.5), Color(red: 0.07, green: 0.52, blue: 0.52)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Habits Card

    private var habitsCard: some View {
        let allHabits = DailyHabitRecord.defaultHabits + customHabits
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Günlük Alışkanlıklar", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                Spacer()
                Text("\(record.completedHabits.filter { allHabits.contains($0) }.count)/\(max(allHabits.count, 1))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                TextField("Alışkanlık ekle", text: $customHabitText)
                    .textInputAutocapitalization(.sentences)
                    .focused($isCustomHabitFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        addCustomHabit()
                    }
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(.rect(cornerRadius: 10))
                Button {
                    addCustomHabit()
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .frame(width: 34, height: 34)
                        .background(Color.teal.opacity(0.15))
                        .foregroundStyle(.teal)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(allHabits, id: \.self) { habit in
                    let isCompleted = record.completedHabits.contains(habit)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            storage.toggleHabit(habit)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .stroke(isCompleted ? Color.teal : Color(.tertiarySystemFill), lineWidth: 2)
                                    .frame(width: 26, height: 26)
                                if isCompleted {
                                    Circle()
                                        .fill(Color.teal)
                                        .frame(width: 26, height: 26)
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            Text(habit)
                                .font(.subheadline)
                                .foregroundStyle(isCompleted ? .primary : .secondary)
                                .strikethrough(isCompleted, color: .teal)
                            Spacer()
                            if customHabits.contains(habit) {
                                Button(role: .destructive) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        removeCustomHabit(habit)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption.bold())
                                        .foregroundStyle(.red)
                                        .frame(width: 28, height: 28)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(.rect(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)

                    if habit != allHabits.last {
                        Divider().padding(.leading, 40)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    // MARK: - Qibla Mini Card

    private var qiblaCard: some View {
        Button {
            showQiblaSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.06, green: 0.26, blue: 0.5), Color(red: 0.07, green: 0.52, blue: 0.52)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    if qiblaService.userLocation != nil {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(qiblaService.qiblaDirection))
                            .animation(.interpolatingSpring(stiffness: 80, damping: 12), value: qiblaService.qiblaDirection)
                    } else {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Kıble Bulucu")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    if qiblaService.authorizationStatus == .notDetermined {
                        Text("Kıble yönünü bulmak için dokun")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if qiblaService.authorizationStatus == .denied {
                        Text("Konum izni gerekli")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if qiblaService.userLocation != nil {
                        let isAligned: Bool = {
                            let n = ((qiblaService.qiblaDirection.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
                            return n < 5 || n > 355
                        }()
                        Text(isAligned ? "Kıble yönündesiniz ✓" : "\(Int(qiblaService.qiblaBearing))° \(bearingToCardinal(qiblaService.qiblaBearing))")
                            .font(.caption)
                            .foregroundStyle(isAligned ? .teal : .secondary)
                    } else {
                        Text("Konum alınıyor...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .onAppear {
            if qiblaService.authorizationStatus == .notDetermined {
                qiblaService.requestPermission()
            } else if qiblaService.authorizationStatus == .authorizedWhenInUse || qiblaService.authorizationStatus == .authorizedAlways {
                qiblaService.startUpdates()
            }
        }
    }

    private func bearingToCardinal(_ bearing: Double) -> String {
        let directions = ["Kuzey", "KD", "Doğu", "GD", "Güney", "GB", "Batı", "KB"]
        let index = Int(((bearing + 22.5).truncatingRemainder(dividingBy: 360)) / 45)
        return directions[max(0, min(index, 7))]
    }

    private func prayerPill(icon: String, title: String, time: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white)
            Text(time)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.12))
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: - Khutbah Card

    private var khutbahCard: some View {
        NavigationLink(value: "khutbah") {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "building.columns.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Text("Haftanın Hutbesi")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    if khutbahService.isLoading {
                        ProgressView().tint(.white).scaleEffect(0.75)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.06, green: 0.26, blue: 0.5), Color(red: 0.07, green: 0.52, blue: 0.52)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                VStack(alignment: .leading, spacing: 8) {
                    if let khutbah = khutbahService.content {
                        Text(khutbah.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        if !khutbah.date.isEmpty {
                            Label(khutbah.date, systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(String(khutbah.content.prefix(130)) + (khutbah.content.count > 130 ? "..." : ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    } else if khutbahService.isLoading {
                        HStack(spacing: 8) {
                            ProgressView().tint(.secondary).scaleEffect(0.8)
                            Text("Hutbe yükleniyor...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if let error = khutbahService.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Cards

    private var aiCards: some View {
        VStack(spacing: 12) {
            dailyGuidanceAndDuaCard
        }
    }

    private var maneviAssistantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Rabia'ya Sor", systemImage: "bubble.left.and.sparkles.fill")
                    .font(.headline)
                Spacer()
                AIBadge()
            }

            TextField("Rabia'ya sorunuzu yazın ve Enter'a basın…", text: $spiritualQuestion, axis: .vertical)
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
                        Text("Rabia düşünüyor…")
                            .font(.subheadline.bold())
                            .foregroundStyle(.teal)
                    } else {
                        Text("Sor")
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
                Text("Ücretsiz kullanıcılar için Rabia'da günde 1 soru hakkı vardır.")
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.25), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
                Text("Rabia'nın Günlük Rehberi")
                    .font(.headline)
                Spacer()
                if geminiService.isLoadingWisdom || geminiService.isLoadingAIDua {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.teal)
                        Text("Rabia düşünüyor…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    storage.toggleFavorite(dailyDua.id)
                } label: {
                    Image(systemName: storage.isFavorite(dailyDua.id) ? "moon.stars.fill" : "moon.stars")
                        .foregroundStyle(storage.isFavorite(dailyDua.id) ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }

            if (geminiService.isLoadingWisdom || geminiService.isLoadingAIDua) && geminiService.dailyWisdom == nil {
                ShimmerPlaceholder()
            } else {
                if let wisdom = geminiService.dailyWisdom {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Rabia'nın Tavsiyesi", systemImage: "lightbulb.max.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.teal)
                        Text(wisdom)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Rabia'nın Duası", systemImage: "hands.sparkles.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                    Text(geminiService.dailyAIDua ?? dailyDua.turkishMeaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Bu içerik Rabia tarafından hazırlanmıştır.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.07), Color.blue.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.teal.opacity(0.22), lineWidth: 1)
        )
    }

    // MARK: - My Notes Card

    private var myNotesAndDuasCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Günlük Notlarım")
                    .font(.headline)
                Spacer()
                Button {
                    draftDua = ""
                    draftNote = ""
                    draftReflection = ""
                    showNotesSheet = true
                } label: {
                    Label("Ekle", systemImage: "plus")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }

            if storage.journalEntries.isEmpty {
                Text("Dua, şükür ve tefekkür notlarınız burada görünür")
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
                                Text("🤲 \(entry.duaText)")
                                    .font(.caption)
                            }
                            if !entry.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("💛 \(entry.noteText)")
                                    .font(.caption)
                            }
                            if !entry.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("💭 \(entry.reflectionText)")
                                    .font(.caption)
                            }
                            HStack(spacing: 10) {
                                Button("Düzenle") {
                                    draftDua = entry.duaText
                                    draftNote = entry.noteText
                                    draftReflection = entry.reflectionText
                                    editingEntry = entry
                                }
                                .font(.caption.bold())
                                Button("Sil", role: .destructive) {
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
            Text("Favori Kısayollar")
                .font(.headline)

            if storage.favorites().isEmpty {
                Text("Favori zikir ve dualarınız burada görünür")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(storage.favorites().prefix(12)) { favorite in
                            Button {
                                switch favorite.type {
                                case .quran: onNavigateToTab(3)
                                case .zikir: onNavigateToTab(1)
                                case .dua: onNavigateToTab(2)
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

    // MARK: - Weekly Habit Card

    private var weeklyHabitCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Haftalık Takip")
                    .font(.headline)
                Spacer()
                Label("\(storage.profile.currentStreak)", systemImage: "flame.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 8) {
                ForEach(lastSevenDates, id: \.self) { date in
                    let dayStats = storage.stats(for: date)
                    let habitRec = storage.habitRecord(for: date)
                    let progress = min(Double(dayStats.totalCount) / Double(max(storage.profile.dailyGoal, 1)), 1.0)
                    let hasActivity = dayStats.totalCount > 0 || habitRec.completedPrayerCount > 0

                    Button {
                        selectedHabitDate = date
                        showHabitDetail = true
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(Color(.tertiarySystemFill), lineWidth: 4)
                                    .frame(width: 34, height: 34)
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(.teal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 34, height: 34)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                                if hasActivity {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Text(dayAbbreviation(for: date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 10) {
                statCell(title: "Seri", value: "\(storage.profile.currentStreak)", icon: "flame.fill", color: .orange)
                statCell(title: "En iyi", value: "\(storage.profile.longestStreak)", icon: "trophy.fill", color: .yellow)
                statCell(title: "Bugün", value: "\(todayStats.totalCount)", icon: "number.circle.fill", color: .teal)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    // MARK: - Helpers

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.subheadline.bold()).lineLimit(1)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemFill))
        .clipShape(.rect(cornerRadius: 10))
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
        faithFlowDate.formatted(date: .complete, time: .omitted)
    }

    private var hijriFlowDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: faithFlowDate)
    }

    private var remainingPrayerText: String {
        let remaining = prayerService.minutesUntilNextPrayer() ?? 0
        let h = remaining / 60
        let m = remaining % 60
        return h > 0 ? "\(h)s \(m)dk" : "\(m) dk"
    }

    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func userInitials(_ user: AuthUser) -> String {
        if let name = user.displayName, !name.isEmpty {
            let parts = name.split(separator: " ")
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
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
                Text("Rabia")
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
                        title: "Rabia Cevabı",
                        subtitle: Date().formatted(date: .abbreviated, time: .shortened),
                        detail: spiritualAnswer
                    )
                    storage.toggleFavorite(item)
                } label: {
                    Label("Favorilere Kaydet", systemImage: "moon.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    saveSpiritualAnswerImage()
                } label: {
                    Label("Görsel Olarak Telefona Kaydet", systemImage: "photo.badge.plus")
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
            .navigationTitle("Manevi Akış")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var faithFlowDateHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Miladi", systemImage: "calendar")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(gregorianFlowDateText)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Label("Hicri", systemImage: "moon.stars.fill")
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
            DatePicker("Tarih", selection: $faithFlowDate, displayedComponents: .date)
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
                Label("Dini Günler & Kandiller", systemImage: "star.fill")
                    .font(.headline)
                Spacer()
            }

            let currentMonth = Calendar.current.component(.month, from: faithFlowDate)
            let monthEvents = religiousDays.filter { $0.month == currentMonth }
            let otherEvents = religiousDays.filter { $0.month != currentMonth }

            if !monthEvents.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(monthEvents.enumerated()), id: \.element.title) { index, day in
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
                Text("Bu ayda özel bir dini gün bulunmuyor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Text("Yaklaşan Diğer Günler")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            VStack(spacing: 0) {
                ForEach(Array(otherEvents.enumerated()), id: \.element.title) { index, day in
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
        formatter.locale = Locale(identifier: "tr_TR")
        let symbols = formatter.shortMonthSymbols ?? []
        guard month >= 1, month <= symbols.count else { return "" }
        return symbols[month - 1].uppercased()
    }

    private func daysUntilText(month: Int, day: Int) -> String {
        let target = dateForCurrentYear(month: month, day: day)
        let today = Calendar.current.startOfDay(for: Date())
        let targetDay = Calendar.current.startOfDay(for: target)
        let diff = Calendar.current.dateComponents([.day], from: today, to: targetDay).day ?? 0
        if diff == 0 { return "Bugün" }
        if diff < 0 { return "Geçti" }
        return "\(diff) gün sonra"
    }

    private var faithFlowNoteSection: some View {
        Group {
            if !canAccessFaithFlow(for: faithFlowDate) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bu gün için kilitli")
                        .font(.headline)
                    Text("Ücretsiz planda reklam izleyerek bu günü açabilirsiniz.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Reklamı İzle ve Aç") {
                        showFaithFlowAdGateAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(14)
                .background(Color.orange.opacity(0.12))
                .clipShape(.rect(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bugün Allah için ne yaptın?")
                        .font(.title3.bold())

                    TextField("Niyetini ve yaptığını yaz…", text: $faithFlowNoteDraft, axis: .vertical)
                        .focused($isFaithFlowNoteFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            saveFaithFlow()
                        }
                        .lineLimit(3...7)
                        .padding(14)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(.rect(cornerRadius: 12))

                    Button {
                        saveFaithFlow()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                            Text("Kaydet ve Rabia'ya Sor")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .disabled(faithFlowNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if isLoadingFaithFlowAdvice {
                        HStack(spacing: 8) {
                            ProgressView().tint(.teal)
                            Text("Rabia o güne özel öneriyi hazırlıyor…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if !faithFlowAdvice.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Rabia'nın Tavsiyesi", systemImage: "sparkles")
                                .font(.subheadline.bold())
                                .foregroundStyle(.teal)
                            Text(faithFlowAdvice)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.teal.opacity(0.10))
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    private var faithFlowHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Geçmiş Akış")
                .font(.headline)
            if storage.faithLogs.isEmpty {
                Text("Henüz kayıt yok")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(storage.faithLogs.prefix(30)) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.date, format: .dateTime.day().month(.wide).year())
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
        customHabitsRaw
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func addCustomHabit() {
        let trimmed = customHabitText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var habits = customHabits
        guard !habits.contains(trimmed) else {
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

    private nonisolated struct ReligiousDay: Sendable {
        let title: String
        let day: Int
        let month: Int
    }

    private var religiousDays: [ReligiousDay] {
        [
            ReligiousDay(title: "Regaib Kandili", day: 2, month: 1),
            ReligiousDay(title: "Miraç Kandili", day: 26, month: 1),
            ReligiousDay(title: "Berat Kandili", day: 13, month: 2),
            ReligiousDay(title: "Kadir Gecesi", day: 26, month: 3),
            ReligiousDay(title: "Ramazan Bayramı", day: 30, month: 3),
            ReligiousDay(title: "Kurban Bayramı", day: 6, month: 6),
            ReligiousDay(title: "Mevlid Kandili", day: 11, month: 9)
        ]
    }

    private var selectedReligiousDay: ReligiousDay {
        let day = Calendar.current.component(.day, from: faithFlowDate)
        let month = Calendar.current.component(.month, from: faithFlowDate)
        return religiousDays.first(where: { $0.day == day && $0.month == month }) ?? ReligiousDay(title: "Bugünün Manevi Günü", day: day, month: month)
    }

    private func dateForCurrentYear(month: Int, day: Int) -> Date {
        let year = Calendar.current.component(.year, from: Date())
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    private func canAccessFaithFlow(for date: Date) -> Bool {
        if isPremium { return true }
        let unlocked = Date(timeIntervalSince1970: faithFlowUnlockedDay)
        return Calendar.current.isDate(unlocked, inSameDayAs: date)
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
            showFaithFlowAdGateAlert = true
            return
        }
        let trimmed = faithFlowNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isFaithFlowNoteFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        storage.upsertFaithLog(for: faithFlowDate, note: trimmed, photoBase64: nil)
        saveTrigger.toggle()

        Task {
            await fetchFaithFlowAdvice(for: selectedReligiousDay, userNote: trimmed)
        }
    }

    private func fetchFaithFlowAdvice(for day: ReligiousDay, userNote: String? = nil) async {
        guard canAccessFaithFlow(for: faithFlowDate) else {
            showFaithFlowAdGateAlert = true
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
        faithFlowAdvice = response ?? "Şu an tavsiye oluşturulamadı."
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
                if let info = try? await RevenueCatService.shared.customerInfo(), RevenueCatService.shared.hasActiveEntitlement(info) {
                    isPremium = true
                }
            }

            if !isPremium && !geminiService.canAskDailySpiritualQuestion() {
                showAIAdAlert = true
                return
            }

            if !isPremium {
                AdService.shared.showInterstitial()
            }

            isAskingSpiritualQuestion = true
            let response = try? await geminiService.answerSpiritualQuestion(trimmed)
            spiritualAnswer = response ?? "Şu an yanıt üretilemedi. Lütfen tekrar deneyin."
            showSpiritualPopup = true
            if !isPremium {
                geminiService.markDailySpiritualQuestionAsked()
            }
            isAskingSpiritualQuestion = false
            spiritualQuestion = ""
        }
    }

    private func saveSpiritualAnswerImage() {
        let card = VStack(alignment: .leading, spacing: 18) {
            Text("Rabia")
                .font(.system(size: 62, weight: .bold))
                .foregroundStyle(.white)
            Text(spiritualAnswer)
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
            Spacer()
            Text("Zikrim - Dua & Tesbihat")
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
                Text(entry == nil ? "Notlarım ve Dualarım" : "Notu Düzenle")
                    .font(.title3.bold())

                Group {
                    TextField("Kişisel dua", text: $draftDua, axis: .vertical)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .lineLimit(2...4)
                    TextField("Şükür notu", text: $draftNote, axis: .vertical)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .lineLimit(2...4)
                    TextField("Günlük tefekkür", text: $draftReflection, axis: .vertical)
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
                        Label(entry == nil ? "Kaydet" : "Güncelle", systemImage: "checkmark.circle.fill")
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
        return VStack(alignment: .leading, spacing: 12) {
            Text(dayLabelFormatter.string(from: date))
                .font(.headline)
            HStack {
                Label("\(habitRec.completedPrayerCount)/5 namaz", systemImage: "moon.stars.fill")
                Spacer()
                Text("Namaz takibi")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("\(stats.totalCount)", systemImage: "number.circle.fill")
                Spacer()
                Text("Toplam zikir")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("\(habitRec.completedHabits.count) alışkanlık", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("Tamamlanan")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
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
        saveMessage = entry == nil ? "Günlük kaydı eklendi" : "Günlük kaydı güncellendi"
        saveTrigger.toggle()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        showNotesSheet = false
        editingEntry = nil

        if authService.isLoggedIn, let userID = authService.currentUser?.id {
            await CloudBackupService.shared.backupNow(userID: userID, storage: storage)
        }

        isSavingEntry = false
    }

    private func deleteJournalEntry(_ id: String) async {
        storage.deleteJournalEntry(id: id)
        saveMessage = "Günlük kaydı silindi"
        if authService.isLoggedIn, let userID = authService.currentUser?.id {
            await CloudBackupService.shared.backupNow(userID: userID, storage: storage)
        }
    }

    // MARK: - Achievement Card

    private func generateAndShare() {
        if !isPremium {
            AdService.shared.showInterstitial()
        }

        Task {
            isGeneratingCard = true
            let reflection = try? await geminiService.generateReflectionNote(
                progress: record.progress,
                streak: storage.maneviStreak,
                prayerCount: record.completedPrayerCount
            )
            isGeneratingCard = false
            let cardView = AchievementCardView(
                date: Date(),
                progress: record.progress,
                streak: storage.maneviStreak,
                prayerCount: record.completedPrayerCount,
                habitCount: record.completedHabits.count,
                reflectionNote: reflection
            )
            let renderer = ImageRenderer(content: cardView)
            renderer.scale = 3.0
            achievementImage = renderer.uiImage
            showShareSheet = achievementImage != nil
        }
    }
}
