import Foundation

nonisolated enum RabiaRuntimeScreen: String, Codable, Sendable {
    case home = "home"
    case prayerTimes = "prayer_times"
    case dhikr = "dhikr"
    case dua = "dua"
    case rabiaChat = "rabia_chat"
    case khutbahSummary = "khutbah_summary"
    case quranListening = "quran_listening"
    case rehber = "rehber"
    case more = "more"
    case unknown = "unknown"
}

nonisolated struct RabiaRuntimeDiyanetContext: Codable, Sendable {
    let title: String
    let excerpt: String
    let source: String
}

nonisolated struct RabiaRuntimeContext: Codable, Sendable {
    let currentAppLanguage: String
    let currentScreen: RabiaRuntimeScreen
    let diyanet: RabiaRuntimeDiyanetContext?
}

@MainActor
final class RabiaRuntimeContextStore {
    static let shared = RabiaRuntimeContextStore()

    private var diyanetContext: RabiaRuntimeDiyanetContext?

    private init() {}

    func snapshot(
        appLanguage: String,
        currentScreen: RabiaRuntimeScreen
    ) -> RabiaRuntimeContext {
        RabiaRuntimeContext(
            currentAppLanguage: RabiaAppLanguage.normalizedCode(for: appLanguage),
            currentScreen: currentScreen,
            diyanet: diyanetContext
        )
    }

    func setDiyanetContext(for record: DiyanetKnowledgeRecord) {
        let excerpt = record.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !excerpt.isEmpty else {
            diyanetContext = nil
            return
        }

        diyanetContext = RabiaRuntimeDiyanetContext(
            title: record.displayTitle,
            excerpt: excerpt,
            source: record.sourceName
        )
    }

    func clearDiyanetContext() {
        diyanetContext = nil
    }
}
