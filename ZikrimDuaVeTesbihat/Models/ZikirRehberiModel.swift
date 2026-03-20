import Foundation

nonisolated enum RehberCategory: String, Codable, CaseIterable, Sendable {
    case favoriler = "favoriler"
    case gunlukRutinler = "gunluk_rutinler"
    case duygusalDurumlar = "duygusal_durumlar"
    case hayatDurumlari = "hayat_durumlari"
    case kisaTesbihatlar = "kisa_tesbihatlar"
    case kuranDualari = "kuran_dualari"
    case rabbena = "rabbena"
    case esmaülHüsna = "esmaulhusna"
    case hisnulMuslim = "hisnul_muslim"
    case cevsen = "cevsen"
    case kullanici = "kullanici"

    var displayName: String {
        switch self {
        case .favoriler: return L10n.string(.favoriler)
        case .gunlukRutinler: return L10n.string(.dailyRoutines)
        case .duygusalDurumlar: return L10n.string(.rehberCategoryDuygusalDurumlar)
        case .hayatDurumlari: return L10n.string(.rehberCategoryHayatDurumlari)
        case .kisaTesbihatlar: return L10n.string(.rehberCategoryKisaTesbihat)
        case .kuranDualari: return L10n.string(.rehberCategoryKuranDualari)
        case .rabbena: return L10n.string(.rehberCategoryRabbenaDualari)
        case .esmaülHüsna: return L10n.string(.rehberCategoryEsmaulHusna)
        case .hisnulMuslim: return L10n.string(.rehberCategoryHisnulMuslim)
        case .cevsen: return L10n.string(.rehberCategoryCevsen)
        case .kullanici: return L10n.string(.rehberCategoryEklediklerim)
        }
    }

    var icon: String {
        switch self {
        case .favoriler: return "heart.fill"
        case .gunlukRutinler: return "sun.max.fill"
        case .duygusalDurumlar: return "brain.head.profile"
        case .hayatDurumlari: return "leaf.fill"
        case .kisaTesbihatlar: return "circle.grid.3x3.fill"
        case .kuranDualari: return "book.closed.fill"
        case .rabbena: return "hands.sparkles.fill"
        case .esmaülHüsna: return "star.circle.fill"
        case .hisnulMuslim: return "shield.lefthalf.filled"
        case .cevsen: return "sparkles"
        case .kullanici: return "person.crop.circle.badge.plus"
        }
    }

    var requiresPremiumAccess: Bool {
        self == .cevsen
    }
}

nonisolated enum MoodFilter: String, CaseIterable, Sendable {
    case huzursuz = "huzursuz"
    case sukur = "sukur"
    case dardaKaldim = "darda_kaldim"
    case hastaOldum = "hasta_oldum"
    case sinavBasarisi = "sinav"

    var displayName: String {
        switch self {
        case .huzursuz: return L10n.string(.emotionUneasy)
        case .sukur: return L10n.string(.emotionGrateful)
        case .dardaKaldim: return L10n.string(.emotionDistressed)
        case .hastaOldum: return L10n.string(.emotionSick)
        case .sinavBasarisi: return L10n.string(.emotionExam)
        }
    }

    var icon: String {
        switch self {
        case .huzursuz: return "cloud.rain.fill"
        case .sukur: return "sun.max.fill"
        case .dardaKaldim: return "exclamationmark.triangle.fill"
        case .hastaOldum: return "cross.fill"
        case .sinavBasarisi: return "graduationcap.fill"
        }
    }
}

nonisolated struct RehberEntry: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let arabicText: String
    let transliteration: String
    let meaning: String
    let purpose: String
    let recommendedCount: Int
    let recommendedCountNote: String?
    let category: RehberCategory
    let notes: String?
    let schedule: String?
    let isInformational: Bool
    let moodTags: [String]
    let guideTabID: String?
    let sourceLabel: String?
    let verificationStatus: GuideVerificationStatus?
    let localizedTitleMap: [String: String]?
    let localizedTransliterationMap: [String: String]?
    let localizedMeaningMap: [String: String]?
    let localizedPurposeMap: [String: String]?
    let localizedSourceLabelMap: [String: String]?

    init(
        id: String,
        title: String,
        arabicText: String,
        transliteration: String,
        meaning: String,
        purpose: String,
        recommendedCount: Int,
        recommendedCountNote: String? = nil,
        category: RehberCategory,
        notes: String? = nil,
        schedule: String? = nil,
        isInformational: Bool = false,
        moodTags: [String] = [],
        guideTabID: String? = nil,
        sourceLabel: String? = nil,
        verificationStatus: GuideVerificationStatus? = nil,
        localizedTitleMap: [String: String]? = nil,
        localizedTransliterationMap: [String: String]? = nil,
        localizedMeaningMap: [String: String]? = nil,
        localizedPurposeMap: [String: String]? = nil,
        localizedSourceLabelMap: [String: String]? = nil
    ) {
        self.id = id
        self.title = title
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.meaning = meaning
        self.purpose = purpose
        self.recommendedCount = recommendedCount
        self.recommendedCountNote = recommendedCountNote
        self.category = category
        self.notes = notes
        self.schedule = schedule
        self.isInformational = isInformational
        self.moodTags = moodTags
        self.guideTabID = guideTabID
        self.sourceLabel = sourceLabel
        self.verificationStatus = verificationStatus
        self.localizedTitleMap = localizedTitleMap
        self.localizedTransliterationMap = localizedTransliterationMap
        self.localizedMeaningMap = localizedMeaningMap
        self.localizedPurposeMap = localizedPurposeMap
        self.localizedSourceLabelMap = localizedSourceLabelMap
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RehberEntry, rhs: RehberEntry) -> Bool {
        lhs.id == rhs.id
    }
}

extension RehberEntry {
    private func localizedInlineValue(
        _ map: [String: String]?,
        fallback: String,
        transliterationMode: Bool = false
    ) -> String {
        guard let map, !map.isEmpty else { return fallback }
        let currentCode = RabiaAppLanguage.currentCode()
        let fallbackOrder = transliterationMode ? [currentCode, "en", "tr"] : [currentCode, "en", "ar"]

        for code in fallbackOrder.map(RabiaAppLanguage.normalizedCode(for:)) {
            if let value = map[code]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        return fallback
    }

    var localizedTitle: String {
        if localizedTitleMap != nil {
            return localizedInlineValue(localizedTitleMap, fallback: title)
        }
        return ContentLocalizer.shared.localized("rehber.\(id).title", fallback: title)
    }

    var localizedTransliteration: String {
        localizedInlineValue(localizedTransliterationMap, fallback: transliteration, transliterationMode: true)
    }

    var localizedMeaning: String {
        if localizedMeaningMap != nil {
            return localizedInlineValue(localizedMeaningMap, fallback: meaning)
        }
        return ContentLocalizer.shared.localized("rehber.\(id).meaning", fallback: meaning)
    }

    var localizedPurpose: String {
        if localizedPurposeMap != nil {
            return localizedInlineValue(localizedPurposeMap, fallback: purpose)
        }
        return ContentLocalizer.shared.localized("rehber.\(id).purpose", fallback: purpose)
    }

    var localizedNotes: String? {
        guard let notes else { return nil }
        return ContentLocalizer.shared.localized("rehber.\(id).notes", fallback: notes)
    }

    var localizedSchedule: String? {
        guard let schedule else { return nil }
        return ContentLocalizer.shared.localized("rehber.\(id).schedule", fallback: schedule)
    }

    var localizedRecommendedCountNote: String? {
        guard let recommendedCountNote else { return nil }
        return ContentLocalizer.shared.localized("rehber.\(id).recommended_count_note", fallback: recommendedCountNote)
    }

    var localizedSourceLabel: String? {
        guard let sourceLabel else { return nil }
        return localizedInlineValue(localizedSourceLabelMap, fallback: sourceLabel)
    }

    var isHisnulMuslimEntry: Bool {
        id.hasPrefix("hisnul-muslim-")
    }

    var supportsCounter: Bool {
        !isInformational && recommendedCount > 1
    }

    var displayCategory: RehberCategory {
        category
    }
}
