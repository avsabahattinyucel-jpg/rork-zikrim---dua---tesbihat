import Foundation

nonisolated struct QuranRecitationResponse: Codable, Sendable {
    let audioFiles: [QuranAudioFile]

    private enum CodingKeys: String, CodingKey {
        case audioFiles = "audio_files"
    }
}

nonisolated struct QuranAudioFile: Codable, Sendable {
    let verseKey: String
    let url: String

    private enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case url
    }
}

nonisolated struct QuranSurah: Codable, Identifiable, Sendable, Hashable {
    let id: Int
    let arabicName: String
    let turkishName: String
    let totalVerses: Int
    let revelationType: String

    var revelationTypeTurkish: String {
        revelationType == "Meccan" ? "Mekki" : "Medeni"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: QuranSurah, rhs: QuranSurah) -> Bool { lhs.id == rhs.id }
}

nonisolated struct QuranVerse: Codable, Identifiable, Sendable, Hashable {
    var id: String { "\(surahId):\(verseNumber)" }
    let surahId: Int
    let verseNumber: Int
    let arabicText: String
    let turkishTranslation: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: QuranVerse, rhs: QuranVerse) -> Bool { lhs.id == rhs.id }
}

nonisolated struct QuranBookmark: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let surahId: Int
    let verseNumber: Int
    let surahName: String
    let addedAt: Date

    init(surahId: Int, verseNumber: Int, surahName: String) {
        self.id = "\(surahId):\(verseNumber)"
        self.surahId = surahId
        self.verseNumber = verseNumber
        self.surahName = surahName
        self.addedAt = Date()
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: QuranBookmark, rhs: QuranBookmark) -> Bool { lhs.id == rhs.id }
}

nonisolated struct QuranReadPosition: Codable, Sendable {
    var surahId: Int
    var verseNumber: Int
    var surahName: String
}

enum QuranDisplayMode: String, CaseIterable, Codable {
    case both = "İkisi de"
    case arabicOnly = "Sadece Arapça"
    case turkishOnly = "Sadece Türkçe"
}

nonisolated struct MultiEditionResponse: Codable, Sendable {
    let code: Int
    let data: [EditionSurahData]
}

nonisolated struct EditionSurahData: Codable, Sendable {
    let edition: EditionInfo
    let ayahs: [AyahData]
}

nonisolated struct EditionInfo: Codable, Sendable {
    let identifier: String
}

nonisolated struct AyahData: Codable, Sendable {
    let numberInSurah: Int
    let text: String
}
