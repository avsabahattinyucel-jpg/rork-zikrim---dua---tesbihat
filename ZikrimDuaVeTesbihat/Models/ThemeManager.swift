import Combine
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var currentThemeID: ThemeID
    @Published private(set) var currentTheme: AppTheme
    @Published private(set) var navigationRefreshID = UUID()
    @Published var appearanceMode: AppAppearanceMode

    private let persistence: ThemePersistence
    private let appearanceCoordinator: ThemeAppearanceCoordinator
    private let persistsSelection: Bool
    private var lastSystemColorScheme: ColorScheme?

    var current: AppTheme { currentTheme }

    init(
        initialThemeID: ThemeID? = nil,
        initialAppearanceMode: AppAppearanceMode? = nil,
        persistsSelection: Bool = true,
        persistence: ThemePersistence? = nil,
        appearanceCoordinator: ThemeAppearanceCoordinator? = nil
    ) {
        self.persistence = persistence ?? ThemePersistence()
        self.appearanceCoordinator = appearanceCoordinator ?? ThemeAppearanceCoordinator()
        self.persistsSelection = persistsSelection

        let persistence = self.persistence

        let themeID = persistsSelection
            ? (persistence.loadThemeID() ?? initialThemeID ?? .default)
            : (initialThemeID ?? .default)
        let appearanceMode = persistsSelection
            ? (persistence.loadAppearanceMode() ?? initialAppearanceMode ?? .system)
            : (initialAppearanceMode ?? .system)

        self.currentThemeID = themeID
        self.appearanceMode = appearanceMode
        self.currentTheme = AppTheme.resolved(
            themeID: themeID,
            appearanceMode: appearanceMode,
            systemColorScheme: nil
        )

        self.appearanceCoordinator.apply(theme: currentTheme, reason: "init")
    }

    static func preview(theme: ThemeID = .default, appearanceMode: AppAppearanceMode = .dark) -> ThemeManager {
        ThemeManager(
            initialThemeID: theme,
            initialAppearanceMode: appearanceMode,
            persistsSelection: false
        )
    }

    func selectTheme(_ themeID: ThemeID) {
        guard currentThemeID != themeID else {
            debugLog("selected theme id=\(themeID.rawValue) unchanged=true")
            syncAppearance(using: lastSystemColorScheme, reason: "theme_reselected")
            return
        }

        currentThemeID = themeID
        if persistsSelection {
            persistence.persist(themeID: themeID)
        }

        debugLog("selected theme id=\(themeID.rawValue)")
        syncAppearance(using: lastSystemColorScheme, reason: "theme_selected")
    }

    func apply(_ themeID: ThemeID) {
        selectTheme(themeID)
    }

    func setTheme(_ themeID: ThemeID) {
        selectTheme(themeID)
    }

    func setAppearanceMode(_ mode: AppAppearanceMode) {
        guard appearanceMode != mode else {
            syncAppearance(using: lastSystemColorScheme, reason: "appearance_reselected")
            return
        }

        appearanceMode = mode
        if persistsSelection {
            persistence.persist(appearanceMode: mode)
        }

        debugLog("appearance mode=\(mode.rawValue)")
        syncAppearance(using: lastSystemColorScheme, reason: "appearance_changed")
    }

    func enforceSubscriptionAccess(isPremiumUnlocked: Bool) {
        guard !isPremiumUnlocked, currentThemeID.isPremium else { return }
        selectTheme(.default)
    }

    var preferredColorScheme: ColorScheme? {
        appearanceMode.preferredColorScheme
    }

    func palette(using systemColorScheme: ColorScheme?) -> ThemePalette {
        theme(for: currentThemeID, systemColorScheme: systemColorScheme)
    }

    func theme(for themeID: ThemeID, systemColorScheme: ColorScheme?) -> AppTheme {
        AppTheme.resolved(
            themeID: themeID,
            appearanceMode: appearanceMode,
            systemColorScheme: systemColorScheme ?? lastSystemColorScheme
        )
    }

    func resolvedIsDarkMode(using systemColorScheme: ColorScheme?) -> Bool {
        theme(for: currentThemeID, systemColorScheme: systemColorScheme).isDarkMode
    }

    func applyGlobalAppearance(using systemColorScheme: ColorScheme?) {
        syncAppearance(using: systemColorScheme, reason: "global_apply")
    }

    func syncAppearance(using systemColorScheme: ColorScheme?, reason: String = "sync") {
        lastSystemColorScheme = systemColorScheme

        let previousSignature = currentTheme.runtimeSignature
        let resolvedTheme = AppTheme.resolved(
            themeID: currentThemeID,
            appearanceMode: appearanceMode,
            systemColorScheme: systemColorScheme
        )

        currentTheme = resolvedTheme
        appearanceCoordinator.apply(theme: resolvedTheme, reason: reason)

        if previousSignature != resolvedTheme.runtimeSignature {
            navigationRefreshID = UUID()
            debugLog("navigation refresh triggered id=\(navigationRefreshID.uuidString)")
        }
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[ThemeManager] \(message)")
#endif
    }
}
