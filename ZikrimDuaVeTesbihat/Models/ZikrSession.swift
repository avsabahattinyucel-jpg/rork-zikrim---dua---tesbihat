import Foundation

nonisolated struct ZikrSession: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let zikrTitle: String
    let arabicText: String
    let transliteration: String
    let meaning: String
    let recommendedCount: Int
    let category: String
    let sourceID: String?

    init(
        id: String = UUID().uuidString,
        zikrTitle: String,
        arabicText: String,
        transliteration: String,
        meaning: String,
        recommendedCount: Int,
        category: String,
        sourceID: String? = nil
    ) {
        self.id = id
        self.zikrTitle = zikrTitle
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.meaning = meaning
        self.recommendedCount = recommendedCount
        self.category = category
        self.sourceID = sourceID
    }
}
