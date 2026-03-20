import Foundation

nonisolated struct QuranReaderPreferences: Codable, Equatable, Sendable {
    var appearance: QuranReaderAppearance
    var fontOption: QuranFontOption
    var mushafScriptOption: QuranArabicScriptOption
    var displayMode: QuranDisplayMode
    var layoutMode: QuranReaderLayoutMode
    var arabicFontSize: Double
    var translationFontSize: Double
    var transliterationFontSize: Double
    var arabicLineSpacing: Double
    var translationLineSpacing: Double
    var keepScreenAwake: Bool
    var autoHideChromeInMushafFocusedMode: Bool
    var rememberLastPosition: Bool
    var showAyahNumbers: Bool
    var compactMode: Bool
    var preferredTafsirSourceID: String
    var showShortExplanationChip: Bool
    var enableInlineTafsirPreview: Bool
    var showWordByWord: Bool
    var defaultTafsirFallbackLanguage: AppLanguage

    static let `default` = QuranReaderPreferences(
        appearance: .standardDark,
        fontOption: .standardNaskh,
        mushafScriptOption: .standardUthmani,
        displayMode: .arabicWithTranslation,
        layoutMode: .verseByVerse,
        arabicFontSize: 31,
        translationFontSize: 17,
        transliterationFontSize: 15,
        arabicLineSpacing: 0.46,
        translationLineSpacing: 0.34,
        keepScreenAwake: false,
        autoHideChromeInMushafFocusedMode: true,
        rememberLastPosition: true,
        showAyahNumbers: true,
        compactMode: false,
        preferredTafsirSourceID: QuranTafsirSource.zikrimShortExplanation.id,
        showShortExplanationChip: true,
        enableInlineTafsirPreview: true,
        showWordByWord: false,
        defaultTafsirFallbackLanguage: .en
    )
}

nonisolated struct QuranReaderScrollAnchor: Codable, Equatable, Sendable {
    let surahID: Int
    let ayahNumber: Int
    let layoutMode: QuranReaderLayoutMode
}

nonisolated struct QuranReaderVerseItem: Identifiable, Hashable, Sendable {
    let verse: QuranVerse
    let translation: String
    let transliteration: String?
    let mushafArabicText: String?
    let isBookmarked: Bool
    let verseNote: QuranVerseNote?
    let shortExplanation: QuranShortExplanationPayload?
    let wordByWord: [QuranWordByWordEntry]?

    var id: String { verse.id }
    var reference: AyahReference { AyahReference(surahNumber: verse.surahId, ayahNumber: verse.verseNumber) }
}

nonisolated struct QuranWordByWordEntry: Codable, Hashable, Sendable, Identifiable {
    let surahNumber: Int
    let ayahNumber: Int
    let wordIndex: Int
    let arabic: String
    let translation: String?

    var id: String { "\(surahNumber):\(ayahNumber):\(wordIndex)" }
}

nonisolated struct ReaderVerseMode: Identifiable, Hashable, Sendable {
    let item: QuranReaderVerseItem
    var id: String { item.id }
}

nonisolated struct ReaderPageMode: Identifiable, Hashable, Sendable {
    let index: Int
    let verses: [QuranReaderVerseItem]

    var id: Int { index }
}

nonisolated enum QuranReaderPremiumFeature: Hashable, Sendable {
    case arabicFont(QuranFontOption)
    case layout(QuranReaderLayoutMode)
    case tafsirSource(String)
    case notes
    case advancedAudio
}

protocol QuranReaderFeatureGating: Sendable {
    func isEnabled(_ feature: QuranReaderPremiumFeature) -> Bool
}

struct OpenQuranReaderFeatureGating: QuranReaderFeatureGating {
    func isEnabled(_ feature: QuranReaderPremiumFeature) -> Bool { true }
}

extension QuranReaderPreferences {
    private enum CodingKeys: String, CodingKey {
        case appearance
        case fontOption
        case mushafScriptOption
        case displayMode
        case layoutMode
        case arabicFontSize
        case translationFontSize
        case transliterationFontSize
        case arabicLineSpacing
        case translationLineSpacing
        case keepScreenAwake
        case autoHideChromeInMushafFocusedMode
        case rememberLastPosition
        case showAyahNumbers
        case compactMode
        case preferredTafsirSourceID
        case showShortExplanationChip
        case enableInlineTafsirPreview
        case showWordByWord
        case defaultTafsirFallbackLanguage
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Self.default

        appearance = try container.decodeIfPresent(QuranReaderAppearance.self, forKey: .appearance) ?? fallback.appearance
        fontOption = try container.decodeIfPresent(QuranFontOption.self, forKey: .fontOption) ?? fallback.fontOption
        mushafScriptOption = try container.decodeIfPresent(QuranArabicScriptOption.self, forKey: .mushafScriptOption) ?? fallback.mushafScriptOption
        displayMode = try container.decodeIfPresent(QuranDisplayMode.self, forKey: .displayMode) ?? fallback.displayMode
        layoutMode = try container.decodeIfPresent(QuranReaderLayoutMode.self, forKey: .layoutMode) ?? fallback.layoutMode
        arabicFontSize = try container.decodeIfPresent(Double.self, forKey: .arabicFontSize) ?? fallback.arabicFontSize
        translationFontSize = try container.decodeIfPresent(Double.self, forKey: .translationFontSize) ?? fallback.translationFontSize
        transliterationFontSize = try container.decodeIfPresent(Double.self, forKey: .transliterationFontSize) ?? fallback.transliterationFontSize
        arabicLineSpacing = try container.decodeIfPresent(Double.self, forKey: .arabicLineSpacing) ?? fallback.arabicLineSpacing
        translationLineSpacing = try container.decodeIfPresent(Double.self, forKey: .translationLineSpacing) ?? fallback.translationLineSpacing
        keepScreenAwake = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? fallback.keepScreenAwake
        autoHideChromeInMushafFocusedMode = try container.decodeIfPresent(Bool.self, forKey: .autoHideChromeInMushafFocusedMode) ?? fallback.autoHideChromeInMushafFocusedMode
        rememberLastPosition = try container.decodeIfPresent(Bool.self, forKey: .rememberLastPosition) ?? fallback.rememberLastPosition
        showAyahNumbers = try container.decodeIfPresent(Bool.self, forKey: .showAyahNumbers) ?? fallback.showAyahNumbers
        compactMode = try container.decodeIfPresent(Bool.self, forKey: .compactMode) ?? fallback.compactMode
        preferredTafsirSourceID = try container.decodeIfPresent(String.self, forKey: .preferredTafsirSourceID) ?? fallback.preferredTafsirSourceID
        showShortExplanationChip = try container.decodeIfPresent(Bool.self, forKey: .showShortExplanationChip) ?? fallback.showShortExplanationChip
        enableInlineTafsirPreview = try container.decodeIfPresent(Bool.self, forKey: .enableInlineTafsirPreview) ?? fallback.enableInlineTafsirPreview
        showWordByWord = try container.decodeIfPresent(Bool.self, forKey: .showWordByWord) ?? fallback.showWordByWord
        defaultTafsirFallbackLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .defaultTafsirFallbackLanguage) ?? fallback.defaultTafsirFallbackLanguage
    }
}
