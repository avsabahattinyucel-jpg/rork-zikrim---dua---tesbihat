import SwiftUI

struct PremiumAtmosphereParticlesView: View {
    let reduceMotion: Bool

    @State private var animate: Bool = false

    private let particles: [ParticleSpec] = [
        ParticleSpec(x: 0.12, size: 54, travel: 380, duration: 17, delay: 0, opacity: 0.11, tint: Color(red: 0.88, green: 0.74, blue: 0.44)),
        ParticleSpec(x: 0.24, size: 24, travel: 320, duration: 15, delay: 3, opacity: 0.08, tint: Color.white),
        ParticleSpec(x: 0.39, size: 36, travel: 360, duration: 19, delay: 1.5, opacity: 0.06, tint: Color(red: 0.32, green: 0.67, blue: 0.58)),
        ParticleSpec(x: 0.54, size: 20, travel: 300, duration: 13, delay: 5, opacity: 0.05, tint: Color.white),
        ParticleSpec(x: 0.67, size: 42, travel: 340, duration: 18, delay: 2, opacity: 0.07, tint: Color(red: 0.88, green: 0.74, blue: 0.44)),
        ParticleSpec(x: 0.78, size: 26, travel: 330, duration: 16, delay: 4.5, opacity: 0.05, tint: Color(red: 0.32, green: 0.67, blue: 0.58)),
        ParticleSpec(x: 0.88, size: 48, travel: 390, duration: 20, delay: 1, opacity: 0.06, tint: Color.white)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(particles.enumerated()), id: \.offset) { index, particle in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    particle.tint.opacity(particle.opacity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: particle.size / 2
                            )
                        )
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size * 0.18)
                        .position(
                            x: proxy.size.width * particle.x,
                            y: particleYPosition(for: particle, in: proxy.size.height)
                        )
                        .animation(animation(for: particle, index: index), value: animate)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                guard !reduceMotion else { return }
                animate = true
            }
        }
        .allowsHitTesting(false)
    }

    private func particleYPosition(for particle: ParticleSpec, in height: CGFloat) -> CGFloat {
        if reduceMotion {
            return height * 0.78
        }

        return animate ? -particle.size : height + particle.travel * 0.35
    }

    private func animation(for particle: ParticleSpec, index: Int) -> Animation? {
        guard !reduceMotion else { return nil }
        return .linear(duration: particle.duration)
            .delay(particle.delay + Double(index) * 0.25)
            .repeatForever(autoreverses: false)
    }
}

private struct ParticleSpec {
    let x: CGFloat
    let size: CGFloat
    let travel: CGFloat
    let duration: Double
    let delay: Double
    let opacity: Double
    let tint: Color
}
