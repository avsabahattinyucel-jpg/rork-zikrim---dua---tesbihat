import Foundation

struct NotificationContentHistoryStore {
    private struct Payload: Codable {
        var recordsByKey: [String: String]
    }

    private let defaults: UserDefaults
    private let storageKey = "zikrim.notification.content.history.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordedContentID(for key: String) -> String? {
        load().recordsByKey[key]
    }

    func recentContentIDs(category: NotificationContentCategory, excluding key: String, limit: Int = 3) -> [String] {
        let prefix = "\(category.rawValue)|"
        return load().recordsByKey
            .filter { $0.key.hasPrefix(prefix) && $0.key != key }
            .sorted { $0.key > $1.key }
            .prefix(limit)
            .map(\.value)
    }

    func saveContentID(_ contentID: String, for key: String) {
        var payload = load()
        payload.recordsByKey[key] = contentID
        if payload.recordsByKey.count > 120 {
            let trimmed = payload.recordsByKey
                .sorted { $0.key > $1.key }
                .prefix(120)
            payload.recordsByKey = Dictionary(uniqueKeysWithValues: trimmed.map { ($0.key, $0.value) })
        }

        guard let data = try? encoder.encode(payload) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func load() -> Payload {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode(Payload.self, from: data) else {
            return Payload(recordsByKey: [:])
        }
        return decoded
    }
}
