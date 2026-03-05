import Foundation

@Observable
@MainActor
class StorageService {
    private let countersKey = "saved_counters"
    private let profileKey = "user_profile"
    private let statsKey = "daily_stats"
    private let customZikirsKey = "custom_zikirs"
    private let journalEntriesKey = "daily_journal_entries"
    private let zikrSessionKey = "active_zikr_session"
    private let habitRecordKey = "daily_habit_records"
    private let faithLogKey = "daily_faith_logs"
    
    var counters: [CounterModel] = []
    var profile: UserProfile = UserProfile()
    var allStats: [DailyStats] = []
    var customZikirs: [ZikirItem] = []
    var journalEntries: [DailyJournalEntry] = []
    var pendingSelectedCounterId: String? = nil
    var activeZikrSession: ZikrSession? = nil
    var habitRecords: [DailyHabitRecord] = []
    var faithLogs: [DailyFaithLogEntry] = []
    var maneviStreak: Int = 0

    init() {
        loadAll()
    }

    func loadAll() {
        counters = load([CounterModel].self, key: countersKey) ?? []
        profile = load(UserProfile.self, key: profileKey) ?? UserProfile()
        allStats = load([DailyStats].self, key: statsKey) ?? []
        customZikirs = load([ZikirItem].self, key: customZikirsKey) ?? []
        journalEntries = (load([DailyJournalEntry].self, key: journalEntriesKey) ?? []).sorted { $0.createdAt > $1.createdAt }
        activeZikrSession = load(ZikrSession.self, key: zikrSessionKey)
        habitRecords = load([DailyHabitRecord].self, key: habitRecordKey) ?? []
        faithLogs = (load([DailyFaithLogEntry].self, key: faithLogKey) ?? []).sorted { $0.date > $1.date }
        recomputeManeviStreak()
    }

    func saveCounters() { save(counters, key: countersKey) }
    func saveProfile() { save(profile, key: profileKey) }
    func saveStats() { save(allStats, key: statsKey) }
    func saveCustomZikirs() { save(customZikirs, key: customZikirsKey) }
    func saveJournalEntries() { save(journalEntries, key: journalEntriesKey) }
    func saveActiveZikrSession() { save(activeZikrSession, key: zikrSessionKey) }
    func saveHabitRecords() { save(habitRecords, key: habitRecordKey) }
    func saveFaithLogs() { save(faithLogs, key: faithLogKey) }

    var todayHabitRecord: DailyHabitRecord {
        let today = todayString()
        return habitRecords.first(where: { $0.dateString == today }) ?? DailyHabitRecord(dateString: today)
    }

    func togglePrayer(_ prayer: String) {
        var record = todayHabitRecord
        record.prayerStatus[prayer] = !(record.prayerStatus[prayer] ?? false)
        upsertHabitRecord(record)
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

    private func recomputeManeviStreak() {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for _ in 0..<366 {
            let dateStr = formatter.string(from: checkDate)
            if let r = habitRecords.first(where: { $0.dateString == dateStr }), r.isFullyComplete {
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
    }

    func setActiveZikrSession(_ session: ZikrSession?) {
        activeZikrSession = session
        saveActiveZikrSession()
    }

    func updateCounter(_ counter: CounterModel) {
        if let index = counters.firstIndex(where: { $0.id == counter.id }) {
            counters[index] = counter
            saveCounters()
        }
    }

    func session(for counter: CounterModel) -> ZikrSession? {
        if let session = activeZikrSession, session.sourceID == counter.zikirItemId {
            return session
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

    func setActiveSession(from counter: CounterModel) {
        setActiveZikrSession(session(for: counter))
    }

    func deleteCounter(_ counter: CounterModel) {
        counters.removeAll { $0.id == counter.id }
        saveCounters()
    }

    func addZikirCount(_ count: Int, zikirName: String) {
        let today = todayString()
        if let index = allStats.firstIndex(where: { $0.dateString == today }) {
            allStats[index].totalCount += count
            allStats[index].zikirDetails[zikirName, default: 0] += count
        } else {
            var stats = DailyStats()
            stats.totalCount = count
            stats.zikirDetails[zikirName] = count
            allStats.append(stats)
        }
        profile.totalLifetimeCount += count
        updateStreak()
        saveStats()
        saveProfile()
        let progress = min(Int((Double(todayStats().totalCount) / Double(max(profile.dailyGoal, 1))) * 100.0), 100)
        UserDefaults.standard.set(max(progress, 0), forKey: "widget_daily_progress")
    }

    func completeSession() {
        let today = todayString()
        if let index = allStats.firstIndex(where: { $0.dateString == today }) {
            allStats[index].sessionsCompleted += 1
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
        customZikirs.append(item)
        saveCustomZikirs()
    }

    func deleteCustomZikir(_ item: ZikirItem) {
        customZikirs.removeAll { $0.id == item.id }
        saveCustomZikirs()
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

    private nonisolated func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private nonisolated func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
