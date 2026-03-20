import Foundation

@MainActor
final class RabiaConversationStore {
    static let shared = RabiaConversationStore()

    private let storageKey = "rabia_conversations_v1"
    private let guestScopeID = "guest"
    private let maxStoredMessages = 12

    private init() {}

    func loadMessages(for userID: String?) -> [ManeviMessage] {
        let key = scopedKey(for: userID)
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([ManeviMessage].self, from: data),
              !messages.isEmpty else {
            return []
        }

        return messages
    }

    func saveMessages(_ messages: [ManeviMessage], for userID: String?) {
        let trimmedMessages = Array(messages.suffix(maxStoredMessages))
        guard let data = try? JSONEncoder().encode(trimmedMessages) else { return }
        UserDefaults.standard.set(data, forKey: scopedKey(for: userID))
    }

    func clearMessages(for userID: String?) {
        UserDefaults.standard.removeObject(forKey: scopedKey(for: userID))
    }
    private func scopedKey(for userID: String?) -> String {
        let normalizedID = userID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let scopeID = (normalizedID?.isEmpty == false) ? normalizedID! : guestScopeID
        return "\(scopeID)_\(storageKey)"
    }
}
