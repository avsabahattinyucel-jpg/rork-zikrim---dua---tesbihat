import Foundation

struct WatchCounterOption: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

struct WatchCounterSnapshot: Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let arabicText: String
    let transliteration: String
    let meaning: String
    let currentCount: Int
    let targetCount: Int
    let stepName: String?
    let stepProgressText: String?
    let overallProgress: Double
}

struct WatchSyncPayload: Codable, Hashable {
    let generatedAt: Date
    let isReachable: Bool
    let dailyCount: Int
    let dailyGoal: Int
    let streak: Int
    let counters: [WatchCounterOption]
    let selectedCounter: WatchCounterSnapshot?
}

enum WatchCounterActionKind: String, Codable {
    case increment
    case undo
    case reset
    case selectCounter
}

struct WatchCounterAction: Codable {
    let kind: WatchCounterActionKind
    let counterID: String?
}
