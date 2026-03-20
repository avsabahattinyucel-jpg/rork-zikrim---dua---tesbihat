import Foundation

enum HisnulMuslimContentRefiner {
    static let supportedLanguageCodes = ["tr", "ar", "en", "fr", "de", "id", "ms", "fa", "ru", "es", "ur"]

    static func refinedTitleMap(
        _ base: [String: String],
        entryID: String,
        turkishOverride: String? = nil,
        transliterationMap: [String: String]? = nil,
        meaningMap: [String: String]? = nil,
        arabicText: String? = nil
    ) -> [String: String] {
        var result = base

        if let turkishTitle = trimmed(base["tr"]) ?? trimmed(base["en"]) {
            let refinedTitle = trimmed(turkishOverride)
                ?? specificTurkishTitleOverrides[entryID]
                ?? deriveTurkishTitle(
                    originalTitle: turkishTitle,
                    transliteration: trimmed(transliterationMap?["tr"]) ?? trimmed(transliterationMap?["en"]),
                    meaning: trimmed(meaningMap?["tr"]) ?? trimmed(meaningMap?["en"]),
                    arabicText: trimmed(arabicText)
                )
            result["tr"] = refinedTitle
        }

        if let englishTitle = trimmed(base["en"]) {
            result["en"] = stripOrdinalSuffix(from: englishTitle)
        }

        if let arabicTitle = trimmed(base["ar"]) {
            result["ar"] = stripOrdinalSuffix(from: arabicTitle)
        }

        for code in supportedLanguageCodes where code != "tr" && code != "en" && code != "ar" {
            if let value = trimmed(base[code]) {
                result[code] = stripOrdinalSuffix(from: value)
            }
        }

        return result
    }

    private static func deriveTurkishTitle(
        originalTitle: String,
        transliteration: String?,
        meaning: String?,
        arabicText: String?
    ) -> String {
        let strippedTitle = stripOrdinalSuffix(from: originalTitle)

        guard hasArtificialOrdinalSuffix(originalTitle) else {
            return refineTurkishTitle(strippedTitle)
        }

        if let transliterationCandidate = titleCandidateFromTransliteration(transliteration) {
            return transliterationCandidate
        }

        if let meaningCandidate = titleCandidateFromMeaning(meaning) {
            return meaningCandidate
        }

        if let arabicCandidate = titleCandidateFromArabic(arabicText) {
            return arabicCandidate
        }

        return refineTurkishTitle(strippedTitle)
    }

    private static func titleCandidateFromTransliteration(_ text: String?) -> String? {
        guard let text = trimmed(text) else { return nil }

        let normalized = turkishizeTransliteration(text)
            .replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\[[^\]]*\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let firstLine = normalized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? normalized

        return shortenedTitleCandidate(firstLine)
    }

    private static func titleCandidateFromMeaning(_ text: String?) -> String? {
        guard var result = trimmed(text) else { return nil }

        let specificReplacements: [(String, String)] = [
            ("Mu'adh-dhin'in çağrısına cevap verdikten sonra. Allah'ın Peygamber Efendimiz (sav)'e salat-ü selamını Arapça olarak okum", "Ezandan Sonra Salavat"),
            ("Ezan ile kamet arasında kendin için Allah'a dua etmelisin", "Ezan ile Kamet Arasında Dua"),
            ("32. (Secde) ve 67. (Mülk) surelerini Arapça okuyun", "Secde ve Mülk Sureleri"),
            ("Solunuza tükürün (üç defa)", "Kötü Rüyadan Korunma"),
            ("Eğer istiyorsanız kalkın ve dua edin", "Rüyadan Sonra Namaz"),
            ("Dua çağrısı - 'Ezan.", "Ezan"),
            ("Allah'ı anma (zikir) sözlerini söylemek ve Kur'an okumak", "Zikir ve Kur'an Tilaveti")
        ]

        if let matched = specificReplacements.first(where: { result.localizedCaseInsensitiveContains($0.0) }) {
            return matched.1
        }

        result = result
            .replacingOccurrences(of: "Peygamber (s.a.v.) şöyle buyurmuştur:", with: "")
            .replacingOccurrences(of: "Peygamber (sav) şöyle buyurmuştur:", with: "")
            .replacingOccurrences(of: "Peygamber (sav) şöyle buyurdu:", with: "")
            .replacingOccurrences(of: "Peygamber (s.a.v.) şöyle buyurdu:", with: "")
            .replacingOccurrences(of: "Peygamber (ﷺ) buyurdu ki:", with: "")
            .replacingOccurrences(of: "Peygamber (ﷺ) şöyle buyurmuştur:", with: "")
            .replacingOccurrences(of: "Peygamber (ﷺ) şöyle buyurdu:", with: "")
            .replacingOccurrences(of: "Allah Resulü (s.a.v.) şöyle buyurmuştur:", with: "")
            .replacingOccurrences(of: "Allah Resulü (s.a.v.) şöyle buyurdu:", with: "")
            .replacingOccurrences(of: "Allah Resulü (ﷺ) şöyle buyurmuştur:", with: "")
            .replacingOccurrences(of: "Allah Resulü (ﷺ) şöyle buyurdu:", with: "")
            .replacingOccurrences(of: "Abdullah bin Ömer (RA) şöyle dedi:", with: "")
            .replacingOccurrences(of: "Bir adam Peygamber Efendimiz (sav)'e", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'‘’ ").union(.whitespacesAndNewlines))

        if let colonIndex = result.firstIndex(of: ":"), result.distance(from: result.startIndex, to: colonIndex) < 80 {
            let tail = result[result.index(after: colonIndex)...].trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'‘’ ").union(.whitespacesAndNewlines))
            if !tail.isEmpty {
                result = tail
            }
        }

        let firstSentence = result
            .components(separatedBy: CharacterSet(charactersIn: ".!?;\n"))
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'‘’ ").union(.whitespacesAndNewlines)) }
            .first(where: { !$0.isEmpty }) ?? result

        return shortenedTitleCandidate(firstSentence)
    }

    static func refinedTransliterationMap(_ base: [String: String], entryID: String) -> [String: String] {
        var result = base

        if let override = specificTurkishTransliterationOverrides[entryID] {
            result["tr"] = override
            return result
        }

        if let turkishText = trimmed(base["tr"]) ?? trimmed(base["en"]) {
            result["tr"] = turkishizeTransliteration(turkishText)
        }

        return result
    }

    static func refinedMeaningMap(_ base: [String: String], entryID: String) -> [String: String] {
        var result = base

        if let override = specificTurkishMeaningOverrides[entryID] {
            result["tr"] = override
            return result
        }

        if let turkishMeaning = trimmed(base["tr"]) {
            result["tr"] = refineTurkishMeaning(turkishMeaning)
        }

        return result
    }

    static func localizedSourceLabelMap(for source: GuideSourceReference) -> [String: String] {
        let cleanedReference = cleanedReferenceText(source.hadithReference)
        let english = buildSourceLabel(
            primaryBook: localizedBookTitle(source.primaryBook, languageCode: "en"),
            reference: localizedReference(cleanedReference, languageCode: "en")
        )
        let turkish = buildSourceLabel(
            primaryBook: localizedBookTitle(source.primaryBook, languageCode: "tr"),
            reference: localizedReference(cleanedReference, languageCode: "tr")
        )
        let arabic = buildSourceLabel(
            primaryBook: localizedBookTitle(source.primaryBook, languageCode: "ar"),
            reference: localizedReference(cleanedReference, languageCode: "ar")
        )

        var result: [String: String] = [:]
        for code in supportedLanguageCodes {
            switch code {
            case "tr":
                result[code] = turkish
            case "ar":
                result[code] = arabic
            default:
                result[code] = english
            }
        }

        return result
    }

    private static let specificTurkishTitleOverrides: [String: String] = [
        "hisnul-muslim-017": "Evden Çıkarken Dua"
    ]

    private static let specificTurkishTransliterationOverrides: [String: String] = [:]

    private static let specificTurkishMeaningOverrides: [String: String] = [
        "hisnul-muslim-017": "Allah'ım! Sapmaktan ya da saptırılmaktan, ayağımın kaymasından ya da kaydırılmaktan, zulmetmekten ya da zulme uğramaktan, cahillik etmekten ya da cahillerin davranışlarına maruz kalmaktan Sana sığınırım.",
        "hisnul-muslim-120": "Allah'ım, ben Senin kulunum; babam da annem de Senin kullarındandır. Benim iradem ve kaderim Senin elindedir. Hakkımdaki hükmün geçerlidir, takdirin ise tam bir adalettir. Kendine verdiğin, kitabında indirdiğin, kullarından birine öğrettiğin yahut gayb ilminde sadece Kendine sakladığın bütün isimlerinle Senden diliyorum: Kur'an'ı kalbimin baharı, göğsümün nuru, hüznümün gidericisi ve sıkıntımın ferahlığı kıl."
    ]

    private static func refineTurkishTitle(_ title: String) -> String {
        var result = title

        let replacements: [(String, String)] = [
            (" anma", " dua"),
            ("Anma", "Dua"),
            (" hatırlama", " dua"),
            ("Hatırlama", "Dua"),
            ("Eve girince", "Eve girerken"),
            ("Evden çıkarken dua", "Evden Çıkarken Dua"),
            ("Eve girerken dua", "Eve Girerken Dua")
        ]

        for (source, target) in replacements {
            result = result.replacingOccurrences(of: source, with: target)
        }

        result = result.replacingOccurrences(
            of: #"\s{2,}"#,
            with: " ",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func refineTurkishMeaning(_ meaning: String) -> String {
        var result = meaning

        let replacements: [(String, String)] = [
            (
                "erkek kölenin oğlu ve kadın kölenin oğluyum",
                "babam da annem de Senin kullarındandır"
            ),
            (
                "erkek kölenin oğlu ve kadın kölenin oğluyum.",
                "babam da annem de Senin kullarındandır."
            )
        ]

        for (source, target) in replacements {
            result = result.replacingOccurrences(of: source, with: target)
        }

        result = result.replacingOccurrences(
            of: #"\s{2,}"#,
            with: " ",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func titleCandidateFromArabic(_ text: String?) -> String? {
        guard let text = trimmed(text) else { return nil }
        let firstLine = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        return shortenedTitleCandidate(firstLine)
    }

    private static func shortenedTitleCandidate(_ text: String?) -> String? {
        guard let text = trimmed(text) else { return nil }

        var candidate = text
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'‘’.,:; ").union(.whitespacesAndNewlines))

        guard candidate.count >= 3 else { return nil }

        if candidate.count > 72 {
            let words = candidate.split(separator: " ")
            if words.count > 7 {
                candidate = words.prefix(7).joined(separator: " ")
            } else {
                candidate = String(candidate.prefix(72))
            }
        }

        return candidate.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'‘’.,:; ").union(.whitespacesAndNewlines))
    }

    private static func hasArtificialOrdinalSuffix(_ text: String) -> Bool {
        text.range(of: #"\([0-9A-Za-z]+\)\s*$"#, options: .regularExpression) != nil
    }

    private static func stripOrdinalSuffix(from text: String) -> String {
        text
            .replacingOccurrences(of: #"\s*\([0-9A-Za-z]+\)\s*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func turkishizeTransliteration(_ text: String) -> String {
        var result = text

        let directReplacements: [(String, String)] = [
            ("`", ""),
            ("‘", ""),
            ("’", ""),
            ("ʻ", ""),
            ("ʿ", ""),
            ("ʼ", ""),
            ("Ā", "Â"),
            ("ā", "â"),
            ("Ī", "Î"),
            ("ī", "î"),
            ("Ū", "Û"),
            ("ū", "û"),
            ("Ḥ", "H"),
            ("ḥ", "h"),
            ("Ṣ", "S"),
            ("ṣ", "s"),
            ("Ṭ", "T"),
            ("ṭ", "t"),
            ("Ḍ", "D"),
            ("ḍ", "d"),
            ("Ẓ", "Z"),
            ("ẓ", "z"),
            ("Gh", "Ğ"),
            ("gh", "ğ"),
            ("Sh", "Ş"),
            ("sh", "ş"),
            ("Kh", "H"),
            ("kh", "h"),
            ("Dh", "Z"),
            ("dh", "z"),
            ("Th", "S"),
            ("th", "s"),
            ("J", "C"),
            ("j", "c"),
            ("W", "V"),
            ("w", "v"),
            ("Q", "K"),
            ("q", "k")
        ]

        for (source, target) in directReplacements {
            result = result.replacingOccurrences(of: source, with: target)
        }

        let wholeWordReplacements: [(String, String)] = [
            ("Allâhumma", "Allahumme"),
            ("Allahumma", "Allahumme"),
            ("wa", "ve"),
            ("Wa", "Ve"),
            ("aw", "ev"),
            ("Aw", "Ev"),
            ("huva", "huve"),
            ("Huva", "Huve")
        ]

        for (source, target) in wholeWordReplacements {
            result = replacingWholeWord(source, with: target, in: result)
        }

        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: " .", with: ".")
        result = result.replacingOccurrences(
            of: #"[ ]{2,}"#,
            with: " ",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func replacingWholeWord(_ source: String, with target: String, in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"(?<!\p{L})\#(source)(?!\p{L})"#) else {
            return text
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: target)
    }

    private static func cleanedReferenceText(_ reference: String?) -> String? {
        guard var result = trimmed(reference) else { return nil }

        let cutMarkers = [
            " says that ",
            " said that ",
            " where the Prophet said ",
            " and that the devil",
            " hearing this, says:"
        ]

        for marker in cutMarkers {
            if let range = result.range(of: marker, options: .caseInsensitive) {
                result = String(result[..<range.lowerBound])
            }
        }

        result = result
            .replacingOccurrences(of: "{", with: "(")
            .replacingOccurrences(of: "}", with: ")")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: " .", with: ".")
            .replacingOccurrences(
                of: #"\s{2,}"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".;")))

        return result.isEmpty ? nil : result
    }

    private static func localizedBookTitle(_ title: String, languageCode: String) -> String {
        switch languageCode {
        case "tr":
            return localizedSourceFragment(title, replacements: turkishSourceReplacements)
        case "ar":
            return localizedSourceFragment(title, replacements: arabicSourceReplacements)
        default:
            return title
        }
    }

    private static func localizedReference(_ reference: String?, languageCode: String) -> String? {
        guard let reference = reference else { return nil }

        switch languageCode {
        case "tr":
            return localizedSourceFragment(reference, replacements: turkishSourceReplacements)
        case "ar":
            return localizedSourceFragment(reference, replacements: arabicSourceReplacements)
        default:
            return reference
        }
    }

    private static func localizedSourceFragment(_ text: String, replacements: [(String, String)]) -> String {
        var result = text

        for (source, target) in replacements {
            result = result.replacingOccurrences(
                of: source,
                with: target,
                options: .caseInsensitive
            )
        }

        result = result
            .replacingOccurrences(
                of: #"\s{2,}"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    private static func buildSourceLabel(primaryBook: String, reference: String?) -> String {
        [trimmed(primaryBook), reference]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private static let turkishSourceReplacements: [(String, String)] = [
        ("Hisn al-Muslim", "Hüsnü'l Müslim"),
        ("Al-Bukhari", "Buhârî"),
        ("Bukhari", "Buhârî"),
        ("Muslim", "Müslim"),
        ("Abu Dawud", "Ebû Dâvûd"),
        ("Ibn Majah", "İbn Mâce"),
        ("An-Nasa'i", "Nesâî"),
        ("At-Tirmidhi", "Tirmizî"),
        ("Tirmidhi", "Tirmizî"),
        ("Ahmad", "Ahmed"),
        ("Al-Albani", "Elbânî"),
        ("Al-Asqalani", "İbn Hacer el-Askalânî"),
        ("Fathul-Bari", "Fethu'l-Bârî"),
        ("Sahih", "Sahîh"),
        ("See also", "Ayrıca bkz."),
        ("cf.", "bkz."),
        ("graded it authentic", "bunu sahih kabul etmiştir"),
        ("Hadith no.", "Hadis no.")
    ]

    private static let arabicSourceReplacements: [(String, String)] = [
        ("Hisn al-Muslim", "حصن المسلم"),
        ("Al-Bukhari", "البخاري"),
        ("Bukhari", "البخاري"),
        ("Muslim", "مسلم"),
        ("Abu Dawud", "أبو داود"),
        ("Ibn Majah", "ابن ماجه"),
        ("An-Nasa'i", "النسائي"),
        ("At-Tirmidhi", "الترمذي"),
        ("Tirmidhi", "الترمذي"),
        ("Ahmad", "أحمد"),
        ("Al-Albani", "الألباني"),
        ("Al-Asqalani", "ابن حجر العسقلاني"),
        ("Fathul-Bari", "فتح الباري"),
        ("See also", "انظر أيضًا"),
        ("cf.", "راجع"),
        ("Hadith no.", "رقم الحديث")
    ]
}
