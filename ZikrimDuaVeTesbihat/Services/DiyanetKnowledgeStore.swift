import Combine
import CryptoKit
import Foundation

private struct DiyanetRemoteManifest: Decodable {
    let generatedAt: String
    let datasetVersion: String
    let sourceName: String
    let sourceDomain: String
    let recordCount: Int
    let payloadFile: String
    let payloadSHA256: String

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case datasetVersion = "dataset_version"
        case sourceName = "source_name"
        case sourceDomain = "source_domain"
        case recordCount = "record_count"
        case payloadFile = "payload_file"
        case payloadSHA256 = "payload_sha256"
    }
}

@MainActor
final class DiyanetKnowledgeStore: ObservableObject {
    @Published private(set) var payload: DiyanetKnowledgePayload = .empty
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    var records: [DiyanetKnowledgeRecord] {
        payload.records
    }

    var totalCount: Int {
        records.count
    }

    var sections: [DiyanetKnowledgeSection] {
        DiyanetContentType.allCases.compactMap { type in
            let count = records.filter { $0.type == type }.count
            guard count > 0 else { return nil }
            return DiyanetKnowledgeSection(type: type, count: count)
        }
    }

    var topCategories: [(name: String, count: Int)] {
        Dictionary(grouping: records, by: \.topCategory)
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { left, right in
                if left.count == right.count {
                    return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
                }
                return left.count > right.count
            }
    }

    func loadIfNeeded() async {
        guard records.isEmpty, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let cachedPayload = try loadCachedPayload() {
                payload = cachedPayload
            } else if let bundledPayload = try loadBundledPayload() {
                payload = bundledPayload
            }
        } catch {
            payload = .empty
            errorMessage = "Diyanet veri paketi okunamadı: \(error.localizedDescription)"
        }

        do {
            if let manifestURL = remoteManifestURL() {
                let remotePayload = try await fetchRemotePayload(usingManifestAt: manifestURL)
                payload = remotePayload
                try cachePayload(remotePayload)
                errorMessage = nil
                return
            }

            if let remoteURL = remoteDatasetURL() {
                let remotePayload = try await fetchRemotePayload(from: remoteURL)
                payload = remotePayload
                try cachePayload(remotePayload)
                errorMessage = nil
                return
            }

            if payload.records.isEmpty {
                if let bundledPayload = try loadBundledPayload() {
                    payload = bundledPayload
                    return
                }

                errorMessage = "Diyanet veri paketi bundle içinde bulunamadı."
            }
        } catch {
            if payload.records.isEmpty {
                errorMessage = "Diyanet veri paketi okunamadı: \(error.localizedDescription)"
            }
        }
    }

    func record(withID id: String) -> DiyanetKnowledgeRecord? {
        records.first { $0.id == id }
    }

    private func resourceURL() -> URL? {
        let candidateNames = [
            "diyanet_official_dataset_payload",
            "diyanet_official_dataset"
        ]

        for name in candidateNames {
            if let rootURL = Bundle.main.url(forResource: name, withExtension: "json") {
                return rootURL
            }

            if let dataFolderURL = Bundle.main.url(
                forResource: name,
                withExtension: "json",
                subdirectory: "Data"
            ) {
                return dataFolderURL
            }
        }

        return nil
    }

    private func remoteManifestURL() -> URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "DIYKDatasetManifestURL") as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return URL(string: rawValue)
    }

    private func remoteDatasetURL() -> URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "DIYKDatasetRemoteURL") as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return URL(string: rawValue)
    }

    private func loadBundledPayload() throws -> DiyanetKnowledgePayload? {
        guard let url = resourceURL() else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decodePayload(from: data)
    }

    private func loadCachedPayload() throws -> DiyanetKnowledgePayload? {
        let cacheURL = try cacheFileURL()
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: cacheURL)
        return try decodePayload(from: data)
    }

    private func cachePayload(_ payload: DiyanetKnowledgePayload) throws {
        let cacheURL = try cacheFileURL()
        let directoryURL = cacheURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let data = try encoder.encode(payload)
        try data.write(to: cacheURL, options: .atomic)
    }

    private func cacheFileURL() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = baseURL.appendingPathComponent("DiyanetKnowledge", isDirectory: true)
        return directoryURL.appendingPathComponent("diyanet_official_dataset_payload.json")
    }

    private func fetchRemotePayload(from url: URL) async throws -> DiyanetKnowledgePayload {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let remotePayload = try decodePayload(from: data)

        if let cachedPayload = try? loadCachedPayload(),
           payloadFingerprint(for: cachedPayload) == payloadFingerprint(for: remotePayload) {
            return cachedPayload
        }

        return remotePayload
    }

    private func fetchRemotePayload(usingManifestAt manifestURL: URL) async throws -> DiyanetKnowledgePayload {
        var request = URLRequest(url: manifestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20

        let (manifestData, manifestResponse) = try await URLSession.shared.data(for: request)

        if let httpResponse = manifestResponse as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let manifest = try decoder.decode(DiyanetRemoteManifest.self, from: manifestData)

        if let cachedPayload = try? loadCachedPayload(),
           cachedPayload.datasetVersion == manifest.datasetVersion {
            return cachedPayload
        }

        let payloadURL = resolvePayloadURL(from: manifest, manifestURL: manifestURL)
        var payloadRequest = URLRequest(url: payloadURL)
        payloadRequest.cachePolicy = .reloadIgnoringLocalCacheData
        payloadRequest.timeoutInterval = 30

        let (payloadData, payloadResponse) = try await URLSession.shared.data(for: payloadRequest)

        if let httpResponse = payloadResponse as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let remotePayload = try decodePayload(from: payloadData)
        let computedHash = payloadSHA256(for: payloadData)
        guard computedHash == manifest.payloadSHA256 else {
            throw CocoaError(.coderReadCorrupt)
        }

        return remotePayload
    }

    private func resolvePayloadURL(from manifest: DiyanetRemoteManifest, manifestURL: URL) -> URL {
        if let absoluteURL = URL(string: manifest.payloadFile), absoluteURL.scheme != nil {
            return absoluteURL
        }

        return manifestURL.deletingLastPathComponent().appendingPathComponent(manifest.payloadFile)
    }

    private func payloadSHA256(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "sha256:\(hex)"
    }

    private func payloadFingerprint(for payload: DiyanetKnowledgePayload) -> String {
        let seed = [
            payload.generatedAt ?? "",
            payload.datasetVersion ?? "",
            String(payload.records.count),
            payload.records.first?.contentHash ?? "",
            payload.records.last?.contentHash ?? ""
        ].joined(separator: "|")
        let digest = SHA256.hash(data: Data(seed.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func decodePayload(from data: Data) throws -> DiyanetKnowledgePayload {
        if let payload = try? decoder.decode(DiyanetKnowledgePayload.self, from: data) {
            return payload
        }

        if let records = try? decoder.decode([DiyanetKnowledgeRecord].self, from: data) {
            return DiyanetKnowledgePayload(
                generatedAt: nil,
                datasetVersion: nil,
                sourceName: "Din İşleri Yüksek Kurulu",
                sourceDomain: "kurul.diyanet.gov.tr",
                records: records
            )
        }

        if let text = String(data: data, encoding: .utf8) {
            let lines = text
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            if !lines.isEmpty {
                let records = try lines.map { line in
                    guard let lineData = line.data(using: .utf8) else {
                        throw CocoaError(.coderReadCorrupt)
                    }

                    return try decoder.decode(DiyanetKnowledgeRecord.self, from: lineData)
                }

                return DiyanetKnowledgePayload(
                    generatedAt: nil,
                    datasetVersion: nil,
                    sourceName: "Din İşleri Yüksek Kurulu",
                    sourceDomain: "kurul.diyanet.gov.tr",
                    records: records
                )
            }
        }

        throw CocoaError(.coderReadCorrupt)
    }
}
