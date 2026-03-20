import Foundation

struct RabiaResponseSanitizer {
    static func containsThinkBlock(_ text: String) -> Bool {
        return text.range(of: "(?is)<think>.*?</think>", options: .regularExpression) != nil
    }

    static func sanitize(_ text: String) -> String {
        var stripped = text
        stripped = stripped.replacingOccurrences(
            of: "(?is)<think>.*?</think>",
            with: "",
            options: .regularExpression
        )
        stripped = stripped.replacingOccurrences(
            of: "(?is)^\\s*(okay|let me think|i need to|first, i should|now, the user|i should start by|however, i must|also, check if).*?(?=(\\n\\n|$))",
            with: "",
            options: .regularExpression
        )
        stripped = stripped.replacingOccurrences(
            of: "(?im)^\\s*</?think>\\s*$",
            with: "",
            options: .regularExpression
        )
        stripped = stripped.replacingOccurrences(
            of: "\\n{3,}",
            with: "\n\n",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        let cleaned = stripped.unicodeScalars.filter { scalar in
            let v = scalar.value
            if (0x0000...0x007F).contains(v) { return true }
            if (0x00A0...0x024F).contains(v) { return true }
            if (0x0250...0x02AF).contains(v) { return true }
            if (0x0300...0x036F).contains(v) { return true }
            if (0x0400...0x04FF).contains(v) { return true }
            if (0x0500...0x052F).contains(v) { return true }
            if (0x0600...0x06FF).contains(v) { return true }
            if (0x0750...0x077F).contains(v) { return true }
            if (0x08A0...0x08FF).contains(v) { return true }
            if (0xFB50...0xFDFF).contains(v) { return true }
            if (0xFE70...0xFEFF).contains(v) { return true }
            return false
        }

        return String(String.UnicodeScalarView(cleaned))
    }
}
