import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var didStartAnimation = false
    @State private var loadingPhase: CGFloat = -0.35

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let shortestSide = min(size.width, size.height)
            let orbSize = min(shortestSide * 0.92, 430.0)
            let emblemPlateSize = min(max(shortestSide * 0.32, 148.0), 184.0)
            let foregroundLogoSize = emblemPlateSize * 0.74
            let haloSize = emblemPlateSize + 34.0

            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.45, green: 0.86, blue: 0.82).opacity(isAnimating ? 0.20 : 0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 24,
                            endRadius: 220
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                    .blur(radius: 26)
                    .scaleEffect(isAnimating ? 1.05 : 0.96)
                    .allowsHitTesting(false)

                Circle()
                    .fill(Color(red: 0.10, green: 0.24, blue: 0.21).opacity(0.34))
                    .frame(width: orbSize * 0.76, height: orbSize * 0.76)
                    .blur(radius: 58)
                    .offset(y: 26)
                    .allowsHitTesting(false)

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: haloSize, height: haloSize)
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            }
                            .shadow(color: Color.black.opacity(0.24), radius: 28, x: 0, y: 16)

                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.10, green: 0.18, blue: 0.17).opacity(0.96),
                                        Color(red: 0.06, green: 0.12, blue: 0.14).opacity(0.98)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: emblemPlateSize, height: emblemPlateSize)
                            .overlay {
                                RoundedRectangle(cornerRadius: 34, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.16),
                                                Color(red: 0.45, green: 0.86, blue: 0.82).opacity(0.24)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 34, style: .continuous)
                                    .fill(Color(red: 0.45, green: 0.86, blue: 0.82).opacity(0.05))
                                    .padding(1)
                            }
                            .shadow(color: Color.black.opacity(0.34), radius: 22, x: 0, y: 16)

                        Image("LaunchLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: foregroundLogoSize, height: foregroundLogoSize)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .scaleEffect(isAnimating ? 1.015 : 0.985)
                    }
                    .offset(y: isAnimating ? -4 : 0)

                    VStack(spacing: 12) {
                        Capsule()
                            .fill(Color(red: 0.45, green: 0.86, blue: 0.82).opacity(0.86))
                            .frame(width: 52, height: 3)

                        Text(AppName.shortTextKey)
                            .font(.system(size: 31, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(AppName.fullTextKey)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.77, green: 0.88, blue: 0.87).opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 18)
                    }

                    loadingBar
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: 360)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard !didStartAnimation else { return }
            didStartAnimation = true

            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }

            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: false)) {
                loadingPhase = 1.35
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.05, blue: 0.08),
                Color(red: 0.05, green: 0.08, blue: 0.12),
                Color(red: 0.04, green: 0.07, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var loadingBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let capsuleWidth = width * 0.28
            let travel = width + capsuleWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.86, blue: 0.82).opacity(0.12),
                                Color(red: 0.63, green: 0.94, blue: 0.90).opacity(0.88),
                                Color(red: 0.45, green: 0.86, blue: 0.82).opacity(0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: capsuleWidth)
                    .offset(x: (loadingPhase * travel) - capsuleWidth)
                    .blur(radius: 0.4)
            }
        }
        .frame(width: 104, height: 3)
        .clipShape(Capsule())
        .padding(.top, 4)
        .accessibilityHidden(true)
    }
}
