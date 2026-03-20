import SwiftUI

struct PremiumFeatureCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 46, height: 46)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentGradient)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentGradient)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.04)
                    ]
                    : [
                        Color.white.opacity(0.94),
                        Color(red: 0.91, green: 0.97, blue: 0.98).opacity(0.96)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.30),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
    }

    private var iconBackground: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.08, green: 0.23, blue: 0.30),
                    Color(red: 0.10, green: 0.34, blue: 0.38)
                ]
                : [
                    Color(red: 0.83, green: 0.95, blue: 0.96),
                    Color(red: 0.90, green: 0.98, blue: 0.97)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.17, green: 0.71, blue: 0.73),
                Color(red: 0.33, green: 0.82, blue: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color(red: 0.12, green: 0.42, blue: 0.50).opacity(0.12)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.18)
            : Color(red: 0.14, green: 0.44, blue: 0.48).opacity(0.10)
    }
}
