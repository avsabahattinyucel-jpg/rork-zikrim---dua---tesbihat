import Foundation

actor QuranTafsirCache {
    private var tafsirStorage: [String: QuranTafsirPayload] = [:]
    private var shortStorage: [String: QuranShortExplanationPayload] = [:]

    func tafsir(for key: String) -> QuranTafsirPayload? {
        tafsirStorage[key]
    }

    func shortExplanation(for key: String) -> QuranShortExplanationPayload? {
        shortStorage[key]
    }

    func store(_ payload: QuranTafsirPayload, for key: String) {
        tafsirStorage[key] = payload
    }

    func store(_ payload: QuranShortExplanationPayload, for key: String) {
        shortStorage[key] = payload
    }
}

enum QuranTafsirLanguageFallbackPolicy {
    static func chain(for requested: AppLanguage, source: QuranTafsirSource, fallback: AppLanguage) -> [AppLanguage] {
        var chain: [AppLanguage] = [requested]

        append(fallback, to: &chain)
        append(.en, to: &chain)

        if source.isTurkishFirst {
            append(.tr, to: &chain)
        }

        append(.ar, to: &chain)

        return chain.filter { source.supportedLanguages.contains($0) }
    }

    private static func append(_ language: AppLanguage, to chain: inout [AppLanguage]) {
        guard !chain.contains(language) else { return }
        chain.append(language)
    }
}

struct MockQuranTafsirProvider: QuranTafsirProviding {
    private let cache = QuranTafsirCache()
    private let fallbackLanguage: AppLanguage

    init(fallbackLanguage: AppLanguage = .en) {
        self.fallbackLanguage = fallbackLanguage
    }

    func tafsir(for reference: AyahReference, language: AppLanguage, source: QuranTafsirSource) async throws -> QuranTafsirPayload? {
        let cacheKey = "\(source.id)-full-\(reference.id)-\(language.rawValue)"
        if let cached = await cache.tafsir(for: cacheKey) {
            return cached
        }

        for candidate in QuranTafsirLanguageFallbackPolicy.chain(for: language, source: source, fallback: fallbackLanguage) {
            if let resolved = resolveFull(reference: reference, language: candidate, source: source, requested: language) {
                await cache.store(resolved, for: cacheKey)
                return resolved
            }
        }

        return nil
    }

    func shortExplanation(for reference: AyahReference, language: AppLanguage, source: QuranTafsirSource) async throws -> QuranShortExplanationPayload? {
        let cacheKey = "\(source.id)-short-\(reference.id)-\(language.rawValue)"
        if let cached = await cache.shortExplanation(for: cacheKey) {
            return cached
        }

        for candidate in QuranTafsirLanguageFallbackPolicy.chain(for: language, source: source, fallback: fallbackLanguage) {
            if let resolved = resolveShort(reference: reference, language: candidate, source: source, requested: language) {
                await cache.store(resolved, for: cacheKey)
                return resolved
            }
        }

        return nil
    }

    private func resolveShort(
        reference: AyahReference,
        language: AppLanguage,
        source: QuranTafsirSource,
        requested: AppLanguage
    ) -> QuranShortExplanationPayload? {
        let text = sampleData[reference]?[language]?.short ?? placeholderShort(reference: reference, language: language, source: source)
        return QuranShortExplanationPayload(
            text: text,
            source: source,
            language: language,
            attribution: source.attribution,
            didUseFallbackLanguage: language != requested
        )
    }

    private func resolveFull(
        reference: AyahReference,
        language: AppLanguage,
        source: QuranTafsirSource,
        requested: AppLanguage
    ) -> QuranTafsirPayload? {
        let body = sampleData[reference]?[language]?.full ?? placeholderFull(reference: reference, language: language, source: source)

        if source.id == QuranTafsirSource.remoteMultiLanguageTafsir.id {
            // TODO: Replace this mock branch with a real API adapter.
            // Expected integration point:
            // 1. Request by ayah reference + language.
            // 2. Parse attribution + license.
            // 3. Persist API/cache metadata and offline fallback policy.
        }

        return QuranTafsirPayload(
            title: QuranReaderStrings.tafsirTitle(reference),
            body: body,
            source: source,
            language: language,
            attribution: source.attribution,
            didUseFallbackLanguage: language != requested
        )
    }

    private func placeholderShort(reference _: AyahReference, language: AppLanguage, source _: QuranTafsirSource) -> String {
        switch language {
        case .tr:
            return "Bu ayet için seçili kaynakta kısa açıklama şu anda gösterilemiyor."
        case .ar:
            return "لا يتوفر شرح موجز لهذه الآية في المصدر المحدد حالياً."
        default:
            return "A short explanation for this ayah is not available in the selected source right now."
        }
    }

    private func placeholderFull(reference: AyahReference, language: AppLanguage, source _: QuranTafsirSource) -> String {
        switch language {
        case .tr:
            return "Seçtiğin kaynakta \(reference.surahNumber). sure \(reference.ayahNumber). ayet için ayrıntılı tefsir şu anda mevcut değil."
        case .ar:
            return "لا يتوفر التفسير التفصيلي لهذه الآية في المصدر المحدد حالياً."
        default:
            return "Detailed tafsir for this ayah is not available in the selected source right now."
        }
    }

    private var sampleData: [AyahReference: [AppLanguage: (short: String, full: String)]] {
        [
            AyahReference(surahNumber: 1, ayahNumber: 1): [
                .en: (
                    short: "The opening verse begins in mercy and reminds the reader that recitation starts with conscious dependence on Allah.",
                    full: "This ayah frames the entire reading experience with mercy, compassion, and intentionality. In the reader, it works well as a short reflective cue before the user continues through the surah."
                ),
                .tr: (
                    short: "Açılış ayeti, kıraatin rahmet ve bilinçle başlamasını hatırlatır.",
                    full: "Bu ayet, okumanın başında rahmet, şefkat ve niyeti öne çıkarır. Uygulama içinde kısa tefekkür için uygun, sakin bir açıklama katmanı olarak düşünülebilir."
                ),
                .ar: (
                    short: "تفتتح الآية التلاوة بالرحمة واستحضار النية.",
                    full: "تقدم هذه الآية معنى الرحمة والاعتماد على الله منذ بداية القراءة، ولذلك تصلح كتذكير قصير وهادئ داخل تجربة القارئ."
                )
            ],
            AyahReference(surahNumber: 112, ayahNumber: 1): [
                .en: (
                    short: "The verse gathers tawhid into a concise declaration and centers the heart on divine oneness.",
                    full: "This ayah is often read slowly because of its concentrated meaning. A premium reading surface should keep the Arabic visually strong while leaving enough breathing room for a short explanation beneath it."
                ),
                .tr: (
                    short: "Bu ayet tevhidi kısa ve güçlü bir beyan halinde toplar.",
                    full: "Ayet, Allah’ın birliğini kalpte merkezleyen yoğun bir anlam taşır. Okuyucuda Arapça metnin vakarını korurken altta kısa ve sade bir açıklama göstermek doğru bir denge sağlar."
                )
            ]
        ]
    }
}
