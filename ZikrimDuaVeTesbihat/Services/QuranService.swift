import Foundation
import AVFoundation
import SwiftUI

@Observable
@MainActor
class QuranService {
    var verses: [QuranVerse] = []
    var semanticResultText: String? = nil
    var isSemanticSearching: Bool = false
    var playingVerseKey: String? = nil
    var isLoading: Bool = false
    var errorMessage: String?
    var bookmarks: [QuranBookmark] = []
    var lastReadPosition: QuranReadPosition?
    var displayMode: QuranDisplayMode = .both
    var arabicFontSize: CGFloat = 26
    var turkishFontSize: CGFloat = 15

    private let bookmarksKey = "quran_bookmarks"
    private let recitationId: Int = 7
    private var audioCache: [String: String] = [:]
    private var audioPlayer: AVPlayer?
    private let lastReadKey = "quran_last_read"
    private let displayModeKey = "quran_display_mode"
    private let arabicFontKey = "quran_arabic_font"
    private let turkishFontKey = "quran_turkish_font"

    init() {
        loadBookmarks()
        loadLastRead()
        loadSettings()
    }

    func loadVerses(for surahId: Int) async {
        isLoading = true
        errorMessage = nil
        verses = []

        if let offline = QuranSurahData.offlineVerses[surahId] {
            verses = offline
            isLoading = false
            return
        }

        let cacheKey = "quran_surah_\(surahId)"
        if let cached = loadCachedVerses(key: cacheKey) {
            verses = cached
            isLoading = false
            return
        }

        await fetchFromAPI(surahId: surahId, cacheKey: cacheKey)
        isLoading = false
    }

    private func fetchFromAPI(surahId: Int, cacheKey: String) async {
        let urlString = "https://api.alquran.cloud/v1/surah/\(surahId)/editions/quran-uthmani,tr.diyanet"
        guard let url = URL(string: urlString) else {
            errorMessage = "Geçersiz URL"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MultiEditionResponse.self, from: data)

            guard response.data.count >= 2 else {
                errorMessage = "Veri formatı hatalı"
                return
            }

            let arabicEdition = response.data[0]
            let turkishEdition = response.data[1]

            var result: [QuranVerse] = []
            for (index, arabicAyah) in arabicEdition.ayahs.enumerated() {
                let turkishText = index < turkishEdition.ayahs.count ? turkishEdition.ayahs[index].text : ""
                result.append(QuranVerse(
                    surahId: surahId,
                    verseNumber: arabicAyah.numberInSurah,
                    arabicText: arabicAyah.text,
                    turkishTranslation: turkishText
                ))
            }
            verses = result
            cacheVerses(result, key: cacheKey)
        } catch {
            errorMessage = "Sure yüklenemedi. İnternet bağlantınızı kontrol edin."
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
            $0.turkishTranslation.localizedStandardContains(trimmed) ||
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

    func saveSettings() {
        UserDefaults.standard.set(displayMode.rawValue, forKey: displayModeKey)
        UserDefaults.standard.set(Double(arabicFontSize), forKey: arabicFontKey)
        UserDefaults.standard.set(Double(turkishFontSize), forKey: turkishFontKey)
    }

    private func loadSettings() {
        if let raw = UserDefaults.standard.string(forKey: displayModeKey),
           let mode = QuranDisplayMode(rawValue: raw) {
            displayMode = mode
        }
        let arabic = UserDefaults.standard.double(forKey: arabicFontKey)
        if arabic > 0 { arabicFontSize = CGFloat(arabic) }
        let turkish = UserDefaults.standard.double(forKey: turkishFontKey)
        if turkish > 0 { turkishFontSize = CGFloat(turkish) }
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

    private func cacheVerses(_ verses: [QuranVerse], key: String) {
        if let data = try? JSONEncoder().encode(verses) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadCachedVerses(key: String) -> [QuranVerse]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([QuranVerse].self, from: data)
    }
}
