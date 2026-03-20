import Foundation
import AVFoundation
import SwiftUI

@Observable
@MainActor
class QuranService {
    var verses: [QuranVerse] = []
    var currentSurahId: Int?
    var semanticResultText: String? = nil
    var isSemanticSearching: Bool = false
    var playingVerseKey: String? = nil
    var isLoading: Bool = false
    var isSurahPlaying: Bool = false
    var surahPlayingCurrentAyah: Int = 0
    var surahPlayingTotalAyahs: Int = 0
    var errorMessage: String?
    var bookmarks: [QuranBookmark] = []
    var lastReadPosition: QuranReadPosition?
    var displayMode: QuranShareDisplayMode = .both
    var arabicFontSize: CGFloat = 26
    var turkishFontSize: CGFloat = 15
    var highlightedVerseNumber: Int?
    var allowsBackgroundPlayback: Bool = false
    var surahPlayingSurahId: Int?
    var surahPlayingSurahName: String?
    var selectedTranslationLanguage: String?
    var resolvedTranslationLanguage: String?
    var resolvedTranslationId: Int?
    var resolvedTranslationAuthorName: String?

    private let bookmarksKey = "quran_bookmarks"
    private let recitationId: Int = 7
    private let translationService = QuranTranslationService()
    private var translationsByKey: [String: QuranVerseTranslation] = [:]
    private var didLogTranslationDebug: Bool = false
    private var didLogRenderedMealLanguage: Bool = false
    private var didClearTranslationCaches: Bool = false
    private var audioCache: [String: String] = [:]
    private var audioPlayer: AVPlayer?
    private var surahQueuePlayer: AVQueuePlayer?
    private var surahPlayerObserver: NSObjectProtocol?
    private var surahTimeObserver: Any?
    private var surahAudioItems: [AVPlayerItem] = []
    private var surahVerseKeys: [String] = []
    private let lastReadKey = "quran_last_read"
    private let displayModeKey = "quran_display_mode"
    private let arabicFontKey = "quran_arabic_font"
    private let turkishFontKey = "quran_turkish_font"
    private let backgroundPlaybackKey = "quran_background_playback_enabled"
    private var currentLoadTask: Task<Void, Never>?
    private var surahQueueStartIndex: Int = 0

    init() {
        loadBookmarks()
        loadLastRead()
        loadSettings()
    }

    func loadVerses(for surahId: Int) async {
        currentLoadTask?.cancel()
        currentLoadTask = nil

        currentSurahId = surahId
        isLoading = true
        errorMessage = nil
        verses = []
        translationsByKey = [:]
        didLogRenderedMealLanguage = false
        didLogTranslationDebug = false
        resolvedTranslationAuthorName = nil

#if DEBUG
        if !didClearTranslationCaches {
            didClearTranslationCaches = true
            await translationService.clearCachesForDebug()
        }
#endif

        let selectedLanguage = appSelectedLanguageCode
        selectedTranslationLanguage = selectedLanguage

        let task = Task {
            if let offline = QuranSurahData.offlineVerses[surahId] {
                guard !Task.isCancelled, currentSurahId == surahId else { return }
                verses = offline
                await loadTranslations(surahId: surahId, selectedLanguage: selectedLanguage)
                if !Task.isCancelled {
                    isLoading = false
                }
                return
            }

            let cacheKey = "quran_surah_\(surahId)"
            if let cached = loadCachedVerses(key: cacheKey) {
                guard !Task.isCancelled, currentSurahId == surahId else { return }
                verses = cached
                await loadTranslations(surahId: surahId, selectedLanguage: selectedLanguage)
                if !Task.isCancelled {
                    isLoading = false
                }
                return
            }

            await fetchFromAPI(surahId: surahId, cacheKey: cacheKey)
            await loadTranslations(surahId: surahId, selectedLanguage: selectedLanguage)
            if !Task.isCancelled {
                isLoading = false
            }
        }
        currentLoadTask = task
        await task.value
    }

    private func fetchFromAPI(surahId: Int, cacheKey: String) async {
        let urlString = "https://api.alquran.cloud/v1/surah/\(surahId)/editions/quran-uthmani"
        guard let url = URL(string: urlString) else {
            errorMessage = L10n.string(.errorInvalidUrl)
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard !Task.isCancelled, currentSurahId == surahId else { return }

            let decoded: MultiEditionResponse
            do {
                decoded = try JSONDecoder().decode(MultiEditionResponse.self, from: data)
            } catch {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("QuranArabic decodeFailed url=\(urlString) status=\(status) error=\(error) body=\(body.prefix(500))")
                errorMessage = L10n.string(.errorDataFormatInvalid)
                return
            }

            guard let arabicEdition = decoded.data.first else {
                errorMessage = L10n.string(.errorDataFormatInvalid)
                return
            }

            var result: [QuranVerse] = []
            for arabicAyah in arabicEdition.ayahs {
                result.append(QuranVerse(
                    surahId: surahId,
                    verseNumber: arabicAyah.numberInSurah,
                    arabicText: arabicAyah.text,
                    turkishTranslation: ""
                ))
            }
            guard !Task.isCancelled, currentSurahId == surahId else { return }
            verses = result
            cacheVerses(result, key: cacheKey)
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                errorMessage = L10n.string(.errorSurahLoadFailed)
            }
        }
    }

    func toggleBookmark(verse: QuranVerse, surahName: String) {
        if let idx = bookmarks.firstIndex(where: { $0.id == "\(verse.surahId):\(verse.verseNumber)" }) {
            bookmarks.remove(at: idx)
        } else {
            bookmarks.append(QuranBookmark(surahId: verse.surahId, verseNumber: verse.verseNumber, surahName: surahName))
        }
        saveBookmarks()
    }

    func isBookmarked(verse: QuranVerse) -> Bool {
        bookmarks.contains(where: { $0.id == "\(verse.surahId):\(verse.verseNumber)" })
    }

    func saveLastRead(surahId: Int, verseNumber: Int, surahName: String) {
        lastReadPosition = QuranReadPosition(surahId: surahId, verseNumber: verseNumber, surahName: surahName)
        if let data = try? JSONEncoder().encode(lastReadPosition) {
            UserDefaults.standard.set(data, forKey: lastReadKey)
        }
    }

    func searchVersesInCurrentSurah(_ query: String) -> [QuranVerse] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return verses.filter {
            translationText(for: $0).localizedStandardContains(trimmed) ||
            $0.arabicText.contains(trimmed)
        }
    }

    func semanticSearchInQuran(query: String, gemini: GroqService) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            semanticResultText = nil
            return
        }
        isSemanticSearching = true
        defer { isSemanticSearching = false }
        semanticResultText = try? await gemini.semanticQuranSearch(query: trimmed)
    }

    func playVerseAudio(surahId: Int, verseNumber: Int) async {
        let verseKey = "\(surahId):\(verseNumber)"
        if playingVerseKey == verseKey {
            audioPlayer?.pause()
            playingVerseKey = nil
            return
        }

        configureAudioSession()

        if let cachedURL = audioCache[verseKey], let url = URL(string: cachedURL) {
            audioPlayer = AVPlayer(url: url)
            audioPlayer?.play()
            playingVerseKey = verseKey
            return
        }

        let endpoint = "https://api.quran.com/api/v4/recitations/\(recitationId)/by_ayah/\(surahId):\(verseNumber)"
        guard let url = URL(string: endpoint) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(QuranRecitationResponse.self, from: data)
            guard let rawAudioURL = response.audioFiles.first?.url else { return }
            let audioURL = rawAudioURL.hasPrefix("http") ? rawAudioURL : "https://verses.quran.com/\(rawAudioURL)"
            audioCache[verseKey] = audioURL
            if let finalURL = URL(string: audioURL) {
                audioPlayer = AVPlayer(url: finalURL)
                audioPlayer?.play()
                playingVerseKey = verseKey
            }
        } catch {
            print("Quran Audio Error: \(error)")
        }
    }

    func playSurahAudio(surahId: Int, surahName: String, totalVerses: Int) async {
        if isSurahPlaying && surahPlayingSurahId == surahId {
            stopSurahPlayback()
            return
        }

        stopSurahPlayback()

        surahPlayingSurahId = surahId
        surahPlayingSurahName = surahName
        surahPlayingTotalAyahs = totalVerses
        surahPlayingCurrentAyah = 1
        isSurahPlaying = true

        do {
            let sortedFiles = try await fetchSurahAudioFiles(surahId: surahId)
            guard !sortedFiles.isEmpty, isSurahPlaying, surahPlayingSurahId == surahId else {
                stopSurahPlayback()
                return
            }

            surahPlayingTotalAyahs = sortedFiles.count
            surahVerseKeys = sortedFiles.map { $0.verseKey }

            surahQueueStartIndex = 0

            var items: [AVPlayerItem] = []
            for file in sortedFiles {
                let audioURLString = file.url.hasPrefix("http") ? file.url : "https://verses.quran.com/\(file.url)"
                if let audioURL = URL(string: audioURLString) {
                    items.append(AVPlayerItem(url: audioURL))
                }
            }

            guard !items.isEmpty, isSurahPlaying, surahPlayingSurahId == surahId else {
                stopSurahPlayback()
                return
            }

            surahAudioItems = items
            surahQueuePlayer = AVQueuePlayer(items: items)
            highlightedVerseNumber = 1

            addSurahObservers()
            configureAudioSession()
            surahQueuePlayer?.play()
        } catch {
            stopSurahPlayback()
        }
    }

    func stopSurahPlayback() {
        if let observer = surahTimeObserver {
            surahQueuePlayer?.removeTimeObserver(observer)
            surahTimeObserver = nil
        }
        surahQueuePlayer?.pause()
        surahQueuePlayer?.removeAllItems()
        surahQueuePlayer = nil
        surahAudioItems = []
        surahVerseKeys = []
        surahQueueStartIndex = 0
        if let observer = surahPlayerObserver {
            NotificationCenter.default.removeObserver(observer)
            surahPlayerObserver = nil
        }
        isSurahPlaying = false
        surahPlayingCurrentAyah = 0
        surahPlayingTotalAyahs = 0
        highlightedVerseNumber = nil
        surahPlayingSurahId = nil
        surahPlayingSurahName = nil
    }

    func saveSettings() {
        UserDefaults.standard.set(displayMode.rawValue, forKey: displayModeKey)
        UserDefaults.standard.set(Double(arabicFontSize), forKey: arabicFontKey)
        UserDefaults.standard.set(Double(turkishFontSize), forKey: turkishFontKey)
        UserDefaults.standard.set(allowsBackgroundPlayback, forKey: backgroundPlaybackKey)
    }

    func setBackgroundPlaybackEnabled(_ isEnabled: Bool) {
        allowsBackgroundPlayback = isEnabled
        saveSettings()
        if isSurahPlaying || playingVerseKey != nil {
            configureAudioSession()
        }
    }

    private func loadSettings() {
        if let raw = UserDefaults.standard.string(forKey: displayModeKey),
           let mode = QuranShareDisplayMode(rawValue: raw) {
            displayMode = mode
        }
        let arabic = UserDefaults.standard.double(forKey: arabicFontKey)
        if arabic > 0 { arabicFontSize = CGFloat(arabic) }
        let turkish = UserDefaults.standard.double(forKey: turkishFontKey)
        if turkish > 0 { turkishFontSize = CGFloat(turkish) }
        allowsBackgroundPlayback = UserDefaults.standard.bool(forKey: backgroundPlaybackKey)
    }

    private func loadLastRead() {
        guard let data = UserDefaults.standard.data(forKey: lastReadKey) else { return }
        lastReadPosition = try? JSONDecoder().decode(QuranReadPosition.self, from: data)
    }

    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey) else { return }
        bookmarks = (try? JSONDecoder().decode([QuranBookmark].self, from: data)) ?? []
    }

    private func fetchSurahAudioFiles(surahId: Int) async throws -> [QuranAudioFile] {
        var allFiles: [QuranAudioFile] = []
        var currentPage = 1
        var hasMore = true

        while hasMore {
            guard isSurahPlaying, surahPlayingSurahId == surahId else { return [] }
            let endpoint = "https://api.quran.com/api/v4/recitations/\(recitationId)/by_chapter/\(surahId)?page=\(currentPage)&per_page=50"
            guard let url = URL(string: endpoint) else { return [] }

            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(QuranRecitationResponse.self, from: data)
            allFiles.append(contentsOf: response.audioFiles)

            if let nextPage = response.pagination?.nextPage {
                currentPage = nextPage
            } else {
                hasMore = false
            }
        }

        return allFiles.sorted { a, b in
            let aNum = Int(a.verseKey.split(separator: ":").last ?? "0") ?? 0
            let bNum = Int(b.verseKey.split(separator: ":").last ?? "0") ?? 0
            return aNum < bNum
        }
    }

    private func addSurahObservers() {
        surahPlayerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let finishedItem = notification.object as? AVPlayerItem
            Task { @MainActor [weak self, finishedItem] in
                guard let self else { return }
                guard self.isSurahPlaying else { return }
                guard let finishedItem else { return }
                guard self.surahAudioItems.contains(where: { $0 === finishedItem }) else { return }

                self.surahPlayingCurrentAyah += 1
                if self.surahPlayingCurrentAyah > self.surahPlayingTotalAyahs {
                    self.stopSurahPlayback()
                } else {
                    self.highlightedVerseNumber = self.surahPlayingCurrentAyah
                }
            }
        }

        surahTimeObserver = surahQueuePlayer?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.syncCurrentAyahFromQueue()
            }
        }
    }

    private func syncCurrentAyahFromQueue() {
        guard isSurahPlaying,
              let currentItem = surahQueuePlayer?.currentItem,
              let itemIndex = surahAudioItems.firstIndex(where: { $0 === currentItem }) else { return }
        let currentIndex = surahQueueStartIndex + itemIndex
        let currentAyah = currentIndex + 1
        surahPlayingCurrentAyah = currentAyah
        highlightedVerseNumber = currentAyah
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        let category: AVAudioSession.Category = allowsBackgroundPlayback ? .playback : .ambient
        try? session.setCategory(category, mode: .default, options: [.allowAirPlay])
        try? session.setActive(true)
    }

    private func cacheVerses(_ verses: [QuranVerse], key: String) {
        if let data = try? JSONEncoder().encode(verses) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadCachedVerses(key: String) -> [QuranVerse]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([QuranVerse].self, from: data)
    }

    func translationText(for verse: QuranVerse) -> String {
        let key = normalizeVerseKey(verse.id)
        if let translation = translationsByKey[key] {
            logRenderedMealLanguageIfNeeded(language: translation.languageCode)
            return translation.text
        }

        if translationsByKey.isEmpty {
            return ""
        }

        logRenderedMealLanguageIfNeeded(language: resolvedTranslationLanguage ?? "unknown")
        return ""
    }

    func translationSourceDisplayName() -> String {
        if let author = resolvedTranslationAuthorName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !author.isEmpty {
            return author
        }

        if let localSource = QuranLocalDataStore.translationSourceDisplayName(for: resolvedTranslationLanguage ?? "") {
            return localSource
        }

        switch resolvedTranslationLanguage {
        case "tr": return "Diyanet İşleri Başkanlığı"
        case "en": return "Sahih International"
        case "de": return "Bubenheim ve Elyas"
        case "fr": return "Muhammad Hamidullah"
        case "es": return "Julio Cortés"
        case "ru": return "Kuliyev"
        case "ur": return "Jalandhry"
        case "fa": return "Fooladvand"
        case "id": return "Kementerian Agama RI"
        case "ms": return "Basmeih"
        case "ar": return "Arapça Mushaf"
        default: return "Kur'an Meali"
        }
    }

    private func loadTranslations(surahId: Int, selectedLanguage: String) async {
        do {
            let translations = try await translationService.fetchSurahTranslations(surahId: surahId, languageCode: selectedLanguage)
            guard !Task.isCancelled, currentSurahId == surahId else { return }
            translationsByKey = Dictionary(uniqueKeysWithValues: translations.map { (normalizeVerseKey($0.verseKey), $0) })
            if let first = translations.first {
                resolvedTranslationLanguage = first.languageCode
                resolvedTranslationId = first.translationId
                resolvedTranslationAuthorName = resolvedAuthorName(for: first.languageCode)
            } else {
                resolvedTranslationLanguage = nil
                resolvedTranslationId = nil
                resolvedTranslationAuthorName = nil
            }
            print("QuranTranslation selectedLanguage=\(selectedLanguage) resolvedLanguage=\(resolvedTranslationLanguage ?? "nil") translationId=\(resolvedTranslationId ?? -1)")
            logTranslationDebug(translations: translations, verses: verses)
        } catch {
            if !Task.isCancelled {
                print("QuranTranslation selectedLanguage=\(selectedLanguage) resolvedLanguage=nil translationId=-1 error=\(error)")
            }
            resolvedTranslationAuthorName = nil
        }
    }

    private func resolvedAuthorName(for languageCode: String) -> String? {
        if let localSource = QuranLocalDataStore.translationSourceDisplayName(for: languageCode) {
            return localSource
        }

        switch languageCode {
        case "tr": return "Diyanet İşleri Başkanlığı"
        case "en": return "Sahih International"
        case "de": return "Bubenheim ve Elyas"
        case "fr": return "Muhammad Hamidullah"
        case "es": return "Julio Cortés"
        case "ru": return "Kuliyev"
        case "ur": return "Jalandhry"
        case "fa": return "Fooladvand"
        case "id": return "Kementerian Agama RI"
        case "ms": return "Basmeih"
        case "ar": return "Arapça Mushaf"
        default: return nil
        }
    }

    private func logRenderedMealLanguageIfNeeded(language: String) {
        guard !didLogRenderedMealLanguage else { return }
        didLogRenderedMealLanguage = true
        print("QuranTranslation renderedMealLanguage=\(language)")
    }

    private func logTranslationDebug(translations: [QuranVerseTranslation], verses: [QuranVerse]) {
        guard !didLogTranslationDebug else { return }
        didLogTranslationDebug = true

        let translationKeys = translations.prefix(3).map { normalizeVerseKey($0.verseKey) }
        let verseIds = verses.prefix(3).map { normalizeVerseKey($0.id) }
        print("QuranTranslation fetchedCount=\(translations.count)")
        print("QuranTranslation translationsByKeyCount=\(translationsByKey.count)")
        print("QuranTranslation firstTranslationKeys=\(translationKeys)")
        print("QuranTranslation firstVerseIds=\(verseIds)")

        if let sampleVerse = verses.first {
            let key = normalizeVerseKey(sampleVerse.id)
            let hit = translationsByKey[key] != nil
            print("QuranTranslation lookupSampleVerseKey=\(key) hit=\(hit)")
        }
    }

    private var appSelectedLanguageCode: String {
        let raw = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? "tr"
        return normalizeLanguageCode(raw)
    }

    private func normalizeLanguageCode(_ raw: String) -> String {
        let lower = raw.lowercased()
        if let sepIndex = lower.firstIndex(where: { $0 == "-" || $0 == "_" }) {
            return String(lower[..<sepIndex])
        }
        return lower
    }

    private func normalizeVerseKey(_ raw: String) -> String {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
        let parts = cleaned.split(separator: ":")
        guard parts.count == 2,
              let surah = Int(parts[0]),
              let verse = Int(parts[1]) else {
            return cleaned
        }
        return "\(surah):\(verse)"
    }
}
