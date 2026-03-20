import Foundation

nonisolated struct ZikirItem: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let category: String
    let arabicText: String
    let turkishPronunciation: String
    let turkishMeaning: String
    let recommendedCount: Int
    let source: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ZikirItem, rhs: ZikirItem) -> Bool {
        lhs.id == rhs.id
    }
}

nonisolated struct ZikirCategory: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let items: [ZikirItem]
    let isPremium: Bool
}

nonisolated struct ZikirDataContainer: Codable, Sendable {
    let categories: [ZikirCategory]
}

extension ZikirCategory {
    var localizedName: String {
        ContentLocalizer.shared.localized("zikir.category.\(id).name", fallback: name)
    }
}

extension ZikirItem {
    var localizedMeaning: String {
        ContentLocalizer.shared.localized("zikir.item.\(id).meaning", fallback: turkishMeaning)
    }

    var localizedPronunciation: String {
        ContentLocalizer.shared.localized("zikir.item.\(id).pronunciation", fallback: turkishPronunciation)
    }
}
