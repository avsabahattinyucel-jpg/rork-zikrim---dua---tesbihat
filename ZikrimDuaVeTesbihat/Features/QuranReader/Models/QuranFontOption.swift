import SwiftUI

nonisolated enum QuranFontOption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case standardNaskh
    case classicMushaf
    case traditionalNaskh

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .standardNaskh: return "quran_reader_font_standard_naskh"
        case .classicMushaf: return "quran_reader_font_classic_mushaf"
        case .traditionalNaskh: return "quran_reader_font_traditional_naskh"
        }
    }

    var defaultTitle: String {
        switch self {
        case .standardNaskh: return "Recitation"
        case .classicMushaf: return "Mushaf"
        case .traditionalNaskh: return "Heritage"
        }
    }

    var detailLocalizationKey: String {
        switch self {
        case .standardNaskh: return "quran_reader_font_standard_naskh_detail"
        case .classicMushaf: return "quran_reader_font_classic_mushaf_detail"
        case .traditionalNaskh: return "quran_reader_font_traditional_naskh_detail"
        }
    }

    var defaultDetail: String {
        switch self {
        case .standardNaskh: return "Clear and balanced for everyday reading."
        case .classicMushaf: return "A classic mushaf feel with more character."
        case .traditionalNaskh: return "A deeper traditional tone with rooted forms."
        }
    }

    var fontCandidates: [String] {
        switch self {
        case .standardNaskh:
            return ["NotoNaskhArabic-Regular", "Noto Naskh Arabic", "DecoTypeNaskh", "DecoType Naskh", "GeezaPro", "Geeza Pro", "SFArabic-Regular"]
        case .classicMushaf:
            return ["Amiri-Regular", "Amiri", "KufiStandardGK", "DiwanKufi", "GeezaPro-Bold", "GeezaPro"]
        case .traditionalNaskh:
            return ["ScheherazadeNew-Regular", "Scheherazade New", "DamascusMedium", "Damascus", "AlNile", "Al Nile", "SFArabicRounded-Regular"]
        }
    }

    var previewSample: String {
        "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
    }

    var isPremiumCandidate: Bool {
        switch self {
        case .standardNaskh: return false
        case .classicMushaf, .traditionalNaskh: return true
        }
    }
}
