import Foundation

enum LegalDocumentType: String, CaseIterable, Identifiable, Hashable {
    case kvkk
    case termsOfUse
    case privacyPolicy

    var id: String { rawValue }

    var titleKey: L10n.Key {
        switch self {
        case .kvkk:
            return .kvkkAydinlatmaMetni
        case .termsOfUse:
            return .kullanimSartlari
        case .privacyPolicy:
            return .gizlilikPolitikasi
        }
    }

    var iconName: String {
        switch self {
        case .kvkk:
            return "hand.raised.square"
        case .termsOfUse:
            return "doc.text"
        case .privacyPolicy:
            return "lock.shield"
        }
    }
}

struct LegalSection: Identifiable, Hashable {
    let id: String
    let heading: String
    let paragraphs: [String]
}

struct LegalDocument: Identifiable, Hashable {
    let type: LegalDocumentType
    let title: String
    let version: String?
    let lastUpdated: Date
    let sections: [LegalSection]

    var id: LegalDocumentType { type }
}
