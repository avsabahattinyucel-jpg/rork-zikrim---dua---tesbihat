import SwiftUI

nonisolated enum QuranReaderAppearance: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case standardDark
    case mushaf
    case sepia
    case nightFocus
    case translationFocus

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .standardDark: return "quran_reader_appearance_standard_dark"
        case .mushaf: return "quran_reader_appearance_mushaf"
        case .sepia: return "quran_reader_appearance_sepia"
        case .nightFocus: return "quran_reader_appearance_night_focus"
        case .translationFocus: return "quran_reader_appearance_translation_focus"
        }
    }

    var defaultTitle: String {
        switch self {
        case .standardDark: return "Standard Dark"
        case .mushaf: return "Mushaf Mode"
        case .sepia: return "Sepia"
        case .nightFocus: return "Night Focus"
        case .translationFocus: return "Translation Focus"
        }
    }

    var iconName: String {
        switch self {
        case .standardDark: return "moon.stars.fill"
        case .mushaf: return "book.closed.fill"
        case .sepia: return "sun.haze.fill"
        case .nightFocus: return "moon.zzz.fill"
        case .translationFocus: return "text.alignleft"
        }
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? QuranReaderAppearance.standardDark.rawValue

        switch rawValue {
        case "dark", "systemLinked":
            self = .standardDark
        case "light":
            self = .translationFocus
        case QuranReaderAppearance.standardDark.rawValue:
            self = .standardDark
        case QuranReaderAppearance.mushaf.rawValue:
            self = .mushaf
        case QuranReaderAppearance.sepia.rawValue:
            self = .sepia
        case QuranReaderAppearance.nightFocus.rawValue:
            self = .nightFocus
        case QuranReaderAppearance.translationFocus.rawValue:
            self = .translationFocus
        default:
            self = .standardDark
        }
    }
}

struct QuranReaderCanvasStyle {
    let background: Color
    let secondaryBackground: Color
    let cardBackground: Color
    let border: Color
    let divider: Color
    let arabicText: Color
    let translationText: Color
    let transliterationText: Color
    let badgeBackground: Color
    let badgeForeground: Color
    let chipBackground: Color
    let chipForeground: Color
    let selectionHighlight: Color
    let activeWordFill: Color
    let activeWordStroke: Color
    let activeWordText: Color
    let audioSurface: Color
    let audioBorder: Color
    let shadowColor: Color
    let heroGradient: LinearGradient
    let heroGlow: Color
}
