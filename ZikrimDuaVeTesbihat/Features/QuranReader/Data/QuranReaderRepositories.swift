import Foundation

protocol QuranTextRepository: Sendable {
    func surah(withID id: Int) async throws -> QuranSurah?
    func verses(forSurahID id: Int) async throws -> [QuranVerse]
}

protocol QuranTranslationRepository: Sendable {
    func translations(forSurahID id: Int, language: AppLanguage) async throws -> [QuranVerseTranslation]
    func sourceDisplayName(for language: AppLanguage) -> String
}

protocol QuranTransliterationRepository: Sendable {
    func transliterations(forSurahID id: Int, language: AppLanguage) async throws -> [AyahReference: String]
}

protocol QuranWordByWordRepository: Sendable {
    func wordByWord(forSurahID id: Int, language: AppLanguage) async throws -> [AyahReference: [QuranWordByWordEntry]]
}

protocol QuranAudioRepository: Sendable {
    func play(surahID: Int, ayahNumber: Int) async
}

@MainActor
protocol QuranBookmarksRepository: Sendable {
    func isBookmarked(_ verse: QuranVerse) -> Bool
    func toggleBookmark(for verse: QuranVerse, surah: QuranSurah?)
}

@MainActor
protocol QuranReaderProgressRepository: Sendable {
    func loadLastAnchor(forSurahID surahID: Int) -> QuranReaderScrollAnchor?
    func save(anchor: QuranReaderScrollAnchor, surah: QuranSurah?)
}

@MainActor
protocol QuranVerseNotesRepository: Sendable {
    func note(for verse: QuranVerse) -> QuranVerseNote?
    func save(noteText: String, for verse: QuranVerse, surahName: String)
    func deleteNote(for verse: QuranVerse)
}
