import Foundation

nonisolated struct DhikrStep: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let arabicText: String
    let transliteration: String
    let meaning: String
    let targetCount: Int
    let source: String

    init(
        id: String = UUID().uuidString,
        name: String,
        arabicText: String = "",
        transliteration: String = "",
        meaning: String = "",
        targetCount: Int = 33,
        source: String = ""
    ) {
        self.id = id
        self.name = name
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.meaning = meaning
        self.targetCount = targetCount
        self.source = source
    }

    static func from(_ item: ZikirItem) -> DhikrStep {
        DhikrStep(
            id: item.id,
            name: item.turkishPronunciation,
            arabicText: item.arabicText,
            transliteration: item.turkishPronunciation,
            meaning: item.turkishMeaning,
            targetCount: item.recommendedCount,
            source: item.source
        )
    }
}
