import Foundation

struct RabiaBackendHistoryItem: Encodable {
    let role: String
    let text: String
}

struct RabiaBackendRequest: Encodable {
    let message: String
    let history: [RabiaBackendHistoryItem]
    let currentAppLanguage: String
    let runtimeContext: RabiaRuntimeContext?
}

struct RabiaBackendResponse: Decodable {
    let reply: String
}

enum RabiaServiceError: LocalizedError {
    case invalidResponse
    case httpStatus(Int, String)
    case decodingFailure(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpStatus(let statusCode, let raw):
            return raw.isEmpty ? "HTTP \(statusCode)" : raw
        case .decodingFailure:
            return "Failed to decode server response"
        }
    }
}

final class RabiaService {
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    func send(
        message: String,
        appLanguage: String = RabiaAppLanguage.currentCode(),
        runtimeContext: RabiaRuntimeContext? = nil,
        history: [RabiaBackendHistoryItem] = []
    ) async throws -> String {
        var request = URLRequest(url: AIBackendConfiguration.endpoint(path: "api/rabia"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONEncoder().encode(
            RabiaBackendRequest(
                message: message,
                history: history,
                currentAppLanguage: RabiaAppLanguage.normalizedCode(for: appLanguage),
                runtimeContext: runtimeContext
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
            let decoded = try JSONDecoder().decode(RabiaBackendResponse.self, from: data)
            return decoded.reply
        } catch {
            throw RabiaServiceError.decodingFailure(error)
        }
    }
}
