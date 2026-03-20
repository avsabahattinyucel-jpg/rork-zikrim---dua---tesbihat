import Foundation

actor QuranReaderTextCache {
    private var storage: [Int: [QuranVerse]] = [:]

    func value(for surahID: Int) -> [QuranVerse]? {
        storage[surahID]
    }

    func store(_ verses: [QuranVerse], for surahID: Int) {
        storage[surahID] = verses
    }
}

struct ZikrimQuranTextRepository: QuranTextRepository {
    private let cache = QuranReaderTextCache()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func surah(withID id: Int) async throws -> QuranSurah? {
        QuranSurahData.surahs.first(where: { $0.id == id })
    }

    func verses(forSurahID id: Int) async throws -> [QuranVerse] {
        if let cached = await cache.value(for: id) {
            return cached
        }

        if let localArabic = await QuranLocalDataStore.shared.localArabicVerses(forSurahId: id) {
            await cache.store(localArabic, for: id)
            return localArabic
        }

        if let offline = QuranSurahData.offlineVerses[id] {
            await cache.store(offline, for: id)
            return offline
        }

        guard let url = URL(string: "https://api.alquran.cloud/v1/surah/\(id)/editions/quran-uthmani") else {
            throw QuranTranslationServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw QuranTranslationServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(MultiEditionResponse.self, from: data)
        guard let arabicEdition = decoded.data.first else {
            throw QuranTranslationServiceError.decodingFailed
        }

        let verses = arabicEdition.ayahs.map {
            QuranVerse(
                surahId: id,
                verseNumber: $0.numberInSurah,
                arabicText: $0.text,
                turkishTranslation: ""
            )
        }
        await cache.store(verses, for: id)
        return verses
    }
}

struct ZikrimQuranTranslationRepository: QuranTranslationRepository {
    private let service: QuranTranslationService

    init(service: QuranTranslationService = QuranTranslationService()) {
        self.service = service
    }

    func translations(forSurahID id: Int, language: AppLanguage) async throws -> [QuranVerseTranslation] {
        try await service.fetchSurahTranslations(surahId: id, languageCode: language.rawValue)
    }

    func sourceDisplayName(for language: AppLanguage) -> String {
        if let localSource = QuranLocalDataStore.translationSourceDisplayName(for: language.rawValue) {
            return localSource
        }

        switch language {
        case .tr: return "Diyanet İşleri Başkanlığı"
        case .en: return "Sahih International"
        case .de: return "Bubenheim & Elyas"
        case .fr: return "Muhammad Hamidullah"
        case .es: return "Julio Cortés"
        case .ru: return "Kuliyev"
        case .ur: return "Jalandhry"
        case .fa: return "Fooladvand"
        case .id: return "Kementerian Agama RI"
        case .ms: return "Basmeih"
        case .ar: return "Arabic Mushaf"
        }
    }
}

struct ZikrimQuranTransliterationRepository: QuranTransliterationRepository {
    func transliterations(forSurahID id: Int, language: AppLanguage) async throws -> [AyahReference: String] {
        await QuranLocalDataStore.shared.transliterations(forSurahId: id, languageCode: language.rawValue)
    }
}

struct ZikrimQuranWordByWordRepository: QuranWordByWordRepository {
    func wordByWord(forSurahID id: Int, language: AppLanguage) async throws -> [AyahReference: [QuranWordByWordEntry]] {
        await QuranLocalDataStore.shared.wordByWord(forSurahId: id, languageCode: language.rawValue)
    }
}

struct ZikrimQuranBookmarksRepository: QuranBookmarksRepository {
    private let quranService: QuranService
    private let storage: StorageService

    init(quranService: QuranService, storage: StorageService) {
        self.quranService = quranService
        self.storage = storage
    }

    func isBookmarked(_ verse: QuranVerse) -> Bool {
        quranService.isBookmarked(verse: verse)
    }

    func toggleBookmark(for verse: QuranVerse, surah: QuranSurah?) {
        let surahName = surah?.localizedTurkishName ?? ""
        quranService.toggleBookmark(verse: verse, surahName: surahName)

        let favorite = FavoriteItem(
            id: verse.id,
            type: .quran,
            title: "\(surahName.isEmpty ? QuranReaderStrings.surahFallbackTitle : surahName) \(verse.verseNumber)",
            subtitle: surah?.arabicName ?? "",
            detail: verse.localizedTranslation
        )
        storage.toggleFavorite(favorite)
    }
}

struct ZikrimQuranProgressRepository: QuranReaderProgressRepository {
    private let quranService: QuranService
    private let defaults: UserDefaults
    private let key = "quran_reader_progress_anchor"

    init(quranService: QuranService, defaults: UserDefaults = .standard) {
        self.quranService = quranService
        self.defaults = defaults
    }

    func loadLastAnchor(forSurahID surahID: Int) -> QuranReaderScrollAnchor? {
        guard let data = defaults.data(forKey: key),
              let anchor = try? JSONDecoder().decode(QuranReaderScrollAnchor.self, from: data),
              anchor.surahID == surahID else {
            if let lastRead = quranService.lastReadPosition, lastRead.surahId == surahID {
                return QuranReaderScrollAnchor(
                    surahID: lastRead.surahId,
                    ayahNumber: lastRead.verseNumber,
                    layoutMode: .verseByVerse
                )
            }
            return nil
        }
        return anchor
    }

    func save(anchor: QuranReaderScrollAnchor, surah: QuranSurah?) {
        if let data = try? JSONEncoder().encode(anchor) {
            defaults.set(data, forKey: key)
        }
        quranService.saveLastRead(
            surahId: anchor.surahID,
            verseNumber: anchor.ayahNumber,
            surahName: surah?.localizedTurkishName ?? ""
        )
    }
}

struct ZikrimQuranVerseNotesRepository: QuranVerseNotesRepository {
    private let defaults: UserDefaults
    private let key = "quran_reader_verse_notes"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func note(for verse: QuranVerse) -> QuranVerseNote? {
        loadNotes()[verse.id]
    }

    func save(noteText: String, for verse: QuranVerse, surahName: String) {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            deleteNote(for: verse)
            return
        }

        var notes = loadNotes()
        let now = Date()
        let existingCreatedAt = notes[verse.id]?.createdAt ?? now
        notes[verse.id] = QuranVerseNote(
            surahId: verse.surahId,
            verseNumber: verse.verseNumber,
            surahName: surahName,
            noteText: trimmed,
            createdAt: existingCreatedAt,
            updatedAt: now
        )
        persist(notes)
    }

    func deleteNote(for verse: QuranVerse) {
        var notes = loadNotes()
        notes.removeValue(forKey: verse.id)
        persist(notes)
    }

    private func loadNotes() -> [String: QuranVerseNote] {
        guard let data = defaults.data(forKey: key),
              let notes = try? JSONDecoder().decode([String: QuranVerseNote].self, from: data) else {
            return [:]
        }
        return notes
    }

    private func persist(_ notes: [String: QuranVerseNote]) {
        if let data = try? JSONEncoder().encode(notes) {
            defaults.set(data, forKey: key)
        }
    }
}
