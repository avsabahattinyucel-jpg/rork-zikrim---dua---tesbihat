import Foundation

nonisolated struct EveryAyahAudioProvider: QuranAudioProvider {
    let kind: AudioProviderKind = .everyAyah

    private enum Constants {
        static let baseURL = "https://everyayah.com/data"
    }

    func supports(_ reciter: Reciter) -> Bool {
        reciter.configuration(for: .everyAyah) != nil
    }

    func resolveAudioURL(for request: AyahAudioRequest) async throws -> URL {
        let directory = try reciterDirectory(for: request.reciter)
        let path = "\(Constants.baseURL)/\(directory)/\(verseFileName(surah: request.surah, ayah: request.ayah))"

        guard let url = URL(string: path) else {
            throw QuranAudioProviderError.invalidURL(path)
        }

        return url
    }

    func preloadAudioURLs(forSurah surah: Int, reciter: Reciter) async throws -> [Int: URL] {
        let directory = try reciterDirectory(for: reciter)
        let totalAyahs = ayahCount(forSurah: surah)

        guard totalAyahs > 0 else { return [:] }

        var urls: [Int: URL] = [:]
        for ayah in 1...totalAyahs {
            let path = "\(Constants.baseURL)/\(directory)/\(verseFileName(surah: surah, ayah: ayah))"
            guard let url = URL(string: path) else {
                throw QuranAudioProviderError.invalidURL(path)
            }
            urls[ayah] = url
        }

        return urls
    }

    private func reciterDirectory(for reciter: Reciter) throws -> String {
        guard let configuration = reciter.configuration(for: .everyAyah) else {
            throw QuranAudioProviderError.unsupportedReciter(provider: kind, reciterID: reciter.id)
        }

        return configuration.basePath ?? configuration.remoteIdentifier
    }
}
