import Foundation

nonisolated enum AudioCacheError: LocalizedError, Sendable {
    case invalidDownloadResponse(statusCode: Int)
    case failedToCreateCacheDirectory

    var errorDescription: String? {
        switch self {
        case .invalidDownloadResponse(let statusCode):
            return "Audio download failed with status \(statusCode)"
        case .failedToCreateCacheDirectory:
            return "Audio cache directory could not be created"
        }
    }
}

actor AudioCacheManager {
    private let fileManager: FileManager
    private let cacheDirectoryURL: URL
    private let maxDiskUsageInBytes: Int64

    init(
        fileManager: FileManager = .default,
        directoryName: String = "QuranAyahAudioCache",
        maxDiskUsageInBytes: Int64 = 250 * 1024 * 1024
    ) {
        self.fileManager = fileManager
        self.maxDiskUsageInBytes = maxDiskUsageInBytes

        let cachesRoot = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        let targetDirectory = cachesRoot?
            .appendingPathComponent("ZikrimDuaVeTesbihat", isDirectory: true)
            .appendingPathComponent(directoryName, isDirectory: true)

        self.cacheDirectoryURL = targetDirectory ?? URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(directoryName, isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: cacheDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            assertionFailure("Audio cache directory could not be created: \(error)")
        }
    }

    func cacheKey(for request: AyahAudioRequest) -> String {
        request.cacheKey
    }

    func exists(for request: AyahAudioRequest) -> Bool {
        let url = localFileURL(for: request)
        return fileManager.fileExists(atPath: url.path)
    }

    func cachedFileURL(for request: AyahAudioRequest) -> URL? {
        let url = localFileURL(for: request)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func save(_ data: Data, for request: AyahAudioRequest, fileExtension: String = "mp3") throws -> URL {
        try ensureCacheDirectory()
        let destinationURL = localFileURL(for: request, fileExtension: fileExtension)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }

    func cacheRemoteFile(
        from remoteURL: URL,
        for request: AyahAudioRequest,
        session: URLSession = .shared
    ) async throws -> URL {
        if let cached = cachedFileURL(for: request) {
            return cached
        }

        try ensureCacheDirectory()

        let (temporaryURL, response) = try await session.download(from: remoteURL)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

        guard (200...299).contains(statusCode) else {
            throw AudioCacheError.invalidDownloadResponse(statusCode: statusCode)
        }

        let destinationURL = localFileURL(for: request)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: temporaryURL, to: destinationURL)
        try evictIfNeeded()

        return destinationURL
    }

    func evictIfNeeded() throws {
        let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
        let fileURLs = try fileManager.contentsOfDirectory(
            at: cacheDirectoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        )

        var totalSize: Int64 = 0
        var files: [(url: URL, modifiedAt: Date, size: Int64)] = []

        for fileURL in fileURLs {
            let values = try fileURL.resourceValues(forKeys: resourceKeys)
            guard values.isRegularFile == true else { continue }
            let size = Int64(values.fileSize ?? 0)
            totalSize += size
            files.append((fileURL, values.contentModificationDate ?? .distantPast, size))
        }

        guard totalSize > maxDiskUsageInBytes else { return }

        let sortedFiles = files.sorted(by: { $0.modifiedAt < $1.modifiedAt })
        var remainingSize = totalSize

        for file in sortedFiles {
            try fileManager.removeItem(at: file.url)
            remainingSize -= file.size

            if remainingSize <= maxDiskUsageInBytes {
                break
            }
        }
    }

    private func localFileURL(for request: AyahAudioRequest, fileExtension: String = "mp3") -> URL {
        cacheDirectoryURL.appendingPathComponent("\(cacheKey(for: request)).\(fileExtension)", isDirectory: false)
    }

    private func ensureCacheDirectory() throws {
        do {
            try fileManager.createDirectory(
                at: cacheDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw AudioCacheError.failedToCreateCacheDirectory
        }
    }
}
