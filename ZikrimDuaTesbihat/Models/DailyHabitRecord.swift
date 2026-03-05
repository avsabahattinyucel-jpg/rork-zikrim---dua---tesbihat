import Foundation

nonisolated struct DailyHabitRecord: Codable, Sendable {
    let dateString: String
    var prayerStatus: [String: Bool]
    var completedHabits: [String]
    var shukurNote: String
    var isAchievementShared: Bool

    static let prayerNames: [String] = ["Sabah", "Öğle", "İkindi", "Akşam", "Yatsı"]
    static let prayerIcons: [String: String] = [
        "Sabah": "moon.stars.fill",
        "Öğle": "sun.max.fill",
        "İkindi": "sun.haze.fill",
        "Akşam": "sunset.fill",
        "Yatsı": "moon.fill"
    ]
    static let defaultHabits: [String] = ["Kur'an Oku", "Günlük Zikir", "Dua Et", "Sadaka Ver", "İstiğfar"]

    init(dateString: String) {
        self.dateString = dateString
        self.prayerStatus = [:]
        self.completedHabits = []
        self.shukurNote = ""
        self.isAchievementShared = false
    }

    var completedPrayerCount: Int {
        Self.prayerNames.filter { prayerStatus[$0] == true }.count
    }

    var progress: Double {
        let prayerFraction = Double(completedPrayerCount) / 5.0 * 0.6
        let noteFraction: Double = shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.0 : 0.2
        let habitFraction = min(Double(completedHabits.count) / Double(max(Self.defaultHabits.count, 1)), 1.0) * 0.2
        return min(prayerFraction + noteFraction + habitFraction, 1.0)
    }

    var isFullyComplete: Bool {
        completedPrayerCount == 5 && !shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
