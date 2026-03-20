import Foundation

@Observable
@MainActor
class StorageService {
    private let countersKey = "saved_counters"
    private let selectedCounterKey = "selected_counter_id"
    private let profileKey = "user_profile"
    private let statsKey = "daily_stats"
    private let customZikirsKey = "custom_zikirs"
    private let journalEntriesKey = "daily_journal_entries"
    private let zikrSessionKey = "active_zikr_session"
    private let habitRecordKey = "daily_habit_records"
    private let qadaTrackersKey = "prayer_qada_trackers"
    private let qadaCalculationPlanKey = "prayer_qada_calculation_plan"
    private let faithLogKey = "daily_faith_logs"
    private let storageScopeKey = "storage_scope_id"
    private let guestScopeID = "guest"
    
    var counters: [CounterModel] = []
    var selectedCounterID: String? = nil
    var profile: UserProfile = UserProfile()
    var allStats: [DailyStats] = []
    var customZikirs: [ZikirItem] = []
    var journalEntries: [DailyJournalEntry] = []
    var pendingSelectedCounterId: String? = nil
    var activeZikrSession: ZikrSession? = nil
    var habitRecords: [DailyHabitRecord] = []
    var qadaTrackers: [PrayerName: QadaTracker] = QadaTracker.defaultTrackers()
    var qadaCalculationPlan: QadaCalculationPlan? = nil
    var faithLogs: [DailyFaithLogEntry] = []
    var maneviStreak: Int = 0
    private var currentScopeID: String
    private var deferredCountersSaveTask: Task<Void, Never>?
    private var deferredProgressSaveTask: Task<Void, Never>?

    init() {
        currentScopeID = UserDefaults.standard.string(forKey: storageScopeKey) ?? guestScopeID
        loadAll()
    }

    func loadAll() {
        counters = loadScoped([CounterModel].self, key: countersKey) ?? []
        selectedCounterID = load(String.self, key: scopedKey(selectedCounterKey))
        profile = loadScoped(UserProfile.self, key: profileKey) ?? UserProfile()
        allStats = loadScoped([DailyStats].self, key: statsKey) ?? []
        customZikirs = loadScoped([ZikirItem].self, key: customZikirsKey) ?? []
        journalEntries = (loadScoped([DailyJournalEntry].self, key: journalEntriesKey) ?? []).sorted { $0.createdAt > $1.createdAt }
        activeZikrSession = loadScoped(ZikrSession.self, key: zikrSessionKey)
        habitRecords = loadScoped([DailyHabitRecord].self, key: habitRecordKey) ?? []
        qadaTrackers = mergedQadaTrackers(from: loadScoped([PrayerName: QadaTracker].self, key: qadaTrackersKey) ?? [:])
        qadaCalculationPlan = loadScoped(QadaCalculationPlan.self, key: qadaCalculationPlanKey)
        faithLogs = (loadScoped([DailyFaithLogEntry].self, key: faithLogKey) ?? []).sorted { $0.date > $1.date }
        normalizeSelectedCounter()
        recomputeManeviStreak()
    }

    func saveCounters() { saveScoped(counters, key: countersKey) }
    func saveSelectedCounter() {
        let key = scopedKey(selectedCounterKey)
        if let selectedCounterID {
            save(selectedCounterID, key: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    func saveProfile() { saveScoped(profile, key: profileKey) }
    func saveStats() { saveScoped(allStats, key: statsKey) }
    func saveCustomZikirs() { saveScoped(customZikirs, key: customZikirsKey) }
    func saveJournalEntries() { saveScoped(journalEntries, key: journalEntriesKey) }
    func saveActiveZikrSession() { saveScoped(activeZikrSession, key: zikrSessionKey) }
    func saveHabitRecords() { saveScoped(habitRecords, key: habitRecordKey) }
    func saveQadaTrackers() { saveScoped(qadaTrackers, key: qadaTrackersKey) }
    func saveQadaCalculationPlan() { saveScoped(qadaCalculationPlan, key: qadaCalculationPlanKey) }
    func saveFaithLogs() { saveScoped(faithLogs, key: faithLogKey) }

    var todayHabitRecord: DailyHabitRecord {
        let today = todayString()
        return habitRecords.first(where: { $0.dateString == today }) ?? DailyHabitRecord(dateString: today)
    }

    func togglePrayer(_ prayer: String) {
        guard let prayerName = prayerName(fromLegacyLabel: prayer), prayerName.isObligatory else { return }
        let current = prayerCompletionStatus(for: prayerName)
        let next: PrayerCompletionStatus = current == .prayed ? .unknown : .prayed
        setPrayerCompletionStatus(next, for: prayerName)
    }

    func prayerCompletionStatus(for prayer: PrayerName, on date: Date = Date()) -> PrayerCompletionStatus {
        guard prayer.isObligatory else { return .unknown }
        return habitRecord(for: date).prayerCompletionStatus(for: prayer)
    }

    func prayerCompletionMap(for date: Date = Date()) -> [PrayerName: PrayerCompletionStatus] {
        Dictionary(uniqueKeysWithValues: PrayerName.obligatoryCases.map { prayer in
            (prayer, prayerCompletionStatus(for: prayer, on: date))
        })
    }

    func setPrayerCompletionStatus(_ status: PrayerCompletionStatus, for prayer: PrayerName, on date: Date = Date()) {
        guard prayer.isObligatory else { return }
        var record = habitRecord(for: date)
        let previousStatus = record.prayerCompletionStatus(for: prayer)
        record.setPrayerCompletionStatus(status, for: prayer)

        if previousStatus != .missed || status != .missed {
            record.qadaLinkedPrayerKeys.removeAll { $0 == prayer.rawValue }
        }

        upsertHabitRecord(record)
    }

    func dailyPrayerProgress(on date: Date = Date()) -> PrayerDailyProgress {
        PrayerDailyProgress(
            completedCount: habitRecord(for: date).completedPrayerCount,
            totalCount: PrayerName.obligatoryCases.count
        )
    }

    func weeklyPrayerHistory(days: Int = 7, endingOn endDate: Date = Date()) -> [PrayerHistoryDay] {
        let calendar = Calendar.current

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(days - 1 - offset), to: endDate) else { return nil }
            let record = habitRecord(for: date)
            return PrayerHistoryDay(
                date: calendar.startOfDay(for: date),
                completionCount: record.completedPrayerCount,
                totalCount: PrayerName.obligatoryCases.count,
                statuses: prayerCompletionMap(for: date)
            )
        }
    }

    func qadaTracker(for prayer: PrayerName) -> QadaTracker {
        qadaTrackers[prayer] ?? QadaTracker(prayerType: prayer, missedCount: 0, completedQadaCount: 0, userAdjustedValue: nil)
    }

    func allQadaTrackers() -> [PrayerName: QadaTracker] {
        mergedQadaTrackers(from: qadaTrackers)
    }

    func pendingQadaSuggestions(on date: Date = Date()) -> [PrayerName] {
        let record = habitRecord(for: date)
        return PrayerName.obligatoryCases.filter { prayer in
            record.prayerCompletionStatus(for: prayer) == .missed && !record.isLinkedToQada(prayer)
        }
    }

    func missedPrayers(on date: Date = Date()) -> [PrayerName] {
        PrayerName.obligatoryCases.filter { prayerCompletionStatus(for: $0, on: date) == .missed }
    }

    func addMissedPrayerToQada(_ prayer: PrayerName, on date: Date = Date()) {
        guard prayer.isObligatory else { return }

        incrementQada(for: prayer)
        var record = habitRecord(for: date)
        record.markLinkedToQada(prayer)
        upsertHabitRecord(record)
    }

    func incrementQada(for prayer: PrayerName) {
        guard prayer.isObligatory else { return }
        var tracker = qadaTracker(for: prayer)
        let currentValue = tracker.userAdjustedValue ?? tracker.missedCount
        tracker.userAdjustedValue = currentValue + 1
        qadaTrackers[prayer] = tracker
        saveQadaTrackers()
    }

    func decrementQada(for prayer: PrayerName) {
        guard prayer.isObligatory else { return }
        var tracker = qadaTracker(for: prayer)
        let currentValue = tracker.userAdjustedValue ?? tracker.missedCount
        tracker.userAdjustedValue = max(currentValue - 1, 0)
        qadaTrackers[prayer] = tracker
        saveQadaTrackers()
    }

    func completeQada(for prayer: PrayerName) {
        guard prayer.isObligatory else { return }
        var tracker = qadaTracker(for: prayer)
        guard tracker.outstandingCount > 0 else { return }
        tracker.userAdjustedValue = max(tracker.outstandingCount - 1, 0)
        tracker.completedQadaCount += 1
        qadaTrackers[prayer] = tracker
        saveQadaTrackers()
    }

    func applyQadaCalculation(yearsNotPrayed: Int) {
        let existingTrackers = allQadaTrackers()
        let plan = Self.makeQadaCalculationPlan(yearsNotPrayed: yearsNotPrayed)

        qadaCalculationPlan = plan
        qadaTrackers = Self.qadaTrackers(applying: plan, to: existingTrackers)

        saveQadaCalculationPlan()
        saveQadaTrackers()
    }

    nonisolated static func makeQadaCalculationPlan(yearsNotPrayed: Int, createdAt: Date = Date()) -> QadaCalculationPlan? {
        let sanitizedYears = max(yearsNotPrayed, 0)
        guard sanitizedYears > 0 else { return nil }

        return QadaCalculationPlan(
            yearsNotPrayed: sanitizedYears,
            estimatedDays: sanitizedYears * 365,
            createdAt: createdAt
        )
    }

    nonisolated static func qadaTrackers(applying plan: QadaCalculationPlan?, to existingTrackers: [PrayerName: QadaTracker]) -> [PrayerName: QadaTracker] {
        var updatedTrackers = QadaTracker.defaultTrackers()

        for prayer in PrayerName.obligatoryCases {
            let existingTracker = existingTrackers[prayer] ?? QadaTracker(
                prayerType: prayer,
                missedCount: 0,
                completedQadaCount: 0,
                userAdjustedValue: nil
            )

            var tracker = existingTracker
            tracker.missedCount = plan?.estimatedCountPerPrayer ?? 0
            tracker.userAdjustedValue = max((plan?.estimatedCountPerPrayer ?? 0) - existingTracker.completedQadaCount, 0)
            updatedTrackers[prayer] = tracker
        }

        return updatedTrackers
    }

    nonisolated static func previewQadaCalculation(yearsNotPrayed: Int, existingTrackers: [PrayerName: QadaTracker]) -> QadaCalculationPreview {
        let sanitizedYears = max(yearsNotPrayed, 0)
        let plan = makeQadaCalculationPlan(yearsNotPrayed: sanitizedYears)
        let trackers = qadaTrackers(applying: plan, to: existingTrackers)
        let totalOutstanding = PrayerName.obligatoryCases.reduce(0) { partialResult, prayer in
            partialResult + (trackers[prayer]?.outstandingCount ?? 0)
        }

        return QadaCalculationPreview(
            yearsNotPrayed: sanitizedYears,
            estimatedCountPerPrayer: plan?.estimatedCountPerPrayer ?? 0,
            totalOutstanding: totalOutstanding
        )
    }

    func toggleHabit(_ habit: String) {
        var record = todayHabitRecord
        if record.completedHabits.contains(habit) {
            record.completedHabits.removeAll { $0 == habit }
        } else {
            record.completedHabits.append(habit)
        }
        upsertHabitRecord(record)
    }

    func saveShukurNote(_ note: String) {
        var record = todayHabitRecord
        record.shukurNote = note
        upsertHabitRecord(record)
    }

    func habitRecord(for date: Date) -> DailyHabitRecord {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return habitRecords.first(where: { $0.dateString == dateString }) ?? DailyHabitRecord(dateString: dateString)
    }

    private func upsertHabitRecord(_ record: DailyHabitRecord) {
        if let index = habitRecords.firstIndex(where: { $0.dateString == record.dateString }) {
            habitRecords[index] = record
        } else {
            habitRecords.append(record)
        }
        saveHabitRecords()
        recomputeManeviStreak()
    }

    private func mergedQadaTrackers(from stored: [PrayerName: QadaTracker]) -> [PrayerName: QadaTracker] {
        var merged = QadaTracker.defaultTrackers()
        for prayer in PrayerName.obligatoryCases {
            if let tracker = stored[prayer] {
                merged[prayer] = tracker
            }
        }
        return merged
    }

    private func prayerName(fromLegacyLabel label: String) -> PrayerName? {
        switch label {
        case "Sabah":
            return .fajr
        case "Öğle":
            return .dhuhr
        case "İkindi":
            return .asr
        case "Akşam":
            return .maghrib
        case "Yatsı":
            return .isha
        default:
            return nil
        }
    }

    private func recomputeManeviStreak() {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for _ in 0..<366 {
            let dateStr = formatter.string(from: checkDate)
            let hasCompletedDhikr = allStats.first(where: { $0.dateString == dateStr })?.totalCount ?? 0 > 0
            if let record = habitRecords.first(where: { $0.dateString == dateStr }),
               record.completedPrayerCount == DailyHabitRecord.prayerNames.count,
               hasCompletedDhikr {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        maneviStreak = streak
    }

    func addCounter(_ counter: CounterModel) {
        counters.append(counter)
        saveCounters()
        if selectedCounterID == nil {
            selectedCounterID = counter.id
            saveSelectedCounter()
        }
    }

    func setActiveZikrSession(_ session: ZikrSession?) {
        activeZikrSession = session
        saveActiveZikrSession()
    }

    func updateCounter(_ counter: CounterModel) {
        if let index = counters.firstIndex(where: { $0.id == counter.id }) {
            counters[index] = counter
            scheduleDeferredCountersSave()
            normalizeSelectedCounter()
        }
    }

    var selectedCounter: CounterModel? {
        if let selectedCounterID,
           let counter = counters.first(where: { $0.id == selectedCounterID }) {
            return counter
        }
        return counters.first
    }

    func selectCounter(id: String?) {
        let resolvedID: String?
        if let id, counters.contains(where: { $0.id == id }) {
            resolvedID = id
        } else {
            resolvedID = counters.first?.id
        }

        guard selectedCounterID != resolvedID else { return }
        selectedCounterID = resolvedID
        saveSelectedCounter()
    }

    func session(for counter: CounterModel) -> ZikrSession? {
        if let session = activeZikrSession, session.sourceID == counter.zikirItemId {
            return session
        }
        if let snapshot = counter.sessionSnapshot {
            return snapshot
        }
        guard let zikirItemId = counter.zikirItemId else { return nil }

        if let rehber = ZikirRehberiData.entries.first(where: { $0.id == zikirItemId }) {
            return ZikrSession(
                zikrTitle: rehber.title,
                arabicText: rehber.arabicText,
                transliteration: rehber.transliteration,
                meaning: rehber.meaning,
                recommendedCount: rehber.recommendedCount,
                category: rehber.category.displayName,
                sourceID: rehber.id
            )
        }

        let allZikir = ZikirData.categories.flatMap(\.items) + ZikirData.dailyDuas + customZikirs
        if let zikir = allZikir.first(where: { $0.id == zikirItemId }) {
            return ZikrSession(
                zikrTitle: zikir.turkishPronunciation,
                arabicText: zikir.arabicText,
                transliteration: zikir.turkishPronunciation,
                meaning: zikir.turkishMeaning,
                recommendedCount: zikir.recommendedCount,
                category: zikir.category,
                sourceID: zikir.id
            )
        }

        return nil
    }

    func resolvedSession(for counter: CounterModel) -> ZikrSession {
        if let session = session(for: counter) {
            return session
        }

        return ZikrSession(
            zikrTitle: counter.name,
            arabicText: "",
            transliteration: counter.name,
            meaning: "",
            recommendedCount: counter.targetCount,
            category: "Kişisel",
            sourceID: counter.zikirItemId
        )
    }

    func setActiveSession(from counter: CounterModel) {
        setActiveZikrSession(session(for: counter))
    }

    func deleteCounter(_ counter: CounterModel) {
        counters.removeAll { $0.id == counter.id }
        saveCounters()
        normalizeSelectedCounter()
    }

    func addZikirCount(_ count: Int, zikirName: String, session: ZikrSession? = nil) {
        let today = todayString()
        let index: Int
        if let existingIndex = allStats.firstIndex(where: { $0.dateString == today }) {
            index = existingIndex
        } else {
            allStats.append(DailyStats())
            index = allStats.count - 1
        }

        allStats[index].totalCount = max(allStats[index].totalCount + count, 0)
        let updatedCount = (allStats[index].zikirDetails[zikirName] ?? 0) + count
        if updatedCount > 0 {
            allStats[index].zikirDetails[zikirName] = updatedCount
        } else {
            allStats[index].zikirDetails.removeValue(forKey: zikirName)
        }

        updateDhikrRecord(in: &allStats[index], countDelta: count, fallbackTitle: zikirName, session: session)

        profile.totalLifetimeCount = max(profile.totalLifetimeCount + count, 0)
        updateStreak()
        scheduleDeferredProgressSave()
    }

    func completeSession() {
        let today = todayString()
        if let index = allStats.firstIndex(where: { $0.dateString == today }) {
            allStats[index].sessionsCompleted += 1
        } else {
            var stats = DailyStats()
            stats.sessionsCompleted = 1
            allStats.append(stats)
        }
        saveStats()
    }

    func todayStats() -> DailyStats {
        let today = todayString()
        return allStats.first(where: { $0.dateString == today }) ?? DailyStats()
    }

    func weeklyStats() -> [DailyStats] {
        let calendar = Calendar.current
        let today = Date()
        var result: [DailyStats] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateStr = formatter.string(from: date)
            if let stats = allStats.first(where: { $0.dateString == dateStr }) {
                result.append(stats)
            } else {
                result.append(DailyStats(date: date))
            }
        }
        return result.reversed()
    }

    func toggleFavorite(_ item: FavoriteItem) {
        if profile.favoriteZikirIds.contains(item.id) {
            profile.favoriteZikirIds.removeAll { $0 == item.id }
            profile.favorites.removeAll { $0.id == item.id }
        } else {
            profile.favoriteZikirIds.append(item.id)
            profile.favorites.removeAll { $0.id == item.id }
            profile.favorites.append(item)
        }
        saveProfile()
    }

    func toggleFavorite(_ id: String) {
        if let existing = profile.favorites.first(where: { $0.id == id }) {
            toggleFavorite(existing)
            return
        }
        if let dua = ZikirData.dailyDuas.first(where: { $0.id == id }) {
            toggleFavorite(FavoriteItem(id: dua.id, type: .dua, title: dua.turkishPronunciation, subtitle: dua.source, detail: dua.turkishMeaning))
            return
        }
        let allZikir = ZikirData.categories.flatMap(\.items) + customZikirs
        if let zikir = allZikir.first(where: { $0.id == id }) {
            toggleFavorite(FavoriteItem(id: zikir.id, type: .zikir, title: zikir.turkishPronunciation, subtitle: zikir.source, detail: zikir.turkishMeaning))
            return
        }
        if let rehber = ZikirRehberiData.entries.first(where: { $0.id == id }) {
            toggleFavorite(FavoriteItem(id: rehber.id, type: .dua, title: rehber.title, subtitle: rehber.category.displayName, detail: rehber.purpose))
            return
        }
        if profile.favoriteZikirIds.contains(id) {
            profile.favoriteZikirIds.removeAll { $0 == id }
        } else {
            profile.favoriteZikirIds.append(id)
        }
        saveProfile()
    }

    func isFavorite(_ id: String) -> Bool {
        profile.favoriteZikirIds.contains(id)
    }

    func favorites(of type: FavoriteItemType? = nil) -> [FavoriteItem] {
        let list = profile.favorites.sorted { $0.createdAt > $1.createdAt }
        guard let type else { return list }
        return list.filter { $0.type == type }
    }

    func addCustomZikir(_ item: ZikirItem) {
        customZikirs.removeAll { $0.id == item.id }
        customZikirs.append(item)
        saveCustomZikirs()
    }

    func deleteCustomZikir(_ item: ZikirItem) {
        deleteCustomZikir(id: item.id)
    }

    func deleteCustomZikir(id: String) {
        customZikirs.removeAll { $0.id == id }
        profile.favoriteZikirIds.removeAll { $0 == id }
        profile.favorites.removeAll { $0.id == id }
        saveCustomZikirs()
        saveProfile()
    }

    func faithLog(for date: Date) -> DailyFaithLogEntry? {
        let calendar = Calendar.current
        return faithLogs.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func upsertFaithLog(for date: Date, note: String, photoBase64: String?) {
        if let index = faithLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            faithLogs[index].note = note
            faithLogs[index].photoBase64 = photoBase64
        } else {
            let entry = DailyFaithLogEntry(date: date, note: note, photoBase64: photoBase64)
            faithLogs.append(entry)
        }
        faithLogs.sort { $0.date > $1.date }
        saveFaithLogs()
    }

    func deleteFaithLog(id: String) {
        faithLogs.removeAll { $0.id == id }
        saveFaithLogs()
    }

    func addJournalEntry(duaText: String, noteText: String, reflectionText: String, mood: JournalMood, attachedCounterID: String?) {
        let entry = DailyJournalEntry(
            duaText: duaText,
            noteText: noteText,
            reflectionText: reflectionText,
            mood: mood,
            attachedCounterID: attachedCounterID
        )
        journalEntries.insert(entry, at: 0)
        saveJournalEntries()
    }

    func updateJournalEntry(_ entry: DailyJournalEntry) {
        guard let index = journalEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        journalEntries[index] = entry
        journalEntries.sort { $0.createdAt > $1.createdAt }
        saveJournalEntries()
    }

    func deleteJournalEntry(id: String) {
        journalEntries.removeAll { $0.id == id }
        saveJournalEntries()
    }

    func stats(for date: Date) -> DailyStats {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return allStats.first(where: { $0.dateString == dateString }) ?? DailyStats(date: date)
    }

    private func updateStreak() {
        let today = todayString()
        if profile.lastActiveDate == today { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        if let lastDate = formatter.date(from: profile.lastActiveDate),
           let todayDate = formatter.date(from: today) {
            let diff = calendar.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0
            if diff == 1 {
                profile.currentStreak += 1
            } else if diff > 1 {
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }
        profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
        profile.lastActiveDate = today
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func updateDhikrRecord(in stats: inout DailyStats, countDelta: Int, fallbackTitle: String, session: ZikrSession?) {
        let sessionTitle = session?.zikrTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (sessionTitle?.isEmpty == false ? sessionTitle : nil) ?? fallbackTitle
        let recordID = recordIdentifier(for: title, sourceID: session?.sourceID)
        let arabicText = session?.arabicText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let transliteration = session?.transliteration.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let existingIndex = stats.dhikrRecords.firstIndex(where: { $0.id == recordID }) {
            stats.dhikrRecords[existingIndex].count += countDelta
            stats.dhikrRecords[existingIndex].title = title
            if !arabicText.isEmpty {
                stats.dhikrRecords[existingIndex].arabicText = arabicText
            }
            if !transliteration.isEmpty {
                stats.dhikrRecords[existingIndex].transliteration = transliteration
            }
            if let sourceID = session?.sourceID {
                stats.dhikrRecords[existingIndex].sourceID = sourceID
            }

            if stats.dhikrRecords[existingIndex].count <= 0 {
                stats.dhikrRecords.remove(at: existingIndex)
            }
            return
        }

        guard countDelta > 0 else { return }

        stats.dhikrRecords.append(
            DailyDhikrRecord(
                id: recordID,
                title: title,
                count: countDelta,
                arabicText: arabicText,
                transliteration: transliteration,
                sourceID: session?.sourceID
            )
        )
    }

    private func recordIdentifier(for title: String, sourceID: String?) -> String {
        if let sourceID, !sourceID.isEmpty {
            return sourceID
        }

        return title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: #"\s+"#, with: "-", options: .regularExpression)
    }

    func resetForFreshGuestSession(removingUserID userID: String?) {
        clearScopeData(scopeID: userID)
        clearScopeData(scopeID: guestScopeID)

        currentScopeID = guestScopeID
        UserDefaults.standard.set(guestScopeID, forKey: storageScopeKey)

        counters = []
        selectedCounterID = nil
        profile = UserProfile()
        allStats = []
        customZikirs = []
        journalEntries = []
        pendingSelectedCounterId = nil
        activeZikrSession = nil
        habitRecords = []
        faithLogs = []
        maneviStreak = 0
    }

    func switchToUserScope(_ userID: String?) {
        let normalizedID = (userID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? userID! : guestScopeID
        guard normalizedID != currentScopeID else { return }
        currentScopeID = normalizedID
        UserDefaults.standard.set(normalizedID, forKey: storageScopeKey)
        loadAll()
    }

    private func scopedKey(_ key: String) -> String {
        "\(currentScopeID)_\(key)"
    }

    private func normalizeSelectedCounter() {
        let resolvedID = counters.contains(where: { $0.id == selectedCounterID }) ? selectedCounterID : counters.first?.id
        guard resolvedID != selectedCounterID else { return }
        selectedCounterID = resolvedID
        saveSelectedCounter()
    }

    private func clearScopeData(scopeID: String?) {
        let normalizedID = scopeID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedScopeID = (normalizedID?.isEmpty == false) ? normalizedID! : guestScopeID

        [
            countersKey,
            selectedCounterKey,
            profileKey,
            statsKey,
            customZikirsKey,
            journalEntriesKey,
            zikrSessionKey,
            habitRecordKey,
            faithLogKey
        ]
        .map { "\(resolvedScopeID)_\($0)" }
        .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    private func scheduleDeferredCountersSave() {
        deferredCountersSaveTask?.cancel()
        let countersSnapshot = counters
        let saveKey = scopedKey(countersKey)

        deferredCountersSaveTask = Task { [countersSnapshot, saveKey] in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            save(countersSnapshot, key: saveKey)
        }
    }

    private func scheduleDeferredProgressSave() {
        deferredProgressSaveTask?.cancel()
        let statsSnapshot = allStats
        let profileSnapshot = profile
        let statsSaveKey = scopedKey(statsKey)
        let profileSaveKey = scopedKey(profileKey)
        let dailyCount = todayStats().totalCount
        let dailyGoal = profile.dailyGoal
        let streak = profile.currentStreak

        deferredProgressSaveTask = Task { [statsSnapshot, profileSnapshot, statsSaveKey, profileSaveKey, dailyCount, dailyGoal, streak] in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            save(statsSnapshot, key: statsSaveKey)
            save(profileSnapshot, key: profileSaveKey)
            SharedDefaults.updateZikirProgress(
                dailyCount: dailyCount,
                dailyGoal: dailyGoal,
                streak: streak
            )
        }
    }

    private nonisolated func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private nonisolated func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func saveScoped<T: Encodable>(_ value: T, key: String) {
        save(value, key: scopedKey(key))
    }

    private func loadScoped<T: Codable>(_ type: T.Type, key: String) -> T? {
        if let scoped = load(type, key: scopedKey(key)) {
            return scoped
        }

        // Migrate legacy single-user storage into the active scope on first access.
        if let legacy = load(type, key: key) {
            saveScoped(legacy, key: key)
            return legacy
        }

        return nil
    }
}
