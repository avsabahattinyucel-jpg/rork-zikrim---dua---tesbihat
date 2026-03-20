import Foundation

actor QuranTranslationCache {
    private let fileManager: FileManager
    private let baseURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(cacheDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let root = cacheDirectory ?? (fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory()))
        baseURL = root.appendingPathComponent("quran_translations", isDirectory: true)
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        Task { await createBaseDirectoryIfNeeded() }
    }

    func loadSurahTranslations(surahId: Int, translationId: Int) -> [QuranVerseTranslation]? {
        let url = fileURL(surahId: surahId, translationId: translationId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode([QuranVerseTranslation].self, from: data)
    }

    func storeSurahTranslations(_ verses: [QuranVerseTranslation], surahId: Int, translationId: Int) throws {
        let dirURL = translationDirectory(translationId: translationId)
        if !fileManager.fileExists(atPath: dirURL.path) {
            try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        }
        let url = fileURL(surahId: surahId, translationId: translationId)
        let data = try encoder.encode(verses)
        try data.write(to: url, options: [.atomic])
    }

    func clearTranslation(translationId: Int) throws {
        let dirURL = translationDirectory(translationId: translationId)
        if fileManager.fileExists(atPath: dirURL.path) {
            try fileManager.removeItem(at: dirURL)
        }
    }

    func clearAll() throws {
        if fileManager.fileExists(atPath: baseURL.path) {
            try fileManager.removeItem(at: baseURL)
        }
        Task { await createBaseDirectoryIfNeeded() }
    }

    private func createBaseDirectoryIfNeeded() async {
        if !fileManager.fileExists(atPath: baseURL.path) {
            try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func translationDirectory(translationId: Int) -> URL {
        baseURL.appendingPathComponent("t_\(translationId)", isDirectory: true)
    }

    private func fileURL(surahId: Int, translationId: Int) -> URL {
        translationDirectory(translationId: translationId).appendingPathComponent("surah_\(surahId).json")
    }
}
