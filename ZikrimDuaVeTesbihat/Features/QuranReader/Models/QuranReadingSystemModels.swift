import Foundation

nonisolated struct QuranReadingSession: Codable, Equatable, Sendable {
    var surahId: Int
    var ayahId: Int
    var isTranslationVisible: Bool
    var selectedTafsirSourceID: String
    var readingAppearancePreset: QuranReaderAppearance
    var arabicFontScale: Double
    var translationFontScale: Double
    var lineSpacing: Double
    var lastReciterID: String?
    var lastOpenedAt: Date
}

nonisolated struct QuranPlaybackSession: Codable, Equatable, Sendable {
    var surahId: Int
    var ayahId: Int
    var reciterId: String
    var progressInAyah: Double
    var isPlaying: Bool
    var autoAdvance: Bool
    var repeatMode: QuranPlaybackRepeatMode
    var sleepTimerState: QuranSleepTimerOption
    var backgroundPlaybackEnabled: Bool
    var startedAt: Date?
    var updatedAt: Date
}

nonisolated enum QuranPlaybackRepeatMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case off
    case repeatAyah

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .off:
            return AppLanguage.current == .tr ? "Tekrar Kapalı" : "Repeat Off"
        case .repeatAyah:
            return AppLanguage.current == .tr ? "Ayet Tekrarı" : "Repeat Ayah"
        }
    }
}

nonisolated struct QuranReadingRoute: Hashable, Identifiable, Sendable {
    let surahId: Int
    let ayahNumber: Int?
    let shouldResumePlayback: Bool
    let shouldOpenListeningControls: Bool
    let preferredReciterID: String?
    let preferredAppearance: QuranReaderAppearance?

    init(
        surahId: Int,
        ayahNumber: Int?,
        shouldResumePlayback: Bool = false,
        shouldOpenListeningControls: Bool = false,
        preferredReciterID: String? = nil,
        preferredAppearance: QuranReaderAppearance? = nil
    ) {
        self.surahId = surahId
        self.ayahNumber = ayahNumber
        self.shouldResumePlayback = shouldResumePlayback
        self.shouldOpenListeningControls = shouldOpenListeningControls
        self.preferredReciterID = preferredReciterID
        self.preferredAppearance = preferredAppearance
    }

    var id: String {
        "\(surahId):\(ayahNumber ?? 0):\(shouldResumePlayback):\(shouldOpenListeningControls):\(preferredReciterID ?? ""):\(preferredAppearance?.rawValue ?? "")"
    }
}

nonisolated struct QuranAudioControlRoute: Hashable, Identifiable, Sendable {
    let surahId: Int
    let ayahNumber: Int?

    var id: String {
        "\(surahId):\(ayahNumber ?? 0)"
    }
}

nonisolated struct QuranRecentReference: Codable, Equatable, Identifiable, Sendable {
    let surahId: Int
    let ayahNumber: Int?
    let lastOpenedAt: Date

    var id: String {
        "\(surahId):\(ayahNumber ?? 0)"
    }
}
