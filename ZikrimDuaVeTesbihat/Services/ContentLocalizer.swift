import Foundation

final class ContentLocalizer: @unchecked Sendable {
    // This singleton is immutable after initialization, so cross-actor reads are safe.
    nonisolated static let shared = ContentLocalizer()

    nonisolated private struct Payload: Codable, Sendable {
        let version: Int
        let sourceLanguage: String
        let keys: [String: [String: String]]
    }

    private let fallbackLanguage = "tr"
    private let translations: [String: [String: String]]

    private init() {
        self.translations = Self.loadTranslations()
    }

    nonisolated private var currentLanguageCode: String {
        RabiaAppLanguage.currentCode()
    }

    nonisolated private static func loadTranslations() -> [String: [String: String]] {
        guard let url = Bundle.main.url(forResource: "content_localizations", withExtension: "json") else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            return payload.keys
        } catch {
            return [:]
        }
    }

    nonisolated func localized(_ key: String, fallback: String) -> String {
        let lang = currentLanguageCode
        if let value = translations[key]?[lang] { return value }
        if let value = translations[key]?[fallbackLanguage] { return value }
        return fallback
    }

    nonisolated func localizedValue(
        _ key: String,
        preferredLanguageCodes: [String],
        fallback: String? = nil
    ) -> (value: String, languageCode: String)? {
        for code in preferredLanguageCodes.map(RabiaAppLanguage.normalizedCode(for:)) {
            if let value = translations[key]?[code]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return (value, code)
            }
        }

        if let fallback, !fallback.isEmpty {
            return (fallback, "fallback")
        }

        return nil
    }
}
