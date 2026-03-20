import Foundation

nonisolated struct DailyDhikrRecord: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var count: Int
    var arabicText: String
    var transliteration: String
    var sourceID: String?

    init(
        id: String,
        title: String,
        count: Int,
        arabicText: String = "",
        transliteration: String = "",
        sourceID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.sourceID = sourceID
    }
}

nonisolated struct DailyStats: Codable, Identifiable, Sendable {
    var id: String { dateString }
    let dateString: String
    var totalCount: Int
    var sessionsCompleted: Int
    var zikirDetails: [String: Int]
    var dhikrRecords: [DailyDhikrRecord]

    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.totalCount = 0
        self.sessionsCompleted = 0
        self.zikirDetails = [:]
        self.dhikrRecords = []
    }

    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case dateString
        case totalCount
        case sessionsCompleted
        case zikirDetails
        case dhikrRecords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateString = try container.decode(String.self, forKey: .dateString)
        totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount) ?? 0
        sessionsCompleted = try container.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        zikirDetails = try container.decodeIfPresent([String: Int].self, forKey: .zikirDetails) ?? [:]
        dhikrRecords = try container.decodeIfPresent([DailyDhikrRecord].self, forKey: .dhikrRecords) ?? []
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
