import Foundation

nonisolated struct RabiaMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated enum RabiaLLMProvider: String, Sendable {
    case backend
}

nonisolated struct RabiaResponse: Sendable {
    let text: String
    let provider: RabiaLLMProvider
    let model: String
    let usedFallback: Bool
}

nonisolated enum RabiaProviderError: LocalizedError, Sendable {
    case httpError(provider: RabiaLLMProvider, statusCode: Int, body: String)
    case emptyResponse(provider: RabiaLLMProvider)

    var errorDescription: String? {
        switch self {
        case .httpError(let provider, let statusCode, _):
            return "\(provider.rawValue) API \(statusCode) hatası"
        case .emptyResponse(let provider):
            return "\(provider.rawValue) yanıt vermedi"
        }
    }
}

actor RabiaProvider {
    static let shared = RabiaProvider()

    private let backendModel = "gpt-4.1-mini"
    private let textGenerationService = BackendTextGenerationService()

    func generateRabiaResponse(
        messages: [RabiaMessage],
        queryMode: RabiaQueryMode,
        wantsReferences: Bool
    ) async throws -> RabiaResponse {
        let provider: RabiaLLMProvider = .backend
        Swift.print("[RabiaProvider] selected_provider=\(provider.rawValue)")
        logRequestStart(
            provider: provider,
            model: backendModel,
            queryMode: queryMode,
            wantsReferences: wantsReferences,
            messageCount: messages.count
        )

        do {
            let payload = serializedPayload(
                messages: messages,
                queryMode: queryMode,
                wantsReferences: wantsReferences
            )
            let text = try await textGenerationService.generate(
                message: payload,
                instructions: "Return only the requested final answer text.",
                appLanguage: RabiaAppLanguage.currentCode(),
                maxOutputTokens: 700,
                temperature: 0.3
            )
            let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw RabiaProviderError.emptyResponse(provider: provider)
            }

            Swift.print("[RabiaProvider] response_success provider=\(provider.rawValue) request_model=\(backendModel) chars=\(trimmed.count)")
            return RabiaResponse(text: trimmed, provider: provider, model: backendModel, usedFallback: false)
        } catch {
            logFailure(provider: provider, model: backendModel, error: error)
            return gracefulErrorResponse(provider: provider, model: backendModel)
        }
    }

    private func logRequestStart(
        provider: RabiaLLMProvider,
        model: String,
        queryMode: RabiaQueryMode,
        wantsReferences: Bool,
        messageCount: Int
    ) {
        Swift.print("[RabiaProvider] provider=\(provider.rawValue)")
        Swift.print("[RabiaProvider] request_model=\(model)")
        Swift.print("[RabiaProvider] request_start provider=\(provider.rawValue) query_mode=\(queryMode.rawValue) wants_references=\(wantsReferences) messages=\(messageCount)")
    }

    private func logFailure(provider: RabiaLLMProvider, model: String, error: Error) {
        Swift.print("[RabiaProvider] response_failure provider=\(provider.rawValue) request_model=\(model) error=\(error)")
    }

    private func gracefulErrorResponse(
        provider: RabiaLLMProvider,
        model: String,
        usedFallback: Bool = false
    ) -> RabiaResponse {
        RabiaResponse(
            text: localizedGracefulErrorText(),
            provider: provider,
            model: model,
            usedFallback: usedFallback
        )
    }

    private func localizedGracefulErrorText() -> String {
        switch AppLanguage(code: RabiaAppLanguage.currentCode()) {
        case .tr:
            return "Su an kisa ve net bir cevap veremiyorum. Sorunu biraz daha kisa yazarsan tekrar deneyebilirim."
        case .en:
            return "I can't give a clear short answer right now. If you write it a little shorter, I can try again."
        case .de:
            return "Ich kann im Moment keine kurze klare Antwort geben. Wenn du es etwas kurzer schreibst, kann ich es erneut versuchen."
        case .ar:
            return "لا أستطيع تقديم جواب قصير وواضح الآن. إذا كتبت السؤال باختصار أكثر يمكنني المحاولة مرة أخرى."
        case .fr:
            return "Je ne peux pas donner une reponse courte et claire pour le moment. Si vous l'ecrivez un peu plus court, je peux reessayer."
        case .es:
            return "Ahora no puedo dar una respuesta breve y clara. Si lo escribes un poco mas corto, puedo intentarlo de nuevo."
        case .id:
            return "Saat ini saya belum bisa memberi jawaban singkat yang jelas. Jika ditulis sedikit lebih ringkas, saya bisa mencoba lagi."
        case .ur:
            return "میں ابھی مختصر اور واضح جواب نہیں دے پا رہی۔ اگر سوال تھوڑا مختصر لکھیں تو میں دوبارہ کوشش کر سکتی ہوں۔"
        case .ms:
            return "Saya belum dapat memberi jawapan yang ringkas dan jelas sekarang. Jika ditulis sedikit lebih pendek, saya boleh cuba lagi."
        case .ru:
            return "Сейчас я не могу дать короткий и ясный ответ. Если напишете чуть короче, я попробую еще раз."
        case .fa:
            return "الان نمي توانم پاسخى كوتاه و روشن بدهم. اگر سوال را كمي كوتاه تر بنويسيد دوباره تلاش مي كنم."
        }
    }

    private func serializedPayload(
        messages: [RabiaMessage],
        queryMode: RabiaQueryMode,
        wantsReferences: Bool
    ) -> String {
        let transcript = messages
            .map { "\($0.role.uppercased()): \($0.content)" }
            .joined(separator: "\n\n")

        return """
        Query mode: \(queryMode.rawValue)
        Wants references: \(wantsReferences ? "yes" : "no")

        \(transcript)
        """
    }
}
