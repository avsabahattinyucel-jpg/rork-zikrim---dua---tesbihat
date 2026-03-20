import Foundation

nonisolated enum RabiaAppLanguage {
    nonisolated static func currentCode() -> String {
        let preferredLocalization = Bundle.main.preferredLocalizations.first ?? "tr"
        return AppLanguage(code: preferredLocalization).rawValue
    }

    nonisolated static func normalizedCode(for rawCode: String) -> String {
        AppLanguage(code: rawCode).rawValue
    }

    nonisolated static func displayName(for code: String) -> String {
        AppLanguage(code: code).displayName
    }
}
