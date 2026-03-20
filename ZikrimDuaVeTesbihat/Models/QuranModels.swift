import Foundation

nonisolated struct QuranRecitationResponse: Codable, Sendable {
    let audioFiles: [QuranAudioFile]
    let pagination: QuranPagination?

    private enum CodingKeys: String, CodingKey {
        case audioFiles = "audio_files"
        case pagination
    }
}

nonisolated struct QuranPagination: Codable, Sendable {
    let perPage: Int?
    let currentPage: Int?
    let nextPage: Int?
    let totalPages: Int?
    let totalRecords: Int?

    private enum CodingKeys: String, CodingKey {
        case perPage = "per_page"
        case currentPage = "current_page"
        case nextPage = "next_page"
        case totalPages = "total_pages"
        case totalRecords = "total_records"
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

    var localizedTurkishName: String {
        ContentLocalizer.shared.localized("quran.surah.\(id).name", fallback: turkishName)
    }

    var localizedRevelationType: String {
        ContentLocalizer.shared.localized("quran.revelation_type.\(revelationType)", fallback: revelationTypeTurkish)
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

    var localizedTranslation: String {
        ContentLocalizer.shared.localized("quran.verse.\(id).translation", fallback: turkishTranslation)
    }

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

nonisolated struct QuranVerseNote: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let surahId: Int
    let verseNumber: Int
    let surahName: String
    var noteText: String
    let createdAt: Date
    var updatedAt: Date

    init(
        surahId: Int,
        verseNumber: Int,
        surahName: String,
        noteText: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = "\(surahId):\(verseNumber)"
        self.surahId = surahId
        self.verseNumber = verseNumber
        self.surahName = surahName
        self.noteText = noteText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

nonisolated struct QuranReadPosition: Codable, Sendable {
    var surahId: Int
    var verseNumber: Int
    var surahName: String
}

nonisolated struct QuranSurahPlaybackState: Codable, Sendable {
    var surahId: Int
    var surahName: String
    var currentAyah: Int
    var totalAyahs: Int
    var timeOffset: Double
}

enum QuranShareDisplayMode: String, CaseIterable, Codable {
    case both = "İkisi de"
    case arabicOnly = "Sadece Arapça"
    case turkishOnly = "Sadece Türkçe"

    var localizedTitle: String {
        switch self {
        case .both: return L10n.string(.quranDisplayModeBoth)
        case .arabicOnly: return L10n.string(.quranDisplayModeArabic)
        case .turkishOnly: return L10n.string(.quranDisplayModeTranslation)
        }
    }
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
