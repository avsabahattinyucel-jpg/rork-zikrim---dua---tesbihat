import Foundation

nonisolated enum QuranArabicScriptOption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case standardUthmani
    case indoPakMushaf

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .standardUthmani: return "quran_reader_script_standard_uthmani"
        case .indoPakMushaf: return "quran_reader_script_indopak_mushaf"
        }
    }

    var defaultTitle: String {
        switch self {
        case .standardUthmani: return "Standard Uthmani"
        case .indoPakMushaf: return "IndoPak Mushaf"
        }
    }
}
