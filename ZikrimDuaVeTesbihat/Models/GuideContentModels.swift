import Foundation

nonisolated enum GuideVerificationStatus: String, Codable, Sendable {
    case verified
    case needsReview = "needs_review"
    case unknown

    var badgeText: String {
        switch AppLanguage(code: RabiaAppLanguage.currentCode()) {
        case .tr:
            switch self {
            case .verified: return "Doğrulandı"
            case .needsReview: return "İnceleme Gerekli"
            case .unknown: return "Belirsiz"
            }
        case .ar:
            switch self {
            case .verified: return "موثّق"
            case .needsReview: return "بحاجة إلى مراجعة"
            case .unknown: return "غير واضح"
            }
        default:
            switch self {
            case .verified: return "Verified"
            case .needsReview: return "Needs Review"
            case .unknown: return "Unknown"
            }
        }
    }
}

nonisolated struct GuideLocalizedText: Codable, Sendable {
    let tr: String
    let ar: String
    let en: String
    let fr: String
    let de: String
    let id: String
    let ms: String
    let fa: String
    let ru: String
    let es: String
    let ur: String

    var asDictionary: [String: String] {
        [
            "tr": tr,
            "ar": ar,
            "en": en,
            "fr": fr,
            "de": de,
            "id": id,
            "ms": ms,
            "fa": fa,
            "ru": ru,
            "es": es,
            "ur": ur
        ]
    }
}

nonisolated struct GuideCategoryTitleText: Codable, Sendable {
    let ar: String
    let tr: String
    let en: String
}

nonisolated struct GuideTransliterationText: Codable, Sendable {
    let tr: String?
    let ar: String?
    let en: String?
    let fr: String?
    let de: String?
    let id: String?
    let ms: String?
    let fa: String?
    let ru: String?
    let es: String?
    let ur: String?

    var asDictionary: [String: String] {
        [
            "tr": tr,
            "ar": ar,
            "en": en,
            "fr": fr,
            "de": de,
            "id": id,
            "ms": ms,
            "fa": fa,
            "ru": ru,
            "es": es,
            "ur": ur
        ]
        .compactMapValues { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

nonisolated struct GuideUsageContext: Codable, Sendable {
    let tags: [String]
    let derivedTags: [String]?
    let emotionalStates: [String]?
    let guideTabHints: [String]?
}

nonisolated struct GuideSourceReference: Codable, Sendable {
    let primaryBook: String
    let hadithReference: String?
    let narratorOptional: String?
    let sourceType: String
}

nonisolated struct GuideVerificationBlock: Codable, Sendable {
    let status: GuideVerificationStatus
    let notes: String
    let lastReviewedAt: String?
}

nonisolated struct GuideMetadata: Codable, Sendable {
    let orderIndex: Int
    let popularityWeight: Int
    let isFeatured: Bool
    let recommendedForPremium: Bool
    let reflectionAvailable: Bool?
    let audioAvailable: Bool?
    let aiReflectionAvailable: Bool?
    let createdAt: String
    let updatedAt: String
}

nonisolated struct GuideHints: Codable, Sendable {
    let primaryTabId: String?
    let suggestedTabIds: [String]?
}

nonisolated struct GuideBundleDua: Codable, Sendable {
    let id: String
    let collection: String
    let categoryId: String
    let categoryTitle: GuideCategoryTitleText
    let title: GuideLocalizedText
    let arabicText: String
    let transliteration: GuideTransliterationText
    let meaning: GuideLocalizedText
    let shortExplanation: GuideLocalizedText
    let usageContext: GuideUsageContext
    let source: GuideSourceReference
    let verification: GuideVerificationBlock
    let metadata: GuideMetadata
    let guide: GuideHints?
}

nonisolated struct GuideTabDefinition: Codable, Identifiable, Sendable {
    let id: String
    let title: GuideLocalizedText
    let shortDescription: GuideLocalizedText
    let iconName: String
    let sortOrder: Int
    let relatedDuaCategoryIds: [String]
    let featuredDuaId: String?
    let legacyGuideTabId: String?
}

nonisolated struct GuideCategoryMapping: Codable, Identifiable, Sendable {
    let id: String
    let duaCategoryId: String
    let guideTabId: String
    let strategy: String
    let reason: String
}

nonisolated struct GuideSectionViewModel: Identifiable, Sendable {
    let id: String
    let title: String
    let shortDescription: String
    let iconName: String
    let sortOrder: Int
    let featuredDuaId: String?
}

nonisolated struct HisnulMuslimGuideBundle: Codable, Sendable {
    let version: Int
    let exportedAt: String
    let guideTabs: [GuideTabDefinition]
    let categoryMappings: [GuideCategoryMapping]
    let duas: [GuideBundleDua]
}
