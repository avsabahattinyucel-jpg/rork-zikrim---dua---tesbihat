import SwiftUI

enum AppResponsiveMetrics {
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    static var isCompactPhone: Bool {
        screenWidth <= 375
    }

    static var isVeryCompactPhone: Bool {
        screenWidth <= 350
    }

    static func spacing(base: CGFloat, compact: CGFloat, veryCompact: CGFloat? = nil) -> CGFloat {
        if let veryCompact, isVeryCompactPhone {
            return veryCompact
        }

        if isCompactPhone {
            return compact
        }

        return base
    }

    static func font(_ base: CGFloat, compact: CGFloat, veryCompact: CGFloat? = nil) -> CGFloat {
        spacing(base: base, compact: compact, veryCompact: veryCompact)
    }
}

enum QuranResponsiveMetrics {
    static var screenWidth: CGFloat {
        AppResponsiveMetrics.screenWidth
    }

    static var isWidePhone: Bool {
        screenWidth >= 430 && screenWidth < 768
    }

    static var isCompactPhone: Bool {
        AppResponsiveMetrics.isCompactPhone
    }

    static var isVeryCompactPhone: Bool {
        AppResponsiveMetrics.isVeryCompactPhone
    }

    static func font(base: CGFloat, compact: CGFloat, veryCompact: CGFloat? = nil) -> CGFloat {
        if let veryCompact, isVeryCompactPhone {
            return veryCompact
        }

        if isCompactPhone {
            return compact
        }

        return base
    }
}

enum AppThemeMetrics {
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let iconCornerRadius: CGFloat = 9
}

struct PrayerTimesThemeMetrics {
    static let heroCornerRadius: CGFloat = 30
    static let cardCornerRadius: CGFloat = 24
    static let miniCardCornerRadius: CGFloat = 22
    static let iconCornerRadius: CGFloat = 16
    static let heroPadding: CGFloat = 22
    static let cardPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 18
    static let compactSpacing: CGFloat = 12
}

struct PrayerTimesThemeTokens {
    let heroGradient: LinearGradient
    let heroAccent: Color
    let heroGlow: Color
    let heroSymbolTint: Color
    let surfaceGradient: LinearGradient
    let surfaceFill: Color
    let surfaceStroke: Color
    let miniCardFill: Color
    let miniCardStroke: Color
    let miniCardIconTint: Color
    let activeMiniCardGradient: LinearGradient
    let activeMiniCardStroke: Color
    let activeMiniCardGlow: Color
    let actionIconTint: Color
    let shadowColor: Color
    let backgroundGlow: Color
}

extension AppTheme {
    var prayerTimesTokens: PrayerTimesThemeTokens {
        PrayerTimesThemeTokens(
            heroGradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        Color(red: 0.03, green: 0.12, blue: 0.24),
                        Color(red: 0.05, green: 0.29, blue: 0.36)
                    ]
                    : [
                        Color(red: 0.04, green: 0.24, blue: 0.43),
                        Color(red: 0.06, green: 0.46, blue: 0.49)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            heroAccent: isDarkMode
                ? Color(red: 0.49, green: 0.88, blue: 0.90)
                : Color(red: 0.37, green: 0.86, blue: 0.86),
            heroGlow: isDarkMode
                ? Color(red: 0.42, green: 0.83, blue: 0.88).opacity(0.26)
                : Color(red: 0.55, green: 0.93, blue: 0.92).opacity(0.30),
            heroSymbolTint: Color.white.opacity(isDarkMode ? 0.20 : 0.16),
            surfaceGradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        elevatedBackground.opacity(0.96),
                        backgroundSecondary.opacity(0.94)
                    ]
                    : [
                        Color.white.opacity(0.90),
                        cardBackground.opacity(0.96)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            surfaceFill: isDarkMode ? elevatedBackground.opacity(0.88) : Color.white.opacity(0.84),
            surfaceStroke: Color.white.opacity(isDarkMode ? 0.12 : 0.46),
            miniCardFill: isDarkMode
                ? Color.white.opacity(0.05)
                : Color(red: 0.94, green: 0.98, blue: 1.0).opacity(0.92),
            miniCardStroke: isDarkMode
                ? Color.white.opacity(0.10)
                : Color(red: 0.14, green: 0.39, blue: 0.53).opacity(0.10),
            miniCardIconTint: isDarkMode
                ? Color(red: 0.68, green: 0.90, blue: 0.92)
                : Color(red: 0.12, green: 0.42, blue: 0.52),
            activeMiniCardGradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        Color(red: 0.08, green: 0.27, blue: 0.40),
                        Color(red: 0.10, green: 0.47, blue: 0.53)
                    ]
                    : [
                        Color(red: 0.08, green: 0.33, blue: 0.52),
                        Color(red: 0.13, green: 0.60, blue: 0.63)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            activeMiniCardStroke: Color.white.opacity(isDarkMode ? 0.22 : 0.58),
            activeMiniCardGlow: isDarkMode
                ? Color(red: 0.22, green: 0.73, blue: 0.78).opacity(0.32)
                : Color(red: 0.26, green: 0.77, blue: 0.80).opacity(0.22),
            actionIconTint: isDarkMode
                ? Color(red: 0.72, green: 0.92, blue: 0.94)
                : Color(red: 0.11, green: 0.44, blue: 0.52),
            shadowColor: Color.black.opacity(isDarkMode ? 0.34 : 0.12),
            backgroundGlow: isDarkMode
                ? Color(red: 0.18, green: 0.48, blue: 0.58).opacity(0.30)
                : Color(red: 0.48, green: 0.84, blue: 0.86).opacity(0.22)
        )
    }
}

extension View {
    func themedScreenBackground() -> some View {
        modifier(ThemedScreenBackgroundModifier())
    }

    func themedScreenBackground(_ palette: ThemePalette) -> some View {
        modifier(LegacyScreenBackgroundModifier(theme: palette))
    }

    func themedCard(cornerRadius: CGFloat = AppThemeMetrics.cornerRadius) -> some View {
        modifier(ThemedCardModifier(elevated: false, cornerRadius: cornerRadius))
    }

    func themedSecondaryCard(cornerRadius: CGFloat = AppThemeMetrics.cornerRadius) -> some View {
        modifier(ThemedCardModifier(elevated: true, cornerRadius: cornerRadius))
    }

    func themedNavigation(title: String, displayMode: NavigationBarItem.TitleDisplayMode = .inline) -> some View {
        modifier(ThemedNavigationStringModifier(title: title, displayMode: displayMode))
    }

    func themedNavigation(title: LocalizedStringKey, displayMode: NavigationBarItem.TitleDisplayMode = .inline) -> some View {
        modifier(ThemedNavigationLocalizedModifier(title: title, displayMode: displayMode))
    }

    func themedGlow(radius: CGFloat = 18, y: CGFloat = 10) -> some View {
        modifier(ThemedGlowModifier(radius: radius, y: y))
    }

    func themedPrimaryButton(
        cornerRadius: CGFloat = AppThemeMetrics.cornerRadius,
        fill: Color? = nil,
        foreground: Color? = nil
    ) -> some View {
        modifier(ThemedPrimaryButtonModifier(cornerRadius: cornerRadius, fill: fill, foreground: foreground))
    }

    func themedSecondaryButton(
        cornerRadius: CGFloat = AppThemeMetrics.cornerRadius,
        fill: Color? = nil,
        foreground: Color? = nil,
        border: Color? = nil
    ) -> some View {
        modifier(ThemedSecondaryButtonModifier(cornerRadius: cornerRadius, fill: fill, foreground: foreground, border: border))
    }

    func themedListRow(selected: Bool = false, cornerRadius: CGFloat = AppThemeMetrics.smallCornerRadius) -> some View {
        modifier(ThemedListRowModifier(selected: selected, cornerRadius: cornerRadius))
    }

    func appScreenBackground(_ theme: AppTheme) -> some View {
        modifier(LegacyScreenBackgroundModifier(theme: theme))
    }

    func appCardStyle(_ theme: AppTheme, elevated: Bool = false, cornerRadius: CGFloat = AppThemeMetrics.cornerRadius) -> some View {
        modifier(LegacyCardModifier(theme: theme, elevated: elevated, cornerRadius: cornerRadius))
    }

    func appListRowStyle(_ theme: AppTheme, selected: Bool = false, cornerRadius: CGFloat = AppThemeMetrics.smallCornerRadius) -> some View {
        modifier(LegacyListRowModifier(theme: theme, selected: selected, cornerRadius: cornerRadius))
    }

    func appFloatingButtonStyle(_ theme: AppTheme) -> some View {
        modifier(LegacyFloatingButtonModifier(theme: theme))
    }

    func quranSearchFieldStyle(_ theme: AppTheme) -> some View {
        modifier(QuranSearchFieldStyle(theme: theme))
    }

    func quranSurahRowStyle(_ theme: AppTheme) -> some View {
        modifier(QuranSurahRowStyle(theme: theme))
    }

    func quranSurfaceCard(_ theme: AppTheme, cornerRadius: CGFloat = 24) -> some View {
        modifier(QuranSurfaceCardStyle(theme: theme, cornerRadius: cornerRadius))
    }

    func quranVerseCardStyle(_ theme: AppTheme, isHighlighted: Bool = false, isBookmarked: Bool = false) -> some View {
        modifier(QuranVerseCardStyle(theme: theme, isHighlighted: isHighlighted, isBookmarked: isBookmarked))
    }

    func quranHeaderStyle(_ theme: AppTheme) -> some View {
        modifier(QuranHeaderStyle(theme: theme))
    }
}

private struct ThemedScreenBackgroundModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content.background {
            themeManager.currentTheme.backgroundView
                .ignoresSafeArea()
        }
    }
}

private struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let elevated: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(elevated ? themeManager.currentTheme.elevatedCardBackground : themeManager.currentTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(themeManager.currentTheme.heroGradient.opacity(themeManager.currentTheme.isDarkMode ? 0.08 : 0.05))
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(themeManager.currentTheme.divider.opacity(0.65), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(themeManager.currentTheme.isDarkMode ? 0.10 : 0.34),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: themeManager.currentTheme.shadowColor.opacity(elevated ? 0.18 : 0.08),
                radius: elevated ? 14 : 8,
                x: 0,
                y: elevated ? 8 : 3
            )
            .shadow(
                color: themeManager.currentTheme.glow.opacity(themeManager.currentTheme.isDarkMode ? 0.12 : 0.05),
                radius: elevated ? 18 : 12,
                x: 0,
                y: elevated ? 10 : 4
            )
    }
}

private struct ThemedNavigationStringModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(themeManager.currentTheme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.currentTheme.colorScheme, for: .navigationBar)
    }
}

private struct ThemedNavigationLocalizedModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: LocalizedStringKey
    let displayMode: NavigationBarItem.TitleDisplayMode

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(themeManager.currentTheme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.currentTheme.colorScheme, for: .navigationBar)
    }
}

private struct ThemedGlowModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(
            color: themeManager.currentTheme.glow.opacity(themeManager.currentTheme.isDarkMode ? 0.32 : 0.20),
            radius: radius,
            x: 0,
            y: y
        )
    }
}

private struct ThemedPrimaryButtonModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let cornerRadius: CGFloat
    let fill: Color?
    let foreground: Color?

    func body(content: Content) -> some View {
        let theme = themeManager.currentTheme
        let resolvedFill = fill ?? theme.accent
        let resolvedForeground = foreground ?? theme.foregroundColor(forBackground: resolvedFill)

        content
            .foregroundStyle(resolvedForeground)
            .tint(resolvedForeground)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(resolvedFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.divider.opacity(theme.isDarkMode ? 0.14 : 0.08), lineWidth: 1)
            )
            .shadow(
                color: resolvedFill.opacity(theme.isDarkMode ? 0.32 : 0.18),
                radius: 9,
                x: 0,
                y: 4
            )
    }
}

private struct ThemedSecondaryButtonModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let cornerRadius: CGFloat
    let fill: Color?
    let foreground: Color?
    let border: Color?

    func body(content: Content) -> some View {
        let theme = themeManager.currentTheme
        let resolvedFill = fill ?? theme.selectionBackground
        let resolvedForeground = foreground ?? theme.accent
        let resolvedBorder = border ?? theme.accent.opacity(theme.isDarkMode ? 0.24 : 0.18)

        content
            .foregroundStyle(resolvedForeground)
            .tint(resolvedForeground)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(resolvedFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(resolvedBorder, lineWidth: 1)
            )
    }
}

private struct ThemedListRowModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let selected: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(selected ? themeManager.currentTheme.selectionBackground : themeManager.currentTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(themeManager.currentTheme.divider.opacity(selected ? 0.90 : 0.55), lineWidth: 1)
            )
    }
}

private struct LegacyScreenBackgroundModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content.background {
            theme.backgroundView
                .ignoresSafeArea()
        }
    }
}

private struct LegacyCardModifier: ViewModifier {
    let theme: AppTheme
    let elevated: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(elevated ? theme.elevatedCardBackground : theme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(theme.heroGradient.opacity(theme.isDarkMode ? 0.08 : 0.05))
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.divider.opacity(0.65), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDarkMode ? 0.10 : 0.34),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: theme.shadowColor.opacity(elevated ? 0.16 : 0.08), radius: elevated ? 12 : 8, x: 0, y: elevated ? 7 : 3)
            .shadow(color: theme.glow.opacity(theme.isDarkMode ? 0.10 : 0.05), radius: elevated ? 18 : 12, x: 0, y: elevated ? 10 : 4)
    }
}

private struct LegacyListRowModifier: ViewModifier {
    let theme: AppTheme
    let selected: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(selected ? theme.selectionBackground : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.divider.opacity(selected ? 0.95 : 0.55), lineWidth: 1)
            )
    }
}

private struct LegacyFloatingButtonModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .padding(AppResponsiveMetrics.spacing(base: 12, compact: 11, veryCompact: 10))
            .background(theme.floatingButtonBackground)
            .foregroundStyle(Color.white)
            .clipShape(Circle())
            .shadow(color: theme.glow.opacity(theme.isDarkMode ? 0.30 : 0.18), radius: 14, x: 0, y: 8)
            .shadow(color: theme.shadowColor.opacity(0.18), radius: 6, x: 0, y: 3)
    }
}

struct AppSectionHeaderStyle: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.textSecondary)
            .tracking(0.5)
    }
}

struct QuranSearchFieldStyle: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppResponsiveMetrics.spacing(base: 14, compact: 12, veryCompact: 11))
            .padding(.vertical, AppResponsiveMetrics.spacing(base: 12, compact: 11, veryCompact: 10))
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.quranSearchBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(theme.heroGradient.opacity(theme.isDarkMode ? 0.10 : 0.07))
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(theme.quranSearchBorder, lineWidth: 1)
            )
            .shadow(color: theme.shadowColor.opacity(0.07), radius: 10, x: 0, y: 5)
    }
}

struct QuranSurahRowStyle: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(theme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(theme.heroGradient.opacity(theme.isDarkMode ? 0.16 : 0.09))
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(theme.divider.opacity(0.52), lineWidth: 1)
            )
            .shadow(color: theme.shadowColor.opacity(0.07), radius: 10, x: 0, y: 5)
    }
}

struct QuranSurfaceCardStyle: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(theme.heroGradient.opacity(theme.isDarkMode ? 0.10 : 0.06))
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.divider.opacity(0.50), lineWidth: 1)
            )
            .shadow(color: theme.shadowColor.opacity(0.07), radius: 10, x: 0, y: 5)
    }
}

struct QuranVerseCardStyle: ViewModifier {
    let theme: AppTheme
    let isHighlighted: Bool
    let isBookmarked: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(theme.quranDivider, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        if isHighlighted {
            return theme.quranVerseHighlightBackground
        }
        if isBookmarked {
            return theme.quranBookmarkHighlightBackground
        }
        return theme.quranVerseBackground
    }
}

struct QuranHeaderStyle: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.quranHeaderBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(theme.heroGradient.opacity(theme.isDarkMode ? 0.16 : 0.10))
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.divider.opacity(0.65), lineWidth: 1)
            )
            .shadow(color: theme.shadowColor.opacity(0.07), radius: 12, x: 0, y: 7)
    }
}

struct PremiumFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.fontDesign(.rounded)
    }
}

extension View {
    func premiumStyle() -> some View {
        modifier(PremiumFontModifier())
    }
}
