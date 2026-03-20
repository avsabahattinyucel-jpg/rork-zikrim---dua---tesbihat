import Foundation

enum DiyanetContentType: String, Codable, CaseIterable, Sendable {
    case qa
    case faq
    case karar
    case mutalaa

    var displayName: String {
        switch self {
        case .qa:
            return "Soru-Cevap"
        case .faq:
            return "Sık Sorulanlar"
        case .karar:
            return "Karar"
        case .mutalaa:
            return "Mütalaa"
        }
    }

    var systemImage: String {
        switch self {
        case .qa:
            return "questionmark.bubble.fill"
        case .faq:
            return "list.bullet.rectangle.portrait.fill"
        case .karar:
            return "checkmark.seal.fill"
        case .mutalaa:
            return "text.document.fill"
        }
    }
}

struct DiyanetKnowledgeRecord: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let type: DiyanetContentType
    let title: String
    let titleClean: String
    let question: String?
    let questionClean: String?
    let answerHTML: String?
    let answerText: String?
    let answerTextClean: String
    let categoryPath: [String]
    let tags: [String]?
    let sourceName: String
    let sourceURL: String
    let sourceDomain: String
    let decisionKind: String?
    let decisionYear: String?
    let decisionNo: String?
    let subject: String?
    let contentHash: String
    let searchKeywords: [String]
    let discoveredAt: String
    let fetchedAt: String?
    let parsedAt: String
    let isOfficial: Bool
    let language: String
    let lowConfidence: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case titleClean = "title_clean"
        case question
        case questionClean = "question_clean"
        case answerHTML = "answer_html"
        case answerText = "answer_text"
        case answerTextClean = "answer_text_clean"
        case categoryPath = "category_path"
        case tags
        case sourceName = "source_name"
        case sourceURL = "source_url"
        case sourceDomain = "source_domain"
        case decisionKind = "decision_kind"
        case decisionYear = "decision_year"
        case decisionNo = "decision_no"
        case subject
        case contentHash = "content_hash"
        case searchKeywords = "search_keywords"
        case discoveredAt = "discovered_at"
        case fetchedAt = "fetched_at"
        case parsedAt = "parsed_at"
        case isOfficial = "is_official"
        case language
        case lowConfidence = "low_confidence"
    }

    var displayTitle: String {
        titleClean.isEmpty ? title : titleClean
    }

    var officialBodyText: String {
        if let answerText, !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return answerText
        }

        return answerTextClean
    }

    var topCategory: String {
        categoryPath.first ?? "Genel"
    }

    var sourceHostLabel: String {
        sourceDomain
    }

    var previewText: String {
        let rawValue = officialBodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard rawValue.count > 220 else { return rawValue }

        let truncated = String(rawValue.prefix(220))
        if let lastSpaceIndex = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpaceIndex]) + "..."
        }

        return truncated + "..."
    }

    var shareSummaryText: String {
        let rawValue = officialBodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard rawValue.count > 360 else { return rawValue }

        let truncated = String(rawValue.prefix(360))
        if let lastSpaceIndex = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpaceIndex]) + "..."
        }

        return truncated + "..."
    }
}

struct DiyanetKnowledgePayload: Codable, Sendable {
    let generatedAt: String?
    let datasetVersion: String?
    let sourceName: String
    let sourceDomain: String
    let records: [DiyanetKnowledgeRecord]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case datasetVersion = "dataset_version"
        case sourceName = "source_name"
        case sourceDomain = "source_domain"
        case records
    }

    static let empty = DiyanetKnowledgePayload(
        generatedAt: nil,
        datasetVersion: nil,
        sourceName: "Din İşleri Yüksek Kurulu",
        sourceDomain: "kurul.diyanet.gov.tr",
        records: []
    )
}

struct DiyanetKnowledgeSection: Identifiable, Hashable, Sendable {
    let type: DiyanetContentType
    let count: Int

    var id: DiyanetContentType { type }
    var title: String { type.displayName }
    var systemImage: String { type.systemImage }
}

enum DiyanetKnowledgeRoute: Hashable, Sendable {
    case all
    case type(DiyanetContentType)
    case record(String)
}
