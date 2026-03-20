import Foundation

struct ThemePersistence {
    static let themeStorageKey = "selected_app_theme"
    static let legacyThemeStorageKey = "selected_premium_theme"
    static let appearanceStorageKey = "selected_app_appearance_mode"

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadThemeID() -> ThemeID? {
        if let theme = ThemeID.resolvePersistedValue(defaults.string(forKey: Self.themeStorageKey)) {
            return theme
        }

        guard let legacy = ThemeID.resolvePersistedValue(defaults.string(forKey: Self.legacyThemeStorageKey)) else {
            return nil
        }

        defaults.set(legacy.rawValue, forKey: Self.themeStorageKey)
        return legacy
    }

    func persist(themeID: ThemeID) {
        defaults.set(themeID.rawValue, forKey: Self.themeStorageKey)
    }

    func loadAppearanceMode() -> AppAppearanceMode? {
        guard let rawValue = defaults.string(forKey: Self.appearanceStorageKey) else {
            return nil
        }
        return AppAppearanceMode(rawValue: rawValue)
    }

    func persist(appearanceMode: AppAppearanceMode) {
        defaults.set(appearanceMode.rawValue, forKey: Self.appearanceStorageKey)
    }
}
