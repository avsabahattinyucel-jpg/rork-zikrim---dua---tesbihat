import Foundation

nonisolated struct CounterModel: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var targetCount: Int
    var currentCount: Int
    var zikirItemId: String?
    var createdAt: Date
    var lastUpdated: Date
    var isCompleted: Bool

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }

    init(id: String = UUID().uuidString, name: String, targetCount: Int = 33, currentCount: Int = 0, zikirItemId: String? = nil) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.zikirItemId = zikirItemId
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.isCompleted = false
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CounterModel, rhs: CounterModel) -> Bool {
        lhs.id == rhs.id
    }
}
