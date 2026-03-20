import SwiftUI

struct PremiumPaywallBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    let reduceMotion: Bool

    var body: some View {
        ZStack {
            AtmosphericBackgroundView(
                baseColors: backgroundColors,
                primaryGlow: glowTeal,
                secondaryGlow: glowCyan,
                overlayTint: Color.white.opacity(colorScheme == .dark ? 0.02 : 0.06),
                isDarkMode: colorScheme == .dark,
                primaryAlignment: .topLeading,
                secondaryAlignment: .bottomTrailing,
                primaryOffsetRatio: CGSize(width: -0.18, height: -0.20),
                secondaryOffsetRatio: CGSize(width: 0.16, height: 0.18),
                glowIntensity: 1.24,
                ornamentOpacity: 1.18
            )

            if !reduceMotion {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                glowMint.opacity(colorScheme == .dark ? 0.18 : 0.12),
                                glowCyan.opacity(colorScheme == .dark ? 0.10 : 0.08),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 360, height: 220)
                    .rotationEffect(.degrees(-18))
                    .blur(radius: 46)
                    .offset(x: 92, y: 210)
            }

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.10 : 0.20)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.03, green: 0.06, blue: 0.10),
                Color(red: 0.05, green: 0.10, blue: 0.16),
                Color(red: 0.02, green: 0.04, blue: 0.08)
            ]
        }

        return [
            Color(red: 0.95, green: 0.98, blue: 0.99),
            Color(red: 0.91, green: 0.96, blue: 0.98),
            Color(red: 0.94, green: 0.98, blue: 0.98)
        ]
    }

    private var glowTeal: Color {
        Color(red: 0.18, green: 0.75, blue: 0.72)
    }

    private var glowCyan: Color {
        Color(red: 0.28, green: 0.82, blue: 0.92)
    }

    private var glowMint: Color {
        Color(red: 0.46, green: 0.88, blue: 0.78)
    }
}
