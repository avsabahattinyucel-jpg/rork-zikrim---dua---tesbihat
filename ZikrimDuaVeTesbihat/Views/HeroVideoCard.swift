import SwiftUI

struct HeroVideoCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let height: CGFloat

    private let cardCornerRadius: CGFloat = 34
    private let videoCornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            atmosphericGlow

            ZStack {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(cardBackdrop)

                LoopingVideoPlayerView(resourceName: videoResourceName, resourceExtension: "mp4")
                    .overlay(videoDarkOverlay)
                    .overlay(videoMaterialVeil)
                    .mask(HeroVideoEdgeFadeMask(cornerRadius: videoCornerRadius))
                    .clipShape(RoundedRectangle(cornerRadius: videoCornerRadius, style: .continuous))
                    .padding(7)
            }
            .frame(height: height)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cardCornerRadius + 2, style: .continuous))
            .overlay(cardStroke)
            .overlay(topHighlight)
            .shadow(color: shadowColor, radius: 30, x: 0, y: 18)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Premium tanitim videosu")
    }

    private var atmosphericGlow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardCornerRadius + 8, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            tealGlow.opacity(colorScheme == .dark ? 0.40 : 0.22),
                            .clear
                        ],
                        center: .center,
                        startRadius: 16,
                        endRadius: 170
                    )
                )
                .frame(height: height + 14)
                .blur(radius: 20)
                .scaleEffect(1.04)

            RoundedRectangle(cornerRadius: cardCornerRadius + 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            cyanGlow.opacity(colorScheme == .dark ? 0.14 : 0.10),
                            mintGlow.opacity(colorScheme == .dark ? 0.08 : 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: height + 26)
                .blur(radius: 28)
                .scaleEffect(1.08)
        }
    }

    private var cardBackdrop: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.06, green: 0.11, blue: 0.17),
                    Color(red: 0.04, green: 0.09, blue: 0.15)
                ]
                : [
                    Color.white.opacity(0.58),
                    Color(red: 0.84, green: 0.93, blue: 0.96).opacity(0.72)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var videoDarkOverlay: some View {
        RoundedRectangle(cornerRadius: videoCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(colorScheme == .dark ? 0.10 : 0.04),
                        Color.black.opacity(colorScheme == .dark ? 0.22 : 0.10),
                        Color.black.opacity(colorScheme == .dark ? 0.34 : 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var videoMaterialVeil: some View {
        RoundedRectangle(cornerRadius: videoCornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(colorScheme == .dark ? 0.08 : 0.16)
            .blur(radius: 0.6)
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius + 2, style: .continuous)
            .stroke(
                LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.22 : 0.60),
                            tealGlow.opacity(colorScheme == .dark ? 0.38 : 0.28),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                lineWidth: 1
            )
    }

    private var topHighlight: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius + 2, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.42),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
            .blendMode(.screen)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.34)
            : tealGlow.opacity(0.12)
    }

    private var videoResourceName: String {
        colorScheme == .dark ? "paywall" : "paywalllight"
    }

    private var tealGlow: Color {
        Color(red: 0.18, green: 0.78, blue: 0.76)
    }

    private var cyanGlow: Color {
        Color(red: 0.33, green: 0.83, blue: 0.94)
    }

    private var mintGlow: Color {
        Color(red: 0.56, green: 0.90, blue: 0.80)
    }
}

private struct HeroVideoEdgeFadeMask: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(0.95), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 34)
                .blendMode(.destinationOut)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.black.opacity(0.98), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 44)
                .blendMode(.destinationOut)
            }
            .overlay(alignment: .leading) {
                LinearGradient(
                    colors: [Color.black.opacity(0.9), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 36)
                .blendMode(.destinationOut)
            }
            .overlay(alignment: .trailing) {
                LinearGradient(
                    colors: [Color.black.opacity(0.9), .clear],
                    startPoint: .trailing,
                    endPoint: .leading
                )
                .frame(width: 36)
                .blendMode(.destinationOut)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.45), lineWidth: 14)
                    .blur(radius: 10)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
}
