import Foundation

nonisolated struct RabiaQuranIndexEntry: Codable, Sendable, Hashable {
    let surah: Int
    let ayah: Int
    let arabic: String

    var id: String { "\(surah):\(ayah)" }
}

nonisolated struct RabiaQuranTranslationEntry: Codable, Sendable, Hashable {
    let s: Int
    let a: Int
    let t: String

    var id: String { "\(s):\(a)" }
}

nonisolated struct RabiaQuranVerse: Sendable, Hashable {
    let surah: Int
    let ayah: Int
    let arabic: String
    let translation: String

    var id: String { "\(surah):\(ayah)" }
}

nonisolated struct RabiaQuranSurahNameEntry: Codable, Sendable, Hashable {
    let id: Int
    let names: [String: String]
}

nonisolated struct LegacyQuranDatasetVerse: Codable, Sendable, Hashable {
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let arabic: String
    let turkish: String

    enum CodingKeys: String, CodingKey {
        case surahNumber = "surah_number"
        case surahName = "surah_name"
        case ayahNumber = "ayah_number"
        case arabic
        case turkish
    }

    var id: String { "\(surahNumber):\(ayahNumber)" }
}

nonisolated struct VerifiedQuranHit: Sendable {
    let surahId: Int
    let surahName: String
    let verseNumber: Int
    let arabicText: String
    let translationText: String
    let score: Int

    var verseID: String { "\(surahId):\(verseNumber)" }

    init(verse: RabiaQuranVerse, surahName: String, score: Int) {
        surahId = verse.surah
        self.surahName = surahName
        verseNumber = verse.ayah
        arabicText = verse.arabic
        translationText = verse.translation
        self.score = score
    }
}

nonisolated struct VerifiedHadithHit: Sendable {
    let id: String
    let collection: String
    let reference: String
    let text: String
    let keywords: [String]
    let score: Int
}

nonisolated struct IslamicKnowledgeCard: Codable, Sendable, Hashable {
    let id: String
    let title: String
    let summary: String
    let keywords: [String]
    let tags: [String]
}

nonisolated struct VerifiedKnowledgeHit: Sendable {
    let id: String
    let title: String
    let summary: String
    let score: Int
}

nonisolated struct RabiaRetrievedContext: Sendable {
    let quranVerses: [RabiaQuranVerse]
    let hadiths: [VerifiedHadithHit]
    let knowledgeCards: [VerifiedKnowledgeHit]
}

final class RabiaVerifiedSourceStore {
    static let shared = RabiaVerifiedSourceStore()

#if DEBUG
    static var testQuranDisplayProvider: ((Int, Int) -> String?)?
#endif

    private lazy var quranDataset: [RabiaQuranVerse] = loadRabiaQuranDataset()
    private lazy var quranVerseById: [String: RabiaQuranVerse] = Dictionary(uniqueKeysWithValues: quranDataset.map { ($0.id, $0) })
    private lazy var surahNamesById: [Int: RabiaQuranSurahNameEntry] = loadRabiaSurahNames()
    private lazy var surahNameList: [String] = buildSurahNameList()
    private lazy var hadithDataset: [VerifiedHadithHit] = loadHadithDataset()
    private lazy var islamicKnowledgeDataset: [IslamicKnowledgeCard] = loadIslamicKnowledgeDataset()
    private lazy var appKnowledgeDataset: [IslamicKnowledgeCard] = loadAppKnowledgeDataset()
    private var translationMapsByLanguage: [String: [String: String]] = [:]
    private(set) var rabiaDatasetLoaded: Bool = false
    private(set) var rabiaIndexLoadSucceeded: Bool = false
    private(set) var rabiaTranslationsLoadSucceeded: Bool = false
    private(set) var rabiaTranslationLanguage: String = "tr"
    private let stopWords: Set<String> = [
        "acaba", "ait", "ama", "ancak", "artık", "aslında", "az", "bana", "bazen", "belki", "ben", "beni",
        "benim", "bir", "biraz", "biz", "bize", "bizi", "bu", "böyle", "çok", "çünkü", "da", "daha", "de",
        "defa", "diye", "edebilir", "eder", "en", "gibi", "hangi", "hani", "hemen", "hem", "hep", "her",
        "hiç", "için", "ile", "ise", "iyi", "kadar", "karşı", "kez", "ki", "kim", "mı", "mi", "mu", "mü",
        "ne", "neden", "nerede", "nasıl", "o", "olarak", "olur", "ona", "onu", "orada", "sadece", "sanki",
        "sen", "seni", "senin", "siz", "size", "sizi", "sonra", "şey", "şu", "tüm", "ve", "veya", "ya",
        "yani"
    ]

    var hasQuranDataset: Bool { quranDataset.count == 6236 }
    var hasHadithDataset: Bool { !hadithDataset.isEmpty }
    var quranVerseCount: Int { quranDataset.count }

    private init() {}

    func allSurahNames() -> [String] {
        if !surahNameList.isEmpty {
            return surahNameList
        }
        return buildSurahNameList()
    }

    func searchQuranVerses(keyword query: String, limit: Int = 5) -> [RabiaQuranVerse] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let queryTokens = tokenizedKeywords(from: normalizedQuery)
        guard !queryTokens.isEmpty else { return [] }

        let weightedTokens = expandedKeywords(from: queryTokens)
        var scored: [(verse: RabiaQuranVerse, score: Int)] = []

        for verse in quranDataset {
            let normalizedTranslation = normalize(verse.translation)
            let normalizedArabic = normalize(verse.arabic)

            var score = 0

            if normalizedTranslation.contains(normalizedQuery) {
                score += 10
            }

            for token in weightedTokens {
                if normalizedTranslation.contains(token) {
                    score += 4
                }
                if normalizedArabic.contains(token) {
                    score += 2
                }
            }

            if score > 0 {
                scored.append((verse, score))
            }
        }

        return scored
            .sorted {
                if $0.score == $1.score {
                    if $0.verse.surah == $1.verse.surah {
                        return $0.verse.ayah < $1.verse.ayah
                    }
                    return $0.verse.surah < $1.verse.surah
                }
                return $0.score > $1.score
            }
            .prefix(limit)
            .map(\.verse)
    }

    func searchQuran(query: String, limit: Int = 5) -> [VerifiedQuranHit] {
        let verses = searchQuranVerses(keyword: query, limit: max(limit * 3, limit))
        let normalizedQuery = normalize(query)
        let weightedTokens = expandedKeywords(from: tokenizedKeywords(from: normalizedQuery))

        return verses.map { verse in
            let normalizedTranslation = normalize(verse.translation)
            let normalizedArabic = normalize(verse.arabic)

            var score = 0
            if normalizedTranslation.contains(normalizedQuery) { score += 10 }

            for token in weightedTokens {
                if normalizedTranslation.contains(token) { score += 4 }
                if normalizedArabic.contains(token) { score += 2 }
            }

            let surahName = surahDisplayName(for: verse.surah) ?? "Sure"
            return VerifiedQuranHit(verse: verse, surahName: surahName, score: score)
        }
        .sorted {
            if $0.score == $1.score {
                if $0.surahId == $1.surahId {
                    return $0.verseNumber < $1.verseNumber
                }
                return $0.surahId < $1.surahId
            }
            return $0.score > $1.score
        }
        .prefix(limit)
        .map { $0 }
    }

    func formattedVerseContext(for query: String, limit: Int = 3) -> String? {
        let verses = searchQuranVerses(keyword: query, limit: limit)
        guard !verses.isEmpty else { return nil }

        return verses.map { verse in
            """
            "\(verse.translation)"
            (\(verse.surah):\(verse.ayah))
            """
        }
        .joined(separator: "\n\n")
    }

    func searchHadith(query: String, limit: Int = 5) -> [VerifiedHadithHit] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let weightedTokens = expandedKeywords(from: tokenizedKeywords(from: normalizedQuery))

        return hadithDataset
            .compactMap { hadith in
                let normalizedText = normalize(hadith.text)
                let normalizedReference = normalize(hadith.reference)
                let normalizedCollection = normalize(hadith.collection)
                let normalizedKeywords = hadith.keywords.map(normalize)

                var score = 0
                if normalizedText.contains(normalizedQuery) { score += 10 }
                if normalizedReference.contains(normalizedQuery) { score += 8 }
                if normalizedCollection.contains(normalizedQuery) { score += 6 }

                for token in weightedTokens {
                    if normalizedText.contains(token) { score += 4 }
                    if normalizedKeywords.contains(where: { $0.contains(token) }) { score += 5 }
                    if normalizedCollection.contains(token) { score += 2 }
                }

                guard score > 0 else { return nil }
                return VerifiedHadithHit(
                    id: hadith.id,
                    collection: hadith.collection,
                    reference: hadith.reference,
                    text: hadith.text,
                    keywords: hadith.keywords,
                    score: score
                )
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.reference < $1.reference
                }
                return $0.score > $1.score
            }
            .prefix(limit)
            .map { $0 }
    }

    func searchIslamicKnowledge(query: String, limit: Int = 5) -> [VerifiedKnowledgeHit] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let weightedTokens = expandedKeywords(from: tokenizedKeywords(from: normalizedQuery))

        return (islamicKnowledgeDataset + appKnowledgeDataset)
            .compactMap { card in
                let normalizedTitle = normalize(card.title)
                let normalizedSummary = normalize(card.summary)
                let normalizedKeywords = card.keywords.map(normalize)
                let normalizedTags = card.tags.map(normalize)

                var score = 0
                if normalizedTitle.contains(normalizedQuery) { score += 8 }
                if normalizedSummary.contains(normalizedQuery) { score += 6 }

                for token in weightedTokens {
                    if normalizedTitle.contains(token) { score += 5 }
                    if normalizedSummary.contains(token) { score += 4 }
                    if normalizedKeywords.contains(where: { $0.contains(token) }) { score += 5 }
                    if normalizedTags.contains(where: { $0.contains(token) }) { score += 3 }
                }

                guard score > 0 else { return nil }
                return VerifiedKnowledgeHit(id: card.id, title: card.title, summary: card.summary, score: score)
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.title < $1.title
                }
                return $0.score > $1.score
            }
            .prefix(limit)
            .map { $0 }
    }

    func retrieveContext(for query: String, includeQuran: Bool = true) -> RabiaRetrievedContext {
        let quranVerses = includeQuran ? searchQuranVerses(keyword: query, limit: 2) : []
        let hadiths = searchHadith(query: query, limit: 1)
        let knowledgeCards = searchIslamicKnowledge(query: query, limit: 1)

#if DEBUG
        print("[RabiaQuran] dataset_hit=\(!quranVerses.isEmpty) quran_hits=\(quranVerses.count) include_quran=\(includeQuran)")
#endif

        return RabiaRetrievedContext(
            quranVerses: quranVerses,
            hadiths: hadiths,
            knowledgeCards: knowledgeCards
        )
    }

    private func loadRabiaQuranDataset() -> [RabiaQuranVerse] {
        let indexEntries = loadRabiaQuranIndex()
        rabiaIndexLoadSucceeded = indexEntries.count == 6236

        guard rabiaIndexLoadSucceeded else {
#if DEBUG
            print("[RabiaQuran] dataset_load_failure=index_entries=\(indexEntries.count)")
#endif
            rabiaDatasetLoaded = false
            return []
        }

        let appLanguage = RabiaAppLanguage.currentCode()
        rabiaTranslationLanguage = appLanguage
        let translations = loadRabiaQuranTranslations(language: appLanguage)
        rabiaTranslationsLoadSucceeded = !translations.isEmpty
        let englishFallback = appLanguage == "en"
            ? translations
            : loadRabiaQuranTranslations(language: "en")

#if DEBUG
        print("[RabiaQuran] app_language=\(appLanguage)")
        print("[RabiaQuran] translation_file=rabia_quran_translations_\(appLanguage).json entries=\(translations.count)")
        if appLanguage != "en" {
            print("[RabiaQuran] fallback_translation_file=rabia_quran_translations_en.json entries=\(englishFallback.count)")
        }
#endif

        rabiaDatasetLoaded = true

#if DEBUG
        print("[RabiaQuran] dataset_load_success=true entries=\(indexEntries.count)")
#endif

        return indexEntries.map { entry in
            let key = entry.id
            let translation = translations[key] ?? englishFallback[key] ?? entry.arabic
            return RabiaQuranVerse(
                surah: entry.surah,
                ayah: entry.ayah,
                arabic: entry.arabic,
                translation: translation
            )
        }
    }

    private func loadRabiaQuranIndex() -> [RabiaQuranIndexEntry] {
        guard let url = Bundle.main.url(forResource: "rabia_quran_dataset", withExtension: "json") else {
#if DEBUG
            print("[RabiaQuran] index_load_failure=missing_file")
#endif
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
#if DEBUG
            print("[RabiaQuran] index_load_failure=read_error")
#endif
            return []
        }
        guard let verses = try? JSONDecoder().decode([RabiaQuranIndexEntry].self, from: data) else {
#if DEBUG
            print("[RabiaQuran] index_load_failure=decode_error")
#endif
            return []
        }

#if DEBUG
        let status = verses.count == 6236 ? "success" : "unexpected_count"
        print("[RabiaQuran] index_load_\(status)=\(verses.count)")
#endif

        return verses
    }

    private func loadRabiaQuranTranslations(language: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: "rabia_quran_translations_\(language)", withExtension: "json") else {
#if DEBUG
            print("[RabiaQuran] translation_load_failure=missing_file lang=\(language)")
#endif
            return [:]
        }
        guard let data = try? Data(contentsOf: url) else {
#if DEBUG
            print("[RabiaQuran] translation_load_failure=read_error lang=\(language)")
#endif
            return [:]
        }
        guard let entries = try? JSONDecoder().decode([RabiaQuranTranslationEntry].self, from: data) else {
#if DEBUG
            print("[RabiaQuran] translation_load_failure=decode_error lang=\(language)")
#endif
            return [:]
        }

#if DEBUG
        let status = entries.count == 6236 ? "success" : "unexpected_count"
        print("[RabiaQuran] translation_load_\(status)=\(entries.count) lang=\(language)")
#endif

        var map: [String: String] = [:]
        map.reserveCapacity(entries.count)
        for entry in entries {
            map[entry.id] = entry.t
        }
        return map
    }

    private func loadRabiaSurahNames() -> [Int: RabiaQuranSurahNameEntry] {
        guard let url = Bundle.main.url(forResource: "rabia_quran_surah_names", withExtension: "json") else {
#if DEBUG
            print("[RabiaQuran] surah_names_load_failure=missing_file")
#endif
            return [:]
        }
        guard let data = try? Data(contentsOf: url) else {
#if DEBUG
            print("[RabiaQuran] surah_names_load_failure=read_error")
#endif
            return [:]
        }
        guard let entries = try? JSONDecoder().decode([RabiaQuranSurahNameEntry].self, from: data) else {
#if DEBUG
            print("[RabiaQuran] surah_names_load_failure=decode_error")
#endif
            return [:]
        }

        var map: [Int: RabiaQuranSurahNameEntry] = [:]
        map.reserveCapacity(entries.count)
        for entry in entries {
            map[entry.id] = entry
        }
#if DEBUG
        print("[RabiaQuran] surah_names_load_success=\(map.count)")
#endif
        return map
    }

    private func buildSurahNameList() -> [String] {
        var set = Set<String>()
        set.reserveCapacity(surahNamesById.count * 2)
        for entry in surahNamesById.values {
            for name in entry.names.values {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count >= 3 {
                    set.insert(trimmed)
                }
            }
        }
        return Array(set).sorted { $0.count > $1.count }
    }

    func quranDisplayText(surah: Int, ayah: Int) -> String? {
#if DEBUG
        if let provider = Self.testQuranDisplayProvider {
            return provider(surah, ayah)
        }
#endif
        let preferredLanguageCodes = RabiaLanguagePolicy.preferredReferenceLanguageCodes(for: RabiaAppLanguage.currentCode())
        guard quranVerseById["\(surah):\(ayah)"] != nil else { return nil }

        let surahName = localizedSurahName(for: surah, preferredLanguageCodes: preferredLanguageCodes)
            ?? surahDisplayName(for: surah)
            ?? "\(surah)"

        if let localized = localizedTranslation(surah: surah, ayah: ayah, preferredLanguageCodes: preferredLanguageCodes) {
            return "\(surahName) \(surah):\(ayah)\n\(localized.text)"
        }

        return "\(surahName) \(surah):\(ayah)"
    }

    func localizedTranslation(surah: Int, ayah: Int, preferredLanguageCodes: [String]) -> (text: String, languageCode: String)? {
        let verseID = "\(surah):\(ayah)"
        guard quranVerseById[verseID] != nil else { return nil }

        for code in preferredLanguageCodes {
            let normalizedCode = normalizeLanguageCode(code)
            let translations = cachedRabiaQuranTranslations(language: normalizedCode)
            if let text = translations[verseID]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty {
                return (text, normalizedCode)
            }
        }

        return nil
    }

    func localizedSurahName(for surahId: Int, preferredLanguageCodes: [String]) -> String? {
        guard let entry = surahNamesById[surahId] else { return nil }

        for code in preferredLanguageCodes {
            let normalizedCode = normalizeLanguageCode(code)
            if let value = entry.names[normalizedCode]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }

        return entry.names["tr"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? entry.names["en"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func surahDisplayName(for surahId: Int) -> String? {
        guard let entry = surahNamesById[surahId] else { return nil }
        let appLanguage = RabiaAppLanguage.currentCode()
        if appLanguage == "ar" {
            return entry.names["ar"] ?? entry.names["en"] ?? entry.names["tr"]
        }

#if DEBUG
        if entry.names[appLanguage] == nil {
            print("[RabiaQuran] surah_name_fallback lang=\(appLanguage) surah=\(surahId)")
        }
#endif

        let latinFallback = entry.names["en"] ?? entry.names["tr"]
        return entry.names[appLanguage]
            ?? entry.names["en"]
            ?? latinFallback
    }

    private func loadLegacyQuranDataset() -> [RabiaQuranVerse] {
        if let url = Bundle.main.url(forResource: "quran_dataset", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let verses = try? JSONDecoder().decode([LegacyQuranDatasetVerse].self, from: data),
           verses.count == 6236 {
            return verses.map { verse in
                RabiaQuranVerse(
                    surah: verse.surahNumber,
                    ayah: verse.ayahNumber,
                    arabic: verse.arabic,
                    translation: verse.turkish
                )
            }
        }

        return QuranSurahData.offlineVerses
            .flatMap { surahId, verses in
                verses.map { verse in
                    RabiaQuranVerse(
                        surah: surahId,
                        ayah: verse.verseNumber,
                        arabic: verse.arabicText,
                        translation: verse.turkishTranslation
                    )
                }
            }
            .sorted {
                if $0.surah == $1.surah {
                    return $0.ayah < $1.ayah
                }
                return $0.surah < $1.surah
            }
    }

    private func loadHadithDataset() -> [VerifiedHadithHit] {
        guard let url = Bundle.main.url(forResource: "hadith_dataset", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let hadiths = try? JSONDecoder().decode([HadithDatasetEntry].self, from: data) else {
            return []
        }

        return hadiths.map {
            VerifiedHadithHit(
                id: $0.id,
                collection: $0.collection,
                reference: $0.reference,
                text: $0.text,
                keywords: $0.keywords,
                score: 0
            )
        }
    }

    private func loadIslamicKnowledgeDataset() -> [IslamicKnowledgeCard] {
        guard let url = Bundle.main.url(forResource: "islamic_knowledge", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cards = try? JSONDecoder().decode([IslamicKnowledgeCard].self, from: data) else {
            return []
        }

        return cards
    }

    private func loadAppKnowledgeDataset() -> [IslamicKnowledgeCard] {
        [
            IslamicKnowledgeCard(
                id: "app_rabia_identity",
                title: "Rabia kimdir?",
                summary: "Rabia, \(AppName.short) uygulamasinin uygulama ici sohbet asistanidir. Kuran, dua, zikir, gunluk takip ve uygulama bolumleri hakkinda rehberlik eder.",
                keywords: ["rabia", "chat bot", "chatbot", "hangi uygulama", "uygulama ici asistan", "zikrim"],
                tags: ["app", "assistant", "rabia"]
            ),
            IslamicKnowledgeCard(
                id: "app_prayer_times",
                title: "Namaz vakitleri",
                summary: "Namaz vakitleri ekraninda Turkiye icin Diyanet kaynakli vakitler, diger konumlar icin ise hesaplama tabanli vakitler gosterilir. Konum ve bildirim ayarlari ayni alandan yonetilir.",
                keywords: ["namaz vakitleri", "diyanet", "ezan", "bildirim", "konum"],
                tags: ["app", "prayer", "diyanet"]
            ),
            IslamicKnowledgeCard(
                id: "app_quran",
                title: "Kur'an bolumu",
                summary: "Kur'an ekraninda sure ve ayet aramasi, favori ayetler, yer imleri, meal gorunumu ve gelismis sesli dinleme ozellikleri bulunur.",
                keywords: ["kuran", "ayet", "meal", "player", "dinleme", "favori ayet"],
                tags: ["app", "quran", "audio"]
            ),
            IslamicKnowledgeCard(
                id: "app_guide",
                title: "Zikir ve dua rehberi",
                summary: "Rehber bolumunde gunluk dualar, ruh haline gore oneriler, favoriler ve Rabia destekli yonlendirmeler yer alir.",
                keywords: ["dua rehberi", "zikir rehberi", "favoriler", "arama", "ruh hali"],
                tags: ["app", "guide", "favorites"]
            ),
            IslamicKnowledgeCard(
                id: "app_more",
                title: "Daha fazla bolumu",
                summary: "Daha Fazla ekraninda profil, namaz vakitleri, kibla bulucu, tema, bildirim ve widget aciklamalari gibi yardimci araclara ulasilir.",
                keywords: ["daha fazla", "profil", "widget", "tema", "kible bulucu"],
                tags: ["app", "more", "tools"]
            )
        ]
    }

    private func tokenizedKeywords(from normalizedQuery: String) -> [String] {
        normalizedQuery
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 1 && !stopWords.contains($0) }
    }

    private func expandedKeywords(from tokens: [String]) -> [String] {
        var allTokens = Set(tokens)
        let joined = tokens.joined(separator: " ")

        let expansions: [(matches: [String], adds: [String])] = [
            (["huzur", "sakin", "dingin", "ferah"], ["huzur", "kalp", "zikr", "rahmet"]),
            (["sabir", "zorluk", "musibet", "imtihan"], ["sabir", "zorluk", "kolaylik"]),
            (["sukur", "nimet", "hamd"], ["sukur", "hamd", "nimet"]),
            (["tevbe", "gunah", "bagislanma", "magfiret"], ["tevbe", "magfiret", "rahmet"]),
            (["dua", "yakaris"], ["dua", "rab", "rahmet"]),
            (["rizik", "bereket"], ["rizik", "bereket", "takva"]),
            (["korku", "endise", "kaygi"], ["korku", "guven", "tevekkul"]),
            (["merhamet", "rahmet"], ["rahmet", "merhamet"]),
            (["namaz", "ibadet", "secde"], ["namaz", "ibadet", "secde"])
        ]

        for expansion in expansions where expansion.matches.contains(where: { joined.contains($0) }) {
            allTokens.formUnion(expansion.adds)
        }

        return Array(allTokens)
    }

    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "[^\\p{L}\\p{N}\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cachedRabiaQuranTranslations(language: String) -> [String: String] {
        let normalizedLanguage = normalizeLanguageCode(language)
        if let cached = translationMapsByLanguage[normalizedLanguage] {
            return cached
        }

        let loaded = loadRabiaQuranTranslations(language: normalizedLanguage)
        translationMapsByLanguage[normalizedLanguage] = loaded
        return loaded
    }

    private func normalizeLanguageCode(_ raw: String) -> String {
        let normalized = raw
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        return normalized.split(separator: "-").first.map(String.init) ?? normalized
    }
}

extension VerifiedQuranHit {
    var localizedTranslation: String {
        translationText
    }

    var localizedSurahName: String {
        surahName
    }
}

extension VerifiedHadithHit {
    var localizedText: String {
        ContentLocalizer.shared.localized("hadith.\(id).text", fallback: text)
    }

    var localizedCollection: String {
        ContentLocalizer.shared.localized("hadith.\(id).collection", fallback: collection)
    }

    var localizedReference: String {
        ContentLocalizer.shared.localized("hadith.\(id).reference", fallback: reference)
    }

    func localizedText(preferredLanguageCodes: [String]) -> (value: String, languageCode: String)? {
        ContentLocalizer.shared.localizedValue(
            "hadith.\(id).text",
            preferredLanguageCodes: preferredLanguageCodes
        )
    }

    func localizedCollection(preferredLanguageCodes: [String]) -> (value: String, languageCode: String)? {
        ContentLocalizer.shared.localizedValue(
            "hadith.\(id).collection",
            preferredLanguageCodes: preferredLanguageCodes,
            fallback: collection
        )
    }

    func localizedReference(preferredLanguageCodes: [String]) -> (value: String, languageCode: String)? {
        ContentLocalizer.shared.localizedValue(
            "hadith.\(id).reference",
            preferredLanguageCodes: preferredLanguageCodes,
            fallback: reference
        )
    }
}

extension VerifiedKnowledgeHit {
    var localizedTitle: String {
        ContentLocalizer.shared.localized("knowledge.\(id).title", fallback: title)
    }

    var localizedSummary: String {
        ContentLocalizer.shared.localized("knowledge.\(id).summary", fallback: summary)
    }

    func localizedTitle(preferredLanguageCodes: [String]) -> String? {
        ContentLocalizer.shared.localizedValue(
            "knowledge.\(id).title",
            preferredLanguageCodes: preferredLanguageCodes
        )?.value
    }

    func localizedSummary(preferredLanguageCodes: [String]) -> String? {
        ContentLocalizer.shared.localizedValue(
            "knowledge.\(id).summary",
            preferredLanguageCodes: preferredLanguageCodes
        )?.value
    }
}

extension IslamicKnowledgeCard {
    var localizedTitle: String {
        ContentLocalizer.shared.localized("knowledge.\(id).title", fallback: title)
    }

    var localizedSummary: String {
        ContentLocalizer.shared.localized("knowledge.\(id).summary", fallback: summary)
    }

    func localizedTitle(preferredLanguageCodes: [String]) -> String? {
        ContentLocalizer.shared.localizedValue(
            "knowledge.\(id).title",
            preferredLanguageCodes: preferredLanguageCodes
        )?.value
    }

    func localizedSummary(preferredLanguageCodes: [String]) -> String? {
        ContentLocalizer.shared.localizedValue(
            "knowledge.\(id).summary",
            preferredLanguageCodes: preferredLanguageCodes
        )?.value
    }
}

private struct HadithDatasetEntry: Codable {
    let id: String
    let collection: String
    let reference: String
    let text: String
    let keywords: [String]
    let tags: [String]
}
