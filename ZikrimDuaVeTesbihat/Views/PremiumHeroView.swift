import SwiftUI

struct PremiumHeroView: View {
    let theme: ActiveTheme
    let reduceMotion: Bool

    @State private var isAnimatingGlow: Bool = false

    var body: some View {
        ZStack {
            ambientGlow

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.accent.opacity(theme.isDarkMode ? 0.36 : 0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 88
                        )
                    )
                    .frame(width: 176, height: 176)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.selectionBackground.opacity(theme.isDarkMode ? 0.95 : 0.8),
                                theme.cardBackground.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 126, height: 126)
                    .overlay(
                        Circle()
                            .stroke(theme.border.opacity(0.55), lineWidth: 1)
                    )

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white.opacity(theme.isDarkMode ? 0.95 : 0.85))

                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(theme.accent.opacity(0.92))
                    .offset(x: 34, y: -34)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.elevatedBackground.opacity(theme.isDarkMode ? 0.98 : 0.92),
                            theme.cardBackground.opacity(theme.isDarkMode ? 0.92 : 0.84)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.border.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.28 : 0.14), radius: 24, x: 0, y: 14)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
                isAnimatingGlow = true
            }
        }
    }

    private var ambientGlow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.selectionBackground.opacity(theme.isDarkMode ? 0.55 : 0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .fill(theme.accent.opacity(theme.isDarkMode ? 0.15 : 0.08))
                .frame(width: 190, height: 190)
                .blur(radius: 40)
                .offset(x: 76, y: -70)
        }
        .clipped()
    }

    private var glowScale: CGFloat {
        guard !reduceMotion else { return 1 }
        return isAnimatingGlow ? 1.05 : 0.96
    }

    private var glowOpacity: Double {
        guard !reduceMotion else { return 0.95 }
        return isAnimatingGlow ? 0.98 : 0.72
    }
}
