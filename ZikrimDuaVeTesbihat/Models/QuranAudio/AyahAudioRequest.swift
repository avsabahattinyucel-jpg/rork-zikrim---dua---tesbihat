import Foundation

nonisolated struct AyahAudioRequest: Hashable, Sendable {
    let surah: Int
    let ayah: Int
    let reciter: Reciter

    var verseKey: String {
        "\(surah):\(ayah)"
    }

    var cacheKey: String {
        "\(reciter.id)_\(paddedSurah(surah))_\(paddedAyah(ayah))"
    }
}
