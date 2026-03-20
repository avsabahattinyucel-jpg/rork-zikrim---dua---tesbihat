import Foundation

nonisolated enum QuranAudioProviderError: LocalizedError, Sendable {
    case unsupportedReciter(provider: AudioProviderKind, reciterID: String)
    case invalidURL(String)
    case invalidResponse(provider: AudioProviderKind)
    case missingAudioURL(provider: AudioProviderKind, verseKey: String)
    case requestFailed(provider: AudioProviderKind, statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedReciter(let provider, let reciterID):
            return "Unsupported reciter \(reciterID) for provider \(provider.rawValue)"
        case .invalidURL(let value):
            return "Invalid URL: \(value)"
        case .invalidResponse(let provider):
            return "Invalid response from \(provider.rawValue)"
        case .missingAudioURL(let provider, let verseKey):
            return "Missing audio URL for \(verseKey) from \(provider.rawValue)"
        case .requestFailed(let provider, let statusCode):
            return "Request failed for \(provider.rawValue) with status \(statusCode)"
        }
    }
}

nonisolated protocol QuranAudioProvider: Sendable {
    var kind: AudioProviderKind { get }

    func supports(_ reciter: Reciter) -> Bool
    func resolveAudioURL(for request: AyahAudioRequest) async throws -> URL
    func preloadAudioURLs(forSurah surah: Int, reciter: Reciter) async throws -> [Int: URL]
}
