import SwiftUI

struct AtmosphericBackgroundView: View {
    let baseColors: [Color]
    let primaryGlow: Color
    let secondaryGlow: Color
    let overlayTint: Color
    let isDarkMode: Bool
    var primaryAlignment: Alignment = .topLeading
    var secondaryAlignment: Alignment = .bottomTrailing
    var primaryOffsetRatio: CGSize = CGSize(width: -0.16, height: -0.18)
    var secondaryOffsetRatio: CGSize = CGSize(width: 0.16, height: 0.22)
    var glowIntensity: CGFloat = 1
    var ornamentOpacity: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            let longSide = max(proxy.size.width, proxy.size.height)
            let primaryFrame = longSide * (0.88 + (0.08 * glowIntensity))
            let secondaryFrame = longSide * (0.72 + (0.08 * glowIntensity))
            let archWidth = min(proxy.size.width * 0.74, 430)
            let archHeight = min(proxy.size.height * 0.38, 320)

            ZStack {
                LinearGradient(
                    colors: normalizedBaseColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                MihrabArchShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.055 : 0.085),
                                primaryGlow.opacity(isDarkMode ? 0.045 : 0.030),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: archWidth, height: archHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .overlay(
                        MihrabArchShape()
                            .stroke(
                                Color.white.opacity(isDarkMode ? 0.08 : 0.12),
                                lineWidth: 1
                            )
                            .blur(radius: 0.5)
                            .frame(width: archWidth * 0.94, height: archHeight * 0.92)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .offset(y: archHeight * 0.045)
                    )
                    .blur(radius: 2)
                    .opacity(0.72 * ornamentOpacity)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                primaryGlow.opacity(isDarkMode ? 0.24 : 0.18),
                                .clear
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: primaryFrame * 0.5
                        )
                    )
                    .frame(width: primaryFrame, height: primaryFrame)
                    .blur(radius: longSide * 0.07)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: primaryAlignment)
                    .offset(
                        x: longSide * primaryOffsetRatio.width,
                        y: longSide * primaryOffsetRatio.height
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                secondaryGlow.opacity(isDarkMode ? 0.18 : 0.12),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: secondaryFrame * 0.5
                        )
                    )
                    .frame(width: secondaryFrame, height: secondaryFrame)
                    .blur(radius: longSide * 0.08)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: secondaryAlignment)
                    .offset(
                        x: longSide * secondaryOffsetRatio.width,
                        y: longSide * secondaryOffsetRatio.height
                    )

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                primaryGlow.opacity(isDarkMode ? 0.16 : 0.12),
                                .clear,
                                secondaryGlow.opacity(isDarkMode ? 0.10 : 0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: longSide * 0.96, height: longSide * 0.28)
                    .rotationEffect(.degrees(isDarkMode ? -24 : -18))
                    .offset(x: -longSide * 0.12, y: -longSide * 0.04)
                    .blur(radius: longSide * 0.05)
                    .opacity(0.88)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                secondaryGlow.opacity(isDarkMode ? 0.14 : 0.10),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: longSide * 0.84, height: longSide * 0.22)
                    .rotationEffect(.degrees(isDarkMode ? 28 : 22))
                    .offset(x: longSide * 0.18, y: longSide * 0.22)
                    .blur(radius: longSide * 0.055)
                    .opacity(0.82)

                RoundedRectangle(cornerRadius: longSide * 0.24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.026 : 0.060),
                                .clear,
                                primaryGlow.opacity(isDarkMode ? 0.030 : 0.020)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: longSide * 0.92, height: longSide * 0.62)
                    .rotationEffect(.degrees(isDarkMode ? -20 : -14))
                    .offset(x: longSide * 0.14, y: longSide * 0.24)
                    .blur(radius: longSide * 0.045)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.016 : 0.042),
                                .clear,
                                Color.white.opacity(isDarkMode ? 0.010 : 0.024)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(isDarkMode ? .screen : .softLight)

                CelestialDustLayer(
                    tint: Color.white,
                    isDarkMode: isDarkMode,
                    intensity: ornamentOpacity
                )

                overlayTint
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var normalizedBaseColors: [Color] {
        switch baseColors.count {
        case 0:
            return [.black, .gray, .black]
        case 1:
            return [baseColors[0], baseColors[0], baseColors[0]]
        case 2:
            return [baseColors[0], baseColors[1], baseColors[1]]
        default:
            return Array(baseColors.prefix(3))
        }
    }
}

private struct CelestialDustLayer: View {
    let tint: Color
    let isDarkMode: Bool
    let intensity: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(atmosphericDustSpecs) { spec in
                    Circle()
                        .fill(tint.opacity((isDarkMode ? 0.70 : 0.46) * spec.opacity * intensity))
                        .frame(width: spec.size, height: spec.size)
                        .blur(radius: spec.size < 2 ? 0 : spec.size * 0.5)
                        .position(
                            x: proxy.size.width * spec.x,
                            y: proxy.size.height * spec.y
                        )
                }
            }
        }
        .blendMode(isDarkMode ? .screen : .overlay)
    }
}

private struct MihrabArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sideInset = rect.width * 0.18
        let shoulderY = rect.height * 0.48

        var path = Path()
        path.move(to: CGPoint(x: sideInset, y: rect.height))
        path.addLine(to: CGPoint(x: sideInset, y: shoulderY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: 0),
            control: CGPoint(x: sideInset, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width - sideInset, y: shoulderY),
            control: CGPoint(x: rect.width - sideInset, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width - sideInset, y: rect.height))
        path.addLine(to: CGPoint(x: sideInset, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct AtmosphericDustSpec: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: CGFloat
}

private let atmosphericDustSpecs: [AtmosphericDustSpec] = [
    .init(id: 0, x: 0.16, y: 0.12, size: 2.2, opacity: 0.70),
    .init(id: 1, x: 0.24, y: 0.18, size: 1.8, opacity: 0.42),
    .init(id: 2, x: 0.72, y: 0.16, size: 2.4, opacity: 0.62),
    .init(id: 3, x: 0.82, y: 0.22, size: 1.5, opacity: 0.36),
    .init(id: 4, x: 0.58, y: 0.12, size: 1.4, opacity: 0.34),
    .init(id: 5, x: 0.10, y: 0.34, size: 1.6, opacity: 0.30),
    .init(id: 6, x: 0.88, y: 0.40, size: 2.0, opacity: 0.40),
    .init(id: 7, x: 0.18, y: 0.62, size: 1.7, opacity: 0.28),
    .init(id: 8, x: 0.74, y: 0.60, size: 1.9, opacity: 0.34),
    .init(id: 9, x: 0.62, y: 0.74, size: 2.2, opacity: 0.46),
    .init(id: 10, x: 0.30, y: 0.82, size: 1.6, opacity: 0.26),
    .init(id: 11, x: 0.84, y: 0.84, size: 2.1, opacity: 0.36),
    .init(id: 12, x: 0.46, y: 0.28, size: 1.3, opacity: 0.24),
    .init(id: 13, x: 0.40, y: 0.56, size: 1.8, opacity: 0.28)
]
