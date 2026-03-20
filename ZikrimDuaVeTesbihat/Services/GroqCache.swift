import Foundation

@MainActor
final class GroqCache {

    static let shared = GroqCache()

    private var cache: [String: CacheEntry] = [:]
    private let maxAge: TimeInterval = 3600

    private struct CacheEntry {
        let response: String
        let timestamp: Date
    }

    func get(prompt: String) -> String? {
        let key = cacheKey(for: prompt)
        guard let entry = cache[key] else { return nil }
        if Date().timeIntervalSince(entry.timestamp) > maxAge {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.response
    }

    func set(prompt: String, response: String) {
        let key = cacheKey(for: prompt)
        cache[key] = CacheEntry(response: response, timestamp: Date())
    }

    func clearAll() {
        cache.removeAll()
    }

    private func cacheKey(for prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(500))
    }
}
