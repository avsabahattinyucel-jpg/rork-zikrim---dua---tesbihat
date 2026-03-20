import Foundation

nonisolated struct FavoriteGuide: Codable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let date: Date

    init(id: UUID = UUID(), text: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }
}

@Observable
@MainActor
final class FavoriteGuideService {
    static let shared = FavoriteGuideService()

    private let key = "favorite_guides"
    var favorites: [FavoriteGuide] = []

    private init() {
        load()
    }

    func addFavorite(text: String) {
        let guide = FavoriteGuide(text: text)
        favorites.insert(guide, at: 0)
        save()
    }

    func removeFavorite(id: UUID) {
        favorites.removeAll { $0.id == id }
        save()
    }

    func isFavorited(text: String) -> Bool {
        favorites.contains { $0.text == text }
    }

    func toggleFavorite(text: String) {
        if let existing = favorites.first(where: { $0.text == text }) {
            removeFavorite(id: existing.id)
        } else {
            addFavorite(text: text)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FavoriteGuide].self, from: data) else { return }
        favorites = decoded
    }
}
