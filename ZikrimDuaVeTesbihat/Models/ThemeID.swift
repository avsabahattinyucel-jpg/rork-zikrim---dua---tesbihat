import SwiftUI

enum ThemeID: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case `default` = "default"
    case nightMosque = "night_mosque"
    case islamicGreen = "islamic_green"
    case deepSpiritual = "deep_spiritual"
    case desertDawn = "desert_dawn"
    case roseGarden = "rose_garden"
    case sapphireCourtyard = "sapphire_courtyard"
    case amberMihrab = "amber_mihrab"
    case lunarPearl = "lunar_pearl"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default:
            return L10n.string(.themeDefault)
        case .nightMosque:
            return L10n.string(.themeNightMosque)
        case .islamicGreen:
            return String(localized: "theme_islamic_green", defaultValue: "Islamic Green")
        case .deepSpiritual:
            return String(localized: "theme_deep_spiritual", defaultValue: "Deep Spiritual")
        case .desertDawn:
            return String(localized: "theme_desert_dawn", defaultValue: "Desert Dawn")
        case .roseGarden:
            return String(localized: "theme_rose_garden", defaultValue: "Rose Garden")
        case .sapphireCourtyard:
            return String(localized: "theme_sapphire_courtyard", defaultValue: "Sapphire Courtyard")
        case .amberMihrab:
            return String(localized: "theme_amber_mihrab", defaultValue: "Amber Mihrab")
        case .lunarPearl:
            return String(localized: "theme_lunar_pearl", defaultValue: "Lunar Pearl")
        }
    }

    var subtitle: String {
        switch self {
        case .default:
            return String(localized: "theme_subtitle_default", defaultValue: "Temiz, dengeli ve ferah")
        case .nightMosque:
            return String(localized: "theme_subtitle_night_mosque", defaultValue: "Gece mavisi ve derin sakinlik")
        case .islamicGreen:
            return String(localized: "theme_subtitle_islamic_green", defaultValue: "Canli yesil ve dogal yuzeyler")
        case .deepSpiritual:
            return String(localized: "theme_subtitle_deep_spiritual", defaultValue: "Daha koyu, daha mistik bir ton")
        case .desertDawn:
            return String(localized: "theme_subtitle_desert_dawn", defaultValue: "Kum tonlari ve yumusak gunes isigi")
        case .roseGarden:
            return String(localized: "theme_subtitle_rose_garden", defaultValue: "Gul kurusu, krem ve sicak huzur")
        case .sapphireCourtyard:
            return String(localized: "theme_subtitle_sapphire_courtyard", defaultValue: "Safir, tas yuzeyler ve serin denge")
        case .amberMihrab:
            return String(localized: "theme_subtitle_amber_mihrab", defaultValue: "Kehribar parilti ve dingin altin katmanlar")
        case .lunarPearl:
            return String(localized: "theme_subtitle_lunar_pearl", defaultValue: "Inci beyazi, gumus mavi ve gece sakinligi")
        }
    }

    var icon: String {
        switch self {
        case .default:
            return "circle.lefthalf.filled"
        case .nightMosque:
            return "moon.stars.fill"
        case .islamicGreen:
            return "leaf.fill"
        case .deepSpiritual:
            return "sparkles"
        case .desertDawn:
            return "sunrise.fill"
        case .roseGarden:
            return "heart.circle.fill"
        case .sapphireCourtyard:
            return "diamond.fill"
        case .amberMihrab:
            return "building.columns.fill"
        case .lunarPearl:
            return "moon.fill"
        }
    }

    var isPremium: Bool {
        self != .default
    }

    static let defaultTheme: ThemeID = .default
    static let minimalGold: ThemeID = .islamicGreen
    static let darkSpiritual: ThemeID = .deepSpiritual

    static func resolvePersistedValue(_ value: String?) -> ThemeID? {
        guard let value else { return nil }

        switch value {
        case "default", "default_theme":
            return .default
        case "night_mosque", "nightMosque":
            return .nightMosque
        case "minimal_gold", "islamic_green", "islamicGreen":
            return .islamicGreen
        case "dark_spiritual", "deep_spiritual", "deepSpiritual":
            return .deepSpiritual
        default:
            return ThemeID(rawValue: value)
        }
    }
}

enum AppAppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system:
            return L10n.string(.appearanceSystem)
        case .light:
            return L10n.string(.appearanceLight)
        case .dark:
            return L10n.string(.appearanceDark)
        }
    }

    var icon: String {
        switch self {
        case .system:
            return "gearshape.2.fill"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
