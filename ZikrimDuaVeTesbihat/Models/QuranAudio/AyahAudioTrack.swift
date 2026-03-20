import Foundation

nonisolated struct AyahAudioTrack: Equatable, Sendable {
    let request: AyahAudioRequest
    let providerKind: AudioProviderKind
    let remoteURL: URL?
    let localFileURL: URL

    var playbackURL: URL {
        // Playback should always prefer the cached local file so verse-to-verse
        // transitions stay reliable even when the app continues in the background.
        localFileURL
    }
}
