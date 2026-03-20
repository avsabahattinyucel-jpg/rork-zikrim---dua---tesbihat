import Foundation

struct Hadith: Identifiable, Hashable, Sendable, Codable {
    let id: Int
    let language: String
    let title: String
    let fullHadith: String
    let shortCardText: String?
    let isShortFeedEligible: Bool
    let grade: String?
    let attribution: String?
    let explanation: String?
    let hints: [String]
    let hadeethArabic: String?

    var hadeeth: String {
        fullHadith
    }

    nonisolated init(
        id: Int,
        language: String,
        title: String,
        fullHadith: String,
        grade: String?,
        attribution: String?,
        explanation: String?,
        hints: [String],
        hadeethArabic: String?
    ) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedFullHadith = fullHadith.trimmingCharacters(in: .whitespacesAndNewlines)
        let selection = Self.makeShortFeedSelection(title: normalizedTitle, fullHadith: normalizedFullHadith)

        self.id = id
        self.language = language
        self.title = normalizedTitle
        self.fullHadith = normalizedFullHadith
        self.shortCardText = selection.shortCardText
        self.isShortFeedEligible = selection.isShortFeedEligible
        self.grade = grade
        self.attribution = attribution
        self.explanation = explanation
        self.hints = hints
        self.hadeethArabic = hadeethArabic
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            id: try container.decode(Int.self, forKey: .id),
            language: try container.decode(String.self, forKey: .language),
            title: try container.decode(String.self, forKey: .title),
            fullHadith: try container.decodeIfPresent(String.self, forKey: .fullHadith)
                ?? container.decodeIfPresent(String.self, forKey: .hadeeth)
                ?? "",
            grade: try container.decodeIfPresent(String.self, forKey: .grade),
            attribution: try container.decodeIfPresent(String.self, forKey: .attribution),
            explanation: try container.decodeIfPresent(String.self, forKey: .explanation),
            hints: try container.decodeIfPresent([String].self, forKey: .hints) ?? [],
            hadeethArabic: try container.decodeIfPresent(String.self, forKey: .hadeethArabic)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(language, forKey: .language)
        try container.encode(title, forKey: .title)
        try container.encode(fullHadith, forKey: .fullHadith)
        try container.encodeIfPresent(shortCardText, forKey: .shortCardText)
        try container.encode(isShortFeedEligible, forKey: .isShortFeedEligible)
        try container.encodeIfPresent(grade, forKey: .grade)
        try container.encodeIfPresent(attribution, forKey: .attribution)
        try container.encodeIfPresent(explanation, forKey: .explanation)
        try container.encode(hints, forKey: .hints)
        try container.encodeIfPresent(hadeethArabic, forKey: .hadeethArabic)
    }

    private nonisolated static func makeShortFeedSelection(title: String, fullHadith: String) -> (shortCardText: String?, isShortFeedEligible: Bool) {
        if isMeaningfulShortTitle(title) {
            return (title, true)
        }

        if isConciseHadith(fullHadith) {
            return (fullHadith, true)
        }

        return (nil, false)
    }

    private nonisolated static func isMeaningfulShortTitle(_ title: String) -> Bool {
        guard !title.isEmpty, title.count <= 80 else {
            return false
        }

        let normalized = title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        let genericTitles = Set(["hadith", "hadeeth", "hadis"])
        guard !genericTitles.contains(normalized) else {
            return false
        }

        let letterCount = normalized.unicodeScalars.filter(CharacterSet.letters.contains).count
        return letterCount >= 3
    }

    private nonisolated static func isConciseHadith(_ fullHadith: String) -> Bool {
        guard !fullHadith.isEmpty, fullHadith.count <= 140 else {
            return false
        }

        let letterCount = fullHadith.unicodeScalars.filter(CharacterSet.letters.contains).count
        return letterCount >= 8
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case language
        case title
        case fullHadith
        case hadeeth
        case shortCardText
        case isShortFeedEligible
        case grade
        case attribution
        case explanation
        case hints
        case hadeethArabic
    }
}

protocol HadithShareRouting {
    func share(hadith: Hadith)
}
