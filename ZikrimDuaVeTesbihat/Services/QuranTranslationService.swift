import Foundation

enum QuranTranslationServiceError: Error {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case translationUnavailable
    case cacheWriteFailed
}

final class QuranTranslationService {
    private struct ArabicVersesResponse: Codable {
        let verses: [ArabicVerse]
    }

    private struct ArabicVerse: Codable, Sendable {
        let verseKey: String
        let textUthmani: String

        enum CodingKeys: String, CodingKey {
            case verseKey = "verse_key"
            case textUthmani = "text_uthmani"
        }
    }

    private struct TranslationResponse: Codable {
        let translations: [TranslationVerse]
    }

    private struct TranslationVerse: Codable, Sendable {
        let verseKey: String?
        let text: String
        let resourceId: Int?

        enum CodingKeys: String, CodingKey {
            case verseKey = "verse_key"
            case text
            case resourceId = "resource_id"
        }
    }

    private let session: URLSession
    private let baseURL: URL
    private let cache: QuranTranslationCache
    private let mapper: LanguageTranslationMapper
    private let arabicTranslationId = 0

    init(baseURL: URL = URL(string: "https://api.quran.com/api/v4")!,
         session: URLSession = .shared,
         cache: QuranTranslationCache = QuranTranslationCache(),
         mapper: LanguageTranslationMapper = LanguageTranslationMapper()) {
        self.baseURL = baseURL
        self.session = session
        self.cache = cache
        self.mapper = mapper
    }

#if DEBUG
    func clearCachesForDebug() async {
        try? await cache.clearAll()
        UserDefaults.standard.removeObject(forKey: "quran_translation_id_map")
    }
#endif

    func fetchSurahTranslations(surahId: Int, languageCode: String) async throws -> [QuranVerseTranslation] {
        let normalized = normalizeLanguageCode(languageCode)

        if normalized == "ar",
           let localArabic = await QuranLocalDataStore.shared.localArabicVerses(forSurahId: surahId) {
            return localArabic.map {
                QuranVerseTranslation(
                    surahId: $0.surahId,
                    verseNumber: $0.verseNumber,
                    verseKey: $0.id,
                    translationId: arabicTranslationId,
                    languageCode: "ar",
                    text: $0.arabicText
                )
            }
        }

        if let localTranslations = await QuranLocalDataStore.shared.localTranslations(
            forSurahId: surahId,
            languageCode: normalized
        ) {
            return localTranslations
        }

        if normalized == "ar" {
            if let cached = await cache.loadSurahTranslations(surahId: surahId, translationId: arabicTranslationId) {
                return cached
            }

            do {
                let verses = try await fetchArabicVersesFromAPI(surahId: surahId)
                do {
                    try await cache.storeSurahTranslations(verses, surahId: surahId, translationId: arabicTranslationId)
                } catch {
                    throw QuranTranslationServiceError.cacheWriteFailed
                }
                return verses
            } catch {
                if let cached = await cache.loadSurahTranslations(surahId: surahId, translationId: arabicTranslationId) {
                    return cached
                }
                throw error
            }
        }

        let resolved = try await mapper.resolveTranslation(for: languageCode)

        if let cached = await cache.loadSurahTranslations(surahId: surahId, translationId: resolved.translationId) {
            return cached
        }

        do {
            let verses = try await fetchFromAPI(surahId: surahId, resolved: resolved)
            do {
                try await cache.storeSurahTranslations(verses, surahId: surahId, translationId: resolved.translationId)
            } catch {
                throw QuranTranslationServiceError.cacheWriteFailed
            }
            return verses
        } catch {
            if let cached = await cache.loadSurahTranslations(surahId: surahId, translationId: resolved.translationId) {
                return cached
            }
            throw error
        }
    }

    private func fetchArabicVersesFromAPI(surahId: Int) async throws -> [QuranVerseTranslation] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("verses/by_chapter/\(surahId)"), resolvingAgainstBaseURL: false) else {
            throw QuranTranslationServiceError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "language", value: "ar"),
            URLQueryItem(name: "fields", value: "text_uthmani")
        ]

        guard let url = components.url else { throw QuranTranslationServiceError.invalidURL }
        let (data, response) = try await session.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw QuranTranslationServiceError.invalidResponse
        }

        let decoded: ArabicVersesResponse
        do {
            decoded = try JSONDecoder().decode(ArabicVersesResponse.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("QuranTranslation decodeFailed url=\(url.absoluteString) status=\(status) error=\(error) body=\(body.prefix(500))")
            throw QuranTranslationServiceError.decodingFailed
        }

        var result: [QuranVerseTranslation] = []
        result.reserveCapacity(decoded.verses.count)

        for item in decoded.verses {
            guard let (surah, verse) = parseVerseKey(item.verseKey) else { continue }
            result.append(QuranVerseTranslation(
                surahId: surah,
                verseNumber: verse,
                verseKey: item.verseKey,
                translationId: arabicTranslationId,
                languageCode: "ar",
                text: item.textUthmani
            ))
        }

        return result
    }

    private func fetchFromAPI(surahId: Int, resolved: LanguageTranslationMapper.ResolvedTranslation) async throws -> [QuranVerseTranslation] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("quran/translations/\(resolved.translationId)"), resolvingAgainstBaseURL: false) else {
            throw QuranTranslationServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "chapter_number", value: String(surahId))]

        guard let url = components.url else { throw QuranTranslationServiceError.invalidURL }
        let (data, response) = try await session.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw QuranTranslationServiceError.invalidResponse
        }

        let decoded: TranslationResponse
        do {
            decoded = try JSONDecoder().decode(TranslationResponse.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("QuranTranslation decodeFailed url=\(url.absoluteString) status=\(status) error=\(error) body=\(body.prefix(500))")
            throw QuranTranslationServiceError.decodingFailed
        }

        var result: [QuranVerseTranslation] = []
        result.reserveCapacity(decoded.translations.count)

        for (index, item) in decoded.translations.enumerated() {
            let key = item.verseKey ?? "\(surahId):\(index + 1)"
            guard let (surah, verse) = parseVerseKey(key) else { continue }
            result.append(QuranVerseTranslation(
                surahId: surah,
                verseNumber: verse,
                verseKey: key,
                translationId: resolved.translationId,
                languageCode: resolved.languageCode,
                text: item.text
            ))
        }

        return result
    }

    private func parseVerseKey(_ key: String) -> (Int, Int)? {
        let parts = key.split(separator: ":")
        guard parts.count == 2,
              let surah = Int(parts[0]),
              let verse = Int(parts[1]) else { return nil }
        return (surah, verse)
    }

    private func normalizeLanguageCode(_ raw: String) -> String {
        let lower = raw.lowercased()
        if let sepIndex = lower.firstIndex(where: { $0 == "-" || $0 == "_" }) {
            return String(lower[..<sepIndex])
        }
        return lower
    }
}

#if DEBUG
@MainActor
enum QuranTranslationExamples {
    static func fetchSurahExample() async {
        let service = QuranTranslationService()
        let verses = try? await service.fetchSurahTranslations(surahId: 1, languageCode: "tr")
        _ = verses
    }

    static func cacheWriteReadExample() async {
        let cache = QuranTranslationCache()
        let sample = [
            QuranVerseTranslation(surahId: 1, verseNumber: 1, verseKey: "1:1", translationId: 20, languageCode: "en", text: "Sample")
        ]
        try? await cache.storeSurahTranslations(sample, surahId: 1, translationId: 20)
        let cached = await cache.loadSurahTranslations(surahId: 1, translationId: 20)
        _ = cached
    }
}
#endif
