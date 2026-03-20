import Foundation

final class LanguageTranslationMapper {
    struct ResolvedTranslation: Sendable {
        let languageCode: String
        let translationId: Int
        let name: String?
        let authorName: String?
        let slug: String?
    }

    private struct TranslationsResponse: Codable {
        let translations: [TranslationResource]
    }

    private struct TranslationResource: Codable, Sendable {
        let id: Int
        let name: String?
        let authorName: String?
        let slug: String?
        let languageName: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case authorName = "author_name"
            case slug
            case languageName = "language_name"
        }
    }

    private let session: URLSession
    private let baseURL: URL
    private let userDefaults: UserDefaults
    private let cacheKey = "quran_translation_id_map"

    private let preferredSlugs: [String: [String]] = [
        "en": ["sahih-international", "yusuf-ali"],
        "tr": ["diyanet-isleri", "turkish"],
        "de": ["de-bubenheim"],
        "es": ["spanish"],
        "fr": ["french"],
        "id": ["indonesian"],
        "ur": ["urdu"],
        "ms": ["malay"],
        "ru": ["russian"],
        "fa": ["farsi"]
    ]

    init(baseURL: URL = URL(string: "https://api.quran.com/api/v4")!,
         session: URLSession = .shared,
         userDefaults: UserDefaults = .standard) {
        self.baseURL = baseURL
        self.session = session
        self.userDefaults = userDefaults
    }

    func resolveTranslation(for languageCode: String) async throws -> ResolvedTranslation {
        print("QuranTranslationMapper resolve start languageCode=\(languageCode)")
        let codes = fallbackLanguageCodes(from: languageCode)
        var lastError: Error?

        for code in codes {
            if let cachedId = cachedTranslationId(for: code) {
                return ResolvedTranslation(
                    languageCode: code,
                    translationId: cachedId,
                    name: nil,
                    authorName: cachedAuthorName(for: code),
                    slug: nil
                )
            }

            do {
                if let resolvedResource = try await fetchTranslationId(for: code) {
                    cacheTranslationId(resolvedResource.id, for: code)
                    cacheAuthorName(resolvedResource.authorName ?? resolvedResource.name, for: code)
                    return ResolvedTranslation(
                        languageCode: code,
                        translationId: resolvedResource.id,
                        name: resolvedResource.name,
                        authorName: resolvedResource.authorName,
                        slug: resolvedResource.slug
                    )
                } else {
                    print("QuranTranslationMapper resolve failed for \(code): translationId=nil")
                }
            } catch {
                lastError = error
            }
        }

        if let lastError { throw lastError }
        throw QuranTranslationServiceError.translationUnavailable
    }

    private func fetchTranslationId(for languageCode: String) async throws -> TranslationResource? {
        print("QuranTranslationMapper fetchTranslationId start languageCode=\(languageCode)")
        guard var components = URLComponents(url: baseURL.appendingPathComponent("resources/translations"), resolvingAgainstBaseURL: false) else {
            throw QuranTranslationServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "language", value: languageCode)]

        guard let url = components.url else { throw QuranTranslationServiceError.invalidURL }
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw QuranTranslationServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(TranslationsResponse.self, from: data)
        let requested = normalizeLanguageCode(languageCode)

        let filtered = decoded.translations.filter { resource in
            let langName = normalizeLanguageName(resource.languageName)
            if langName == requested { return true }

            let slug = (resource.slug ?? "").lowercased()
            if slug.hasPrefix("\(requested)-") { return true }
            if slug.hasPrefix("quran.\(requested).") { return true }
            return false
        }

        print("QuranTranslationMapper requested=\(requested) total=\(decoded.translations.count) filtered=\(filtered.count)")
        let preview = filtered.prefix(5).map { "\($0.id)|\($0.slug ?? "")|\($0.languageName ?? "")" }
        print("QuranTranslationMapper filteredPreview=\(preview)")

        if let slugs = preferredSlugs[requested] {
            for slug in slugs {
                if let match = filtered.first(where: { ($0.slug ?? "").caseInsensitiveCompare(slug) == .orderedSame }) {
                    print("QuranTranslationMapper chosenId=\(match.id)")
                    return match
                }
            }
        }

        if let first = filtered.first {
            print("QuranTranslationMapper chosenId=\(first.id)")
            return first
        }

        print("QuranTranslationMapper chosenId=nil reason=filtered_empty requested=\(requested)")
        return nil
    }

    private func cachedTranslationId(for languageCode: String) -> Int? {
        let map = cachedMap()
        return map[languageCode]
    }

    private func cachedAuthorName(for languageCode: String) -> String? {
        userDefaults.string(forKey: "\(cacheKey)_author_\(languageCode)")
    }

    private func cacheTranslationId(_ id: Int, for languageCode: String) {
        var map = cachedMap()
        map[languageCode] = id
        if let data = try? JSONEncoder().encode(map) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }

    private func cacheAuthorName(_ name: String?, for languageCode: String) {
        userDefaults.set(name, forKey: "\(cacheKey)_author_\(languageCode)")
    }

    private func cachedMap() -> [String: Int] {
        guard let data = userDefaults.data(forKey: cacheKey),
              let map = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return map
    }

    private func fallbackLanguageCodes(from raw: String) -> [String] {
        let normalized = normalizeLanguageCode(raw)
        var result: [String] = []
        for code in [normalized, "en", "ar"] {
            if !code.isEmpty, !result.contains(code) {
                result.append(code)
            }
        }
        return result
    }

    private func normalizeLanguageCode(_ raw: String) -> String {
        let lower = raw.lowercased()
        if let sepIndex = lower.firstIndex(where: { $0 == "-" || $0 == "_" }) {
            return String(lower[..<sepIndex])
        }
        return lower
    }

    private func normalizeLanguageName(_ raw: String?) -> String {
        guard let raw else { return "" }
        let lower = raw.lowercased()
        if let mapped = languageNameMap[lower] {
            return mapped
        }
        return normalizeLanguageCode(lower)
    }

    private var languageNameMap: [String: String] {
        [
            "german": "de",
            "russian": "ru",
            "urdu": "ur",
            "malay": "ms",
            "french": "fr",
            "spanish": "es",
            "turkish": "tr",
            "english": "en",
            "arabic": "ar",
            "indonesian": "id",
            "persian": "fa",
            "farsi": "fa"
        ]
    }
}
