import Foundation

struct RabiaQuranSafetyFilter {
    static func apply(rawResponse: String, allowedRefs: Set<String>) -> String {
        let withoutQuotedVerseText = stripQuotedVerseText(aroundReferencesIn: rawResponse)
        let withoutStandaloneSurahPrefixes = stripStandaloneSurahNamePrefixes(in: withoutQuotedVerseText)
        let processed = processReferenceSpans(in: withoutStandaloneSurahPrefixes, allowedRefs: allowedRefs)

#if DEBUG
        if !processed.foundRefs.isEmpty {
            let joined = processed.foundRefs.joined(separator: ",")
            print("[RabiaQuranSafe] model_refs=\(joined)")
        }
        if !processed.removedRefs.isEmpty {
            let joined = processed.removedRefs.joined(separator: ",")
            print("[RabiaQuranSafe] removed_refs=\(joined)")
        }
#endif

        return cleanupText(processed.text)
    }

    static func renderVerifiedReferences(in text: String, allowedRefs: Set<String>) -> String {
        guard let refRegex = try? NSRegularExpression(pattern: #"\b(\d{1,3}:\d{1,3})\b"#) else {
            return text
        }

        var result = text
        let nsText = result as NSString
        let matches = refRegex.matches(in: result, range: NSRange(location: 0, length: nsText.length))
        for match in matches.reversed() {
            let ref = nsText.substring(with: match.range(at: 1))
            guard allowedRefs.contains(ref) else { continue }
            let parts = ref.split(separator: ":")
            guard parts.count == 2,
                  let surah = Int(parts[0]),
                  let ayah = Int(parts[1]),
                  let display = RabiaVerifiedSourceStore.shared.quranDisplayText(surah: surah, ayah: ayah),
                  let swiftRange = Range(match.range(at: 1), in: result) else {
                continue
            }
            result.replaceSubrange(swiftRange, with: display)
#if DEBUG
            print("[RabiaQuranSafe] rendered_refs=\(ref)")
#endif
        }

        return result
    }

    private static func processReferenceSpans(
        in text: String,
        allowedRefs: Set<String>
    ) -> (text: String, foundRefs: [String], removedRefs: [String]) {
        // Keep line structure intact by avoiding newline capture around references.
        let rangeSpan = #"(?i)\(?[ \t]*(\d{1,3}:\d{1,3}[ \t]*[-–—][ \t]*\d{1,3})[ \t]*\)?"#
        let singleSpan = #"(?i)\(?[ \t]*(\d{1,3}:\d{1,3})[ \t]*\)?"#

        guard let rangeRegex = try? NSRegularExpression(pattern: rangeSpan),
              let singleRegex = try? NSRegularExpression(pattern: singleSpan) else {
            return (text, [], [])
        }

        var result = text
        var found: [String] = []
        var removed: [String] = []

        let nsText = result as NSString
        let rangeMatches = rangeRegex.matches(in: result, range: NSRange(location: 0, length: nsText.length))
        for match in rangeMatches.reversed() {
            let rangeRef = nsText.substring(with: match.range(at: 1))
            found.append(normalizedRangeReference(rangeRef))
            removed.append(rangeRef.trimmingCharacters(in: .whitespacesAndNewlines))
            if let swiftRange = Range(match.range, in: result) {
                result.replaceSubrange(swiftRange, with: "")
            }
        }

        let nsAfterRange = result as NSString
        let singleMatches = singleRegex.matches(in: result, range: NSRange(location: 0, length: nsAfterRange.length))
        for match in singleMatches.reversed() {
            let ref = nsAfterRange.substring(with: match.range(at: 1))
            found.append(ref)
            if allowedRefs.contains(ref) {
                if let swiftRange = Range(match.range, in: result) {
                    result.replaceSubrange(swiftRange, with: ref)
                }
            } else {
                removed.append(ref)
                if let swiftRange = Range(match.range, in: result) {
                    result.replaceSubrange(swiftRange, with: "")
                }
            }
        }

        return (result, found, removed)
    }

    private static func stripQuotedVerseText(aroundReferencesIn text: String) -> String {
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(
            of: #"(\b\d{1,3}:\d{1,3}\b)\s*["“”«»][^"\n“”«»]+["“”«»]"#,
            with: "$1",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"["“”«»][^"\n“”«»]+["“”«»]\s*\(?\s*(\d{1,3}:\d{1,3}(?:\s*[-–—]\s*\d{1,3})?)\s*\)?"#,
            with: "$1",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"(?m)^\s*["“”«»][^"\n“”«»]+["“”«»]\s*$"#,
            with: "",
            options: .regularExpression
        )
        return cleaned
    }

    private static func stripStandaloneSurahNamePrefixes(in text: String) -> String {
        let surahNames = RabiaVerifiedSourceStore.shared.allSurahNames()
        guard !surahNames.isEmpty else { return text }

        let surahAlternation = surahNames
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")

        let pattern = "(?im)^\\s*(?:\(surahAlternation))\\s+(\\d{1,3}:\\d{1,3})\\s*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
    }

    private static func normalizedRangeReference(_ raw: String) -> String {
        raw.replacingOccurrences(of: #"\s*[-–—]\s*"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanupText(_ text: String) -> String {
        let original = text
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(of: #"\(\s*\)"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"(?m)\(\s*([,.;:!?-]+)\s*\)"#, with: "$1", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\s+([,.;:!?])"#, with: "$1", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\s+\n"#, with: "\n", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)

        let lines = cleaned.components(separatedBy: "\n").filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return false }
            if trimmed.range(of: #"^[-•*–—]+$"#, options: .regularExpression) != nil { return false }
            if trimmed.range(of: #"^[\(\)\[\]\{\}]+$"#, options: .regularExpression) != nil { return false }
            if trimmed.range(of: #"^[,.;:!?'"“”\-]+$"#, options: .regularExpression) != nil { return false }
            return true
        }

        let finalText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
#if DEBUG
        let changed = finalText != original
        print("cleanup_removed_broken_citation_fragments=\(changed)")
#endif
        return finalText
    }
}
