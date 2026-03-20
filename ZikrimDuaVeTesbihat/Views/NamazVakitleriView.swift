import SwiftUI

struct PrayerSurfaceCard<Content: View>: View {
    let theme: ActiveTheme
    let tokens: PrayerTimesThemeTokens
    let padding: CGFloat
    let content: Content

    init(
        theme: ActiveTheme,
        tokens: PrayerTimesThemeTokens,
        padding: CGFloat = PrayerTimesThemeMetrics.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.tokens = tokens
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: PrayerTimesThemeMetrics.cardCornerRadius, style: .continuous)
                .fill(tokens.surfaceGradient)

            RoundedRectangle(cornerRadius: PrayerTimesThemeMetrics.cardCornerRadius, style: .continuous)
                .fill(tokens.heroGlow.opacity(theme.isDarkMode ? 0.06 : 0.10))
                .blur(radius: 26)
                .offset(x: 90, y: -90)

            content
                .padding(padding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: PrayerTimesThemeMetrics.cardCornerRadius, style: .continuous)
                .stroke(tokens.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: tokens.shadowColor.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

struct PrayerScreenBackground: View {
    let theme: ActiveTheme
    let tokens: PrayerTimesThemeTokens

    var body: some View {
        ZStack {
            theme.pageBackground

            LinearGradient(
                colors: [
                    tokens.backgroundGlow,
                    Color.clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            Circle()
                .fill(tokens.heroGlow)
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(x: 110, y: -220)

            Circle()
                .fill(tokens.backgroundGlow.opacity(0.65))
                .frame(width: 220, height: 220)
                .blur(radius: 46)
                .offset(x: -120, y: -40)
        }
    }
}
