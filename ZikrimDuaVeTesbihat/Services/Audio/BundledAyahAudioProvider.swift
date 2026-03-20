import Foundation

nonisolated struct BundledAyahAudioProvider: QuranAudioProvider {
    let kind: AudioProviderKind = .bundledAyahJSON

    func supports(_ reciter: Reciter) -> Bool {
        reciter.configuration(for: kind) != nil
    }

    func resolveAudioURL(for request: AyahAudioRequest) async throws -> URL {
        let resourceName = try resourceName(for: request.reciter)
        guard let url = await BundledAyahAudioCatalog.shared.url(forVerseKey: request.verseKey, resourceName: resourceName) else {
            throw QuranAudioProviderError.missingAudioURL(provider: kind, verseKey: request.verseKey)
        }

        return url
    }

    func preloadAudioURLs(forSurah surah: Int, reciter: Reciter) async throws -> [Int: URL] {
        let resourceName = try resourceName(for: reciter)
        let urls = await BundledAyahAudioCatalog.shared.urls(forSurah: surah, resourceName: resourceName)
        if urls.isEmpty {
            throw QuranAudioProviderError.missingAudioURL(provider: kind, verseKey: "\(surah):1")
        }

        return urls
    }

    private func resourceName(for reciter: Reciter) throws -> String {
        guard let configuration = reciter.configuration(for: kind) else {
            throw QuranAudioProviderError.unsupportedReciter(provider: kind, reciterID: reciter.id)
        }

        return configuration.remoteIdentifier
    }
}

actor BundledAyahAudioCatalog {
    static let shared = BundledAyahAudioCatalog()

    private var cachedMaps: [String: [String: QuranAyahTimingPayload]] = [:]

    func url(forVerseKey verseKey: String, resourceName: String) -> URL? {
        audioMap(for: resourceName)[verseKey]?.audioURL
    }

    func timingPayload(forVerseKey verseKey: String, resourceName: String) -> QuranAyahTimingPayload? {
        audioMap(for: resourceName)[verseKey]
    }

    func urls(forSurah surah: Int, resourceName: String) -> [Int: URL] {
        let prefix = "\(surah):"
        let map = audioMap(for: resourceName)
        var urls: [Int: URL] = [:]

        for (verseKey, payload) in map where verseKey.hasPrefix(prefix) {
            guard let ayah = Self.parseAyahNumber(from: verseKey) else { continue }
            urls[ayah] = payload.audioURL
        }

        return urls
    }

    private func audioMap(for resourceName: String) -> [String: QuranAyahTimingPayload] {
        if let cached = cachedMaps[resourceName] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            cachedMaps[resourceName] = [:]
            return [:]
        }

        var map: [String: QuranAyahTimingPayload] = [:]
        map.reserveCapacity(root.count)

        for (verseKey, rawValue) in root {
            guard let object = rawValue as? [String: Any],
                  let rawURL = object["audio_url"] as? String,
                  let audioURL = URL(string: rawURL) else {
                continue
            }

            let rawSegments = object["segments"] as? [[Int]] ?? []
            let segments = rawSegments.compactMap(QuranWordTimingSegment.init(rawValues:))
            map[verseKey] = QuranAyahTimingPayload(audioURL: audioURL, segments: segments)
        }

        cachedMaps[resourceName] = map
        return map
    }

    private static func parseAyahNumber(from verseKey: String) -> Int? {
        verseKey.split(separator: ":").last.flatMap { Int($0) }
    }
}
