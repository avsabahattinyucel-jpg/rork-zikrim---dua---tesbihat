import Foundation

struct BundleQuranTafsirProvider: QuranTafsirProviding {
    private let cache = QuranTafsirCache()
    private let fallbackLanguage: AppLanguage
    private let store: QuranLocalDataStore

    init(
        fallbackLanguage: AppLanguage = .en,
        store: QuranLocalDataStore = .shared
    ) {
        self.fallbackLanguage = fallbackLanguage
        self.store = store
    }

    func tafsir(for reference: AyahReference, language: AppLanguage, source: QuranTafsirSource) async throws -> QuranTafsirPayload? {
        let cacheKey = "\(source.id)-full-\(reference.id)-\(language.rawValue)"
        if let cached = await cache.tafsir(for: cacheKey) {
            return cached
        }

        for candidate in QuranTafsirLanguageFallbackPolicy.chain(for: language, source: source, fallback: fallbackLanguage) {
            let resolvedText: String?
            switch source.id {
            case QuranTafsirSource.zikrimShortExplanation.id:
                resolvedText = await store.shortTafsirText(forVerseKey: reference.id, languageCode: candidate.rawValue)
            default:
                resolvedText = await store.tafsirText(forVerseKey: reference.id, languageCode: candidate.rawValue)
            }

            guard let body = resolvedText, !body.isEmpty else { continue }

            let payload = QuranTafsirPayload(
                title: QuranReaderStrings.tafsirTitle(reference),
                body: body,
                source: source,
                language: candidate,
                attribution: source.attribution,
                didUseFallbackLanguage: candidate != language
            )
            await cache.store(payload, for: cacheKey)
            return payload
        }

        return nil
    }

    func shortExplanation(for reference: AyahReference, language: AppLanguage, source: QuranTafsirSource) async throws -> QuranShortExplanationPayload? {
        let cacheKey = "\(source.id)-short-\(reference.id)-\(language.rawValue)"
        if let cached = await cache.shortExplanation(for: cacheKey) {
            return cached
        }

        for candidate in QuranTafsirLanguageFallbackPolicy.chain(for: language, source: source, fallback: fallbackLanguage) {
            guard let text = await store.shortTafsirText(forVerseKey: reference.id, languageCode: candidate.rawValue),
                  !text.isEmpty else {
                continue
            }

            let payload = QuranShortExplanationPayload(
                text: text,
                source: source,
                language: candidate,
                attribution: source.attribution,
                didUseFallbackLanguage: candidate != language
            )
            await cache.store(payload, for: cacheKey)
            return payload
        }

        return nil
    }
}
