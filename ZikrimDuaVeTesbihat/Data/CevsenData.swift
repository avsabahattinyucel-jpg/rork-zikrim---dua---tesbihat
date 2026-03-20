import Foundation

enum CevsenData {
    static let entries: [RehberEntry] = loadBundleEntries()

    private static func loadBundleEntries() -> [RehberEntry] {
        guard
            let url = Bundle.main.url(forResource: "cevsen_bundle", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let bundle = try? JSONDecoder().decode(CevsenBundle.self, from: data)
        else {
            return []
        }

        let sectionEntries = bundle.sections.map { section in
            toEntry(section: section)
        }

        let supplementalEntries = bundle.supplement.map { [toSupplementEntry($0)] } ?? []
        return sectionEntries + supplementalEntries
    }

    private static func toEntry(section: CevsenBundleSection) -> RehberEntry {
        RehberEntry(
            id: section.id,
            title: section.title,
            arabicText: section.arabic,
            transliteration: pageReference(
                arabicRange: section.arabicPageRange,
                turkishRange: section.turkishPageRange
            ),
            meaning: section.meaningTr,
            purpose: section.previewTr,
            recommendedCount: 1,
            category: .cevsen,
            notes: notesText(
                arabicRange: section.arabicPageRange,
                turkishRange: section.turkishPageRange,
                needsReview: section.needsReview
            ),
            isInformational: true,
            guideTabID: RehberCategory.cevsen.rawValue,
            sourceLabel: "Cevşen-i Kebir",
            verificationStatus: section.needsReview ? .needsReview : .verified,
            localizedTitleMap: localizedTitleMap(for: section.sectionNumber),
            localizedTransliterationMap: localizedSectionInfoMap(
                arabicRange: section.arabicPageRange,
                turkishRange: section.turkishPageRange
            ),
            localizedPurposeMap: localizedPreviewMap(
                sectionNumber: section.sectionNumber,
                turkishPreview: section.previewTr
            ),
            localizedSourceLabelMap: localizedSourceMap
        )
    }

    private static func toSupplementEntry(_ supplement: CevsenSupplement) -> RehberEntry {
        RehberEntry(
            id: supplement.id,
            title: supplement.title,
            arabicText: supplement.arabic,
            transliteration: supplementInfoFallback,
            meaning: supplement.meaningTr,
            purpose: supplement.previewTr,
            recommendedCount: 1,
            category: .cevsen,
            notes: supplementNotes(needsReview: supplement.needsReview),
            isInformational: true,
            guideTabID: RehberCategory.cevsen.rawValue,
            sourceLabel: "Cevşen-i Kebir",
            verificationStatus: supplement.needsReview ? .needsReview : .verified,
            localizedTitleMap: supplementTitleMap,
            localizedTransliterationMap: supplementInfoMap,
            localizedPurposeMap: supplementPreviewMap(turkishPreview: supplement.previewTr),
            localizedSourceLabelMap: localizedSourceMap
        )
    }

    private static func localizedTitleMap(for sectionNumber: Int) -> [String: String] {
        [
            "tr": "Cevşen \(sectionNumber). Bab",
            "en": "Jawshan Section \(sectionNumber)",
            "ar": "الجوشن الباب \(sectionNumber)"
        ]
    }

    private static func localizedSectionInfoMap(
        arabicRange: [Int],
        turkishRange: [Int]
    ) -> [String: String] {
        let arabicPages = formattedRange(arabicRange)
        let turkishPages = formattedRange(turkishRange)

        return [
            "tr": "Tam metin • Arapça s. \(arabicPages) • Türkçe s. \(turkishPages)",
            "en": "Full text • Arabic p. \(arabicPages) • Turkish p. \(turkishPages)",
            "ar": "النص الكامل • العربية ص \(arabicPages) • التركية ص \(turkishPages)"
        ]
    }

    private static func localizedPreviewMap(
        sectionNumber: Int,
        turkishPreview: String
    ) -> [String: String] {
        [
            "tr": turkishPreview,
            "en": "Full Jawshan Section \(sectionNumber) with Arabic text and Turkish meaning.",
            "ar": "قسم الجوشن \(sectionNumber) كامل بالنص العربي والمعنى التركي."
        ]
    }

    private static var supplementTitleMap: [String: String] {
        [
            "tr": "Cevşen Son Dua",
            "en": "Jawshan Closing Prayer",
            "ar": "دعاء ختام الجوشن"
        ]
    }

    private static func supplementPreviewMap(turkishPreview: String) -> [String: String] {
        [
            "tr": turkishPreview,
            "en": "Closing Jawshan supplication with Arabic text and Turkish meaning.",
            "ar": "دعاء ختام الجوشن مع النص العربي والمعنى التركي."
        ]
    }

    private static var supplementInfoMap: [String: String] {
        [
            "tr": supplementInfoFallback,
            "en": "Closing supplication from the bundled PDF",
            "ar": "دعاء الختام من ملف PDF المرفق"
        ]
    }

    private static var supplementInfoFallback: String {
        "Son dua • PDF ek metni"
    }

    private static var localizedSourceMap: [String: String] {
        [
            "tr": "Cevşen-i Kebir",
            "en": "Jawshan al-Kabir",
            "ar": "الجوشن الكبير"
        ]
    }

    private static func pageReference(arabicRange: [Int], turkishRange: [Int]) -> String {
        "Tam metin • Arapça s. \(formattedRange(arabicRange)) • Türkçe s. \(formattedRange(turkishRange))"
    }

    private static func notesText(
        arabicRange: [Int],
        turkishRange: [Int],
        needsReview: Bool
    ) -> String {
        let base = "PDF sayfaları: Arapça \(formattedRange(arabicRange)), Türkçe \(formattedRange(turkishRange))."
        guard needsReview else { return base }
        return "\(base) Bu bölüm otomatik ayrıştırmada inceleme işaretine düştü."
    }

    private static func supplementNotes(needsReview: Bool) -> String {
        guard needsReview else {
            return "Bu metin PDF sonundaki ek dua ve münâcât bölümünden aktarıldı."
        }
        return "Bu metin PDF sonundaki ek dua ve münâcât bölümünden aktarıldı. Otomatik ayrıştırma sırasında inceleme işaretine düştü."
    }

    private static func formattedRange(_ values: [Int]) -> String {
        guard let first = values.first else { return "-" }
        guard let last = values.last, last != first else { return "\(first)" }
        return "\(first)-\(last)"
    }
}

private struct CevsenBundle: Decodable {
    let sourcePdf: String
    let parserSummary: CevsenParserSummary
    let sections: [CevsenBundleSection]
    let supplement: CevsenSupplement?
}

private struct CevsenParserSummary: Decodable {
    let totalSectionsParsed: Int
}

private struct CevsenBundleSection: Decodable {
    let id: String
    let sectionNumber: Int
    let title: String
    let arabic: String
    let meaningTr: String
    let closingArabic: String
    let closingMeaningTr: String
    let previewTr: String
    let arabicPageRange: [Int]
    let turkishPageRange: [Int]
    let needsReview: Bool
}

private struct CevsenSupplement: Decodable {
    let id: String
    let title: String
    let arabic: String
    let meaningTr: String
    let previewTr: String
    let needsReview: Bool
}
