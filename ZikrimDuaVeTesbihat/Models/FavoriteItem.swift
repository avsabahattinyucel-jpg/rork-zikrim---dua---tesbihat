import Foundation

nonisolated enum FavoriteItemType: String, Codable, CaseIterable, Sendable {
    case quran = "Kur'an"
    case zikir = "Zikir"
    case dua = "Dua"

    var title: String { rawValue }
}

nonisolated struct FavoriteItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let type: FavoriteItemType
    let title: String
    let subtitle: String
    let detail: String
    let createdAt: Date

    init(id: String, type: FavoriteItemType, title: String, subtitle: String, detail: String, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.createdAt = createdAt
    }
}