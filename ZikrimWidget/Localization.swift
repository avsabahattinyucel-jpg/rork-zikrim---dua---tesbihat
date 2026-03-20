import Foundation

nonisolated enum L10n {
    struct Key: Hashable {
        let raw: String
        let fallback: String

        nonisolated init(_ raw: String, fallback: String) {
            self.raw = raw
            self.fallback = fallback
        }
    }

    static var bundle: Bundle { .main }
    static var missingPlaceholder: String { "—" }

    static func string(_ key: Key) -> String {
        let value = bundle.localizedString(forKey: key.raw, value: nil, table: nil)
        if let englishValue = preferredEnglishFallback(for: key, localizedValue: value) {
            return englishValue
        }
        if value == key.raw {
            MissingKeyReporter.record(key: key.raw)
            return key.fallback.isEmpty ? missingPlaceholder : key.fallback
        }
        return value
    }

    static func format(_ key: Key, _ args: CVarArg...) -> String {
        String.localizedStringWithFormat(string(key), args)
    }

    private static func preferredEnglishFallback(for key: Key, localizedValue: String) -> String? {
        guard !currentLanguageCode.hasPrefix("tr") else { return nil }
        guard localizedValue == key.raw || (!key.fallback.isEmpty && localizedValue == key.fallback) else { return nil }
        guard let enBundle = localizedBundle(for: "en") else { return nil }
        let english = enBundle.localizedString(forKey: key.raw, value: nil, table: nil)
        guard english != key.raw, !english.isEmpty else { return nil }
        return english
    }

    private static var currentLanguageCode: String {
        Locale.preferredLanguages.first?.lowercased()
            ?? Locale.current.language.languageCode?.identifier.lowercased()
            ?? "en"
    }

    private static func localizedBundle(for code: String) -> Bundle? {
        guard let path = bundle.path(forResource: code, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }

    private enum MissingKeyReporter {
        #if DEBUG
        static func record(key: String) {
            print("[L10n] Missing localization for key: \(key)")
        }
        #else
        static func record(key: String) {
        }
        #endif
    }
}
