import Foundation

nonisolated enum AudioPlaybackState: String, Equatable, Sendable {
    case idle
    case loading
    case buffering
    case playing
    case paused
    case stopped
    case failed

    var isActive: Bool {
        switch self {
        case .loading, .buffering, .playing, .paused:
            return true
        case .idle, .stopped, .failed:
            return false
        }
    }

    var isActivelyPlaying: Bool {
        self == .playing || self == .buffering
    }

    var showsLoadingIndicator: Bool {
        self == .loading || self == .buffering
    }
}

nonisolated enum AudioQueueMode: String, Sendable {
    case singleAyah
    case autoAdvance
}

nonisolated enum AudioProviderKind: String, Codable, CaseIterable, Hashable, Sendable {
    case quranCom
    case everyAyah
    case bundledAyahJSON
}

nonisolated struct PlayerErrorState: Identifiable, Equatable, Sendable {
    nonisolated enum Code: String, Sendable {
        case audioUnavailable
        case providerUnavailable
        case sessionFailure
        case interrupted
        case routeChanged
        case playbackFailed
        case unknown
    }

    let code: Code
    let title: String
    let message: String
    let developerDescription: String?

    var id: String {
        "\(code.rawValue):\(message)"
    }
}
