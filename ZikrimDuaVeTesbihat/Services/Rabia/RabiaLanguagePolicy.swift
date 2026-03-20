import Foundation

enum RabiaLanguagePolicy {
    static func promptInstruction(appLanguageCode: String) -> String {
        let resolvedCode = RabiaAppLanguage.normalizedCode(for: appLanguageCode)
        let resolvedName = RabiaAppLanguage.displayName(for: resolvedCode)

        return """
        LANGUAGE RULES
        - Always reply in the current app language.
        - The app language is: \(resolvedName) (\(resolvedCode)).
        - You must strictly use the app language for the entire response.
        - Never mix languages in the same response.
        - Do not automatically switch to the language of the user's message unless the user explicitly asks you to reply in another language.
        - If the user writes in a different language but does not explicitly request a language change, still respond in the app language.
        - If the user explicitly asks for translation or asks you to respond in another language, then follow that request.
        - Religious references, headings, labels, and inserted source text must stay in the same language when a localized version exists.
        - If a localized reference text is unavailable, prefer English as the text fallback. If English is also unavailable, use only the citation/reference.
        - Do not choose the response language from the user's message alone. The app language is the source of truth.
        - Keep all headings, bullets, labels, and closing lines in the app language too.
        """
    }

    static func preferredReferenceLanguageCodes(for rawCode: String) -> [String] {
        let primary = RabiaAppLanguage.normalizedCode(for: rawCode)
        var codes: [String] = [primary]

        if primary != "en" {
            codes.append("en")
        }

        return deduplicated(codes)
    }

    static func generalKnowledgeInstruction(appLanguageCode: String) -> String {
        let resolvedCode = RabiaAppLanguage.normalizedCode(for: appLanguageCode)

        if resolvedCode == "tr" {
            return """
            - general_knowledge modunda: Türkiye'de kullanılan sade ve doğal Türkçe ile yaz.
            - general_knowledge modunda: Arapça transliterasyon kullanma.
            - general_knowledge modunda: İngilizce kelime, karışık dil veya yarı çeviri dini terim kullanma.
            - general_knowledge modunda: dua, hadis, ayet, teknik terim veya dini ifade uydurma.
            - general_knowledge modunda: kısa, pratik ve sade kal; vaaz verir gibi, hutbe gibi veya moralize eden tonda yazma.
            - general_knowledge modunda: emin değilsen kısa, ihtiyatlı ve basit cevap ver; eksik bilgiyi doldurma.
            """
        }

        let resolvedName = RabiaAppLanguage.displayName(for: resolvedCode)
        return """
        - general_knowledge modunda: write in plain, natural \(resolvedName) used by the app.
        - general_knowledge modunda: do not use Arabic transliteration.
        - general_knowledge modunda: do not mix \(resolvedName) with Turkish, English, or any other language.
        - general_knowledge modunda: do not invent duas, hadiths, Quran verses, technical terms, or religious wording.
        - general_knowledge modunda: keep the answer short, practical, and simple; do not moralize or sound like a sermon.
        - general_knowledge modunda: if uncertain, answer conservatively and simply without filling gaps.
        """
    }

    static func hasObviousLanguageMismatch(_ text: String, expectedLanguageCode: String) -> Bool {
        let expected = RabiaAppLanguage.normalizedCode(for: expectedLanguageCode)
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return false }

        switch expected {
        case "en":
            let turkishSignals = score(tokens: ["ve", "bir", "için", "gibi", "şey", "olan", "kadar", "çünkü"], in: normalized)
            let englishSignals = score(tokens: ["the", "and", "for", "with", "that", "this", "your", "is"], in: normalized)
            let hasTurkishCharacters = normalized.range(of: #"[çğıöşüİı]"#, options: .regularExpression) != nil
            return hasTurkishCharacters || (turkishSignals >= 3 && turkishSignals > englishSignals)
        case "tr":
            let englishSignals = score(tokens: ["the", "and", "for", "with", "that", "this", "your", "is"], in: normalized)
            let turkishSignals = score(tokens: ["ve", "bir", "için", "gibi", "şey", "olan", "kadar", "çünkü"], in: normalized)
            let hasTurkishCharacters = normalized.range(of: #"[çğıöşüİı]"#, options: .regularExpression) != nil
            return englishSignals >= 4 && !hasTurkishCharacters && englishSignals > turkishSignals
        default:
            return false
        }
    }

    private static func score(tokens: [String], in text: String) -> Int {
        let lowercased = text.lowercased()
        return tokens.reduce(into: 0) { partialResult, token in
            if lowercased.contains(token) {
                partialResult += 1
            }
        }
    }

    private static func deduplicated(_ codes: [String]) -> [String] {
        var seen = Set<String>()
        return codes.filter { seen.insert($0).inserted }
    }
}
