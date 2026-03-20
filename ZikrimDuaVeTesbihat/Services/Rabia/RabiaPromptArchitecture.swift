import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Sendable {
    case tr
    case en
    case de
    case ar
    case fr
    case es
    case id
    case ur
    case ms
    case ru
    case fa

    init(code rawCode: String) {
        let normalized = rawCode
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        let primary = normalized.split(separator: "-").first.map(String.init) ?? normalized
        self = AppLanguage(rawValue: primary) ?? .tr
    }

    var displayName: String {
        switch self {
        case .tr: return "Turkish"
        case .en: return "English"
        case .de: return "German"
        case .ar: return "Arabic"
        case .fr: return "French"
        case .es: return "Spanish"
        case .id: return "Indonesian"
        case .ur: return "Urdu"
        case .ms: return "Malay"
        case .ru: return "Russian"
        case .fa: return "Persian"
        }
    }
}

nonisolated struct VerifiedQuranRef: Hashable, Sendable {
    let value: String

    init?(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: #"^\d{1,3}:\d{1,3}$"#, options: .regularExpression) != nil else {
            return nil
        }
        self.value = trimmed
    }
}

nonisolated enum RabiaQueryMode: String, Sendable {
    case generalKnowledge = "general_knowledge"
    case sensitiveQuestion = "sensitive_question"
    case emotionalSupport = "emotional_support"
    case explicitVerseRequest = "explicit_verse_request"
    case duaDhikrRequest = "dua_dhikr_request"
    case lightweightGuideRequest = "lightweight_guide_request"
    case onboardingSummary = "onboarding_summary"
    case supportiveSummary = "supportive_summary"

    static func detectQueryMode(userText: String) -> RabiaQueryMode {
        let normalized = normalizedText(userText)
        guard !normalized.isEmpty else { return .generalKnowledge }

        if containsAny(in: normalized, terms: explicitVerseTerms) {
            return .explicitVerseRequest
        }

        if containsAny(in: normalized, terms: emotionalSupportTerms) {
            return .emotionalSupport
        }

        if containsAny(in: normalized, terms: sensitiveQuestionTerms) {
            return .sensitiveQuestion
        }

        return .generalKnowledge
    }

    private static let explicitVerseTerms = [
        "ayet", "ayetler", "kuran", "kur an", "kur'an", "sure", "sura", "verse", "verses",
        "quran", "surah", "verset", "versets", "coran", "corán", "versiculo", "versículos",
        "versiculo", "ayat", "آية", "آيات", "قران", "قرآن", "سورة", "آیت", "سورۃ",
        "аят", "аяты", "коран", "сура", "آیه", "آیات", "سوره"
    ]

    private static let emotionalSupportTerms = [
        "uzgunum", "üzgünüm", "kaygiliyim", "kaygılıyım", "cok kotuyum", "çok kötüyüm",
        "bunaldim", "bunaldım", "yalnizim", "yalnızım", "kalbim sikisiyor", "kalbim sıkışıyor",
        "kendimi kotu hissediyorum", "kendimi kötü hissediyorum", "i am sad", "i feel anxious",
        "i feel terrible", "i feel bad", "i am overwhelmed", "i'm overwhelmed", "i am not okay",
        "i'm not okay", "anxious", "overwhelmed", "triste", "ansioso", "ansiosa", "gelisah",
        "cemas", "sedih", "mujhe bura lag raha hai", "پریشان", "غمگین", "قلق", "حزين",
        "тревожно", "мне плохо", "من ناراحتم", "من خیلی حالم بد است"
    ]

    private static let sensitiveQuestionTerms = [
        "gunah mi", "günah mı", "haram mi", "haram mı", "sapik miyim", "sapık mıyım",
        "kotu biri miyim", "kötü biri miyim", "allah beni affeder mi", "beni affeder mi",
        "tevbe", "tövbe", "gunahkar", "günahkar", "is it a sin", "is this a sin",
        "am i a bad person", "am i perverted", "is it haram", "forbidden", "sinful",
        "haram", "peccato", "pecado", "serait ce un péché", "günah", "حرام", "گناه",
        "آیا گناه است", "грех", "грешно", "дозволено ли", "هل هذا حرام", "هل انا سيء"
    ]

    private static func containsAny(in text: String, terms: [String]) -> Bool {
        terms.contains { text.contains(normalizedText($0)) }
    }

    private static func normalizedText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .replacingOccurrences(of: #"[^[:alnum:]\s\u0600-\u06FF\u0400-\u04FF]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

nonisolated struct RabiaPromptBundle: Sendable {
    let queryMode: RabiaQueryMode
    let basePrompt: String
    let modePrompt: String
    let verifiedRefsBlock: String?
    let verifiedKnowledgeBlock: String?
    let trimmedConversation: [RabiaMessage]
    let currentUserMessage: String

    var messages: [RabiaMessage] {
        var items: [RabiaMessage] = [
            RabiaMessage(role: "system", content: basePrompt),
            RabiaMessage(role: "system", content: modePrompt)
        ]

        if let verifiedRefsBlock {
            items.append(RabiaMessage(role: "system", content: verifiedRefsBlock))
        }

        if let verifiedKnowledgeBlock {
            items.append(RabiaMessage(role: "system", content: verifiedKnowledgeBlock))
        }

        items.append(contentsOf: trimmedConversation)
        items.append(RabiaMessage(role: "user", content: currentUserMessage))
        return items
    }
}

struct RabiaPromptFactory {
    static func makeBasePrompt(appLanguage: AppLanguage) -> String {
        """
        You are Rabia, the in-app Islamic assistant inside the \(AppName.short) mobile app.
        You are not a general chatbot. Stay within Islamic guidance, worship, dhikr, dua, Quran reflection, khutbah-related explanation, and verified app navigation.
        Always reply in \(appLanguage.displayName) (\(appLanguage.rawValue)). Never mix languages.
        Sound natural, calm, respectful, and human. Do not sound robotic, cold, repetitive, or academic.
        Answer the user's intent first. Redirect only if it adds value after the answer.
        Keep answers short and meaningful. Most answers should be 2-4 sentences.
        Be clear in rulings. If something is clearly sinful, impermissible, recommended, or rewarded in mainstream Islamic understanding, say so plainly. If scholars differ, mention that briefly.
        Refuse unrelated topics such as coding, tech support, politics, finance, legal advice, medical advice, shopping, gossip, or general trivia with a short refusal.
        Refuse erotic, explicit, pornographic, vulgar, or arousing sexual conversation. If the question is asked in a valid Islamic moral context, answer briefly, modestly, and without graphic detail.
        Khutbah Summary is a separate read-only app section. Do not generate a fresh khutbah summary in chat. If asked for the khutbah summary, briefly explain and direct the user to the Khutbah Summary section.
        Be app-aware without inventing features. Known sections: Home / Daily screen, Prayer Times, Dhikr / Tasbih, Dua, Rabia Chat, Khutbah Summary, Quran Listening, Rehber.
        If Diyanet Din İşleri Yüksek Kurulu content is provided in verified context, answer naturally first, then treat it as the primary source, summarize it in 1-2 short sentences, and direct the user to the Rehber section for details.
        Never claim you can tap buttons, open screens, change settings, or control the app.
        Never invent Quran verses, hadith, rulings, or religious sources; if verified Quran references are not provided, do not mention Quran, surah names, verse numbers, hadith, or prophetic stories.
        If unsure, say so briefly. Return only the final answer text.
        """
    }

    static func makeModePrompt(queryMode: RabiaQueryMode) -> String {
        switch queryMode {
        case .generalKnowledge:
            return """
            Mode: general_knowledge.
            Give a short, natural answer in 2-4 short sentences.
            Continue follow-up questions in context instead of restarting.
            """
        case .sensitiveQuestion:
            return """
            Mode: sensitive_question.
            Be calm, non-judgmental, and brief.
            Give only a short explanation in 2-4 short sentences, with modest wording and no graphic detail.
            """
        case .emotionalSupport:
            return """
            Mode: emotional_support.
            First acknowledge the feeling, then offer one short human support line.
            No sources, dua, dhikr, verses, hadith, or advice lists. Keep it warm, brief, and natural.
            """
        case .explicitVerseRequest:
            return """
            Mode: explicit_verse_request.
            Use only the verified references provided below, if any.
            Do not write verse text or surah names. Give one short explanation, then output the references exactly as given and in the same order, with no additions, removals, or changes.
            If no verified references are provided, say briefly that specific references are unavailable right now.
            """
        case .duaDhikrRequest, .lightweightGuideRequest, .onboardingSummary, .supportiveSummary:
            return """
            Mode: general_knowledge.
            Give a short, natural answer in 2-4 short sentences.
            When relevant, guide the user to the right app section naturally and only after answering.
            """
        }
    }

    static func makeVerifiedRefsBlock(refs: [String]) -> String? {
        let verifiedRefs = refs.compactMap(VerifiedQuranRef.init).map(\.value)
        guard !verifiedRefs.isEmpty else { return nil }

        let lines = verifiedRefs.map { "- \($0)" }.joined(separator: "\n")
        return """
        Verified Quran references available. Use only these exact references:
        \(lines)
        Never add, remove, change, paraphrase, or reorder them. Never write verse text or surah names.
        """
    }

    static func makeVerifiedKnowledgeBlock(text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return """
        Verified knowledge context:
        \(trimmed)
        Use this only when it is relevant. Do not extend it with unverified religious claims.
        """
    }
}

struct RabiaMessageTrimmer {
    static func trimmedConversation(
        _ messages: [GroqChatMessage],
        maxUserMessages: Int = 2,
        maxAssistantMessages: Int = 1,
        maxTotalMessages: Int = 5
    ) -> [GroqChatMessage] {
        let filtered = messages.filter { $0.role == "user" || $0.role == "assistant" }
        guard !filtered.isEmpty else { return [] }

        var selectedIndices = Set<Int>()
        var userCount = 0
        var assistantCount = 0

        for index in filtered.indices.reversed() {
            let message = filtered[index]
            switch message.role {
            case "user" where userCount < maxUserMessages:
                selectedIndices.insert(index)
                userCount += 1
            case "assistant" where assistantCount < maxAssistantMessages:
                selectedIndices.insert(index)
                assistantCount += 1
            default:
                continue
            }
        }

        if selectedIndices.count < maxTotalMessages {
            let earliestSelectedIndex = selectedIndices.min() ?? filtered.startIndex
            let recentWindow = Array(filtered[earliestSelectedIndex...].suffix(maxTotalMessages))
            return recentWindow
        }

        return filtered.enumerated().compactMap { index, message in
            selectedIndices.contains(index) ? message : nil
        }
    }

    static func trimmedConversation(
        _ messages: [RabiaMessage],
        maxUserMessages: Int = 2,
        maxAssistantMessages: Int = 1,
        maxTotalMessages: Int = 5
    ) -> [RabiaMessage] {
        trimmedConversation(
            messages.map { GroqChatMessage(role: $0.role, content: $0.content) },
            maxUserMessages: maxUserMessages,
            maxAssistantMessages: maxAssistantMessages,
            maxTotalMessages: maxTotalMessages
        )
        .map { RabiaMessage(role: $0.role, content: $0.content) }
    }
}

struct RabiaContextBuilder {
    static func buildRabiaInput(
        currentUserMessage: String,
        history: [GroqChatMessage],
        appLanguage: AppLanguage,
        queryMode: RabiaQueryMode? = nil,
        verifiedRefs: [String] = [],
        verifiedKnowledgeText: String? = nil
    ) -> RabiaPromptBundle {
        let resolvedQueryMode = queryMode ?? RabiaQueryMode.detectQueryMode(userText: currentUserMessage)
        let trimmedHistory = RabiaMessageTrimmer.trimmedConversation(history).map {
            RabiaMessage(role: $0.role, content: $0.content)
        }

        return RabiaPromptBundle(
            queryMode: resolvedQueryMode,
            basePrompt: RabiaPromptFactory.makeBasePrompt(appLanguage: appLanguage),
            modePrompt: RabiaPromptFactory.makeModePrompt(queryMode: resolvedQueryMode),
            verifiedRefsBlock: RabiaPromptFactory.makeVerifiedRefsBlock(refs: verifiedRefs),
            verifiedKnowledgeBlock: RabiaPromptFactory.makeVerifiedKnowledgeBlock(text: verifiedKnowledgeText),
            trimmedConversation: trimmedHistory,
            currentUserMessage: currentUserMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
