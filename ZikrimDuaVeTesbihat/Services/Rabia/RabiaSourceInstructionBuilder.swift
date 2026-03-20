import Foundation

struct RabiaSourceInstructionBuilder {
    static func build(
        context: RabiaRetrievedContext,
        includeReligiousSources: Bool,
        quranReferences: [String],
        allowDhikrSuggestion: Bool,
        queryMode: String,
        allowRepentanceLanguage: Bool,
        appLanguageCode: String = RabiaAppLanguage.currentCode()
    ) -> String {
        _ = includeReligiousSources
        _ = allowDhikrSuggestion
        _ = allowRepentanceLanguage

        let preferredLanguageCodes = RabiaLanguagePolicy.preferredReferenceLanguageCodes(for: appLanguageCode)
        let knowledgeText = context.knowledgeCards
            .map { card in
                let localizedTitle = card.localizedTitle(preferredLanguageCodes: preferredLanguageCodes) ?? card.localizedTitle
                let localizedSummary = card.localizedSummary(preferredLanguageCodes: preferredLanguageCodes) ?? card.localizedSummary
                return "\(localizedTitle): \(localizedSummary)"
            }
            .joined(separator: "\n")

        var sections = ["Current mode: \(queryMode)"]

        if let refsBlock = RabiaPromptFactory.makeVerifiedRefsBlock(refs: quranReferences) {
            sections.append(refsBlock)
        }

        if let knowledgeBlock = RabiaPromptFactory.makeVerifiedKnowledgeBlock(text: knowledgeText) {
            sections.append(knowledgeBlock)
        }

        return sections.joined(separator: "\n\n")
    }
}
