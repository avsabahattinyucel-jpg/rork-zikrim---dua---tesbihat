import Foundation

actor QuranLocalDataStore {
    static let shared = QuranLocalDataStore()

    struct TranslationResource: Sendable {
        let baseName: String
        let sourceDisplayName: String
        let translationId: Int
        let stripsInlineFootnotes: Bool
    }

    struct TafsirResource: Sendable {
        let baseName: String
        let sourceDisplayName: String
    }

    private enum ResourceKind {
        case verseText
        case tafsirText
    }

    nonisolated static let translationResources: [String: TranslationResource] = [
        "tr": TranslationResource(
            baseName: "quran_local_translation_tr",
            sourceDisplayName: "Diyanet Isleri Baskanligi",
            translationId: 9_001,
            stripsInlineFootnotes: false
        ),
        "en": TranslationResource(
            baseName: "quran_local_translation_en",
            sourceDisplayName: "Qaribullah & Darwish",
            translationId: 9_002,
            stripsInlineFootnotes: false
        ),
        "ur": TranslationResource(
            baseName: "quran_local_translation_ur",
            sourceDisplayName: "Maulana Wahiduddin Khan",
            translationId: 9_003,
            stripsInlineFootnotes: false
        ),
        "fa": TranslationResource(
            baseName: "quran_local_translation_fa",
            sourceDisplayName: "Islamhouse.com",
            translationId: 9_004,
            stripsInlineFootnotes: false
        ),
        "de": TranslationResource(
            baseName: "quran_local_translation_de",
            sourceDisplayName: "Bubenheim & Elyas",
            translationId: 9_005,
            stripsInlineFootnotes: false
        ),
        "fr": TranslationResource(
            baseName: "quran_local_translation_fr",
            sourceDisplayName: "Muhammad Hamidullah",
            translationId: 9_006,
            stripsInlineFootnotes: true
        ),
        "es": TranslationResource(
            baseName: "quran_local_translation_es",
            sourceDisplayName: "Noor International Center",
            translationId: 9_007,
            stripsInlineFootnotes: true
        ),
        "id": TranslationResource(
            baseName: "quran_local_translation_id",
            sourceDisplayName: "King Fahad Quran Complex",
            translationId: 9_008,
            stripsInlineFootnotes: false
        ),
        "ms": TranslationResource(
            baseName: "quran_local_translation_ms",
            sourceDisplayName: "Abdullah Basmeih",
            translationId: 9_009,
            stripsInlineFootnotes: false
        ),
        "ru": TranslationResource(
            baseName: "quran_local_translation_ru",
            sourceDisplayName: "Nuri Osmanov",
            translationId: 9_010,
            stripsInlineFootnotes: false
        )
    ]

    nonisolated static let tafsirResources: [String: TafsirResource] = [
        "tr": TafsirResource(baseName: "quran_local_tafsir_tr", sourceDisplayName: "As-Sa'di"),
        "en": TafsirResource(baseName: "quran_local_tafsir_en", sourceDisplayName: "Abridged Explanation of the Quran"),
        "ur": TafsirResource(baseName: "quran_local_tafsir_ur", sourceDisplayName: "As-Sa'di"),
        "fa": TafsirResource(baseName: "quran_local_tafsir_fa", sourceDisplayName: "Mokhtasar Tafsir"),
        "fr": TafsirResource(baseName: "quran_local_tafsir_fr", sourceDisplayName: "Mokhtasar Tafsir"),
        "es": TafsirResource(baseName: "quran_local_tafsir_es", sourceDisplayName: "Mokhtasar Tafsir"),
        "id": TafsirResource(baseName: "quran_local_tafsir_id", sourceDisplayName: "Mokhtasar Tafsir"),
        "ru": TafsirResource(baseName: "quran_local_tafsir_ru", sourceDisplayName: "Mokhtasar Tafsir"),
        "ar": TafsirResource(baseName: "quran_local_tafsir_ar", sourceDisplayName: "Al-Mukhtasar fi Tafsir al-Quran")
    ]

    nonisolated static func translationSourceDisplayName(for languageCode: String) -> String? {
        translationResources[Self.normalizeLanguageCode(languageCode)]?.sourceDisplayName
    }

    nonisolated static func tafsirSourceDisplayName(for languageCode: String) -> String? {
        tafsirResources[Self.normalizeLanguageCode(languageCode)]?.sourceDisplayName
    }

    private var translationCache: [String: [String: String]] = [:]
    private var tafsirCache: [String: [String: String]] = [:]
    private var transliterationCache: [String: [String: String]] = [:]
    private var wordByWordCache: [String: [String: String]] = [:]
    private var arabicVerseCache: [String: [String: String]] = [:]

    func localTranslations(forSurahId surahId: Int, languageCode: String) -> [QuranVerseTranslation]? {
        let normalized = Self.normalizeLanguageCode(languageCode)
        guard let resource = Self.translationResources[normalized],
              let map = loadVerseTextMap(baseName: resource.baseName, kind: .verseText, stripsInlineFootnotes: resource.stripsInlineFootnotes) else {
            return nil
        }

        return buildVerseTranslations(
            from: map,
            surahId: surahId,
            languageCode: normalized,
            translationId: resource.translationId
        )
    }

    func localArabicVerses(
        forSurahId surahId: Int,
        script: QuranArabicScriptOption = .standardUthmani
    ) -> [QuranVerse]? {
        let baseName = arabicVerseBaseName(for: script)
        if arabicVerseCache[baseName] == nil {
            arabicVerseCache[baseName] = loadVerseTextMap(baseName: baseName, kind: .verseText)
        }

        guard let map = arabicVerseCache[baseName] else { return nil }
        let filtered = map.compactMap { key, text -> QuranVerse? in
            guard let (surah, ayah) = Self.parseVerseKey(key), surah == surahId else { return nil }
            return QuranVerse(
                surahId: surah,
                verseNumber: ayah,
                arabicText: Self.normalizeWhitespace(text),
                turkishTranslation: ""
            )
        }

        guard !filtered.isEmpty else { return nil }
        return filtered.sorted { $0.verseNumber < $1.verseNumber }
    }

    func arabicScriptText(
        forSurahId surahId: Int,
        script: QuranArabicScriptOption
    ) -> [AyahReference: String] {
        guard script != .standardUthmani,
              let verses = localArabicVerses(forSurahId: surahId, script: script) else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: verses.map {
            (AyahReference(surahNumber: $0.surahId, ayahNumber: $0.verseNumber), $0.arabicText)
        })
    }

    func transliterations(forSurahId surahId: Int, languageCode: String) -> [AyahReference: String] {
        let normalized = Self.normalizeLanguageCode(languageCode)
        let baseName = transliterationBaseName(for: normalized)
        guard let baseName else { return [:] }

        let map: [String: String]
        if let cached = transliterationCache[baseName] {
            map = cached
        } else {
            guard let loaded = loadVerseTextMap(baseName: baseName, kind: .verseText) else { return [:] }
            transliterationCache[baseName] = loaded
            map = loaded
        }

        var result: [AyahReference: String] = [:]
        for (key, text) in map {
            guard let (surah, ayah) = Self.parseVerseKey(key), surah == surahId else { continue }
            result[AyahReference(surahNumber: surah, ayahNumber: ayah)] = text
        }
        return result
    }

    func tafsirText(forVerseKey verseKey: String, languageCode: String) -> String? {
        let normalized = Self.normalizeLanguageCode(languageCode)
        guard let resource = Self.tafsirResources[normalized],
              let map = loadTafsirMap(baseName: resource.baseName) else {
            return nil
        }
        return map[verseKey]
    }

    func shortTafsirText(forVerseKey verseKey: String, languageCode: String) -> String? {
        guard let full = tafsirText(forVerseKey: verseKey, languageCode: languageCode) else {
            return nil
        }
        return Self.makeShortExcerpt(from: full)
    }

    func wordByWord(forSurahId surahId: Int, languageCode: String) -> [AyahReference: [QuranWordByWordEntry]] {
        guard let arabicMap = loadWordByWordMap(baseName: "quran_local_wbw_ar") else {
            return [:]
        }

        let normalized = Self.normalizeLanguageCode(languageCode)
        let translationMap: [String: String]
        if let translationBaseName = wordByWordTranslationBaseName(for: normalized) {
            translationMap = loadWordByWordMap(baseName: translationBaseName) ?? [:]
        } else {
            translationMap = [:]
        }

        var result: [AyahReference: [QuranWordByWordEntry]] = [:]

        for (key, arabicText) in arabicMap {
            guard let (surah, ayah, wordIndex) = Self.parseWordKey(key), surah == surahId else { continue }
            let reference = AyahReference(surahNumber: surah, ayahNumber: ayah)
            let entry = QuranWordByWordEntry(
                surahNumber: surah,
                ayahNumber: ayah,
                wordIndex: wordIndex,
                arabic: arabicText,
                translation: translationMap[key]
            )
            result[reference, default: []].append(entry)
        }

        for reference in result.keys {
            result[reference]?.sort { $0.wordIndex < $1.wordIndex }
        }

        return result
    }

    private func loadVerseTextMap(
        baseName: String,
        kind: ResourceKind,
        stripsInlineFootnotes: Bool = false
    ) -> [String: String]? {
        if kind == .verseText, let cached = translationCache[baseName] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: baseName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var map: [String: String] = [:]
        map.reserveCapacity(root.count)

        for (key, rawValue) in root {
            guard var text = Self.extractText(from: rawValue) else { continue }
            if stripsInlineFootnotes {
                text = Self.removeInlineFootnotes(from: text)
            }
            text = Self.normalizeWhitespace(text)
            guard !text.isEmpty else { continue }
            map[key] = text
        }

        if kind == .verseText {
            translationCache[baseName] = map
        }
        return map
    }

    private func loadTafsirMap(baseName: String) -> [String: String]? {
        if let cached = tafsirCache[baseName] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: baseName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var map: [String: String] = [:]
        map.reserveCapacity(root.count)

        for key in root.keys {
            guard let sanitized = Self.resolveTafsirText(for: key, in: root, cache: &map, visiting: []) else { continue }
            map[key] = sanitized
        }

        tafsirCache[baseName] = map
        return map
    }

    private func loadWordByWordMap(baseName: String) -> [String: String]? {
        if let cached = wordByWordCache[baseName] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: baseName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var map: [String: String] = [:]
        map.reserveCapacity(root.count)

        for (key, rawValue) in root {
            guard let text = Self.extractText(from: rawValue) else { continue }
            let normalized = Self.normalizeWhitespace(Self.sanitizeRichText(text))
            guard !normalized.isEmpty else { continue }
            map[key] = normalized
        }

        wordByWordCache[baseName] = map
        return map
    }

    private func buildVerseTranslations(
        from map: [String: String],
        surahId: Int,
        languageCode: String,
        translationId: Int
    ) -> [QuranVerseTranslation] {
        let filtered = map.compactMap { key, text -> QuranVerseTranslation? in
            guard let (surah, ayah) = Self.parseVerseKey(key), surah == surahId else { return nil }
            return QuranVerseTranslation(
                surahId: surah,
                verseNumber: ayah,
                verseKey: key,
                translationId: translationId,
                languageCode: languageCode,
                text: text
            )
        }

        return filtered.sorted { lhs, rhs in
            if lhs.surahId != rhs.surahId {
                return lhs.surahId < rhs.surahId
            }
            return lhs.verseNumber < rhs.verseNumber
        }
    }

    private func transliterationBaseName(for languageCode: String) -> String? {
        switch languageCode {
        case "ar":
            return nil
        default:
            return "quran_local_transliteration_tr"
        }
    }

    private func arabicVerseBaseName(for script: QuranArabicScriptOption) -> String {
        switch script {
        case .standardUthmani:
            return "quran_local_arabic_verses"
        case .indoPakMushaf:
            return "quran_local_arabic_verses_indopak"
        }
    }

    private func wordByWordTranslationBaseName(for languageCode: String) -> String? {
        switch languageCode {
        case "en":
            return "quran_local_wbw_en"
        case "fr":
            return "quran_local_wbw_fr"
        case "tr":
            return "quran_local_wbw_tr"
        case "ur":
            return "quran_local_wbw_ur"
        case "fa":
            return "quran_local_wbw_fa"
        case "id":
            return "quran_local_wbw_id"
        default:
            return nil
        }
    }

    private static func extractText(from rawValue: Any) -> String? {
        if let string = rawValue as? String {
            return cleanupChunkArtifacts(in: string)
        }

        guard let object = rawValue as? [String: Any] else {
            return nil
        }

        if let chunks = object["t"] as? [Any] {
            let joined = chunks.compactMap { chunk -> String? in
                if let string = chunk as? String {
                    return string
                }
                return nil
            }.joined()
            return cleanupChunkArtifacts(in: joined)
        }

        if let text = object["t"] as? String {
            return cleanupChunkArtifacts(in: text)
        }

        if let text = object["text"] as? String {
            return cleanupChunkArtifacts(in: text)
        }

        return nil
    }

    private static func parseVerseKey(_ key: String) -> (Int, Int)? {
        let parts = key.split(separator: ":")
        guard parts.count == 2,
              let surah = Int(parts[0]),
              let ayah = Int(parts[1]) else {
            return nil
        }
        return (surah, ayah)
    }

    private static func parseWordKey(_ key: String) -> (Int, Int, Int)? {
        let parts = key.split(separator: ":")
        guard parts.count == 3,
              let surah = Int(parts[0]),
              let ayah = Int(parts[1]),
              let word = Int(parts[2]) else {
            return nil
        }
        return (surah, ayah, word)
    }

    private static func resolveTafsirText(
        for key: String,
        in root: [String: Any],
        cache: inout [String: String],
        visiting: Set<String>
    ) -> String? {
        if let cached = cache[key] {
            return cached
        }

        guard !visiting.contains(key), let rawValue = root[key] else {
            return nil
        }

        guard let text = extractText(from: rawValue) else {
            return nil
        }

        if parseVerseKey(text) != nil, root[text] != nil {
            var nextVisiting = visiting
            nextVisiting.insert(key)
            guard let resolved = resolveTafsirText(for: text, in: root, cache: &cache, visiting: nextVisiting) else {
                return nil
            }
            cache[key] = resolved
            return resolved
        }

        let sanitized = sanitizeRichText(text)
        guard !sanitized.isEmpty else {
            return nil
        }

        cache[key] = sanitized
        return sanitized
    }

    private static func makeShortExcerpt(from text: String, limit: Int = 260) -> String {
        let normalized = normalizeWhitespace(text)
        guard normalized.count > limit else { return normalized }

        let candidate = String(normalized.prefix(limit + 1))
        if let sentenceEnd = candidate.lastIndex(where: { ".!?".contains($0) }) {
            let prefix = candidate[...sentenceEnd].trimmingCharacters(in: .whitespacesAndNewlines)
            if prefix.count >= 80 {
                return prefix
            }
        }

        if let whitespace = candidate.lastIndex(where: { $0.isWhitespace }) {
            return String(candidate[..<whitespace]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        }

        return String(candidate.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private static func sanitizeRichText(_ raw: String) -> String {
        var text = raw
        let blockBreaks = ["</div>", "</p>", "<br>", "<br/>", "<br />"]
        for token in blockBreaks {
            text = text.replacingOccurrences(of: token, with: "\n\n")
        }

        text = removeInlineFootnotes(from: text)

        while let range = text.range(of: "<[^>]+>", options: .regularExpression) {
            text.replaceSubrange(range, with: "")
        }

        return text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func removeInlineFootnotes(from text: String) -> String {
        text.replacingOccurrences(
            of: #"\[\[(?s:.*?)\]\]"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func normalizeWhitespace(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanupChunkArtifacts(in text: String) -> String {
        text
            .replacingOccurrences(of: #"30993>1"#, with: "")
            .replacingOccurrences(of: #"3>1"#, with: "")
            .replacingOccurrences(of: #"(?<=\p{L})3(?=\s)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?<=\s)119,(?=\s)"#, with: "", options: .regularExpression)
    }

    private static func normalizeLanguageCode(_ raw: String) -> String {
        let lower = raw.lowercased()
        if let separator = lower.firstIndex(where: { $0 == "-" || $0 == "_" }) {
            return String(lower[..<separator])
        }
        return lower
    }
}
