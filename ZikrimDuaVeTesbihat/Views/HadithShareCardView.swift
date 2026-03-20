import SwiftUI

struct HadithShareCardView: View {
    let content: HadithShareCardContent
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let shareStyle: ShareCardVisualStyle

    var body: some View {
        AdaptiveShareCard(
            content: ShareCardContent(
                kind: .hadith,
                eyebrow: String(localized: "Hadis", defaultValue: "Hadis"),
                category: nil,
                title: normalizedTitle,
                shortBody: content.bodyText,
                fullBody: content.fullBodyText,
                shareSummary: nil,
                sourceTitle: nil,
                sourceText: nil,
                sourceDetail: nil,
                metadata: metadataItems,
                explanation: content.explanationText,
                supportingBody: content.arabicText,
                ctaText: nil,
                brandingTitle: content.brandingTitle,
                brandingSubtitle: content.brandingSubtitle
            ),
            theme: theme,
            metrics: metrics,
            shareStyle: shareStyle
        )
    }

    private var normalizedTitle: String? {
        let value = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }

        let normalizedTitle = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let normalizedBody = content.bodyText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        return normalizedTitle == normalizedBody ? nil : value
    }

    private var metadataItems: [ShareCardMetadataItem] {
        var items: [ShareCardMetadataItem] = []

        if let narratorText = content.narratorText?.trimmingCharacters(in: .whitespacesAndNewlines), !narratorText.isEmpty {
            items.append(ShareCardMetadataItem(label: "Rivayet", value: narratorText, systemImage: "books.vertical.fill"))
        } else if let referenceText = content.referenceText?.trimmingCharacters(in: .whitespacesAndNewlines), !referenceText.isEmpty {
            items.append(ShareCardMetadataItem(label: "Kaynak", value: referenceText, systemImage: "books.vertical.fill"))
        }

        if let gradeText = content.gradeText?.trimmingCharacters(in: .whitespacesAndNewlines), !gradeText.isEmpty {
            items.append(ShareCardMetadataItem(label: "Derece", value: gradeText, systemImage: "checkmark.seal.fill"))
        }

        return items
    }
}
