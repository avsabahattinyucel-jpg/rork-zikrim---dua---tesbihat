import Foundation
import Testing
@testable import ZikrimDuaVeTesbihat

struct HadithShortFeedSelectionTests {

    @Test func prefersShortMeaningfulTitleForShortFeed() async throws {
        let hadith = Hadith(
            id: 1,
            language: "en",
            title: "Actions are judged by intentions",
            fullHadith: "This is a longer authentic hadith body that should stay untouched for the detail experience even when the card uses the title.",
            grade: "Sahih",
            attribution: "Bukhari",
            explanation: nil,
            hints: [],
            hadeethArabic: nil
        )

        #expect(hadith.fullHadith == "This is a longer authentic hadith body that should stay untouched for the detail experience even when the card uses the title.")
        #expect(hadith.shortCardText == "Actions are judged by intentions")
        #expect(hadith.isShortFeedEligible == true)
    }

    @Test func fallsBackToExactFullHadithWhenBodyIsConcise() async throws {
        let hadith = Hadith(
            id: 2,
            language: "tr",
            title: "Hadith",
            fullHadith: "Kolaylaştırın, zorlaştırmayın; müjdeleyin, nefret ettirmeyin.",
            grade: nil,
            attribution: nil,
            explanation: nil,
            hints: [],
            hadeethArabic: nil
        )

        #expect(hadith.shortCardText == "Kolaylaştırın, zorlaştırmayın; müjdeleyin, nefret ettirmeyin.")
        #expect(hadith.isShortFeedEligible == true)
    }

    @Test func rejectsLongItemsInsteadOfFabricatingPreviewText() async throws {
        let hadith = Hadith(
            id: 3,
            language: "en",
            title: "A long descriptive title that exceeds the short feed limit because it keeps going far beyond eighty characters total",
            fullHadith: """
            This hadith body is intentionally longer than one hundred and forty characters so the short feed must not invent a shortened quote or show a broken excerpt.
            """,
            grade: nil,
            attribution: nil,
            explanation: nil,
            hints: [],
            hadeethArabic: nil
        )

        #expect(hadith.shortCardText == nil)
        #expect(hadith.isShortFeedEligible == false)
        #expect(hadith.fullHadith.contains("must not invent a shortened quote"))
    }

    @Test func decodesLegacyCachedHadeethPayloadIntoFullHadith() async throws {
        let payload = """
        {
          "id": 9,
          "language": "en",
          "title": "Hadith",
          "hadeeth": "Speak good or remain silent.",
          "grade": "Sahih",
          "attribution": "Bukhari",
          "hints": []
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Hadith.self, from: payload)

        #expect(decoded.fullHadith == "Speak good or remain silent.")
        #expect(decoded.shortCardText == "Speak good or remain silent.")
        #expect(decoded.isShortFeedEligible == true)
    }
}
