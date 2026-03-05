import Foundation

nonisolated struct GroqChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct GroqChatRequest: Encodable, Sendable {
    let model: String
    let messages: [GroqChatMessage]
    let stream: Bool
}

nonisolated struct GroqChatChoice: Decodable, Sendable {
    let index: Int
    let message: GroqChatMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

nonisolated struct GroqChatResponse: Decodable, Sendable {
    let choices: [GroqChatChoice]
}

nonisolated enum GroqError: LocalizedError, Sendable {
    case httpError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .httpError(let code, _):
            return "Groq API \(code) hatası"
        case .emptyResponse:
            return "Groq yanıt vermedi"
        }
    }
}

nonisolated struct KhutbahInsight: Sendable {
    let theme: String
    let practicalPoints: [String]
    let weeklyTask: String
}

@Observable
@MainActor
final class GroqService {

    private let systemPrompt: String = "Sen Rabia, kullanıcının manevi yol arkadaşısın. SADECE İslami konularda (ibadet, dua, zikir, ahlak, iman, Kur'an, hadis, siyer, fıkıh, tasavvuf, manevi gelişim) sorulara cevap ver. İslami olmayan sorulara (politika, spor, teknoloji, eğlence vb.) nazikçe 'Ben sadece İslami ve manevi konularda yardımcı olabilirim 💚' diyerek geri çevir. Cevaplarında mümkün olduğunca Kur'an ayetleri ve hadis-i şeriflerden örnekler ver — kaynak belirt (sure adı ve ayet numarası, hadis kaynağı). Konuşma tarzın sıcak, candan ve samimi olsun — sanki yıllardır tanıdığın bir dostunla konuşuyorsun. Sorulara doğrudan ve net cevap ver. Gereksiz giriş veya klişe kalıplar kullanma. Tartışmalı konularda ise nazikçe, birden fazla görüşü aktararak yönlendir. Sadece Türkçe konuş."
    private let apiKey: String = Config.GROQ_API_KEY
    private let apiEndpointBase: String = Config.GROQ_API_BASE_URL
    private let primaryModel: String = Config.GROQ_MODEL
    private let fallbackModel: String = Config.GROQ_FALLBACK_MODEL
    private let maxRetryAttempts: Int = 3
    private let maxBackoffSeconds: Double = 8
    private let retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    private let retryableURLCodes: Set<URLError.Code> = [.timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost]
    private let jitterRange: ClosedRange<Double> = 0...0.35

    var dailyWisdom: String? = nil
    var dailyAIDua: String? = nil
    var isLoadingWisdom: Bool = false
    var isLoadingAIDua: Bool = false
    
    var aiSearchResults: [String] = []
    var assistantAdvice: String? = nil
    var isSearching: Bool = false
    var searchError: String? = nil

    private let wisdomCacheKey = "groq_daily_wisdom_v3"
    private let wisdomDateKey = "groq_daily_wisdom_date_v3"
    private let aiDuaCacheKey = "groq_daily_dua_v3"
    private let dailyQuestionDateKey = "groq_maneviyata_sor_date_v1"

    func generate(prompt: String) async throws -> String {
        let models: [String] = [primaryModel, fallbackModel]
        var lastError: Error? = nil

        for (index, model) in models.enumerated() {
            do {
                let text = try await generateWithRetry(prompt: prompt, model: model)
                if index > 0 {
                    print("[GroqService] ℹ️ Fallback model kullanıldı: \(model)")
                }
                return text
            } catch {
                lastError = error
                print("[GroqService] ❌ model \(model) başarısız — \(error)")
                if index < models.count - 1 {
                    continue
                }
            }
        }

        throw lastError ?? GroqError.emptyResponse
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
                print("[GroqService] ⏳ Retry \(attempt + 1)/\(maxRetryAttempts) | model: \(model) | bekleme: \(String(format: "%.2f", waitSeconds))s")
                try await Task.sleep(for: .seconds(waitSeconds))
                attempt += 1
            }
        }
    }

    private func sendGenerateRequest(prompt: String, model: String) async throws -> String {
        guard !apiEndpointBase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw URLError(.badURL)
        }

        let normalizedBase: String = apiEndpointBase.hasSuffix("/") ? String(apiEndpointBase.dropLast()) : apiEndpointBase
        guard let url = URL(string: "\(normalizedBase)/chat/completions") else {
            print("Groq Error: Bad URL — \(normalizedBase)/chat/completions")
            throw URLError(.badURL)
        }

        let messages: [GroqChatMessage] = [
            GroqChatMessage(role: "system", content: systemPrompt),
            GroqChatMessage(role: "user", content: prompt)
        ]
        let body = GroqChatRequest(
            model: model,
            messages: messages,
            stream: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 45

        print("[GroqService] 🚀 Request → model: \(model) | prompt: \(prompt.prefix(60))…")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            let statusCode = http.statusCode
            print("[GroqService] 📡 HTTP Status: \(statusCode) | model: \(model)")
            if !(200...299).contains(statusCode) {
                let bodyStr = String(data: data, encoding: .utf8) ?? "(boş yanıt)"
                throw GroqError.httpError(statusCode, bodyStr)
            }
        }

        let decoded: GroqChatResponse
        do {
            decoded = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "(parse edilemedi)"
            print("Groq Error: JSON decode — \(error) | Yanıt: \(raw.prefix(300))")
            throw error
        }

        guard let text = decoded.choices.first?.message.content, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let raw = String(data: data, encoding: .utf8) ?? "(boş)"
            print("Groq Error: response boş — \(raw.prefix(300))")
            throw GroqError.emptyResponse
        }

        print("[GroqService] ✅ Yanıt alındı (\(text.count) karakter) | model: \(model)")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
            Sen İslami manevi bir rehbersin.
            Bugün için:
            1) Kısa, uygulanabilir bir manevi tavsiye ver.
            2) Kısa bir günlük dua ver.

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

    func summarizeKhutbah(_ text: String) async throws -> KhutbahInsight {
        let cleaned = stripPlainText(text)
        let truncated = String(cleaned.prefix(4000))
        let prompt = """
        Sen İslami hutbeler konusunda uzman bir asistansın. Aşağıdaki Cuma hutbesini Türkçe olarak analiz et.

        SADECE şu formatta yanıt ver, her başlık ayrı satırda olsun:
        [📍 Ana Tema]: Hutbenin tek cümlelik ana teması
        [📖 3 Önemli Ders]: Birinci önemli ders
        [📖 3 Önemli Ders]: İkinci önemli ders
        [📖 3 Önemli Ders]: Üçüncü önemli ders
        [🌱 Haftalık Uygulama]: Bu hafta yapılacak tek somut görev

        Hutbe:
        \(truncated)
        """
        let result = try await generate(prompt: prompt)
        return parseKhutbahInsight(result)
    }

    private func stripPlainText(_ input: String) -> String {
        var text = input
        while let range = text.range(of: "<[^>]+>", options: .regularExpression) {
            text.replaceSubrange(range, with: "")
        }
        return text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func zikirSpiritualInsight(for zikirName: String) async throws -> String {
        let prompt = """
        "\(zikirName)" zikriyle ilgili kısa, özlü ve derinlikli bir manevi bilgi yaz. Maksimum 140 karakter. Sadece bilgiyi yaz, tırnak veya başlık ekleme. Türkçe.
        """
        let result = try await generate(prompt: prompt)
        return String(result.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generateHikmetNotu(title: String, content: String) async throws -> String {
        let snippet = String(content.prefix(400))
        let prompt = """
        "\(title)" için tek cümlelik, şiirsel ve ilham verici bir Hikmet Notu yaz. Türkçe, maksimum 130 karakter. Sadece cümleyi yaz, tırnak veya başlık ekleme.
        Bağlam: \(snippet.isEmpty ? "Bu bir dua veya zikir paylaşımıdır." : snippet)
        """
        return try await generate(prompt: prompt)
    }

    func generateReflectionNote(progress: Double, streak: Int, prayerCount: Int) async throws -> String {
        let prompt = """
        Bu manevi ilerleme kartı için tek cümlelik, ilham verici bir 'Hikmet Notu' yaz.
        Türkçe, samimi ve kısa olsun. Sadece cümleyi yaz, başlık veya tırnak ekleme.
        Bağlam: %\(Int(progress * 100)) manevi tamamlanma, \(streak) günlük seri, \(prayerCount)/5 namaz.
        """
        return try await generate(prompt: prompt)
    }

    func maneviAssistantSearch(query: String, entries: [RehberEntry]) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        searchError = nil
        aiSearchResults = []
        assistantAdvice = nil
        defer { isSearching = false }

        let titles = entries.prefix(100)
            .map { "[\($0.id)]: \($0.title) — \($0.purpose)" }
            .joined(separator: "\n")

        let prompt = """
        Sen bir Manevi Asistansın. Kullanıcı şunu yazdı: "\(query)"

        GÖREV 1: Aşağıdaki listeden bu duruma/ihtiyaca en uygun 3-5 dua/zikrin ID'sini seç.
        GÖREV 2: Kullanıcıya samimi, 1-2 cümle Türkçe manevi tavsiye yaz.

        SADECE şu formatta yanıt ver:
        IDler: [id1,id2,id3]
        Tavsiye: [tavsiye metni]

        Liste:
        \(titles)
        """
        do {
            let result = try await generate(prompt: prompt)
            parseAssistantResponse(result)
        } catch {
            print("Groq Error: \(error)")
            searchError = "Manevi Asistan şu an yanıt veremiyor"
        }
    }

    func semanticDuaSearch(query: String, entries: [RehberEntry]) async {
        await maneviAssistantSearch(query: query, entries: entries)
    }

    func answerSpiritualQuestion(_ question: String) async throws -> String {
        let prompt = """
        Kullanıcı sana soruyor: "\(question)"

        ÖNEMLİ KURALLAR:
        1. Eğer soru İslami veya manevi bir konu DEĞİLSE, nazikçe "Ben sadece İslami ve manevi konularda yardımcı olabilirim 💚 Dini bir sorun varsa seve seve cevaplarım." de ve başka bir şey ekleme.
        2. Eğer İslami bir soruysa:
           - Doğrudan ve candan cevap ver. Uzun girişler yapma, hemen konuya gir.
           - Cevabında mutlaka ilgili Kur'an ayeti (sure adı ve ayet numarası ile) veya hadis-i şerif (kaynağı ile birlikte, ör: Buhârî, Müslim, Tirmizî) örnekleri ver.
           - Samimi bir dost gibi konuş ama bilgiye sadık kal.
           - Tartışmalı konularda birden fazla görüşü kısaca belirt.
        3. Sadece Türkçe.
        """
        return try await generate(prompt: prompt)
    }

    func semanticQuranSearch(query: String) async throws -> String {
        let prompt = """
        Kullanıcı Kur'an'da şu konu hakkında ayet arıyor: "\(query)"

        En ilgili 5 ayeti aşağıdaki formatta ver:
        [SureAdı:AyetNo] kısa Türkçe meal özeti

        Sadece bu formatta cevap ver, başka açıklama ekleme.
        """
        return try await generate(prompt: prompt)
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
            return "Bismillah, bugün güzel bir başlangıç yaptın. Küçük adımlar da çok kıymetli."
        case ..<0.6:
            return "Maşallah, düzenli devam ediyorsun. Birkaç tekrar daha kalbine ferahlık verecek."
        case ..<0.95:
            return "Harika gidiyorsun, bugünkü zikirlerini tamamlamaya çok az kaldı!"
        default:
            return "Maşallah, bugünkü zikrini tamamladın. Allah kabul etsin."
        }
    }

    // MARK: - Private Parsers

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

    private func parseKhutbahInsight(_ text: String) -> KhutbahInsight {
        var theme = ""
        var practical: [String] = []
        var weeklyTask = ""

        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for line in lines {
            let up = line.uppercased()
            if up.contains("ANA TEMA") || up.contains("📍") {
                let v = extractAfterColon(line)
                if !v.isEmpty && theme.isEmpty { theme = v }
            } else if up.contains("ÖNEMLİ DERS") || up.contains("ONEMLI DERS") || up.contains("📖") || up.contains("PRATIK") {
                let v = extractAfterColon(line)
                if !v.isEmpty && practical.count < 3 { practical.append(v) }
            } else if up.contains("HAFTALIK") || up.contains("🌱") || up.contains("UYGULAMA") {
                let v = extractAfterColon(line)
                if !v.isEmpty && weeklyTask.isEmpty { weeklyTask = v }
            } else if up.hasPrefix("ANA_TEMA:") {
                let v = extractAfter("ANA_TEMA:", in: line)
                if !v.isEmpty && theme.isEmpty { theme = v }
            } else if up.hasPrefix("PRATIK_") {
                let v = extractAfterColon(line)
                if !v.isEmpty && practical.count < 3 { practical.append(v) }
            } else if up.hasPrefix("HAFTALIK_ODEV:") {
                let v = extractAfter("HAFTALIK_ODEV:", in: line)
                if !v.isEmpty && weeklyTask.isEmpty { weeklyTask = v }
            }
        }

        let validPractical = practical.filter { !$0.isEmpty }
        return KhutbahInsight(
            theme: theme.isEmpty ? "Bu haftanın hutbesi işlendi" : theme,
            practicalPoints: validPractical.isEmpty
                ? ["Günlük ibadetlere devam edin", "Bir yakınınıza iyilik yapın", "Zikir ile günü kapatın"]
                : validPractical,
            weeklyTask: weeklyTask.isEmpty ? "Bu hafta en az bir kişiye iyilikte bulunun" : weeklyTask
        )
    }

    private func extractAfterColon(_ line: String) -> String {
        guard let colonIdx = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: colonIdx)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractAfter(_ prefix: String, in line: String) -> String {
        guard line.uppercased().hasPrefix(prefix.uppercased()) else { return "" }
        return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
