import SwiftUI

struct QuranWaveformView: View {
    let isAnimating: Bool
    let tint: Color

    @State private var animate: Bool = false

    private let activeHeights: [CGFloat] = [16, 10, 18, 12]
    private let idleHeights: [CGFloat] = [6, 10, 8, 12]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(activeHeights.enumerated()), id: \.offset) { index, activeHeight in
                Capsule(style: .continuous)
                    .fill(tint.opacity(isAnimating ? 0.92 : 0.42))
                    .frame(width: 3, height: animate && isAnimating ? activeHeight : idleHeights[index])
                    .animation(
                        .easeInOut(duration: 0.64)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.08),
                        value: animate
                    )
            }
        }
        .frame(height: 18)
        .onAppear {
            animate = true
        }
        .onChange(of: isAnimating) { _, newValue in
            animate = newValue
        }
    }
}
