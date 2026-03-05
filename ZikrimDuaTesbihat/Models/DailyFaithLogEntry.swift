import Foundation

nonisolated struct DailyFaithLogEntry: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var date: Date
    var note: String
    var photoBase64: String?
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        date: Date,
        note: String,
        photoBase64: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.note = note
        self.photoBase64 = photoBase64
        self.createdAt = createdAt
    }
}
