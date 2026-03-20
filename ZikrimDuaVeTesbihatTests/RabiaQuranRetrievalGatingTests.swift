import XCTest
@testable import ZikrimDuaVeTesbihat

@MainActor
final class RabiaQuranRetrievalGatingTests: XCTestCase {
    private let retriever = RabiaQuranEmbeddingRetriever.shared

    func testSensitiveQueryLowScoresReturnsEmpty() {
        let entries = [
            semanticEntry(ref: "74:29", text: "uzak alakasiz metin"),
            semanticEntry(ref: "81:26", text: "baska bir konu")
        ]

        let refs = retriever.retrieveRefsForTesting(
            query: "eşcinsellik günah mı",
            appLanguage: "tr",
            entries: entries,
            topK: 3,
            threshold: 0.7,
            sensitiveQuery: true
        )

        XCTAssertTrue(refs.isEmpty)
    }

    func testNonSensitiveQueryStrongMatchReturnsRef() {
        let entries = [
            semanticEntry(ref: "13:28", text: "kalp huzuru hakkında ayet"),
            semanticEntry(ref: "2:286", text: "farkli konu")
        ]

        let refs = retriever.retrieveRefsForTesting(
            query: "kalp huzuru hakkında ayet",
            appLanguage: "tr",
            entries: entries,
            topK: 3,
            threshold: 0.3,
            sensitiveQuery: false
        )

        XCTAssertTrue(refs.contains { $0.ref == "13:28" })
    }

    func testExplicitVerseQueryAllowsRetrieval() {
        let entries = [
            semanticEntry(ref: "13:28", text: "kalp huzuru ile ilgili ayet"),
            semanticEntry(ref: "2:286", text: "baska konu")
        ]

        let refs = retriever.retrieveRefsForTesting(
            query: "kalp huzuru ile ilgili ayetler",
            appLanguage: "tr",
            entries: entries,
            topK: 3,
            threshold: 0.2,
            sensitiveQuery: false
        )

        XCTAssertFalse(refs.isEmpty)
        XCTAssertTrue(refs.contains { $0.ref == "13:28" })
    }

    func testSensitiveQueryWeakMarginFails() {
        let entries = [
            semanticEntry(ref: "7:80", text: "eşcinsellik günah mı"),
            semanticEntry(ref: "7:81", text: "eşcinsellik günah mı")
        ]

        let refs = retriever.retrieveRefsForTesting(
            query: "eşcinsellik günah mı",
            appLanguage: "tr",
            entries: entries,
            topK: 2,
            threshold: 0.2,
            sensitiveQuery: true
        )

        XCTAssertTrue(refs.isEmpty)
    }

    func testThinkBlockRemoved() {
        let raw = "<think>gizli düşünce</think>\nCevap burada."
        let output = RabiaResponseSanitizer.sanitize(raw)
        XCTAssertFalse(output.contains("<think>"))
        XCTAssertFalse(output.contains("gizli düşünce"))
    }

    func testThinkBlockRemovedExactOutput() {
        let raw = "<think>secret</think> Normal cevap"
        let output = RabiaResponseSanitizer.sanitize(raw)
        XCTAssertEqual(output, "Normal cevap")
    }

    func testPromptHasNoRefsWhenEmpty() {
        let instruction = RabiaSourceInstructionBuilder.build(
            context: RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: []),
            includeReligiousSources: false,
            quranReferences: [],
            allowDhikrSuggestion: false,
            queryMode: "general_knowledge",
            allowRepentanceLanguage: false
        )
        XCTAssertFalse(instruction.contains("13:28"))
        XCTAssertNil(instruction.range(of: #"\\b\\d{1,3}:\\d{1,3}\\b"#, options: NSString.CompareOptions.regularExpression))
    }

    func testPromptInjectsOnlyProvidedRefs() {
        let instruction = RabiaSourceInstructionBuilder.build(
            context: RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: []),
            includeReligiousSources: false,
            quranReferences: ["13:28"],
            allowDhikrSuggestion: false,
            queryMode: "explicit_verse_request",
            allowRepentanceLanguage: false
        )
        XCTAssertTrue(instruction.contains("13:28"))
        let refs = extractRefs(from: instruction)
        XCTAssertEqual(Set(refs), ["13:28"])
    }

    func testSensitivePromptContainsOnlyModeHeaderWhenNoVerifiedBlocks() {
        let instruction = RabiaSourceInstructionBuilder.build(
            context: RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: []),
            includeReligiousSources: false,
            quranReferences: [],
            allowDhikrSuggestion: false,
            queryMode: "sensitive_question",
            allowRepentanceLanguage: false
        )
        XCTAssertEqual(instruction, "Current mode: sensitive_question")
    }

    func testGeneralKnowledgeNoRefPromptStaysMinimal() {
        let instruction = RabiaSourceInstructionBuilder.build(
            context: RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: []),
            includeReligiousSources: false,
            quranReferences: [],
            allowDhikrSuggestion: false,
            queryMode: "general_knowledge",
            allowRepentanceLanguage: false
        )
        XCTAssertEqual(instruction, "Current mode: general_knowledge")
    }

    func testEmotionalSupportQueryModeIsDetected() {
        let mode = retriever.queryMode(for: "kalbim sıkışıyor", appLanguage: "tr")
        XCTAssertEqual(mode, "emotional_support")
    }

    func testEmotionalSupportPromptIsWarmAndSourceFree() {
        let prompt = RabiaPromptFactory.makeModePrompt(queryMode: .emotionalSupport)
        XCTAssertTrue(prompt.contains("acknowledge the feeling"))
        XCTAssertTrue(prompt.contains("one short human support line"))
        XCTAssertTrue(prompt.contains("No sources, dua, dhikr"))
    }

    func testExplicitVersePromptRequiresExactProvidedRefs() {
        let instruction = RabiaSourceInstructionBuilder.build(
            context: RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: []),
            includeReligiousSources: false,
            quranReferences: ["48:4", "48:18", "50:16"],
            allowDhikrSuggestion: false,
            queryMode: "explicit_verse_request",
            allowRepentanceLanguage: false
        )
        XCTAssertTrue(instruction.contains("Verified Quran references available"))
        XCTAssertTrue(instruction.contains("Never add, remove, change, paraphrase, or reorder them"))
        let refs = extractRefs(from: instruction)
        XCTAssertEqual(Array(refs.suffix(3)), ["48:4", "48:18", "50:16"])
    }

    func testSystemPromptUsesShortBaseArchitecture() {
        let prompt = RabiaPromptBuilder.buildSystemPrompt(
            memory: RabiaMemory(),
            appLanguageCode: "tr"
        )
        XCTAssertTrue(prompt.contains("You are Rabia, a calm, clear spiritual assistant inside a mobile app."))
        XCTAssertTrue(prompt.contains("Always reply in Turkish (tr)"))
        XCTAssertTrue(prompt.contains("if verified Quran references are not provided"))
        XCTAssertTrue(prompt.contains("Return only the final answer text."))
    }

    func testSensitiveExplanationOnlyFilterRemovesSpiritualAndActionClosings() {
        let service = GroqService()
        let input = """
        Bu duygu, kişinin kendi değeriyle ilgili değil; yaşadığı iç çatışmayla ilgilidir.
        Dua etmek istersen yardımcı olabilirim. Allah'ın rahmetine sığın.
        """

        let output = service.sensitiveExplanationOnlyForTesting(input)

        XCTAssertTrue(output.contains("Bu duygu, kişinin kendi değeriyle ilgili değil; yaşadığı iç çatışmayla ilgilidir."))
        XCTAssertFalse(output.localizedCaseInsensitiveContains("dua etmek"))
        XCTAssertFalse(output.localizedCaseInsensitiveContains("rahmetine sığın"))
        XCTAssertFalse(output.localizedCaseInsensitiveContains("yardımcı olabilirim"))
    }

    func testSensitiveExplanationOnlyFilterRemovesInvitationClosure() {
        let service = GroqService()
        let input = """
        Böyle hissetmen, tek başına seni tanımlayan bir şey değildir.
        İstersen bunun için güvenilir bir alimle görüşebilirsin.
        """

        let output = service.sensitiveExplanationOnlyForTesting(input)

        XCTAssertEqual(output, "Böyle hissetmen, tek başına seni tanımlayan bir şey değildir.")
    }

    func testDebugModelTrackingUsesOpenAIPrimaryModelOnly() {
        let service = GroqService()

        XCTAssertEqual(service.primaryModelForTesting(), "gpt-4.1-mini")
        XCTAssertTrue(service.fallbackModelsForTesting().isEmpty)

        service.recordResolvedModelForTesting(service.primaryModelForTesting())
        XCTAssertEqual(service.lastResolvedModel, service.primaryModelForTesting())
        XCTAssertFalse(service.didLastResponseUseFallbackForTesting())
    }

    func testGeneralKnowledgeKnownTopicUsesVerifiedLocalAnswerBlock() {
        let service = GroqService()
        let context = RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: [])

        let block = service.verifiedGeneralKnowledgeAnswerBlockForTesting(
            query: "Oruç nasıl tutulur?",
            retrievedContext: context
        )

        XCTAssertNotNil(block)
        XCTAssertTrue(block?.contains("imsak vaktinden akşam ezanına kadar") == true)
        XCTAssertTrue(block?.contains("Sahura kalkmak veya gece niyet etmek yeterlidir.") == true)
    }

    func testGeneralKnowledgeRewriteInstructionIncludesStrictTurkishRules() {
        let service = GroqService()
        let context = RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: [])

        let instruction = service.generalKnowledgeRewriteInstructionForTesting(
            query: "abdest nasıl alınır",
            retrievedContext: context
        )

        XCTAssertNotNil(instruction)
        XCTAssertTrue(instruction?.contains("Abdestte önce eller yıkanır") == true)
        XCTAssertTrue(instruction?.contains("baş mesh edilir") == true)
    }

    func testSmallTalkFastPathUsesAppLanguage() {
        XCTAssertEqual(
            RabiaSmallTalk.smallTalkResponse(for: "teşekkürler", language: .tr),
            "Rica ederim."
        )
        XCTAssertEqual(
            RabiaSmallTalk.smallTalkResponse(for: "teşekkürler", language: .en),
            "You're welcome."
        )
    }

    func testConversationTrimmerKeepsShortRecentWindow() {
        let history = [
            GroqChatMessage(role: "user", content: "u1"),
            GroqChatMessage(role: "assistant", content: "a1"),
            GroqChatMessage(role: "user", content: "u2"),
            GroqChatMessage(role: "assistant", content: "a2"),
            GroqChatMessage(role: "user", content: "u3")
        ]

        let trimmed = RabiaMessageTrimmer.trimmedConversation(history)

        XCTAssertEqual(trimmed.map(\.content), ["u2", "a2", "u3"])
        XCTAssertLessThanOrEqual(trimmed.count, 5)
    }

    private func semanticEntry(ref: String, text: String) -> RabiaQuranSemanticEntry {
        let parts = ref.split(separator: ":")
        let surah = Int(parts.first ?? "0") ?? 0
        let ayah = Int(parts.last ?? "0") ?? 0
        return RabiaQuranSemanticEntry(
            ref: ref,
            surah: surah,
            ayah: ayah,
            topics: [],
            priorityScore: 0,
            keywords: ["tr": text.split(separator: " ").map(String.init)],
            searchText: ["tr": text]
        )
    }

    private func extractRefs(from text: String) -> [String] {
        let pattern = #"\b(\d{1,3}):(\d{1,3})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        return matches.map { nsText.substring(with: $0.range(at: 0)) }
    }
}
