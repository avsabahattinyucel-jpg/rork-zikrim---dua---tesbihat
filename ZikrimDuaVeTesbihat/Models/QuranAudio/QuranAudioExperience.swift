import Foundation

nonisolated enum AudioAccessLevel: String, Codable, Sendable {
    case free
    case premium

    var requiresPremium: Bool {
        self == .premium
    }
}

nonisolated enum QuranAudioPremiumFeature: String, Sendable {
    case fullQuranRecitation
    case reciterSelection
    case autoAdvance
    case backgroundListening
    case sleepTimer
    case offlineListening
}

nonisolated struct QuranAudioQueueItem: Identifiable, Hashable, Codable, Sendable {
    let surahID: Int
    let surahName: String
    let ayahNumber: Int
    let totalAyahs: Int
    let accessLevel: AudioAccessLevel

    var id: String {
        "\(surahID):\(ayahNumber)"
    }
}

nonisolated struct QuranAudioResumeState: Codable, Equatable, Sendable {
    let surahID: Int
    let surahName: String
    let ayahNumber: Int
    let reciterID: String
    let progress: Double
    let continuesPlayback: Bool

    init(
        surahID: Int,
        surahName: String,
        ayahNumber: Int,
        reciterID: String,
        progress: Double,
        continuesPlayback: Bool = false
    ) {
        self.surahID = surahID
        self.surahName = surahName
        self.ayahNumber = ayahNumber
        self.reciterID = reciterID
        self.progress = progress
        self.continuesPlayback = continuesPlayback
    }

    private enum CodingKeys: String, CodingKey {
        case surahID
        case surahName
        case ayahNumber
        case reciterID
        case progress
        case continuesPlayback
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        surahID = try container.decode(Int.self, forKey: .surahID)
        surahName = try container.decode(String.self, forKey: .surahName)
        ayahNumber = try container.decode(Int.self, forKey: .ayahNumber)
        reciterID = try container.decode(String.self, forKey: .reciterID)
        progress = try container.decode(Double.self, forKey: .progress)
        continuesPlayback = try container.decodeIfPresent(Bool.self, forKey: .continuesPlayback) ?? false
    }
}

nonisolated struct QuranAudioPremiumPrompt: Identifiable, Equatable, Sendable {
    let feature: QuranAudioPremiumFeature
    let title: String
    let message: String

    var id: String {
        feature.rawValue
    }
}

nonisolated enum QuranSleepTimerOption: String, CaseIterable, Codable, Identifiable, Sendable {
    case off
    case tenMinutes
    case twentyMinutes
    case thirtyMinutes
    case fortyFiveMinutes

    var id: String {
        rawValue
    }

    var duration: Duration? {
        switch self {
        case .off:
            return nil
        case .tenMinutes:
            return .seconds(600)
        case .twentyMinutes:
            return .seconds(1_200)
        case .thirtyMinutes:
            return .seconds(1_800)
        case .fortyFiveMinutes:
            return .seconds(2_700)
        }
    }

    var localizedTitle: String {
        switch self {
        case .off:
            return L10n.string(.quranAudioSleepTimerOff)
        case .tenMinutes:
            return L10n.string(.quranAudioSleepTimer10Minutes)
        case .twentyMinutes:
            return L10n.string(.quranAudioSleepTimer20Minutes)
        case .thirtyMinutes:
            return L10n.string(.quranAudioSleepTimer30Minutes)
        case .fortyFiveMinutes:
            return L10n.string(.quranAudioSleepTimer45Minutes)
        }
    }
}

nonisolated enum QuranAudioAccessPolicy {
    static let freeSurahIDs: Set<Int> = Set(
        [1] + Array(93...114)
    )

    static func accessLevel(for surahID: Int) -> AudioAccessLevel {
        freeSurahIDs.contains(surahID) ? .free : .premium
    }
}

extension QuranSurah {
    var audioAccessLevel: AudioAccessLevel {
        QuranAudioAccessPolicy.accessLevel(for: id)
    }
}

extension ReciterRegistry {
    static var defaultFreeReciter: Reciter {
        all.first(where: { !$0.isPremiumLocked }) ?? defaultReciter
    }
}
