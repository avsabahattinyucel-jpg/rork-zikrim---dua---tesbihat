import Foundation

nonisolated struct DailyStats: Codable, Identifiable, Sendable {
    var id: String { dateString }
    let dateString: String
    var totalCount: Int
    var sessionsCompleted: Int
    var zikirDetails: [String: Int]

    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.totalCount = 0
        self.sessionsCompleted = 0
        self.zikirDetails = [:]
    }

    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }
}

nonisolated struct UserProfile: Codable, Sendable {
    var dailyGoal: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String
    var totalLifetimeCount: Int
    var favoriteZikirIds: [String]
    var favorites: [FavoriteItem]
    var isPremium: Bool
    var vibrationEnabled: Bool
    var soundEnabled: Bool
    var displayName: String
    var email: String
    var avatarBase64: String?
    var cloudSyncEnabled: Bool

    init() {
        self.dailyGoal = 100
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = ""
        self.totalLifetimeCount = 0
        self.favoriteZikirIds = []
        self.favorites = []
        self.isPremium = false
        self.vibrationEnabled = true
        self.soundEnabled = false
        self.displayName = ""
        self.email = ""
        self.avatarBase64 = nil
        self.cloudSyncEnabled = true
    }
}
