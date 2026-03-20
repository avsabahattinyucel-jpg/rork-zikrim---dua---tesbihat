import Foundation

nonisolated struct GroqChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct OpenAIResponseInputText: Encodable, Sendable {
    let type: String = "input_text"
    let text: String
}

nonisolated struct OpenAIResponseInputMessage: Encodable, Sendable {
    let type: String = "message"
    let role: String
    let content: [OpenAIResponseInputText]
}

nonisolated struct OpenAIResponseRequest: Encodable, Sendable {
    let model: String
    let input: [OpenAIResponseInputMessage]
    let temperature: Double
    let topP: Double

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case temperature
        case topP = "top_p"
    }
}

nonisolated struct OpenAIResponseOutputContent: Decodable, Sendable {
    let type: String
    let text: String?
    let refusal: String?
}

nonisolated struct OpenAIResponseOutputItem: Decodable, Sendable {
    let type: String?
    let role: String?
    let content: [OpenAIResponseOutputContent]?
}

nonisolated struct OpenAIResponse: Decodable, Sendable {
    let output: [OpenAIResponseOutputItem]?
}

nonisolated struct GuideGroqChatCompletionRequest: Encodable, Sendable {
    let model: String
    let messages: [GroqChatMessage]
    let temperature: Double
    let topP: Double
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case topP = "top_p"
        case stream
    }
}

nonisolated struct GuideGroqChatCompletionChoice: Decodable, Sendable {
    let message: GroqChatMessage
}

nonisolated struct GuideGroqChatCompletionResponse: Decodable, Sendable {
    let choices: [GuideGroqChatCompletionChoice]
}

nonisolated enum GroqError: LocalizedError, Sendable {
    case httpError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .httpError(let code, _):
            return "Backend API \(code) hatası"
        case .emptyResponse:
            return "Backend yanıt vermedi"
        }
    }
}

@Observable
@MainActor
final class GroqService {
    private let uncertainCitationFallback = "Bu konuda kesin bir ayet veya hadis bilgim yok. Yanlış bilgi vermemek için paylaşmıyorum."
    private let textGenerationService = BackendTextGenerationService()

    private var systemPrompt: String {
        let memory = RabiaMemoryService.shared.loadMemory()
        return RabiaPromptBuilder.buildSystemPrompt(memory: memory, appLanguageCode: appLanguageCode)
    }
    private var appLanguageCode: String {
        RabiaAppLanguage.currentCode()
    }
    private let primaryModel: String = "gpt-4.1-mini"
    private let guideGroqModel: String = "gpt-4.1-mini"
    private let guideSearchSystemPrompt: String = "Kullanici kisa bir durum yazar. Yalniz 1 kisa cumle yaz. Girdiyi tekrar etme. Cumle durumla baglantili olsun; dua, sakinlik, hazirlik veya ic huzur icersin. 'basarilar dilerim' ve 'bol sans' yazma. Turkiye Turkcesi kullan. Kuran ayeti metni yazma."
    private let temperature: Double = 0.35
    private let topP: Double = 0.85
    private let maxRetryAttempts: Int = 3
    private let maxBackoffSeconds: Double = 8
    private let retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    private let retryableURLCodes: Set<URLError.Code> = [.timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost]
    private let jitterRange: ClosedRange<Double> = 0...0.35
    private let quranEmbeddingRetriever: RabiaQuranEmbeddingRetrieving = RabiaQuranEmbeddingRetriever.shared
    private let quranRefThreshold: Float = 0.24
    private let quranRefLimit: Int = 3

    var dailyWisdom: String? = nil
    var dailyAIDua: String? = nil
    var isLoadingWisdom: Bool = false
    var isLoadingAIDua: Bool = false
    
    var aiSearchResults: [String] = []
    var assistantAdvice: String? = nil
    var isSearching: Bool = false
    var searchError: String? = nil

    private var lastRequestTime: Date? = nil
    private var activePrompts: Set<String> = []
    private let minRequestInterval: TimeInterval = 3

    private let wisdomCacheKey = "groq_daily_wisdom_v3"
    private let wisdomDateKey = "groq_daily_wisdom_date_v3"
    private let aiDuaCacheKey = "groq_daily_dua_v3"
    private let dailyQuestionDateKey = "groq_maneviyata_sor_date_v1"

#if DEBUG
    private(set) var lastResolvedModel: String?
    private(set) var lastResolvedModelUsedFallback: Bool = false
#endif

    func generate(prompt: String) async throws -> String {
        if let cached = GroqCache.shared.get(prompt: prompt) {
            print("[GroqService] Cache hit")
            return cached
        }

        let promptKey = String(prompt.prefix(500))
        guard !activePrompts.contains(promptKey) else {
            print("[GroqService] Duplicate request blocked")
            if let cached = GroqCache.shared.get(prompt: prompt) { return cached }
            return ""
        }

        if let last = lastRequestTime, Date().timeIntervalSince(last) < minRequestInterval {
            print("[GroqService] Rate limit — waiting")
            let wait = minRequestInterval - Date().timeIntervalSince(last)
            try await Task.sleep(for: .seconds(wait))
        }

        activePrompts.insert(promptKey)
        defer { activePrompts.remove(promptKey) }

        do {
            let text = try await generateWithRetry(prompt: prompt, model: primaryModel)
            recordResolvedModel(primaryModel, usedFallback: false)
            lastRequestTime = Date()
            GroqCache.shared.set(prompt: prompt, response: text)
            return text
        } catch {
            print("[RabiaProvider] ❌ model \(primaryModel) başarısız — \(error)")
            throw error
        }
    }

    private func generateWithRetry(prompt: String, model: String) async throws -> String {
        var attempt: Int = 0
        while true {
            do {
                return try await sendGenerateRequest(prompt: prompt, model: model)
            } catch {
                let shouldRetry: Bool = isRetryable(error)
                if !shouldRetry || attempt >= maxRetryAttempts {
                    throw error
                }

                let waitSeconds = retryDelay(for: attempt, error: error)
                print("[RabiaProvider] ⏳ Retry \(attempt + 1)/\(maxRetryAttempts) | model: \(model) | bekleme: \(String(format: "%.2f", waitSeconds))s")
                try await Task.sleep(for: .seconds(waitSeconds))
                attempt += 1
            }
        }
    }

    private func sendGenerateRequest(prompt: String, model: String) async throws -> String {
        let payload = """
        \(systemPrompt)

        Kullanıcının mesajı:
        \(prompt)
        """

#if DEBUG
        let appLangInjected = payload.lowercased().contains(appLanguageCode.lowercased())
        print("[RabiaProvider] request_model=\(model) app_language_in_prompt=\(appLangInjected)")
        print("[RabiaProvider] request_start model=\(model) prompt_preview=\(prompt.prefix(60))")
#endif

        do {
            let text = try await textGenerationService.generate(
                message: payload,
                instructions: "Return only the requested final answer text.",
                appLanguage: appLanguageCode,
                maxOutputTokens: 700,
                temperature: 0.3
            )
#if DEBUG
            print("[RabiaProvider] http_status=200 model=\(model)")
            print("[RabiaProvider] response_success model=\(model) chars=\(text.count)")
#endif
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw GroqError.emptyResponse
            }
            return sanitizeResponse(trimmed)
        } catch let error as RabiaServiceError {
            if case .httpStatus(let statusCode, let body) = error {
#if DEBUG
                print("[RabiaProvider] request_error model=\(model) status=\(statusCode) message=\(body)")
#endif
                throw GroqError.httpError(statusCode, body)
            }
            throw GroqError.emptyResponse
        }
    }

    private func isRetryable(_ error: Error) -> Bool {
        if let groqError = error as? GroqError {
            switch groqError {
            case .httpError(let statusCode, _):
                return retryableStatusCodes.contains(statusCode)
            case .emptyResponse:
                return false
            }
        }

        if let urlError = error as? URLError {
            return retryableURLCodes.contains(urlError.code)
        }

        return false
    }

    private func retryDelay(for attempt: Int, error: Error) -> Double {
        let baseDelay = min(pow(2.0, Double(attempt)), maxBackoffSeconds)

        if let retryAfter = retryAfterSeconds(from: error) {
            return min(max(retryAfter, baseDelay), maxBackoffSeconds)
        }

        let jitter = Double.random(in: jitterRange)
        return min(baseDelay + jitter, maxBackoffSeconds)
    }

    private func retryAfterSeconds(from error: Error) -> Double? {
        guard case GroqError.httpError(_, let body) = error else { return nil }
        guard let data = body.data(using: .utf8) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let errorObject = json["error"] as? [String: Any] else { return nil }
        guard let details = errorObject["details"] as? [[String: Any]] else { return nil }

        for detail in details {
            if let retryInfo = detail["retryDelay"] as? String {
                return parseRetryDelaySeconds(retryInfo)
            }
        }

        return nil
    }

    private func firstErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let errorObject = json["error"] as? [String: Any] else { return nil }
        return errorObject["message"] as? String
    }

    private func generateGuideSearchResponse(prompt: String) async throws -> String {
        let backendPrompt = """
        \(guideSearchSystemPrompt)

        Kullanıcı mesajı:
        \(prompt)
        """

        let promptMessageCount = 2
        let promptCharacterCount = backendPrompt.count
        let estimatedPromptSize = max(1, Int(ceil(Double(promptCharacterCount) / 4.0)))

#if DEBUG
        print("[ZikirRehberi] selected_provider=backend")
        print("[ZikirRehberi] request_model=\(guideGroqModel)")
        print("[ZikirRehberi] request_start messages=\(promptMessageCount)")
        print("[ZikirRehberi] prompt_message_count=\(promptMessageCount)")
        print("[ZikirRehberi] prompt_character_count=\(promptCharacterCount)")
        print("[ZikirRehberi] estimated_prompt_size=\(estimatedPromptSize)_tokens_approx")
#endif

        let text = try await textGenerationService.generate(
            message: backendPrompt,
            instructions: "Return only one short final sentence.",
            appLanguage: appLanguageCode,
            maxOutputTokens: 120,
            temperature: 0.3
        )
        let sanitized = sanitizeResponse(text.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !sanitized.isEmpty else {
            throw GroqError.emptyResponse
        }
#if DEBUG
        print("[ZikirRehberi] http_status=200")
        print("[ZikirRehberi] response_success request_model=\(guideGroqModel) chars=\(sanitized.count)")
#endif
        return sanitized
    }

    private func makeOpenAIInputMessages(from messages: [GroqChatMessage]) -> [OpenAIResponseInputMessage] {
        messages.map { message in
            OpenAIResponseInputMessage(
                role: normalizedOpenAIRole(message.role),
                content: [OpenAIResponseInputText(text: message.content)]
            )
        }
    }

    private func normalizedOpenAIRole(_ role: String) -> String {
        switch role.lowercased() {
        case "system", "developer":
            return role.lowercased()
        case "assistant":
            return "assistant"
        default:
            return "user"
        }
    }

    private func extractText(from response: OpenAIResponse) -> String? {
        let text = response.output?
            .flatMap { $0.content ?? [] }
            .compactMap { content -> String? in
                switch content.type {
                case "output_text":
                    return content.text
                case "refusal":
                    return content.refusal
                default:
                    return nil
                }
            }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let text, !text.isEmpty else { return nil }
        return text
    }

    private func isAppLanguageInjected(in messages: [GroqChatMessage]) -> Bool {
        let systemContent = messages.first(where: { $0.role == "system" })?.content.lowercased() ?? ""
        let appLang = appLanguageCode.lowercased()
        if systemContent.contains(appLang) { return true }
        if systemContent.contains("app language") { return true }
        if systemContent.contains("uygulama dili") { return true }
        return false
    }

    private func parseRetryDelaySeconds(_ retryDelay: String) -> Double? {
        let trimmed = retryDelay.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasSuffix("s") {
            let numeric = String(trimmed.dropLast())
            return Double(numeric)
        }
        return Double(trimmed)
    }

    func fetchDailyWisdom() async {
        let today = Calendar.current.startOfDay(for: Date())
        if let cachedDate = UserDefaults.standard.object(forKey: wisdomDateKey) as? Date,
           Calendar.current.isDate(cachedDate, inSameDayAs: today),
           let cachedWisdom = UserDefaults.standard.string(forKey: wisdomCacheKey), !cachedWisdom.isEmpty,
           let cachedDua = UserDefaults.standard.string(forKey: aiDuaCacheKey), !cachedDua.isEmpty {
            dailyWisdom = cachedWisdom
            dailyAIDua = cachedDua
            return
        }

        isLoadingWisdom = true
        isLoadingAIDua = true
        defer {
            isLoadingWisdom = false
            isLoadingAIDua = false
        }

        do {
            let prompt = """
            Sen Rabia'sin. Dogal ve akici, kullanicinin uygulama diliyle, kisa paragraflarla cevap ver.
            Kullanıcının uygulama dili kodu: \(appLanguageCode).
            Bugün için:
            1) Kisa, uygulanabilir bir Islami tavsiye ver.
            2) Kisa bir gunluk dua ver.

            Ayet veya hadis uydurma. Emin olmadigin dini alintilari hic kullanma.

            Sadece şu formatta yanıt ver:
            [TAVSIYE]: ...
            [DUA]: ...
            """
            let result = try await generate(prompt: prompt)
            let parsed = parseDailyGuidance(result)
            dailyWisdom = parsed.wisdom
            dailyAIDua = parsed.dua
            UserDefaults.standard.set(parsed.wisdom, forKey: wisdomCacheKey)
            UserDefaults.standard.set(parsed.dua, forKey: aiDuaCacheKey)
            UserDefaults.standard.set(today, forKey: wisdomDateKey)
            UserDefaults.standard.set(parsed.wisdom, forKey: "widget_daily_wisdom")
        } catch {
            print("Groq Error: \(error)")
            let fallbacks = [
                "Bugün tanıştığın ilk kişiye gülümseyerek selam ver; bu küçük eylem büyük bereketler taşır.",
                "Bir gün on kez 'Elhamdülillah' diyerek dur ve ne için şükrettiğini düşün.",
                "Bir yakınını arayıp hatrını sor; sıla-i rahmin gücünü bugün hisset.",
                "Kalbinde kötü bir düşünce belirdiğinde hemen 'Estağfirullah' de; kalp temizlenir.",
                "Bugün birine iyilik yap; sadaka yalnızca para değil, her güzel davranıştır."
            ]
            let duas = [
                "Allah'ım, kalbime huzur, dilime zikir, amellerime ihlas nasip eyle.",
                "Rabbim, bugünü hayırla geçirip sevdiklerime iyilik yapmayı nasip et.",
                "Allah'ım, beni doğru sözden, güzel ahlaktan ve faydalı amelden ayırma."
            ]
            let day = Calendar.current.component(.day, from: Date())
            let fallbackWisdom = fallbacks[day % fallbacks.count]
            let fallbackDua = duas[day % duas.count]
            dailyWisdom = fallbackWisdom
            dailyAIDua = fallbackDua
            UserDefaults.standard.set(fallbackWisdom, forKey: "widget_daily_wisdom")
        }
    }

    func zikirSpiritualInsight(for zikirName: String) async throws -> String {
        let prompt = """
        "\(zikirName)" zikriyle ilgili kısa, özlü ve derinlikli bir İslami bilgi yaz. Maksimum 140 karakter. Sadece bilgiyi yaz, tırnak veya başlık ekleme. Kullanıcının uygulama diliyle yaz.
        Kullanıcının uygulama dili kodu: \(appLanguageCode).
        """
        let result = try await generate(prompt: prompt)
        return String(result.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generateHikmetNotu(title: String, content: String) async throws -> String {
        let snippet = String(content.prefix(400))
        let prompt = """
        "\(title)" için tek cümlelik, şiirsel ve ilham verici bir Hikmet Notu yaz. Kullanıcının uygulama diliyle yaz, maksimum 130 karakter. Sadece cümleyi yaz, tırnak veya başlık ekleme.
        Kullanıcının uygulama dili kodu: \(appLanguageCode).
        Bağlam: \(snippet.isEmpty ? "Bu bir dua veya zikir paylaşımıdır." : snippet)
        """
        return try await generate(prompt: prompt)
    }

    func generateReflectionNote(progress: Double, streak: Int, prayerCount: Int) async throws -> String {
        let prompt = """
        Bu İslami ilerleme kartı için tek cümlelik, ilham verici bir 'Hikmet Notu' yaz.
        Kullanıcının uygulama diliyle, samimi ve kısa olsun. Sadece cümleyi yaz, başlık veya tırnak ekleme.
        Kullanıcının uygulama dili kodu: \(appLanguageCode).
        Bağlam: %\(Int(progress * 100)) ibadet tamamlanma, \(streak) günlük seri, \(prayerCount)/5 namaz.
        """
        return try await generate(prompt: prompt)
    }

    func maneviAssistantSearch(query: String, entries: [RehberEntry]) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        isSearching = true
        searchError = nil
        aiSearchResults = []
        assistantAdvice = nil
        defer { isSearching = false }

        aiSearchResults = selectGuideEntryMatches(for: trimmedQuery, entries: entries)
        let prompt = String(trimmedQuery.prefix(240))
        do {
            let result = try await generateGuideSearchResponse(prompt: prompt)
            assistantAdvice = compactGuideAdvice(result, query: trimmedQuery)
        } catch {
            print("Groq Error: \(error)")
            searchError = L10n.string(.guideSearchError)
        }
    }

    func semanticDuaSearch(query: String, entries: [RehberEntry]) async {
        await maneviAssistantSearch(query: query, entries: entries)
    }

    func answerSpiritualQuestion(_ question: String) async throws -> String {
        let wantsHadith = wantsHadithResponse(for: question)
        let queryMode = RabiaQuranEmbeddingRetriever.shared.queryMode(for: question, appLanguage: appLanguageCode)
        let retrievedContext = RabiaVerifiedSourceStore.shared.retrieveContext(for: question, includeQuran: false)
        let quranRefs = await retrieveQuranReferences(for: question)
        let promptBundle = buildRabiaInput(
            currentUserMessage: question,
            history: [],
            queryMode: queryMode,
            retrievedContext: retrievedContext,
            quranReferences: quranRefs
        )
        let rawResponse = try await generateRabiaProviderResponse(
            messages: promptBundle.messages,
            queryMode: queryMode,
            wantsReferences: wantsHadith
        )
        let thinkRemoved = RabiaResponseSanitizer.containsThinkBlock(rawResponse)
#if DEBUG
        print("think_block_removed=\(thinkRemoved)")
#endif
        let sanitizedResponse = sanitizeResponse(rawResponse)
        return composeRetrievedResponse(
            context: retrievedContext,
            rawResponse: sanitizedResponse,
            includeSources: wantsHadith,
            allowedQuranRefs: quranRefs,
            queryMode: queryMode
        )
    }

    func answerWithConversationHistory(_ conversationHistory: [GroqChatMessage]) async throws -> String {
        let lastUserMessage = conversationHistory.last(where: { $0.role == "user" })?.content ?? ""
        let wantsHadith = wantsHadithResponse(for: lastUserMessage)
        let queryMode = RabiaQuranEmbeddingRetriever.shared.queryMode(for: lastUserMessage, appLanguage: appLanguageCode)
        let retrievedContext = RabiaVerifiedSourceStore.shared.retrieveContext(for: lastUserMessage, includeQuran: false)
        let quranRefs = await retrieveQuranReferences(for: lastUserMessage)
        let promptBundle = buildRabiaInput(
            currentUserMessage: lastUserMessage,
            history: conversationHistory,
            queryMode: queryMode,
            retrievedContext: retrievedContext,
            quranReferences: quranRefs
        )
        let rawResponse = try await generateRabiaProviderResponse(
            messages: promptBundle.messages,
            queryMode: queryMode,
            wantsReferences: wantsHadith
        )

        let rawTrimmed = rawResponse.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let thinkRemoved = RabiaResponseSanitizer.containsThinkBlock(rawTrimmed)
        let sanitized = sanitizeResponse(rawTrimmed)
#if DEBUG
        print("think_block_removed=\(thinkRemoved)")
#endif
        let filtered = composeRetrievedResponse(
            context: retrievedContext,
            rawResponse: sanitized,
            includeSources: wantsHadith,
            allowedQuranRefs: quranRefs,
            queryMode: queryMode
        )
#if DEBUG
        print("AFTER FILTER:", filtered)
#endif
        return filtered
    }

    private func sendConversationRequest(history: [GroqChatMessage], model: String) async throws -> String {
        _ = model
        return try await answerWithConversationHistory(history)
    }

    func semanticQuranSearch(query: String) async throws -> String {
        let hits = RabiaVerifiedSourceStore.shared.searchQuran(query: query, limit: 5)
        guard !hits.isEmpty else {
            let prompt = """
            Kullanici Kur'an'da "\(query)" konusunda arama yapti fakat dogrulanmis yerel ayet eslesmesi bulunamadi.

            Kurallar:
            - Kullanıcının uygulama diliyle yaz.
            - Kullanıcının uygulama dili kodu: \(appLanguageCode).
            - Ayet veya hadis uydurma.
            - Emin olmadigin bir dini alinti verme.
            - Kisa, sakin ve yardimci bir aciklama yap.
            - Mümkünse kullanicinin aramayi nasil daraltabilecegini oner.

            2 kisa paragrafi gecme.
            """
            return try await generate(prompt: prompt)
        }

        return hits.map { hit in
            """
            "\(hit.translationText)"
            (\(hit.surahId):\(hit.verseNumber))
            """
        }.joined(separator: "\n\n")
    }

    func canAskDailySpiritualQuestion() -> Bool {
        guard let date = UserDefaults.standard.object(forKey: dailyQuestionDateKey) as? Date else { return true }
        return !Calendar.current.isDateInToday(date)
    }

    func markDailySpiritualQuestionAsked() {
        UserDefaults.standard.set(Date(), forKey: dailyQuestionDateKey)
    }

    func zikirProgressAdvice(progress: Double) -> String {
        switch progress {
        case ..<0.2:
            return L10n.string(.dhikrMotivationStart)
        case ..<0.6:
            return L10n.string(.dhikrMotivationMid)
        case ..<0.95:
            return L10n.string(.dhikrMotivationNear)
        default:
            return L10n.string(.dhikrMotivationComplete)
        }
    }

    // MARK: - Private Parsers

    private func normalizeGuideSearchText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9ıüğşöç\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func selectGuideEntryMatches(for query: String, entries: [RehberEntry]) -> [String] {
        let normalizedQuery = normalizeGuideSearchText(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let tokens = normalizedQuery
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 1 }

        let rankedEntries = entries.compactMap { entry -> (id: String, score: Int)? in
            let searchableText = [
                entry.localizedTitle,
                entry.transliteration,
                entry.localizedPurpose,
                entry.localizedMeaning,
                entry.localizedNotes ?? "",
                entry.localizedSchedule ?? "",
                entry.moodTags.joined(separator: " ")
            ].joined(separator: " ")

            let normalizedEntry = normalizeGuideSearchText(searchableText)
            guard !normalizedEntry.isEmpty else { return nil }

            var score = 0
            if normalizedEntry.contains(normalizedQuery) {
                score += 8
            }

            for token in tokens where normalizedEntry.contains(token) {
                score += token.count >= 5 ? 3 : 2
            }

            guard score > 0 else { return nil }
            return (entry.id, score)
        }
        .sorted {
            if $0.score == $1.score {
                return $0.id < $1.id
            }
            return $0.score > $1.score
        }

        if rankedEntries.isEmpty {
            return Array(entries.prefix(3).map(\.id))
        }

        return Array(rankedEntries.prefix(5).map(\.id))
    }

    private func compactGuideAdvice(_ text: String, query: String) -> String {
        let normalized = stripGeneratedQuranCitations(from: text)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let oneSentence = splitIntoSentences(normalized).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? normalized
        let lowered = oneSentence.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")).lowercased()
        let normalizedQuery = normalizeGuideSearchText(query)
        let responseEchoesQuery = !normalizedQuery.isEmpty && normalizeGuideSearchText(oneSentence).contains(normalizedQuery)
        let isGenericWish = lowered.contains("basarilar dilerim") || lowered.contains("bol sans")
        let fallback = fallbackGuideAdvice(for: query)
        let finalText = (oneSentence.isEmpty || isGenericWish || responseEchoesQuery) ? fallback : oneSentence

        guard finalText.count > 160 else { return finalText }
        return String(finalText.prefix(160)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackGuideAdvice(for query: String) -> String {
        let normalizedQuery = normalizeGuideSearchText(query)

        if normalizedQuery.contains("sinav") || normalizedQuery.contains("vize") {
            return "Sakin bir hazirlik ve kisa bir dua, boyle bir gun oncesinde zihnini toparlamaya yardimci olabilir."
        }

        if normalizedQuery.contains("randevu") || normalizedQuery.contains("gorusme") || normalizedQuery.contains("mulakat") {
            return "Onemli bir gorusme oncesi icinin sakinlesmesi icin kisa bir dua iyi gelebilir."
        }

        if normalizedQuery.contains("ameliyat") || normalizedQuery.contains("hastane") {
            return "Zor bir gun oncesinde kalbinin sakinlesmesi icin dua etmek teselli verebilir."
        }

        return "Bu durumda kalbini toparlamak icin kisa bir dua ve sakin bir tefekkur iyi gelebilir."
    }

    private func parseDailyGuidance(_ text: String) -> (wisdom: String, dua: String) {
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var wisdom = ""
        var dua = ""

        for line in lines {
            let upper = line.uppercased()
            if upper.contains("TAVSIYE") || upper.contains("TAVSİYE") {
                wisdom = extractAfterColon(line)
            } else if upper.contains("DUA") {
                dua = extractAfterColon(line)
            }
        }

        let finalWisdom = wisdom.isEmpty ? text : wisdom
        let finalDua = dua.isEmpty ? "Allah'ım, bugünü hayırla tamamlamayı bana nasip eyle." : dua
        return (finalWisdom.trimmingCharacters(in: .whitespacesAndNewlines), finalDua.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func generateRabiaProviderResponse(
        messages: [RabiaMessage],
        queryMode: String,
        wantsReferences: Bool
    ) async throws -> String {
        let providerQueryMode = rabiaProviderQueryMode(for: queryMode)
        let response = try await RabiaProvider.shared.generateRabiaResponse(
            messages: messages,
            queryMode: providerQueryMode,
            wantsReferences: wantsReferences
        )
        recordResolvedModel(response.model, usedFallback: response.usedFallback)
        return response.text
    }

    private func rabiaProviderQueryMode(for queryMode: String) -> RabiaQueryMode {
        switch queryMode {
        case RabiaQueryMode.sensitiveQuestion.rawValue:
            return .sensitiveQuestion
        case RabiaQueryMode.emotionalSupport.rawValue:
            return .emotionalSupport
        case RabiaQueryMode.explicitVerseRequest.rawValue:
            return .explicitVerseRequest
        case RabiaQueryMode.duaDhikrRequest.rawValue:
            return .duaDhikrRequest
        default:
            return .generalKnowledge
        }
    }

    private func buildRabiaInput(
        currentUserMessage: String,
        history: [GroqChatMessage],
        queryMode: String,
        retrievedContext: RabiaRetrievedContext,
        quranReferences: [String]
    ) -> RabiaPromptBundle {
        let mode = RabiaQueryMode(rawValue: queryMode) ?? .generalKnowledge
        let appLanguage = AppLanguage(code: appLanguageCode)
        let historyWithoutCurrentMessage = dropTrailingCurrentUserMessage(
            from: history,
            currentUserMessage: currentUserMessage
        )
        let verifiedKnowledgeText = verifiedKnowledgeBlock(
            for: currentUserMessage,
            queryMode: mode,
            retrievedContext: retrievedContext
        )

        return RabiaContextBuilder.buildRabiaInput(
            currentUserMessage: currentUserMessage,
            history: historyWithoutCurrentMessage,
            appLanguage: appLanguage,
            queryMode: mode,
            verifiedRefs: quranReferences,
            verifiedKnowledgeText: verifiedKnowledgeText
        )
    }

    private func dropTrailingCurrentUserMessage(
        from history: [GroqChatMessage],
        currentUserMessage: String
    ) -> [GroqChatMessage] {
        guard let last = history.last,
              last.role == "user",
              last.content.trimmingCharacters(in: .whitespacesAndNewlines) == currentUserMessage.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return history
        }

        return Array(history.dropLast())
    }

    private func verifiedKnowledgeBlock(
        for query: String,
        queryMode: RabiaQueryMode,
        retrievedContext: RabiaRetrievedContext
    ) -> String? {
        guard queryMode == .generalKnowledge else {
            return localizedKnowledgeCardSummary(from: retrievedContext)
        }

        return verifiedGeneralKnowledgeAnswerBlock(for: query, retrievedContext: retrievedContext)
            ?? localizedKnowledgeCardSummary(from: retrievedContext)
    }

    private func localizedKnowledgeCardSummary(from retrievedContext: RabiaRetrievedContext) -> String? {
        guard let knowledgeCard = retrievedContext.knowledgeCards.first else { return nil }
        let preferredLanguageCodes = RabiaLanguagePolicy.preferredReferenceLanguageCodes(for: appLanguageCode)
        let localizedTitle = knowledgeCard.localizedTitle(preferredLanguageCodes: preferredLanguageCodes) ?? knowledgeCard.localizedTitle
        let localizedSummary = knowledgeCard.localizedSummary(preferredLanguageCodes: preferredLanguageCodes) ?? knowledgeCard.localizedSummary
        return "\(localizedTitle): \(localizedSummary)"
    }

    private func verifiedGeneralKnowledgeAnswerBlock(
        for query: String,
        retrievedContext: RabiaRetrievedContext
    ) -> String? {
        let normalized = query
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9ıüğşöç\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let knownTopics: [(matches: (String) -> Bool, block: String)] = [
            ({ text in
                text.contains("oruc nasil tutulur") || (text.contains("oruc") && text.contains("nasil"))
            }, """
            Oruç, imsak vaktinden akşam ezanına kadar yeme, içme ve cinsel ilişkiden uzak durularak tutulur.
            Sahura kalkmak veya gece niyet etmek yeterlidir.
            Oruç iftar vaktinde açılır.
            Hastalık, yolculuk veya benzeri mazeretlerde hüküm değişebilir.
            """),
            ({ text in
                text.contains("namaz nasil kilinir") || (text.contains("namaz") && text.contains("nasil"))
            }, """
            Namaz için önce abdest alınır, vakit girince niyet edilir ve namaza başlanır.
            Namaz ayakta durma, okuma, rüku, secde ve oturuş sırasıyla kılınır.
            Her namazın rekât sayısı aynı değildir.
            Küçük uygulama farkları olabileceği için temel sıralamayı esas almak en güvenli yoldur.
            """),
            ({ text in
                text.contains("abdest nasil alinir") || (text.contains("abdest") && text.contains("nasil"))
            }, """
            Abdestte önce eller yıkanır, ağız ve buruna su verilir, yüz yıkanır.
            Sonra kollar dirseklerle birlikte yıkanır, baş mesh edilir ve ayaklar topuklarla birlikte yıkanır.
            Suyun ilgili yerlere ulaşması ve abdestin eksiksiz yapılması önemlidir.
            """),
            ({ text in
                text.contains("zekat nasil verilir") || (text.contains("zekat") && text.contains("nasil"))
            }, """
            Zekât, temel ihtiyaçlar dışında nisap miktarı mala sahip olup üzerinden bir kamerî yıl geçen kişiye gerekir.
            Genel kural olarak malın kırkta biri verilir.
            Zekât, zekât alabilecek kimselere verilir.
            Malın türüne ve kişinin durumuna göre hesap değişebileceği için miktar hesabında dikkat gerekir.
            """),
            ({ text in
                text.contains("hac kimlere farzdir") || text.contains("hac kimlere farzdır") || (text.contains("hac") && text.contains("farz"))
            }, """
            Hac, Müslüman, akıllı, ergen ve maddi-bedeni olarak gücü yeten kişiye ömürde bir defa farzdır.
            Yol güvenliği ve gerekli imkanların bulunması da aranır.
            Gücü yetmeyen kimse hac ile yükümlü olmaz.
            """)
        ]

        if let matched = knownTopics.first(where: { $0.matches(normalized) }) {
            return matched.block
        }

        guard let knowledgeCard = retrievedContext.knowledgeCards.first else { return nil }
        let preferredLanguageCodes = RabiaLanguagePolicy.preferredReferenceLanguageCodes(for: appLanguageCode)
        let localizedTitle = knowledgeCard.localizedTitle(preferredLanguageCodes: preferredLanguageCodes) ?? knowledgeCard.localizedTitle
        let localizedSummary = knowledgeCard.localizedSummary(preferredLanguageCodes: preferredLanguageCodes) ?? knowledgeCard.localizedSummary
        return """
        \(localizedTitle): \(localizedSummary)
        """
    }

#if DEBUG
    func buildSourceInstructionForTesting(
        context: RabiaRetrievedContext,
        includeReligiousSources: Bool,
        quranReferences: [String],
        allowDhikrSuggestion: Bool,
        queryMode: String,
        allowRepentanceLanguage: Bool
    ) -> String {
        return RabiaSourceInstructionBuilder.build(
            context: context,
            includeReligiousSources: includeReligiousSources,
            quranReferences: quranReferences,
            allowDhikrSuggestion: allowDhikrSuggestion,
            queryMode: queryMode,
            allowRepentanceLanguage: allowRepentanceLanguage,
            appLanguageCode: appLanguageCode
        )
    }

    func generalKnowledgeRewriteInstructionForTesting(
        query: String,
        retrievedContext: RabiaRetrievedContext
    ) -> String? {
        verifiedKnowledgeBlock(
            for: query,
            queryMode: .generalKnowledge,
            retrievedContext: retrievedContext
        )
    }

    func verifiedGeneralKnowledgeAnswerBlockForTesting(
        query: String,
        retrievedContext: RabiaRetrievedContext
    ) -> String? {
        verifiedGeneralKnowledgeAnswerBlock(for: query, retrievedContext: retrievedContext)
    }
#endif

    private func composeRetrievedResponse(
        context: RabiaRetrievedContext,
        rawResponse: String,
        includeSources: Bool,
        allowedQuranRefs: [String] = [],
        queryMode: String
    ) -> String {
        let resolvedLanguageCode = appLanguageCode
        let cleanedExplanation = normalizeRabiaResponse(stripGeneratedQuranCitations(from: rawResponse))
        let allowedSet = Set(allowedQuranRefs)

#if DEBUG
        if !allowedQuranRefs.isEmpty {
            let joined = allowedQuranRefs.joined(separator: ",")
            print("[RabiaQuranSafe] retrieved_refs=\(joined)")
        } else {
            print("[RabiaQuranSafe] retrieved_refs=none")
        }
        print("no_ref_hard_block_applied=\(allowedSet.isEmpty)")
#endif

        let quranFiltered = RabiaQuranSafetyFilter.apply(
            rawResponse: cleanedExplanation,
            allowedRefs: allowedSet
        )
        let explanationWithoutLocalizedInsertions = quranFiltered.isEmpty
            ? RabiaQuranSafetyFilter.apply(rawResponse: cleanedExplanation, allowedRefs: [])
            : quranFiltered
        let quranInjected = RabiaQuranSafetyFilter.renderVerifiedReferences(
            in: quranFiltered,
            allowedRefs: allowedSet
        )
        let explanation = quranInjected.isEmpty
            ? explanationWithoutLocalizedInsertions
            : quranInjected
        let filteredExplanation = queryMode == "sensitive_question"
            ? enforceSensitiveExplanationOnly(in: explanation)
            : explanation
        let languageSafeBaseExplanation = queryMode == "sensitive_question"
            ? enforceSensitiveExplanationOnly(in: explanationWithoutLocalizedInsertions)
            : explanationWithoutLocalizedInsertions
        let hasLanguageMismatch = RabiaLanguagePolicy.hasObviousLanguageMismatch(
            filteredExplanation,
            expectedLanguageCode: resolvedLanguageCode
        )
        let finalExplanation = hasLanguageMismatch ? languageSafeBaseExplanation : filteredExplanation
        let sourceBlock = (includeSources && queryMode != "sensitive_question" && !hasLanguageMismatch)
            ? buildDisplaySourceBlock(context: context, appLanguageCode: resolvedLanguageCode)
            : ""

#if DEBUG
        print("[RabiaLanguage] expected=\(resolvedLanguageCode) mismatch=\(hasLanguageMismatch)")
#endif

        if finalExplanation.isEmpty {
            return sourceBlock
        }

        guard !sourceBlock.isEmpty else {
            return finalExplanation
        }

        return "\(finalExplanation)\n\n\(sourceBlock)"
    }

    private func stripGeneratedQuranCitations(from text: String) -> String {
        text
            .replacingOccurrences(of: #"(?im)^\s*\([^()\n]*Suresi[^()\n]*\)\s*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?im)^\s*\([^()\n]*(Buh[aâ]r[iî]|M[üu]slim)[^()\n]*\)\s*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*\((?:[A-ZÇĞİÖŞÜa-zçğıöşüÂâÎîÛû'\-]+)\s+\d{1,3}(?::\d{1,3})?\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?im)^\s*".*"\s*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildDisplaySourceBlock(context: RabiaRetrievedContext, appLanguageCode: String) -> String {
        let preferredLanguageCodes = RabiaLanguagePolicy.preferredReferenceLanguageCodes(for: appLanguageCode)

        if let hadith = context.hadiths.first {
            let localizedText = hadith.localizedText(preferredLanguageCodes: preferredLanguageCodes)?.value
            let localizedCollection = hadith.localizedCollection(preferredLanguageCodes: preferredLanguageCodes)?.value ?? hadith.collection
            let localizedReference = hadith.localizedReference(preferredLanguageCodes: preferredLanguageCodes)?.value ?? hadith.reference

            if let localizedText, !localizedText.isEmpty {
                return """
                "\(localizedText)"
                (\(localizedCollection) \(localizedReference))
                """
            }

            return """
            (\(localizedCollection) \(localizedReference))
            """
        }

        return ""
    }

    private func wantsHadithResponse(for text: String) -> Bool {
        let normalized = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()

        let triggers = [
            "hadis", "hadith", "rivayet", "sahih", "buhari", "muslim", "tirmizi", "ebu davud", "ebu davud"
        ]

        return triggers.contains { normalized.contains($0) }
    }

    private func wantsDhikrSuggestion(for text: String) -> Bool {
        let normalized = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()

        let triggers = [
            "zikir", "dhikr", "tesbih", "tesbihat", "tasbih", "tesbi̇h", "dua", "du'a", "vird", "evrad",
            "okuyayim", "okuyayım", "okumak", "cekeyim", "çekeyim", "cekmek", "çekmek", "ne okuyayim",
            "ne okuyayım", "ne cekeyim", "ne çekeyim", "prayer", "supplication", "remembrance"
        ]

        return triggers.contains { normalized.contains($0) }
    }

    private func shouldUseRepentanceLanguage(for text: String, queryMode: String) -> Bool {
        guard queryMode == "sensitive_question" else { return false }
        let normalized = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()

        let repentanceTriggers = [
            "affeder mi", "allah beni affeder", "beni affeder", "bagislar mi", "bağışlar mı",
            "tevbe", "tövbe", "tevbe etmek istiyorum", "tövbe etmek istiyorum",
            "gunahkar", "günahkar", "cok gunah", "çok günah", "günah işledim",
            "pişmanım", "pismanim", "suclu hissediyorum", "suçlu hissediyorum",
            "bagislanmak", "bağışlanmak", "af diliyorum", "af istiyorum"
        ]

        return repentanceTriggers.contains { normalized.contains($0) }
    }

    private func retrieveQuranReferences(for query: String) async -> [String] {
        let appLanguage = appLanguageCode
#if DEBUG
        let mode = RabiaQuranEmbeddingRetriever.shared.queryMode(for: query, appLanguage: appLanguage)
        let explicitVerseMode = mode == "explicit_verse_request"
        print("query_mode=\(mode)")
        print("explicit_verse_mode=\(explicitVerseMode)")
#endif
        if RabiaQuranEmbeddingRetriever.shared.queryMode(for: query, appLanguage: appLanguage) != "explicit_verse_request" {
#if DEBUG
            print("[RabiaQuranEmbedding] injected_refs=none")
#endif
            return []
        }
        let refs = await quranEmbeddingRetriever.retrieveRefs(
            for: query,
            appLanguage: appLanguage,
            topK: quranRefLimit,
            threshold: quranRefThreshold
        )
        var refStrings = refs.map { $0.ref }

        if refStrings.isEmpty {
            let fallbackHits = RabiaVerifiedSourceStore.shared.searchQuran(query: query, limit: max(quranRefLimit, 4))
            refStrings = Array(
                NSOrderedSet(array: fallbackHits.map { "\($0.surahId):\($0.verseNumber)" })
            )
            .compactMap { $0 as? String }

#if DEBUG
            if refStrings.isEmpty {
                print("[RabiaQuranEmbedding] fallback_refs=none")
            } else {
                let joinedFallback = refStrings.joined(separator: ",")
                print("[RabiaQuranEmbedding] fallback_refs=\(joinedFallback)")
            }
#endif
        }

#if DEBUG
        if refStrings.isEmpty {
            print("[RabiaQuranEmbedding] injected_refs=none")
        } else {
            let joined = refStrings.joined(separator: ",")
            print("[RabiaQuranEmbedding] injected_refs=\(joined)")
        }
#endif
        return refStrings
    }

    private func normalizeRabiaResponse(_ text: String) -> String {
        let withoutMarkdown = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: #"(?m)^\s*\d+\.\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?m)^\s*[-•]\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let paragraphs = withoutMarkdown
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(paragraphs.prefix(2)).joined(separator: "\n\n")
    }

    private func enforceSensitiveExplanationOnly(in text: String) -> String {
        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let filteredParagraphs = paragraphs.compactMap { paragraph -> String? in
            let sentences = splitIntoSentences(paragraph).filter { !containsSensitiveActionCue($0) }
            let joined = sentences.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            return joined.isEmpty ? nil : joined
        }

        if !filteredParagraphs.isEmpty {
            return Array(filteredParagraphs.prefix(2)).joined(separator: "\n\n")
        }

        let survivingSentences = splitIntoSentences(text).filter { !containsSensitiveActionCue($0) }
        return survivingSentences.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return [] }

        let pattern = #"[^.!?\u2026]+[.!?\u2026]?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [normalized]
        }

        let nsText = normalized as NSString
        let matches = regex.matches(in: normalized, range: NSRange(location: 0, length: nsText.length))
        return matches
            .map { nsText.substring(with: $0.range).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func containsSensitiveActionCue(_ sentence: String) -> Bool {
        let normalized = sentence
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9ıİüğşöç\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let bannedFragments = [
            "dua et",
            "dua etmek",
            "dua edebilirsin",
            "dua okuyabilirsin",
            "dua istersen",
            "allah a sigin",
            "allaha sigin",
            "allah in rahmetine sigin",
            "allahin rahmetine sigin",
            "allah a yonel",
            "allaha yonel",
            "manevi destek istersen",
            "guvenilir bir alim",
            "alimle gorus",
            "biriyle konus",
            "destek al",
            "yardim al",
            "istersen",
            "dilersen",
            "yapmalisin",
            "sunu yap",
            "şunu yap",
            "dua etmeni",
            "zikir cek",
            "zikir çek"
        ]

        return bannedFragments.contains { normalized.contains($0) }
    }

#if DEBUG
    func applyQuranSafetyForTesting(rawResponse: String, allowedRefs: [String]) -> String {
        let context = RabiaRetrievedContext(quranVerses: [], hadiths: [], knowledgeCards: [])
        return composeRetrievedResponse(
            context: context,
            rawResponse: rawResponse,
            includeSources: false,
            allowedQuranRefs: allowedRefs,
            queryMode: "general_knowledge"
        )
    }

    func sensitiveExplanationOnlyForTesting(_ text: String) -> String {
        enforceSensitiveExplanationOnly(in: text)
    }

    func primaryModelForTesting() -> String {
        primaryModel
    }

    func fallbackModelsForTesting() -> [String] {
        []
    }

    func recordResolvedModelForTesting(_ model: String) {
        recordResolvedModel(model, usedFallback: false)
    }
#endif

    private func recordResolvedModel(_ model: String, usedFallback: Bool) {
#if DEBUG
        lastResolvedModel = model
        lastResolvedModelUsedFallback = usedFallback
#endif
    }

#if DEBUG
    func didLastResponseUseFallbackForTesting() -> Bool {
        lastResolvedModelUsedFallback
    }
#endif

    private func parseAssistantResponse(_ text: String) {
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for line in lines {
            guard let colonIdx = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colonIdx]).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let value = String(line[line.index(after: colonIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)

            if key.contains("DLER") || key == "IDS" || key == "ID" || key == "IDLER" {
                let cleaned = value.trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
                aiSearchResults = cleaned
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            } else if key.contains("TAVS") || key.contains("ADVICE") || key.contains("ÖNERI") || key.contains("ONERI") {
                assistantAdvice = value.isEmpty ? nil : value
            }
        }
    }

    private func extractAfterColon(_ line: String) -> String {
        guard let colonIdx = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: colonIdx)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizeResponse(_ text: String) -> String {
        let sanitized = RabiaResponseSanitizer.sanitize(text)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        return sanitized.isEmpty
            ? "Su an yalnizca son cevabi paylasabiliyorum. Sorunu tekrar biraz daha kisa yazarsan yardimci olayim."
            : sanitized
    }
}
