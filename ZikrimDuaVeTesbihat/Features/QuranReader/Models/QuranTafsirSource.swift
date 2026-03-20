import Foundation

nonisolated struct AyahReference: Hashable, Codable, Sendable, Identifiable {
    let surahNumber: Int
    let ayahNumber: Int

    var id: String { "\(surahNumber):\(ayahNumber)" }
}

nonisolated enum QuranTafsirSourceType: String, Codable, CaseIterable, Hashable, Sendable {
    case embedded
    case localDatabase
    case remoteAPI
    case hybrid
}

nonisolated enum QuranTafsirAvailability: String, Codable, Hashable, Sendable {
    case available
    case partial
    case unavailable
}

nonisolated struct QuranTafsirAttribution: Codable, Hashable, Sendable {
    let sourceName: String
    let detailText: String?
    let licenseNote: String?
    let sourceURL: URL?
}

nonisolated struct QuranTafsirSource: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let type: QuranTafsirSourceType
    let isTurkishFirst: Bool
    let availability: QuranTafsirAvailability
    let supportedLanguages: [AppLanguage]
    let attribution: QuranTafsirAttribution
    let isPremiumCandidate: Bool

    var localizationKey: String {
        "quran_reader_tafsir_source_\(id)"
    }

    var defaultTitle: String {
        switch id {
        case Self.zikrimShortExplanation.id:
            return "Short Reflection"
        case Self.remoteMultiLanguageTafsir.id:
            return "Multi-Language Tafsir"
        default:
            return attribution.sourceName
        }
    }

    static let zikrimShortExplanation = QuranTafsirSource(
        id: "zikrim_short_explanation",
        type: .embedded,
        isTurkishFirst: false,
        availability: .available,
        supportedLanguages: AppLanguage.allCases,
        attribution: QuranTafsirAttribution(
            sourceName: "Short Reflection",
            detailText: "A concise reflection layer prepared from the tafsir content bundled with the app.",
            licenseNote: "This brief explanation is shown as an in-app reading aid.",
            sourceURL: nil
        ),
        isPremiumCandidate: false
    )

    static let remoteMultiLanguageTafsir = QuranTafsirSource(
        id: "remote_multi_language_tafsir",
        type: .localDatabase,
        isTurkishFirst: true,
        availability: .partial,
        supportedLanguages: AppLanguage.allCases,
        attribution: QuranTafsirAttribution(
            sourceName: "Multi-Language Tafsir",
            detailText: "Detailed tafsir texts are presented from the local multi-language resources included in the app.",
            licenseNote: "The text shown here is read from the app's bundled source files.",
            sourceURL: nil
        ),
        isPremiumCandidate: false
    )

    static let allCases: [QuranTafsirSource] = [
        .zikrimShortExplanation,
        .remoteMultiLanguageTafsir
    ]
}

nonisolated struct QuranShortExplanationPayload: Codable, Hashable, Sendable {
    let text: String
    let source: QuranTafsirSource
    let language: AppLanguage
    let attribution: QuranTafsirAttribution
    let didUseFallbackLanguage: Bool
}

nonisolated struct QuranTafsirPayload: Codable, Hashable, Sendable {
    let title: String
    let body: String
    let source: QuranTafsirSource
    let language: AppLanguage
    let attribution: QuranTafsirAttribution
    let didUseFallbackLanguage: Bool
}

protocol QuranTafsirProviding: Sendable {
    func tafsir(for reference: AyahReference, language: AppLanguage, source: QuranTafsirSource) async throws -> QuranTafsirPayload?
    func shortExplanation(for reference: AyahReference, language: AppLanguage, source: QuranTafsirSource) async throws -> QuranShortExplanationPayload?
}
