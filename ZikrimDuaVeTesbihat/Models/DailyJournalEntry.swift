import Foundation

nonisolated struct DailyJournalEntry: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let createdAt: Date
    var duaText: String
    var noteText: String
    var reflectionText: String
    var mood: JournalMood
    var attachedCounterID: String?

    init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        duaText: String,
        noteText: String,
        reflectionText: String,
        mood: JournalMood,
        attachedCounterID: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.duaText = duaText
        self.noteText = noteText
        self.reflectionText = reflectionText
        self.mood = mood
        self.attachedCounterID = attachedCounterID
    }
}

nonisolated enum JournalMood: String, Codable, CaseIterable, Sendable {
    case huzurlu
    case sukurlu
    case umutlu
    case zorlanmis
    case yorgun

    var title: String {
        switch self {
        case .huzurlu: return "Huzurlu"
        case .sukurlu: return "Şükürlü"
        case .umutlu: return "Umutlu"
        case .zorlanmis: return "Zorlanmış"
        case .yorgun: return "Yorgun"
        }
    }

    var icon: String {
        switch self {
        case .huzurlu: return "sun.max.fill"
        case .sukurlu: return "hands.sparkles.fill"
        case .umutlu: return "sparkles"
        case .zorlanmis: return "cloud.rain.fill"
        case .yorgun: return "moon.zzz.fill"
        }
    }
}