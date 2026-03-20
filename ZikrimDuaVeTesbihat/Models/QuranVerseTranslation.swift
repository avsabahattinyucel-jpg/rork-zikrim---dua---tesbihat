import Foundation

struct QuranVerseTranslation: Codable, Identifiable, Hashable, Sendable {
    let surahId: Int
    let verseNumber: Int
    let verseKey: String
    let translationId: Int
    let languageCode: String
    let text: String

    var id: String { "\(translationId):\(verseKey)" }
}
