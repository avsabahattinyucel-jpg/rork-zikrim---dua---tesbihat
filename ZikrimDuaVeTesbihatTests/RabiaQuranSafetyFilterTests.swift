import XCTest
@testable import ZikrimDuaVeTesbihat

@MainActor
final class RabiaQuranSafetyFilterTests: XCTestCase {
    private let display1328 = "Ra'd 13:28\nKalpler ancak Allah'ı anmakla huzur bulur."
    private var defaultProvider: ((Int, Int) -> String?)?

    override func setUp() {
        super.setUp()
        defaultProvider = { [display1328] surah, ayah in
            if surah == 13 && ayah == 28 {
                return display1328
            }
            return nil
        }
        RabiaVerifiedSourceStore.testQuranDisplayProvider = defaultProvider
    }

    override func tearDown() {
        RabiaVerifiedSourceStore.testQuranDisplayProvider = nil
        super.tearDown()
    }

    func testAllowedReferencePasses() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: "Kalbim daralıyor. 13:28",
            allowedRefs: ["13:28"]
        )
        XCTAssertTrue(output.contains("Kalbim daralıyor."))
        XCTAssertTrue(output.contains("13:28"))
    }

    func testNonAllowedReferenceIsRemoved() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: "26:197",
            allowedRefs: ["13:28"]
        )
        XCTAssertFalse(output.contains("26:197"))
    }

    func testEmptyRetrievedRefsBlocksAll() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: "13:28",
            allowedRefs: []
        )
        XCTAssertFalse(output.contains("13:28"))
        XCTAssertFalse(output.contains(display1328))
    }

    func testQuranLikeFabricatedTextIsStripped() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: "\"Kalpler ancak Allah'ı anmakla huzur bulur.\"\n\nالرعد 13:28",
            allowedRefs: []
        )
        XCTAssertFalse(output.contains("Kalpler ancak Allah'ı anmakla huzur bulur."))
        XCTAssertFalse(output.contains("الرعد"))
    }

    func testMixedOutputSanitized() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: "13:28 ve 26:197",
            allowedRefs: ["13:28"]
        )
        XCTAssertTrue(output.contains("13:28"))
        XCTAssertFalse(output.contains("26:197"))
    }

    func testSurahNamesTypedByModelNotTrusted() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: "Ra'd 13:28",
            allowedRefs: ["13:28"]
        )
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), "13:28")
    }

    func testRendererUsesDatasetWhenAvailable() {
        let filtered = RabiaQuranSafetyFilter.apply(
            rawResponse: "Sabırlı ol.\n13:28",
            allowedRefs: ["13:28"]
        )
        let output = RabiaQuranSafetyFilter.renderVerifiedReferences(
            in: filtered,
            allowedRefs: ["13:28"]
        )
        XCTAssertTrue(output.contains("Sabırlı ol."))
        XCTAssertTrue(output.contains(display1328))
    }

    func testRendererKeepsReferenceIfDatasetLookupFails() {
        RabiaVerifiedSourceStore.testQuranDisplayProvider = { _, _ in nil }
        let filtered = RabiaQuranSafetyFilter.apply(
            rawResponse: "Sabırlı ol.\n13:28",
            allowedRefs: ["13:28"]
        )
        let output = RabiaQuranSafetyFilter.renderVerifiedReferences(
            in: filtered,
            allowedRefs: ["13:28"]
        )
        XCTAssertTrue(output.contains("Sabırlı ol."))
        XCTAssertTrue(output.contains("13:28"))
    }

    func testReferenceLineKeepsReferenceAndRemovesQuotedVerseText() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: #"48:4 "Kalpler Allah ile huzur bulur.""#,
            allowedRefs: ["48:4"]
        )
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), "48:4")
    }

    func testExplanationIsPreservedWhenReferenceLinesExist() {
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: "Kalp huzuru ile ilgili ayetler:\n48:4\n48:18",
            allowedRefs: ["48:4", "48:18"]
        )
        XCTAssertTrue(output.contains("Kalp huzuru ile ilgili ayetler:"))
        XCTAssertTrue(output.contains("48:4"))
        XCTAssertTrue(output.contains("48:18"))
    }

    func testReferenceLineBreaksArePreserved() {
        let input = """
        Kalp huzuru ile ilgili bazı ayetler:
        48:4
        48:18
        39:38
        """
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: input,
            allowedRefs: ["48:4", "48:18", "39:38"]
        )
        XCTAssertEqual(output, input)
    }

    func testInvalidReferenceDoesNotCorruptTurkishText() {
        let input = "Allah, insanları her birine göre yaratmıştır. Kur'an'da, \"İnsanlar...\" (17:70) buyurulmuştur."
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: input,
            allowedRefs: []
        )
        XCTAssertTrue(output.contains("insanları"))
        XCTAssertTrue(output.contains("buyurulmuştur"))
        XCTAssertFalse(output.contains("17:70"))
        XCTAssertFalse(output.contains("()"))
    }

    func testInvalidReferencePreservesSentence() {
        let input = "Bu önemlidir. 17:70"
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: input,
            allowedRefs: []
        )
        XCTAssertTrue(output.contains("Bu önemlidir."))
        XCTAssertFalse(output.contains("17:70"))
        XCTAssertFalse(output.contains("öidir"))
    }

    func testRangeReferenceRemovedCleanly() {
        let input = "Bakara 2:246-247 ile ilgili not."
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: input,
            allowedRefs: []
        )
        XCTAssertTrue(output.contains("ile ilgili not."))
        XCTAssertFalse(output.contains("2:246-247"))
        XCTAssertFalse(output.contains("-247"))
        XCTAssertFalse(output.contains("()"))
    }

    func testParenthesizedRangeReferenceRemovedCleanly() {
        let input = "Bu konuda (7:80-84) hatırlatma var."
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: input,
            allowedRefs: []
        )
        XCTAssertTrue(output.contains("Bu konuda"))
        XCTAssertFalse(output.contains("7:80-84"))
        XCTAssertFalse(output.contains("(-84)"))
        XCTAssertFalse(output.contains("()"))
    }

    func testNoRefModeRemovesQuranMentions() {
        let input = "Kısa açıklama. Kur'an'da bu konu geçer."
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: input,
            allowedRefs: []
        )
        XCTAssertTrue(output.contains("Kısa açıklama."))
        XCTAssertTrue(output.contains("Kur'an'da"))
    }

    func testNoRefModeRemovesAllQuranRefsAndRanges() {
        let input = "Kur'an'da 2:255 ve (2:246-247) geçer. Açıklama burada."
        let output = RabiaQuranSafetyFilter.apply(
            rawResponse: input,
            allowedRefs: []
        )
        XCTAssertTrue(output.contains("Açıklama burada."))
        XCTAssertFalse(output.contains("2:255"))
        XCTAssertFalse(output.contains("2:246-247"))
        XCTAssertFalse(output.contains("()"))
    }
}
