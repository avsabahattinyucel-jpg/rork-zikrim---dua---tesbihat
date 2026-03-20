import Foundation

private struct BackendTextGenerationRequest: Encodable {
    let message: String
    let instructions: String
    let appLanguage: String
    let maxOutputTokens: Int?
    let temperature: Double?
}

private struct BackendTextGenerationResponse: Decodable {
    let reply: String
}

final class BackendTextGenerationService {
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    func generate(
        message: String,
        instructions: String,
        appLanguage: String = RabiaAppLanguage.currentCode(),
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil
    ) async throws -> String {
        var request = URLRequest(url: AIBackendConfiguration.endpoint(path: "api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONEncoder().encode(
            BackendTextGenerationRequest(
                message: message,
                instructions: instructions,
                appLanguage: RabiaAppLanguage.normalizedCode(for: appLanguage),
                maxOutputTokens: maxOutputTokens,
                temperature: temperature
            )
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RabiaServiceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw RabiaServiceError.httpStatus(httpResponse.statusCode, raw)
        }

        do {
            let decoded = try JSONDecoder().decode(BackendTextGenerationResponse.self, from: data)
            return decoded.reply
        } catch {
            throw RabiaServiceError.decodingFailure(error)
        }
    }
}
