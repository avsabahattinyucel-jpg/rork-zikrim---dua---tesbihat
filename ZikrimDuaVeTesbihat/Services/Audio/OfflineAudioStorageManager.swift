import Combine
import Foundation

nonisolated enum OfflineAudioStorageError: LocalizedError, Sendable {
    case invalidDownloadResponse(statusCode: Int)
    case failedToCreateStorageDirectory

    var errorDescription: String? {
        switch self {
        case .invalidDownloadResponse(let statusCode):
            return "Offline audio download failed with status \(statusCode)"
        case .failedToCreateStorageDirectory:
            return "Offline audio storage directory could not be created"
        }
    }
}

actor OfflineAudioStorageManager {
    private let fileManager: FileManager
    private let storageDirectoryURL: URL

    init(
        fileManager: FileManager = .default,
        directoryName: String = "QuranOfflineAudio"
    ) {
        self.fileManager = fileManager

        let cachesRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let targetDirectory = cachesRoot?
            .appendingPathComponent("ZikrimDuaVeTesbihat", isDirectory: true)
            .appendingPathComponent(directoryName, isDirectory: true)

        self.storageDirectoryURL = targetDirectory ?? URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(directoryName, isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: storageDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            assertionFailure("Offline audio storage directory could not be created: \(error)")
        }
    }

    func exists(for request: AyahAudioRequest) -> Bool {
        let url = localFileURL(for: request)
        return fileManager.fileExists(atPath: url.path)
    }

    func cachedFileURL(for request: AyahAudioRequest) -> URL? {
        let url = localFileURL(for: request)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func fileSize(for request: AyahAudioRequest) -> Int64 {
        let url = localFileURL(for: request)
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    func cacheRemoteFile(
        from remoteURL: URL,
        for request: AyahAudioRequest,
        session: URLSession = .shared
    ) async throws -> URL {
        if let cached = cachedFileURL(for: request) {
            return cached
        }

        try ensureStorageDirectory()

        let (temporaryURL, response) = try await session.download(from: remoteURL)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

        guard (200...299).contains(statusCode) else {
            throw OfflineAudioStorageError.invalidDownloadResponse(statusCode: statusCode)
        }

        let destinationURL = localFileURL(for: request)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }

    func remove(for request: AyahAudioRequest) throws {
        let url = localFileURL(for: request)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func localFileURL(for request: AyahAudioRequest, fileExtension: String = "mp3") -> URL {
        storageDirectoryURL.appendingPathComponent("\(request.cacheKey).\(fileExtension)", isDirectory: false)
    }

    private func ensureStorageDirectory() throws {
        do {
            try fileManager.createDirectory(
                at: storageDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw OfflineAudioStorageError.failedToCreateStorageDirectory
        }
    }
}
