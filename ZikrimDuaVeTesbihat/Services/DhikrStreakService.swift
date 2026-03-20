import Foundation

@MainActor
final class DhikrStreakService {
    static let shared = DhikrStreakService()

    private let streakCountKey = "dhikr_streak_count"
    private let lastDhikrDateKey = "last_dhikr_date"

    private init() {}

    func recordDhikrSession() {
        let today = todayString()
        let lastDate = UserDefaults.standard.string(forKey: lastDhikrDateKey) ?? ""

        if lastDate == today { return }

        let yesterday = yesterdayString()
        var streak = UserDefaults.standard.integer(forKey: streakCountKey)

        if lastDate == yesterday {
            streak += 1
        } else {
            streak = 1
        }

        UserDefaults.standard.set(streak, forKey: streakCountKey)
        UserDefaults.standard.set(today, forKey: lastDhikrDateKey)
    }

    func getCurrentStreak() -> Int {
        let lastDate = UserDefaults.standard.string(forKey: lastDhikrDateKey) ?? ""
        let today = todayString()
        let yesterday = yesterdayString()

        if lastDate == today || lastDate == yesterday {
            return UserDefaults.standard.integer(forKey: streakCountKey)
        }
        return 0
    }

    func milestoneMessage() -> String? {
        let streak = getCurrentStreak()
        switch streak {
        case 90...: return L10n.string(.dhikrStreakMilestone90)
        case 30...: return L10n.string(.dhikrStreakMilestone30)
        case 7...: return L10n.string(.dhikrStreakMilestone7)
        default: return nil
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func yesterdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }
}
