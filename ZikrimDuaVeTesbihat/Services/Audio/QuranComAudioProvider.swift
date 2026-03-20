import Foundation

nonisolated struct QuranComAudioProvider: QuranAudioProvider {
    let kind: AudioProviderKind = .quranCom

    private enum Constants {
        static let apiBaseURL = "https://api.quran.com/api/v4"
        static let mediaBaseURL = "https://verses.quran.com"
    }

    func supports(_ reciter: Reciter) -> Bool {
        reciter.configuration(for: .quranCom) != nil
    }

    func resolveAudioURL(for request: AyahAudioRequest) async throws -> URL {
        let configuration = try reciterConfiguration(for: request.reciter)
        let endpoint = "\(Constants.apiBaseURL)/recitations/\(configuration.remoteIdentifier)/by_ayah/\(request.verseKey)"
        let response = try await loadResponse(endpoint: endpoint)

        guard let rawPath = response.audioFiles.first?.url else {
            throw QuranAudioProviderError.missingAudioURL(provider: kind, verseKey: request.verseKey)
        }

        return try absoluteURL(for: rawPath)
    }

    func preloadAudioURLs(forSurah surah: Int, reciter: Reciter) async throws -> [Int: URL] {
        let configuration = try reciterConfiguration(for: reciter)
        let endpoint = "\(Constants.apiBaseURL)/recitations/\(configuration.remoteIdentifier)/by_chapter/\(surah)"
        let response = try await loadResponse(endpoint: endpoint)

        var urls: [Int: URL] = [:]
        for file in response.audioFiles {
            let ayahNumber = file.verseKey
                .split(separator: ":")
                .last
                .flatMap { Int($0) }

            guard let ayahNumber else { continue }
            urls[ayahNumber] = try absoluteURL(for: file.url)
        }

        return urls
    }

    private func reciterConfiguration(for reciter: Reciter) throws -> ReciterProviderConfiguration {
        guard let configuration = reciter.configuration(for: .quranCom) else {
            throw QuranAudioProviderError.unsupportedReciter(provider: kind, reciterID: reciter.id)
        }

        return configuration
    }

    private func loadResponse(endpoint: String) async throws -> QuranComResponse {
        guard let url = URL(string: endpoint) else {
            throw QuranAudioProviderError.invalidURL(endpoint)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(statusCode) else {
            throw QuranAudioProviderError.requestFailed(provider: kind, statusCode: statusCode)
        }

        do {
            return try JSONDecoder().decode(QuranComResponse.self, from: data)
        } catch {
            throw QuranAudioProviderError.invalidResponse(provider: kind)
        }
    }

    private func absoluteURL(for rawPath: String) throws -> URL {
        if let absolute = URL(string: rawPath), absolute.scheme != nil {
            return absolute
        }

        let normalizedPath = rawPath.hasPrefix("/") ? rawPath : "/\(rawPath)"
        guard let url = URL(string: "\(Constants.mediaBaseURL)\(normalizedPath)") else {
            throw QuranAudioProviderError.invalidURL(rawPath)
        }

        return url
    }
}

nonisolated private struct QuranComResponse: Decodable {
    let audioFiles: [QuranComAudioFile]

    private enum CodingKeys: String, CodingKey {
        case audioFiles = "audio_files"
    }
}

nonisolated private struct QuranComAudioFile: Decodable {
    let verseKey: String
    let url: String

    private enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case url
    }
}
