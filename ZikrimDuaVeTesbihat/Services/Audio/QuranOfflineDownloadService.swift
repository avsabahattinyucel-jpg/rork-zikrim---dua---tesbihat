import Combine
import Foundation

struct QuranOfflineSurahRecord: Codable, Equatable, Sendable {
    let surahID: Int
    let reciterID: String
    let totalAyahCount: Int
    let totalBytes: Int64
    let downloadedAt: Date
}

enum QuranOfflineSurahStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double, completedAyahs: Int, totalAyahs: Int)
    case downloaded(totalBytes: Int64)
}

@MainActor
final class QuranOfflineDownloadService: ObservableObject {
    static let shared = QuranOfflineDownloadService()

    @Published private var activeDownloads: [String: ActiveDownload] = [:]
    @Published var errorMessage: String?

    private struct ActiveDownload: Equatable {
        let completedAyahs: Int
        let totalAyahs: Int
        let totalBytes: Int64

        var progress: Double {
            guard totalAyahs > 0 else { return 0 }
            return Double(completedAyahs) / Double(totalAyahs)
        }
    }

    private let offlineStorage: OfflineAudioStorageManager
    private let urlSession: URLSession
    private let defaults: UserDefaults
    private let providersByKind: [AudioProviderKind: any QuranAudioProvider]
    private let recordsKey = "quran_audio.offline_surah_records"

    private var records: [String: QuranOfflineSurahRecord]
    private var tasks: [String: Task<Void, Never>] = [:]

    init(
        providers: [any QuranAudioProvider] = [
            BundledAyahAudioProvider(),
            QuranComAudioProvider(),
            EveryAyahAudioProvider()
        ],
        offlineStorage: OfflineAudioStorageManager = OfflineAudioStorageManager(),
        urlSession: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.providersByKind = Dictionary(uniqueKeysWithValues: providers.map { ($0.kind, $0) })
        self.offlineStorage = offlineStorage
        self.urlSession = urlSession
        self.defaults = defaults
        self.records = Self.loadRecords(from: defaults, key: recordsKey)
    }

    func status(for surah: QuranSurah, reciter: Reciter) -> QuranOfflineSurahStatus {
        let key = storageKey(surahID: surah.id, reciterID: reciter.id)

        if let active = activeDownloads[key] {
            return .downloading(
                progress: active.progress,
                completedAyahs: active.completedAyahs,
                totalAyahs: active.totalAyahs
            )
        }

        if let record = records[key], record.totalAyahCount >= surah.totalVerses {
            return .downloaded(totalBytes: record.totalBytes)
        }

        return .notDownloaded
    }

    func startDownload(for surah: QuranSurah, reciter: Reciter) {
        let key = storageKey(surahID: surah.id, reciterID: reciter.id)
        guard tasks[key] == nil else { return }

        activeDownloads[key] = ActiveDownload(
            completedAyahs: 0,
            totalAyahs: surah.totalVerses,
            totalBytes: 0
        )

        tasks[key] = Task { [weak self] in
            await self?.runDownload(for: surah, reciter: reciter, key: key)
        }
    }

    func cancelDownload(for surah: QuranSurah, reciter: Reciter) {
        let key = storageKey(surahID: surah.id, reciterID: reciter.id)
        tasks[key]?.cancel()
        tasks[key] = nil
        activeDownloads.removeValue(forKey: key)
    }

    func removeDownload(for surah: QuranSurah, reciter: Reciter) async {
        let key = storageKey(surahID: surah.id, reciterID: reciter.id)
        tasks[key]?.cancel()
        tasks[key] = nil
        activeDownloads.removeValue(forKey: key)

        for ayah in 1...surah.totalVerses {
            let request = AyahAudioRequest(surah: surah.id, ayah: ayah, reciter: reciter)
            try? await offlineStorage.remove(for: request)
        }

        records.removeValue(forKey: key)
        persistRecords()
    }

    func clearError() {
        errorMessage = nil
    }

    private func runDownload(for surah: QuranSurah, reciter: Reciter, key: String) async {
        defer {
            tasks[key] = nil
            activeDownloads.removeValue(forKey: key)
        }

        do {
            let urls = try await preloadAudioURLs(for: surah, reciter: reciter)
            var totalBytes: Int64 = 0
            var completedAyahs = 0

            for ayah in 1...surah.totalVerses {
                try Task.checkCancellation()

                guard let remoteURL = urls[ayah] else {
                    throw QuranAudioProviderError.missingAudioURL(
                        provider: reciter.providerKind,
                        verseKey: "\(surah.id):\(ayah)"
                    )
                }

                let request = AyahAudioRequest(surah: surah.id, ayah: ayah, reciter: reciter)
                let localURL = try await offlineStorage.cacheRemoteFile(
                    from: remoteURL,
                    for: request,
                    session: urlSession
                )

                let values = try? localURL.resourceValues(forKeys: [.fileSizeKey])
                totalBytes += Int64(values?.fileSize ?? 0)
                completedAyahs += 1

                activeDownloads[key] = ActiveDownload(
                    completedAyahs: completedAyahs,
                    totalAyahs: surah.totalVerses,
                    totalBytes: totalBytes
                )
            }

            records[key] = QuranOfflineSurahRecord(
                surahID: surah.id,
                reciterID: reciter.id,
                totalAyahCount: surah.totalVerses,
                totalBytes: totalBytes,
                downloadedAt: Date()
            )
            persistRecords()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = L10n.string(.quranAudioOfflineDownloadFailed)
        }
    }

    private func preloadAudioURLs(for surah: QuranSurah, reciter: Reciter) async throws -> [Int: URL] {
        for providerKind in orderedProviderKinds(for: reciter) {
            guard let provider = providersByKind[providerKind], provider.supports(reciter) else {
                continue
            }

            do {
                let urls = try await provider.preloadAudioURLs(forSurah: surah.id, reciter: reciter)
                if !urls.isEmpty {
                    return urls
                }
            } catch {
                continue
            }
        }

        throw QuranAudioProviderError.unsupportedReciter(
            provider: reciter.providerKind,
            reciterID: reciter.id
        )
    }

    private func orderedProviderKinds(for reciter: Reciter) -> [AudioProviderKind] {
        var orderedKinds: [AudioProviderKind] = [reciter.providerKind]

        for providerKind in AudioProviderKind.allCases where !orderedKinds.contains(providerKind) {
            orderedKinds.append(providerKind)
        }

        return orderedKinds
    }

    private func storageKey(surahID: Int, reciterID: String) -> String {
        "\(reciterID):\(surahID)"
    }

    private func persistRecords() {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: recordsKey)
        }
    }

    private static func loadRecords(from defaults: UserDefaults, key: String) -> [String: QuranOfflineSurahRecord] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: QuranOfflineSurahRecord].self, from: data) else {
            return [:]
        }

        return decoded
    }
}
