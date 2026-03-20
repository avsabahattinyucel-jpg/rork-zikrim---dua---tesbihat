import SwiftUI

struct ShimmerPlaceholder: View {
    @State private var phase: CGFloat = -1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            shimmerBar(width: .infinity, height: 14)
            shimmerBar(width: .infinity, height: 14)
            shimmerBar(width: 180, height: 14)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 2.0
            }
        }
    }

    private func shimmerBar(width: CGFloat, height: CGFloat) -> some View {
        let isInfinity = width == .infinity
        return RoundedRectangle(cornerRadius: 7)
            .fill(Color(.tertiarySystemFill))
            .frame(maxWidth: isInfinity ? .infinity : width)
            .frame(height: height)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.45), .clear],
                        startPoint: .init(x: phase - 0.4, y: 0.5),
                        endPoint: .init(x: phase + 0.4, y: 0.5)
                    )
                    .frame(width: geo.size.width)
                    .blendMode(.plusLighter)
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
            )
    }
}

struct AIBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption2.bold())
            Text(.geminiAi)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.18), Color.blue.opacity(0.14)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundStyle(.teal)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.teal.opacity(0.3), lineWidth: 0.5))
    }
}
