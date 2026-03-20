import Foundation

nonisolated enum QuranDisplayMode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case arabicOnly
    case arabicWithTranslation
    case arabicWithTransliterationAndTranslation
    case translationOnly

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .arabicOnly: return "quran_reader_display_arabic_only"
        case .arabicWithTranslation: return "quran_reader_display_arabic_translation"
        case .arabicWithTransliterationAndTranslation: return "quran_reader_display_arabic_transliteration_translation"
        case .translationOnly: return "quran_reader_display_translation_only"
        }
    }

    var defaultTitle: String {
        switch self {
        case .arabicOnly: return "Arabic Only"
        case .arabicWithTranslation: return "Arabic with Translation"
        case .arabicWithTransliterationAndTranslation: return "Arabic, Transliteration, Translation"
        case .translationOnly: return "Translation Only"
        }
    }

    var showsArabic: Bool {
        switch self {
        case .translationOnly: return false
        default: return true
        }
    }

    var showsTranslation: Bool {
        switch self {
        case .arabicOnly: return false
        default: return true
        }
    }

    var showsTransliteration: Bool {
        self == .arabicWithTransliterationAndTranslation
    }

    func updatingTranslationVisibility(_ isVisible: Bool) -> QuranDisplayMode {
        switch (self, isVisible) {
        case (.arabicOnly, true):
            return .arabicWithTranslation
        case (.translationOnly, true):
            return .translationOnly
        case (.arabicWithTranslation, false):
            return .arabicOnly
        case (.arabicWithTransliterationAndTranslation, false):
            return .arabicOnly
        case (.translationOnly, false):
            return .arabicOnly
        default:
            return self
        }
    }

    func updatingTransliterationVisibility(_ isVisible: Bool) -> QuranDisplayMode {
        if isVisible {
            return showsArabic ? .arabicWithTransliterationAndTranslation : .translationOnly
        }

        switch self {
        case .arabicWithTransliterationAndTranslation:
            return .arabicWithTranslation
        default:
            return self
        }
    }
}

nonisolated enum QuranReaderLayoutMode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case verseByVerse
    case pageMode
    case mushafFocused

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .verseByVerse: return "quran_reader_layout_verse_by_verse"
        case .pageMode: return "quran_reader_layout_page_mode"
        case .mushafFocused: return "quran_reader_layout_mushaf_focused"
        }
    }

    var defaultTitle: String {
        switch self {
        case .verseByVerse: return "Verse by Verse"
        case .pageMode: return "Page Mode"
        case .mushafFocused: return "Mushaf Focused"
        }
    }
}

nonisolated enum QuranReadingMode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case mushaf
    case reading
    case study

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .mushaf: return "quran_reader_mode_mushaf"
        case .reading: return "quran_reader_mode_reading"
        case .study: return "quran_reader_mode_study"
        }
    }

    var defaultTitle: String {
        switch self {
        case .mushaf: return "Mushaf Mode"
        case .reading: return "Reading Mode"
        case .study: return "Study Mode"
        }
    }

    var iconName: String {
        switch self {
        case .mushaf: return "book.closed"
        case .reading: return "text.alignleft"
        case .study: return "text.book.closed"
        }
    }
}
