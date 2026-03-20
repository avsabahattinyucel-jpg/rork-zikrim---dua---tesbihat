import SwiftUI
import UIKit

struct ThemeTone {
    let light: Color
    let dark: Color

    func resolve(isDarkMode: Bool) -> Color {
        isDarkMode ? dark : light
    }
}

struct ThemeGradientTone {
    let light: [Color]
    let dark: [Color]

    func colors(isDarkMode: Bool) -> [Color] {
        isDarkMode ? dark : light
    }

    func gradient(
        isDarkMode: Bool,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
        LinearGradient(
            colors: colors(isDarkMode: isDarkMode),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

private struct AppThemeSpec {
    let accent: ThemeTone
    let accentSoft: ThemeTone
    let pageBackground: ThemeTone
    let secondaryBackground: ThemeTone
    let cardBackground: ThemeTone
    let elevatedCardBackground: ThemeTone
    let primaryText: ThemeTone
    let secondaryText: ThemeTone
    let mutedText: ThemeTone
    let divider: ThemeTone
    let heroGradient: ThemeGradientTone
    let rabiaAccent: ThemeTone
    let rabiaGlow: ThemeTone
    let rabiaAssistantBubble: ThemeTone
    let rabiaUserBubble: ThemeTone
    let rabiaAssistantText: ThemeTone
    let rabiaUserText: ThemeTone
    let rabiaInputBorder: ThemeTone
    let rabiaSendButton: ThemeTone
    let rabiaHeaderAccent: ThemeTone
    let rabiaBackgroundTop: ThemeTone
    let rabiaBackgroundBottom: ThemeTone
    let rabiaSurface: ThemeTone
    let rabiaSurfaceBorder: ThemeTone
    let rabiaComposerBackground: ThemeTone
    let rabiaPlaceholderText: ThemeTone
    let rabiaTypingDot: ThemeTone
    let rabiaLauncherBorder: ThemeTone

    static func harmonized(
        accent: ThemeTone,
        accentSoft: ThemeTone,
        pageBackground: ThemeTone,
        secondaryBackground: ThemeTone,
        cardBackground: ThemeTone,
        elevatedCardBackground: ThemeTone,
        primaryText: ThemeTone,
        secondaryText: ThemeTone,
        mutedText: ThemeTone,
        divider: ThemeTone,
        heroGradient: ThemeGradientTone,
        rabiaUserBubble: ThemeTone? = nil
    ) -> AppThemeSpec {
        let assistantBubble = ThemeTone(
            light: cardBackground.light.opacity(0.96),
            dark: cardBackground.dark
        )

        return AppThemeSpec(
            accent: accent,
            accentSoft: accentSoft,
            pageBackground: pageBackground,
            secondaryBackground: secondaryBackground,
            cardBackground: cardBackground,
            elevatedCardBackground: elevatedCardBackground,
            primaryText: primaryText,
            secondaryText: secondaryText,
            mutedText: mutedText,
            divider: divider,
            heroGradient: heroGradient,
            rabiaAccent: accent,
            rabiaGlow: accentSoft,
            rabiaAssistantBubble: assistantBubble,
            rabiaUserBubble: rabiaUserBubble ?? ThemeTone(
                light: accent.light,
                dark: accent.dark.opacity(0.72)
            ),
            rabiaAssistantText: primaryText,
            rabiaUserText: ThemeTone(light: .white, dark: .white),
            rabiaInputBorder: ThemeTone(
                light: divider.light.opacity(0.92),
                dark: divider.dark.opacity(0.96)
            ),
            rabiaSendButton: accent,
            rabiaHeaderAccent: accentSoft,
            rabiaBackgroundTop: pageBackground,
            rabiaBackgroundBottom: secondaryBackground,
            rabiaSurface: ThemeTone(
                light: Color.white.opacity(0.88),
                dark: Color.white.opacity(0.06)
            ),
            rabiaSurfaceBorder: ThemeTone(
                light: divider.light.opacity(0.50),
                dark: Color.white.opacity(0.08)
            ),
            rabiaComposerBackground: ThemeTone(
                light: Color.white.opacity(0.92),
                dark: Color.white.opacity(0.06)
            ),
            rabiaPlaceholderText: mutedText,
            rabiaTypingDot: accent,
            rabiaLauncherBorder: ThemeTone(
                light: Color.white.opacity(0.88),
                dark: Color.white.opacity(0.24)
            )
        )
    }

    static func make(for themeID: ThemeID) -> AppThemeSpec {
        switch themeID {
        case .default:
            return AppThemeSpec(
                accent: ThemeTone(light: Color(red: 0.10, green: 0.62, blue: 0.58), dark: Color(red: 0.24, green: 0.74, blue: 0.68)),
                accentSoft: ThemeTone(light: Color(red: 0.55, green: 0.86, blue: 0.80), dark: Color(red: 0.58, green: 0.87, blue: 0.82)),
                pageBackground: ThemeTone(light: Color(red: 0.95, green: 0.97, blue: 0.98), dark: Color(red: 0.05, green: 0.08, blue: 0.11)),
                secondaryBackground: ThemeTone(light: Color(red: 0.90, green: 0.95, blue: 0.96), dark: Color(red: 0.08, green: 0.12, blue: 0.15)),
                cardBackground: ThemeTone(light: .white, dark: Color(red: 0.10, green: 0.14, blue: 0.18)),
                elevatedCardBackground: ThemeTone(light: Color(red: 0.98, green: 1.0, blue: 1.0), dark: Color(red: 0.12, green: 0.18, blue: 0.22)),
                primaryText: ThemeTone(light: Color(red: 0.08, green: 0.11, blue: 0.14), dark: .white),
                secondaryText: ThemeTone(light: Color.black.opacity(0.62), dark: Color.white.opacity(0.72)),
                mutedText: ThemeTone(light: Color.black.opacity(0.40), dark: Color.white.opacity(0.45)),
                divider: ThemeTone(light: Color(red: 0.10, green: 0.62, blue: 0.58).opacity(0.18), dark: Color(red: 0.24, green: 0.74, blue: 0.68).opacity(0.30)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.11, green: 0.58, blue: 0.54), Color(red: 0.55, green: 0.86, blue: 0.80)],
                    dark: [Color(red: 0.04, green: 0.14, blue: 0.32), Color(red: 0.04, green: 0.36, blue: 0.40)]
                ),
                rabiaAccent: ThemeTone(light: Color(red: 0.11, green: 0.56, blue: 0.52), dark: Color(red: 0.22, green: 0.73, blue: 0.66)),
                rabiaGlow: ThemeTone(light: Color(red: 0.33, green: 0.80, blue: 0.72), dark: Color(red: 0.40, green: 0.88, blue: 0.80)),
                rabiaAssistantBubble: ThemeTone(light: Color(red: 0.97, green: 0.99, blue: 1.0), dark: Color(red: 0.12, green: 0.16, blue: 0.20)),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.12, green: 0.47, blue: 0.42), dark: Color(red: 0.17, green: 0.38, blue: 0.34)),
                rabiaAssistantText: ThemeTone(light: Color(red: 0.10, green: 0.14, blue: 0.18), dark: .white),
                rabiaUserText: ThemeTone(light: .white, dark: .white),
                rabiaInputBorder: ThemeTone(light: Color(red: 0.26, green: 0.72, blue: 0.65).opacity(0.28), dark: Color(red: 0.32, green: 0.81, blue: 0.73).opacity(0.42)),
                rabiaSendButton: ThemeTone(light: Color(red: 0.11, green: 0.58, blue: 0.54), dark: Color(red: 0.22, green: 0.73, blue: 0.66)),
                rabiaHeaderAccent: ThemeTone(light: Color(red: 0.10, green: 0.60, blue: 0.56), dark: Color(red: 0.58, green: 0.87, blue: 0.82)),
                rabiaBackgroundTop: ThemeTone(light: Color(red: 0.92, green: 0.97, blue: 0.97), dark: Color(red: 0.06, green: 0.08, blue: 0.10)),
                rabiaBackgroundBottom: ThemeTone(light: Color(red: 0.85, green: 0.93, blue: 0.93), dark: Color(red: 0.09, green: 0.11, blue: 0.14)),
                rabiaSurface: ThemeTone(light: Color.white.opacity(0.86), dark: Color.white.opacity(0.05)),
                rabiaSurfaceBorder: ThemeTone(light: Color(red: 0.18, green: 0.56, blue: 0.52).opacity(0.12), dark: Color.white.opacity(0.08)),
                rabiaComposerBackground: ThemeTone(light: Color.white.opacity(0.92), dark: Color.white.opacity(0.05)),
                rabiaPlaceholderText: ThemeTone(light: Color.black.opacity(0.42), dark: Color.white.opacity(0.52)),
                rabiaTypingDot: ThemeTone(light: Color(red: 0.10, green: 0.52, blue: 0.48), dark: Color.white.opacity(0.92)),
                rabiaLauncherBorder: ThemeTone(light: Color.white.opacity(0.86), dark: Color.white.opacity(0.28))
            )
        case .nightMosque:
            return AppThemeSpec(
                accent: ThemeTone(light: Color(red: 0.20, green: 0.46, blue: 0.74), dark: Color(red: 0.36, green: 0.62, blue: 0.90)),
                accentSoft: ThemeTone(light: Color(red: 0.62, green: 0.80, blue: 0.98), dark: Color(red: 0.55, green: 0.76, blue: 1.0)),
                pageBackground: ThemeTone(light: Color(red: 0.90, green: 0.94, blue: 0.99), dark: Color(red: 0.03, green: 0.06, blue: 0.13)),
                secondaryBackground: ThemeTone(light: Color(red: 0.84, green: 0.90, blue: 0.98), dark: Color(red: 0.06, green: 0.10, blue: 0.19)),
                cardBackground: ThemeTone(light: Color(red: 0.95, green: 0.97, blue: 1.0), dark: Color(red: 0.08, green: 0.12, blue: 0.22)),
                elevatedCardBackground: ThemeTone(light: .white, dark: Color(red: 0.10, green: 0.16, blue: 0.28)),
                primaryText: ThemeTone(light: Color(red: 0.07, green: 0.12, blue: 0.22), dark: .white),
                secondaryText: ThemeTone(light: Color(red: 0.17, green: 0.27, blue: 0.38), dark: Color.white.opacity(0.72)),
                mutedText: ThemeTone(light: Color(red: 0.20, green: 0.30, blue: 0.42).opacity(0.65), dark: Color.white.opacity(0.45)),
                divider: ThemeTone(light: Color(red: 0.20, green: 0.46, blue: 0.74).opacity(0.22), dark: Color(red: 0.36, green: 0.62, blue: 0.90).opacity(0.38)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.18, green: 0.42, blue: 0.74), Color(red: 0.62, green: 0.80, blue: 0.98)],
                    dark: [Color(red: 0.05, green: 0.10, blue: 0.25), Color(red: 0.15, green: 0.25, blue: 0.45)]
                ),
                rabiaAccent: ThemeTone(light: Color(red: 0.18, green: 0.42, blue: 0.74), dark: Color(red: 0.30, green: 0.55, blue: 0.80)),
                rabiaGlow: ThemeTone(light: Color(red: 0.45, green: 0.70, blue: 0.98), dark: Color(red: 0.54, green: 0.74, blue: 1.0)),
                rabiaAssistantBubble: ThemeTone(light: Color(red: 0.96, green: 0.98, blue: 1.0), dark: Color(red: 0.08, green: 0.12, blue: 0.22)),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.17, green: 0.36, blue: 0.66), dark: Color(red: 0.17, green: 0.32, blue: 0.55)),
                rabiaAssistantText: ThemeTone(light: Color(red: 0.07, green: 0.12, blue: 0.22), dark: .white),
                rabiaUserText: ThemeTone(light: .white, dark: .white),
                rabiaInputBorder: ThemeTone(light: Color(red: 0.24, green: 0.47, blue: 0.76).opacity(0.28), dark: Color(red: 0.40, green: 0.63, blue: 0.95).opacity(0.40)),
                rabiaSendButton: ThemeTone(light: Color(red: 0.18, green: 0.42, blue: 0.74), dark: Color(red: 0.30, green: 0.55, blue: 0.80)),
                rabiaHeaderAccent: ThemeTone(light: Color(red: 0.22, green: 0.46, blue: 0.76), dark: Color(red: 0.62, green: 0.80, blue: 0.98)),
                rabiaBackgroundTop: ThemeTone(light: Color(red: 0.90, green: 0.94, blue: 0.99), dark: Color(red: 0.03, green: 0.06, blue: 0.13)),
                rabiaBackgroundBottom: ThemeTone(light: Color(red: 0.82, green: 0.88, blue: 0.98), dark: Color(red: 0.06, green: 0.10, blue: 0.19)),
                rabiaSurface: ThemeTone(light: Color.white.opacity(0.90), dark: Color.white.opacity(0.06)),
                rabiaSurfaceBorder: ThemeTone(light: Color(red: 0.20, green: 0.44, blue: 0.74).opacity(0.14), dark: Color.white.opacity(0.10)),
                rabiaComposerBackground: ThemeTone(light: Color.white.opacity(0.94), dark: Color.white.opacity(0.06)),
                rabiaPlaceholderText: ThemeTone(light: Color(red: 0.17, green: 0.27, blue: 0.38).opacity(0.60), dark: Color.white.opacity(0.52)),
                rabiaTypingDot: ThemeTone(light: Color(red: 0.20, green: 0.46, blue: 0.74), dark: Color.white.opacity(0.92)),
                rabiaLauncherBorder: ThemeTone(light: Color.white.opacity(0.88), dark: Color.white.opacity(0.30))
            )
        case .islamicGreen:
            return AppThemeSpec(
                accent: ThemeTone(light: Color(red: 0.12, green: 0.45, blue: 0.27), dark: Color(red: 0.46, green: 0.78, blue: 0.53)),
                accentSoft: ThemeTone(light: Color(red: 0.63, green: 0.84, blue: 0.66), dark: Color(red: 0.62, green: 0.88, blue: 0.68)),
                pageBackground: ThemeTone(light: Color(red: 0.94, green: 0.98, blue: 0.94), dark: Color(red: 0.04, green: 0.08, blue: 0.05)),
                secondaryBackground: ThemeTone(light: Color(red: 0.89, green: 0.95, blue: 0.89), dark: Color(red: 0.07, green: 0.11, blue: 0.08)),
                cardBackground: ThemeTone(light: Color(red: 0.98, green: 1.0, blue: 0.98), dark: Color(red: 0.10, green: 0.15, blue: 0.11)),
                elevatedCardBackground: ThemeTone(light: .white, dark: Color(red: 0.12, green: 0.18, blue: 0.13)),
                primaryText: ThemeTone(light: Color(red: 0.10, green: 0.20, blue: 0.12), dark: Color(red: 0.92, green: 0.97, blue: 0.92)),
                secondaryText: ThemeTone(light: Color(red: 0.20, green: 0.33, blue: 0.22), dark: Color(red: 0.76, green: 0.88, blue: 0.77)),
                mutedText: ThemeTone(light: Color(red: 0.20, green: 0.33, blue: 0.22).opacity(0.46), dark: Color(red: 0.76, green: 0.88, blue: 0.77).opacity(0.56)),
                divider: ThemeTone(light: Color(red: 0.12, green: 0.45, blue: 0.27).opacity(0.22), dark: Color(red: 0.46, green: 0.78, blue: 0.53).opacity(0.36)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.12, green: 0.45, blue: 0.27), Color(red: 0.63, green: 0.84, blue: 0.66)],
                    dark: [Color(red: 0.05, green: 0.11, blue: 0.07), Color(red: 0.22, green: 0.38, blue: 0.24)]
                ),
                rabiaAccent: ThemeTone(light: Color(red: 0.11, green: 0.43, blue: 0.26), dark: Color(red: 0.35, green: 0.66, blue: 0.43)),
                rabiaGlow: ThemeTone(light: Color(red: 0.44, green: 0.76, blue: 0.50), dark: Color(red: 0.56, green: 0.90, blue: 0.63)),
                rabiaAssistantBubble: ThemeTone(light: Color(red: 0.96, green: 0.99, blue: 0.96), dark: Color(red: 0.08, green: 0.13, blue: 0.09)),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.12, green: 0.45, blue: 0.27), dark: Color(red: 0.15, green: 0.27, blue: 0.18)),
                rabiaAssistantText: ThemeTone(light: Color(red: 0.10, green: 0.20, blue: 0.12), dark: Color(red: 0.92, green: 0.97, blue: 0.92)),
                rabiaUserText: ThemeTone(light: .white, dark: Color(red: 0.93, green: 0.98, blue: 0.93)),
                rabiaInputBorder: ThemeTone(light: Color(red: 0.12, green: 0.45, blue: 0.27).opacity(0.20), dark: Color(red: 0.46, green: 0.78, blue: 0.53).opacity(0.34)),
                rabiaSendButton: ThemeTone(light: Color(red: 0.12, green: 0.45, blue: 0.27), dark: Color(red: 0.35, green: 0.66, blue: 0.43)),
                rabiaHeaderAccent: ThemeTone(light: Color(red: 0.18, green: 0.53, blue: 0.32), dark: Color(red: 0.62, green: 0.88, blue: 0.68)),
                rabiaBackgroundTop: ThemeTone(light: Color(red: 0.93, green: 0.97, blue: 0.93), dark: Color(red: 0.04, green: 0.08, blue: 0.05)),
                rabiaBackgroundBottom: ThemeTone(light: Color(red: 0.87, green: 0.94, blue: 0.87), dark: Color(red: 0.07, green: 0.11, blue: 0.08)),
                rabiaSurface: ThemeTone(light: Color.white.opacity(0.88), dark: Color.white.opacity(0.05)),
                rabiaSurfaceBorder: ThemeTone(light: Color(red: 0.12, green: 0.45, blue: 0.27).opacity(0.10), dark: Color.white.opacity(0.08)),
                rabiaComposerBackground: ThemeTone(light: Color.white.opacity(0.92), dark: Color.white.opacity(0.05)),
                rabiaPlaceholderText: ThemeTone(light: Color(red: 0.20, green: 0.33, blue: 0.22).opacity(0.55), dark: Color(red: 0.80, green: 0.92, blue: 0.81).opacity(0.64)),
                rabiaTypingDot: ThemeTone(light: Color(red: 0.12, green: 0.45, blue: 0.27), dark: Color(red: 0.92, green: 0.97, blue: 0.92)),
                rabiaLauncherBorder: ThemeTone(light: Color.white.opacity(0.86), dark: Color.white.opacity(0.24))
            )
        case .deepSpiritual:
            return AppThemeSpec(
                accent: ThemeTone(light: Color(red: 0.42, green: 0.27, blue: 0.64), dark: Color(red: 0.62, green: 0.50, blue: 0.86)),
                accentSoft: ThemeTone(light: Color(red: 0.80, green: 0.72, blue: 0.94), dark: Color(red: 0.83, green: 0.76, blue: 0.98)),
                pageBackground: ThemeTone(light: Color(red: 0.95, green: 0.93, blue: 0.98), dark: Color(red: 0.05, green: 0.04, blue: 0.09)),
                secondaryBackground: ThemeTone(light: Color(red: 0.90, green: 0.87, blue: 0.96), dark: Color(red: 0.08, green: 0.06, blue: 0.13)),
                cardBackground: ThemeTone(light: Color(red: 0.98, green: 0.97, blue: 1.0), dark: Color(red: 0.10, green: 0.08, blue: 0.14)),
                elevatedCardBackground: ThemeTone(light: .white, dark: Color(red: 0.13, green: 0.10, blue: 0.18)),
                primaryText: ThemeTone(light: Color(red: 0.18, green: 0.12, blue: 0.25), dark: .white),
                secondaryText: ThemeTone(light: Color(red: 0.33, green: 0.23, blue: 0.42), dark: Color.white.opacity(0.72)),
                mutedText: ThemeTone(light: Color(red: 0.33, green: 0.23, blue: 0.42).opacity(0.45), dark: Color.white.opacity(0.45)),
                divider: ThemeTone(light: Color(red: 0.42, green: 0.27, blue: 0.64).opacity(0.22), dark: Color(red: 0.62, green: 0.50, blue: 0.86).opacity(0.38)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.52, green: 0.34, blue: 0.74), Color(red: 0.82, green: 0.72, blue: 0.94)],
                    dark: [Color(red: 0.08, green: 0.06, blue: 0.12), Color(red: 0.30, green: 0.20, blue: 0.45)]
                ),
                rabiaAccent: ThemeTone(light: Color(red: 0.40, green: 0.25, blue: 0.62), dark: Color(red: 0.55, green: 0.40, blue: 0.70)),
                rabiaGlow: ThemeTone(light: Color(red: 0.66, green: 0.55, blue: 0.88), dark: Color(red: 0.72, green: 0.60, blue: 0.92)),
                rabiaAssistantBubble: ThemeTone(light: Color(red: 0.98, green: 0.97, blue: 1.0), dark: Color(red: 0.10, green: 0.08, blue: 0.14)),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.41, green: 0.27, blue: 0.62), dark: Color(red: 0.28, green: 0.18, blue: 0.42)),
                rabiaAssistantText: ThemeTone(light: Color(red: 0.18, green: 0.12, blue: 0.25), dark: .white),
                rabiaUserText: ThemeTone(light: .white, dark: .white),
                rabiaInputBorder: ThemeTone(light: Color(red: 0.42, green: 0.27, blue: 0.64).opacity(0.24), dark: Color(red: 0.62, green: 0.50, blue: 0.86).opacity(0.36)),
                rabiaSendButton: ThemeTone(light: Color(red: 0.40, green: 0.25, blue: 0.62), dark: Color(red: 0.55, green: 0.40, blue: 0.70)),
                rabiaHeaderAccent: ThemeTone(light: Color(red: 0.42, green: 0.27, blue: 0.64), dark: Color(red: 0.83, green: 0.76, blue: 0.98)),
                rabiaBackgroundTop: ThemeTone(light: Color(red: 0.95, green: 0.93, blue: 0.98), dark: Color(red: 0.05, green: 0.04, blue: 0.09)),
                rabiaBackgroundBottom: ThemeTone(light: Color(red: 0.90, green: 0.87, blue: 0.96), dark: Color(red: 0.08, green: 0.06, blue: 0.13)),
                rabiaSurface: ThemeTone(light: Color.white.opacity(0.88), dark: Color.white.opacity(0.05)),
                rabiaSurfaceBorder: ThemeTone(light: Color(red: 0.42, green: 0.27, blue: 0.64).opacity(0.10), dark: Color.white.opacity(0.08)),
                rabiaComposerBackground: ThemeTone(light: Color.white.opacity(0.92), dark: Color.white.opacity(0.05)),
                rabiaPlaceholderText: ThemeTone(light: Color(red: 0.33, green: 0.23, blue: 0.42).opacity(0.54), dark: Color.white.opacity(0.52)),
                rabiaTypingDot: ThemeTone(light: Color(red: 0.40, green: 0.25, blue: 0.62), dark: Color.white.opacity(0.92)),
                rabiaLauncherBorder: ThemeTone(light: Color.white.opacity(0.88), dark: Color.white.opacity(0.24))
            )
        case .desertDawn:
            return .harmonized(
                accent: ThemeTone(light: Color(red: 0.79, green: 0.45, blue: 0.20), dark: Color(red: 0.95, green: 0.69, blue: 0.43)),
                accentSoft: ThemeTone(light: Color(red: 0.96, green: 0.81, blue: 0.63), dark: Color(red: 0.76, green: 0.55, blue: 0.31)),
                pageBackground: ThemeTone(light: Color(red: 0.99, green: 0.96, blue: 0.91), dark: Color(red: 0.11, green: 0.08, blue: 0.07)),
                secondaryBackground: ThemeTone(light: Color(red: 0.97, green: 0.91, blue: 0.84), dark: Color(red: 0.15, green: 0.11, blue: 0.09)),
                cardBackground: ThemeTone(light: Color(red: 1.0, green: 0.99, blue: 0.96), dark: Color(red: 0.18, green: 0.13, blue: 0.10)),
                elevatedCardBackground: ThemeTone(light: .white, dark: Color(red: 0.21, green: 0.15, blue: 0.12)),
                primaryText: ThemeTone(light: Color(red: 0.27, green: 0.18, blue: 0.12), dark: Color(red: 0.98, green: 0.94, blue: 0.88)),
                secondaryText: ThemeTone(light: Color(red: 0.47, green: 0.33, blue: 0.24), dark: Color(red: 0.90, green: 0.80, blue: 0.71)),
                mutedText: ThemeTone(light: Color(red: 0.47, green: 0.33, blue: 0.24).opacity(0.55), dark: Color(red: 0.90, green: 0.80, blue: 0.71).opacity(0.56)),
                divider: ThemeTone(light: Color(red: 0.79, green: 0.45, blue: 0.20).opacity(0.22), dark: Color(red: 0.95, green: 0.69, blue: 0.43).opacity(0.34)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.78, green: 0.52, blue: 0.28), Color(red: 0.96, green: 0.81, blue: 0.63)],
                    dark: [Color(red: 0.17, green: 0.11, blue: 0.08), Color(red: 0.44, green: 0.27, blue: 0.16)]
                ),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.74, green: 0.39, blue: 0.16), dark: Color(red: 0.39, green: 0.24, blue: 0.15))
            )
        case .roseGarden:
            return .harmonized(
                accent: ThemeTone(light: Color(red: 0.72, green: 0.30, blue: 0.42), dark: Color(red: 0.92, green: 0.60, blue: 0.70)),
                accentSoft: ThemeTone(light: Color(red: 0.96, green: 0.80, blue: 0.84), dark: Color(red: 0.84, green: 0.64, blue: 0.72)),
                pageBackground: ThemeTone(light: Color(red: 0.99, green: 0.95, blue: 0.96), dark: Color(red: 0.11, green: 0.06, blue: 0.08)),
                secondaryBackground: ThemeTone(light: Color(red: 0.97, green: 0.90, blue: 0.92), dark: Color(red: 0.16, green: 0.09, blue: 0.11)),
                cardBackground: ThemeTone(light: Color(red: 1.0, green: 0.98, blue: 0.99), dark: Color(red: 0.20, green: 0.11, blue: 0.14)),
                elevatedCardBackground: ThemeTone(light: .white, dark: Color(red: 0.24, green: 0.14, blue: 0.17)),
                primaryText: ThemeTone(light: Color(red: 0.27, green: 0.13, blue: 0.16), dark: Color(red: 0.99, green: 0.93, blue: 0.95)),
                secondaryText: ThemeTone(light: Color(red: 0.48, green: 0.27, blue: 0.33), dark: Color(red: 0.90, green: 0.73, blue: 0.79)),
                mutedText: ThemeTone(light: Color(red: 0.48, green: 0.27, blue: 0.33).opacity(0.52), dark: Color(red: 0.90, green: 0.73, blue: 0.79).opacity(0.56)),
                divider: ThemeTone(light: Color(red: 0.72, green: 0.30, blue: 0.42).opacity(0.22), dark: Color(red: 0.92, green: 0.60, blue: 0.70).opacity(0.34)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.74, green: 0.37, blue: 0.50), Color(red: 0.96, green: 0.80, blue: 0.84)],
                    dark: [Color(red: 0.17, green: 0.08, blue: 0.11), Color(red: 0.45, green: 0.22, blue: 0.30)]
                ),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.69, green: 0.28, blue: 0.39), dark: Color(red: 0.38, green: 0.18, blue: 0.24))
            )
        case .sapphireCourtyard:
            return .harmonized(
                accent: ThemeTone(light: Color(red: 0.15, green: 0.39, blue: 0.70), dark: Color(red: 0.42, green: 0.69, blue: 0.96)),
                accentSoft: ThemeTone(light: Color(red: 0.71, green: 0.86, blue: 0.99), dark: Color(red: 0.57, green: 0.76, blue: 0.94)),
                pageBackground: ThemeTone(light: Color(red: 0.94, green: 0.97, blue: 1.0), dark: Color(red: 0.04, green: 0.08, blue: 0.14)),
                secondaryBackground: ThemeTone(light: Color(red: 0.88, green: 0.93, blue: 0.98), dark: Color(red: 0.08, green: 0.13, blue: 0.21)),
                cardBackground: ThemeTone(light: Color(red: 0.98, green: 0.99, blue: 1.0), dark: Color(red: 0.10, green: 0.15, blue: 0.24)),
                elevatedCardBackground: ThemeTone(light: .white, dark: Color(red: 0.14, green: 0.19, blue: 0.28)),
                primaryText: ThemeTone(light: Color(red: 0.09, green: 0.17, blue: 0.30), dark: Color(red: 0.95, green: 0.97, blue: 1.0)),
                secondaryText: ThemeTone(light: Color(red: 0.23, green: 0.34, blue: 0.49), dark: Color(red: 0.78, green: 0.85, blue: 0.95)),
                mutedText: ThemeTone(light: Color(red: 0.23, green: 0.34, blue: 0.49).opacity(0.52), dark: Color(red: 0.78, green: 0.85, blue: 0.95).opacity(0.56)),
                divider: ThemeTone(light: Color(red: 0.15, green: 0.39, blue: 0.70).opacity(0.22), dark: Color(red: 0.42, green: 0.69, blue: 0.96).opacity(0.34)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.16, green: 0.42, blue: 0.74), Color(red: 0.71, green: 0.86, blue: 0.99)],
                    dark: [Color(red: 0.06, green: 0.12, blue: 0.22), Color(red: 0.20, green: 0.34, blue: 0.55)]
                ),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.14, green: 0.35, blue: 0.62), dark: Color(red: 0.14, green: 0.24, blue: 0.40))
            )
        case .amberMihrab:
            return .harmonized(
                accent: ThemeTone(light: Color(red: 0.67, green: 0.47, blue: 0.13), dark: Color(red: 0.93, green: 0.73, blue: 0.34)),
                accentSoft: ThemeTone(light: Color(red: 0.93, green: 0.83, blue: 0.58), dark: Color(red: 0.86, green: 0.72, blue: 0.29)),
                pageBackground: ThemeTone(light: Color(red: 0.99, green: 0.97, blue: 0.92), dark: Color(red: 0.10, green: 0.08, blue: 0.05)),
                secondaryBackground: ThemeTone(light: Color(red: 0.96, green: 0.92, blue: 0.82), dark: Color(red: 0.14, green: 0.11, blue: 0.07)),
                cardBackground: ThemeTone(light: Color(red: 1.0, green: 0.99, blue: 0.95), dark: Color(red: 0.18, green: 0.14, blue: 0.09)),
                elevatedCardBackground: ThemeTone(light: .white, dark: Color(red: 0.22, green: 0.17, blue: 0.11)),
                primaryText: ThemeTone(light: Color(red: 0.24, green: 0.18, blue: 0.08), dark: Color(red: 0.99, green: 0.95, blue: 0.86)),
                secondaryText: ThemeTone(light: Color(red: 0.43, green: 0.33, blue: 0.14), dark: Color(red: 0.91, green: 0.82, blue: 0.61)),
                mutedText: ThemeTone(light: Color(red: 0.43, green: 0.33, blue: 0.14).opacity(0.54), dark: Color(red: 0.91, green: 0.82, blue: 0.61).opacity(0.56)),
                divider: ThemeTone(light: Color(red: 0.67, green: 0.47, blue: 0.13).opacity(0.22), dark: Color(red: 0.93, green: 0.73, blue: 0.34).opacity(0.34)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.72, green: 0.53, blue: 0.20), Color(red: 0.93, green: 0.83, blue: 0.58)],
                    dark: [Color(red: 0.14, green: 0.10, blue: 0.06), Color(red: 0.45, green: 0.33, blue: 0.15)]
                ),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.62, green: 0.43, blue: 0.10), dark: Color(red: 0.37, green: 0.27, blue: 0.12))
            )
        case .lunarPearl:
            return .harmonized(
                accent: ThemeTone(light: Color(red: 0.40, green: 0.52, blue: 0.73), dark: Color(red: 0.73, green: 0.83, blue: 0.96)),
                accentSoft: ThemeTone(light: Color(red: 0.88, green: 0.91, blue: 0.97), dark: Color(red: 0.64, green: 0.71, blue: 0.86)),
                pageBackground: ThemeTone(light: Color(red: 0.97, green: 0.98, blue: 1.0), dark: Color(red: 0.07, green: 0.08, blue: 0.11)),
                secondaryBackground: ThemeTone(light: Color(red: 0.92, green: 0.94, blue: 0.98), dark: Color(red: 0.10, green: 0.12, blue: 0.16)),
                cardBackground: ThemeTone(light: Color(red: 1.0, green: 1.0, blue: 1.0), dark: Color(red: 0.13, green: 0.15, blue: 0.20)),
                elevatedCardBackground: ThemeTone(light: Color(red: 0.99, green: 0.99, blue: 1.0), dark: Color(red: 0.16, green: 0.18, blue: 0.24)),
                primaryText: ThemeTone(light: Color(red: 0.17, green: 0.21, blue: 0.30), dark: Color(red: 0.97, green: 0.98, blue: 1.0)),
                secondaryText: ThemeTone(light: Color(red: 0.34, green: 0.40, blue: 0.52), dark: Color(red: 0.82, green: 0.86, blue: 0.93)),
                mutedText: ThemeTone(light: Color(red: 0.34, green: 0.40, blue: 0.52).opacity(0.50), dark: Color(red: 0.82, green: 0.86, blue: 0.93).opacity(0.56)),
                divider: ThemeTone(light: Color(red: 0.40, green: 0.52, blue: 0.73).opacity(0.20), dark: Color(red: 0.73, green: 0.83, blue: 0.96).opacity(0.30)),
                heroGradient: ThemeGradientTone(
                    light: [Color(red: 0.72, green: 0.78, blue: 0.90), Color(red: 0.93, green: 0.95, blue: 0.99)],
                    dark: [Color(red: 0.11, green: 0.13, blue: 0.18), Color(red: 0.33, green: 0.40, blue: 0.54)]
                ),
                rabiaUserBubble: ThemeTone(light: Color(red: 0.36, green: 0.48, blue: 0.67), dark: Color(red: 0.25, green: 0.30, blue: 0.40))
            )
        }
    }
}

struct AppTheme: Identifiable {
    let themeID: ThemeID
    let appearanceMode: AppAppearanceMode
    let isDarkMode: Bool

    let backgroundBase: Color
    let backgroundGradientTop: Color
    let backgroundGradientBottom: Color
    let backgroundOverlay: Color
    let appBackground: Color
    let secondaryBackground: Color
    let cardBackground: Color
    let elevatedCardBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let accentSoft: Color
    let divider: Color
    let success: Color
    let warning: Color
    let glow: Color
    let navBarBackground: Color
    let tabBarBackground: Color
    let selectedTab: Color
    let unselectedTab: Color
    let overlayGradient: LinearGradient

    let heroGradient: LinearGradient
    let mutedText: Color
    let selectionBackground: Color
    let badgeBackground: Color
    let shadowColor: Color
    let floatingButtonBackground: Color
    let quranHeaderBackground: Color
    let quranSearchBackground: Color
    let quranSearchBorder: Color
    let quranVerseBackground: Color
    let quranVerseHighlightBackground: Color
    let quranBookmarkHighlightBackground: Color
    let quranArabicBackground: Color
    let quranTranslationBackground: Color
    let quranBadgeBackground: Color
    let quranBadgeText: Color
    let quranDivider: Color
    let quranActionBackground: Color

    let rabiaAccent: Color
    let rabiaGlow: Color
    let rabiaAssistantBubble: Color
    let rabiaUserBubble: Color
    let rabiaAssistantText: Color
    let rabiaUserText: Color
    let rabiaInputBorder: Color
    let rabiaSendButton: Color
    let rabiaHeaderAccent: Color
    let rabiaBackgroundTop: Color
    let rabiaBackgroundBottom: Color
    let rabiaSurface: Color
    let rabiaSurfaceBorder: Color
    let rabiaComposerBackground: Color
    let rabiaPlaceholderText: Color
    let rabiaTypingDot: Color
    let rabiaLauncherBorder: Color

    var id: String {
        runtimeSignature
    }

    var runtimeSignature: String {
        "\(themeID.rawValue)-\(appearanceMode.rawValue)-\(isDarkMode)"
    }

    var appTheme: ThemeID { themeID }
    var displayName: String { themeID.displayName }
    var icon: String { themeID.icon }
    var isPremium: Bool { themeID.isPremium }
    var colorScheme: ColorScheme { isDarkMode ? .dark : .light }

    var palette: AppTheme { self }
    var pageBackground: Color { appBackground }
    var backgroundPrimary: Color { appBackground }
    var backgroundSecondary: Color { secondaryBackground }
    var elevatedBackground: Color { elevatedCardBackground }
    var textPrimary: Color { primaryText }
    var textSecondary: Color { secondaryText }
    var accentForeground: Color { foregroundColor(forBackground: accent) }
    var border: Color { divider }
    var borderColor: Color { divider }
    var primaryTint: Color { accent }
    var secondaryTint: Color { accentSoft }
    var background: Color { secondaryBackground }
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundGradientTop, backgroundGradientBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    var backgroundView: some View {
        AtmosphericBackgroundView(
            baseColors: [
                backgroundBase,
                backgroundGradientTop,
                backgroundGradientBottom
            ],
            primaryGlow: accentSoft,
            secondaryGlow: accent,
            overlayTint: backgroundOverlay,
            isDarkMode: isDarkMode
        )
    }

    func foregroundColor(forBackground background: Color) -> Color {
        background.relativeLuminance > 0.55
            ? Color(red: 0.08, green: 0.10, blue: 0.14).opacity(isDarkMode ? 0.92 : 0.86)
            : .white
    }

    static func resolved(
        themeID: ThemeID,
        appearanceMode: AppAppearanceMode,
        systemColorScheme: ColorScheme?
    ) -> AppTheme {
        let isDarkMode: Bool
        switch appearanceMode {
        case .system:
            if let systemColorScheme {
                isDarkMode = systemColorScheme == .dark
            } else {
                isDarkMode = UITraitCollection.current.userInterfaceStyle != .light
            }
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        }

        let spec = AppThemeSpec.make(for: themeID)
        let accent = spec.accent.resolve(isDarkMode: isDarkMode)
        let accentSoft = spec.accentSoft.resolve(isDarkMode: isDarkMode)
        let appBackground = spec.pageBackground.resolve(isDarkMode: isDarkMode)
        let secondaryBackground = spec.secondaryBackground.resolve(isDarkMode: isDarkMode)
        let cardBackground = spec.cardBackground.resolve(isDarkMode: isDarkMode)
        let elevatedCardBackground = spec.elevatedCardBackground.resolve(isDarkMode: isDarkMode)
        let primaryText = spec.primaryText.resolve(isDarkMode: isDarkMode)
        let secondaryText = spec.secondaryText.resolve(isDarkMode: isDarkMode)
        let mutedText = spec.mutedText.resolve(isDarkMode: isDarkMode)
        let divider = spec.divider.resolve(isDarkMode: isDarkMode)
        let heroGradient = spec.heroGradient.gradient(isDarkMode: isDarkMode)
        let glow = spec.rabiaGlow.resolve(isDarkMode: isDarkMode)
        let selectionBackground = accentSoft.opacity(isDarkMode ? 0.24 : 0.18)
        let badgeBackground = accentSoft.opacity(isDarkMode ? 0.24 : 0.16)
        let shadowColor = primaryText.opacity(isDarkMode ? 0.28 : 0.12)
        let backgroundBase = appBackground
        let backgroundGradientTop = accentSoft.opacity(isDarkMode ? 0.22 : 0.16)
        let backgroundGradientBottom = secondaryBackground
        let backgroundOverlay = isDarkMode
            ? Color.black.opacity(0.10)
            : Color.white.opacity(0.06)

        return AppTheme(
            themeID: themeID,
            appearanceMode: appearanceMode,
            isDarkMode: isDarkMode,
            backgroundBase: backgroundBase,
            backgroundGradientTop: backgroundGradientTop,
            backgroundGradientBottom: backgroundGradientBottom,
            backgroundOverlay: backgroundOverlay,
            appBackground: appBackground,
            secondaryBackground: secondaryBackground,
            cardBackground: cardBackground,
            elevatedCardBackground: elevatedCardBackground,
            primaryText: primaryText,
            secondaryText: secondaryText,
            accent: accent,
            accentSoft: accentSoft,
            divider: divider,
            success: isDarkMode ? Color(red: 0.37, green: 0.82, blue: 0.58) : Color(red: 0.18, green: 0.66, blue: 0.42),
            warning: isDarkMode ? Color(red: 0.96, green: 0.76, blue: 0.34) : Color(red: 0.88, green: 0.60, blue: 0.10),
            glow: glow,
            navBarBackground: secondaryBackground,
            tabBarBackground: secondaryBackground,
            selectedTab: accent,
            unselectedTab: secondaryText,
            overlayGradient: LinearGradient(
                colors: [
                    backgroundBase,
                    backgroundGradientTop,
                    backgroundGradientBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            heroGradient: heroGradient,
            mutedText: mutedText,
            selectionBackground: selectionBackground,
            badgeBackground: badgeBackground,
            shadowColor: shadowColor,
            floatingButtonBackground: accent,
            quranHeaderBackground: elevatedCardBackground,
            quranSearchBackground: elevatedCardBackground,
            quranSearchBorder: divider.opacity(0.85),
            quranVerseBackground: cardBackground,
            quranVerseHighlightBackground: accentSoft.opacity(0.20),
            quranBookmarkHighlightBackground: accentSoft.opacity(0.28),
            quranArabicBackground: elevatedCardBackground,
            quranTranslationBackground: appBackground,
            quranBadgeBackground: accentSoft.opacity(0.18),
            quranBadgeText: accent,
            quranDivider: divider.opacity(0.42),
            quranActionBackground: selectionBackground,
            rabiaAccent: spec.rabiaAccent.resolve(isDarkMode: isDarkMode),
            rabiaGlow: glow,
            rabiaAssistantBubble: spec.rabiaAssistantBubble.resolve(isDarkMode: isDarkMode),
            rabiaUserBubble: spec.rabiaUserBubble.resolve(isDarkMode: isDarkMode),
            rabiaAssistantText: spec.rabiaAssistantText.resolve(isDarkMode: isDarkMode),
            rabiaUserText: spec.rabiaUserText.resolve(isDarkMode: isDarkMode),
            rabiaInputBorder: spec.rabiaInputBorder.resolve(isDarkMode: isDarkMode),
            rabiaSendButton: spec.rabiaSendButton.resolve(isDarkMode: isDarkMode),
            rabiaHeaderAccent: spec.rabiaHeaderAccent.resolve(isDarkMode: isDarkMode),
            rabiaBackgroundTop: spec.rabiaBackgroundTop.resolve(isDarkMode: isDarkMode),
            rabiaBackgroundBottom: spec.rabiaBackgroundBottom.resolve(isDarkMode: isDarkMode),
            rabiaSurface: spec.rabiaSurface.resolve(isDarkMode: isDarkMode),
            rabiaSurfaceBorder: spec.rabiaSurfaceBorder.resolve(isDarkMode: isDarkMode),
            rabiaComposerBackground: spec.rabiaComposerBackground.resolve(isDarkMode: isDarkMode),
            rabiaPlaceholderText: spec.rabiaPlaceholderText.resolve(isDarkMode: isDarkMode),
            rabiaTypingDot: spec.rabiaTypingDot.resolve(isDarkMode: isDarkMode),
            rabiaLauncherBorder: spec.rabiaLauncherBorder.resolve(isDarkMode: isDarkMode)
        )
    }
}

typealias ActiveTheme = AppTheme
typealias ThemePalette = AppTheme

private extension Color {
    var relativeLuminance: CGFloat {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            func linearize(_ component: CGFloat) -> CGFloat {
                component <= 0.03928
                    ? component / 12.92
                    : pow((component + 0.055) / 1.055, 2.4)
            }

            let linearRed = linearize(red)
            let linearGreen = linearize(green)
            let linearBlue = linearize(blue)

            return 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue
        }

        var white: CGFloat = 0
        if uiColor.getWhite(&white, alpha: &alpha) {
            return white
        }

        return 0
    }
}
