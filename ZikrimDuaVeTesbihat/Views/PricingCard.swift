import SwiftUI

struct PricingCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let price: String
    let billingLabel: String
    let detail: String?
    let badge: String?
    let isSelected: Bool
    let isPromoted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let badge, !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(badgeBackground, in: Capsule())
                        }
                    }

                    Text(price)
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(billingLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? accentGradient : AnyShapeStyle(.secondary))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 1.3 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.10 : 0.28),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: shadowColor, radius: isSelected ? 18 : 12, x: 0, y: isSelected ? 10 : 6)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundColors: [Color] {
        if isSelected {
            return colorScheme == .dark
                ? [
                    Color(red: 0.08, green: 0.16, blue: 0.22).opacity(0.98),
                    Color(red: 0.07, green: 0.22, blue: 0.24).opacity(0.96)
                ]
                : [
                    Color.white.opacity(0.96),
                    Color(red: 0.88, green: 0.97, blue: 0.97).opacity(0.98)
                ]
        }

        if isPromoted {
            return colorScheme == .dark
                ? [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.05)
                ]
                : [
                    Color.white.opacity(0.92),
                    Color(red: 0.94, green: 0.98, blue: 0.99).opacity(0.94)
                ]
        }

        return colorScheme == .dark
            ? [
                Color.white.opacity(0.06),
                Color.white.opacity(0.04)
            ]
            : [
                Color.white.opacity(0.86),
                Color(red: 0.95, green: 0.98, blue: 0.99).opacity(0.92)
            ]
    }

    private var borderColor: Color {
        if isSelected {
            return accentColor.opacity(colorScheme == .dark ? 0.74 : 0.46)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color(red: 0.13, green: 0.44, blue: 0.54).opacity(0.12)
    }

    private var badgeBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                accentColor.opacity(colorScheme == .dark ? 0.18 : 0.14),
                accentColor.opacity(colorScheme == .dark ? 0.10 : 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shadowColor: Color {
        if isSelected {
            return accentColor.opacity(colorScheme == .dark ? 0.18 : 0.10)
        }

        return colorScheme == .dark
            ? Color.black.opacity(0.14)
            : Color(red: 0.12, green: 0.40, blue: 0.46).opacity(0.08)
    }

    private var accentGradient: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.72, blue: 0.74),
                    Color(red: 0.34, green: 0.84, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var accentColor: Color {
        Color(red: 0.23, green: 0.78, blue: 0.82)
    }
}
