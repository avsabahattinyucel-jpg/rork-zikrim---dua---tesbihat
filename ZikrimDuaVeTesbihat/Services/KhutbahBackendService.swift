import Foundation

nonisolated struct KhutbahSummaryRecord: Codable, Sendable {
    let hutbahId: String
    let title: String
    let date: String
    let language: String
    let summary: String
    let generatedAt: String
    let model: String?
}

private nonisolated struct KhutbahSummaryResponse: Codable, Sendable {
    let hutbahId: String
    let title: String
    let date: String
    let language: String
    let summary: String
    let generatedAt: String
    let model: String?
}

nonisolated enum KhutbahBackendServiceError: LocalizedError, Sendable {
    case invalidResponse
    case httpStatus(Int, String)
    case decodingFailure(Error)
    case emptySummary

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .httpStatus(let statusCode, let raw):
            if let data = raw.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String,
               !error.isEmpty {
                return error
            }
            return raw.isEmpty ? "HTTP \(statusCode)" : raw
        case .decodingFailure:
            return "Sunucu yanıtı çözülemedi"
        case .emptySummary:
            return "Haftalık hutbe özeti bulunamadı"
        }
    }
}

final class KhutbahBackendService {
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchSummary(
        language: String,
        hutbahId: String,
        title: String,
        date: String
    ) async throws -> KhutbahSummaryRecord {
        let normalizedLanguage = RabiaAppLanguage.normalizedCode(for: language)
        do {
            let decoded = try await requestSummary(language: normalizedLanguage, hutbahId: hutbahId)
            return try mapSummary(decoded, fallbackTitle: title, fallbackDate: date, fallbackLanguage: normalizedLanguage)
        } catch let error as KhutbahBackendServiceError {
            if case .httpStatus(404, _) = error {
                let decoded = try await requestSummary(language: normalizedLanguage, hutbahId: nil)
                return try mapSummary(decoded, fallbackTitle: title, fallbackDate: date, fallbackLanguage: normalizedLanguage)
            }
            throw error
        }
    }

    private func requestSummary(
        language: String,
        hutbahId: String?
    ) async throws -> KhutbahSummaryResponse {
        var components = URLComponents(url: AIBackendConfiguration.endpoint(path: "api/khutbah-summary"), resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem(name: "language", value: language)]
        if let hutbahId, !hutbahId.isEmpty {
            queryItems.append(URLQueryItem(name: "hutbahId", value: hutbahId))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw KhutbahBackendServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KhutbahBackendServiceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw KhutbahBackendServiceError.httpStatus(httpResponse.statusCode, raw)
        }

        do {
            return try JSONDecoder().decode(KhutbahSummaryResponse.self, from: data)
        } catch {
            throw KhutbahBackendServiceError.decodingFailure(error)
        }
    }

    private func mapSummary(
        _ decoded: KhutbahSummaryResponse,
        fallbackTitle: String,
        fallbackDate: String,
        fallbackLanguage: String
    ) throws -> KhutbahSummaryRecord {
        guard !decoded.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw KhutbahBackendServiceError.emptySummary
        }

        return KhutbahSummaryRecord(
            hutbahId: decoded.hutbahId,
            title: decoded.title.isEmpty ? fallbackTitle : decoded.title,
            date: decoded.date.isEmpty ? fallbackDate : decoded.date,
            language: decoded.language.isEmpty ? fallbackLanguage : decoded.language,
            summary: decoded.summary,
            generatedAt: decoded.generatedAt,
            model: decoded.model
        )
    }
}
