import Foundation

enum AIBackendConfiguration {
    private static let fallbackBaseURL = "https://zikrim-backend.vercel.app"

    static var baseURL: URL {
        let configured = Config.EXPO_PUBLIC_RORK_API_BASE_URL
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !configured.isEmpty, let url = URL(string: configured) {
            return url
        }

        return URL(string: fallbackBaseURL)!
    }

    static func endpoint(path: String) -> URL {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appendingPathComponent(normalizedPath)
    }
}
