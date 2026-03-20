import SwiftUI

struct SubscriptionPlanCard: View {
    let title: String
    let duration: String
    let billedPrice: String
    let secondaryDetail: String?
    let badge: String?
    let isSelected: Bool
    let isPromoted: Bool
    let theme: ActiveTheme
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let badge, !badge.isEmpty {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.badgeBackground.opacity(isPromoted ? 1 : 0.65))
                                .foregroundStyle(theme.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(duration)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(theme.textSecondary)

                    Text(billedPrice)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let secondaryDetail, !secondaryDetail.isEmpty {
                        Text(secondaryDetail)
                            .font(.footnote)
                            .foregroundStyle(theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(isSelected ? theme.accent : theme.selectionBackground.opacity(0.55))
                        .frame(width: 28, height: 28)

                    Image(systemName: isSelected ? "checkmark" : "circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white : theme.textSecondary.opacity(0.9))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: isSelected ? theme.accent.opacity(theme.isDarkMode ? 0.18 : 0.12) : theme.shadowColor.opacity(0.08), radius: isSelected ? 18 : 10, x: 0, y: isSelected ? 10 : 5)
            .scaleEffect(isSelected && !reduceMotion ? 1.012 : 1)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.34, dampingFraction: 0.82), value: isSelected)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
    }

    private var backgroundColors: [Color] {
        if isSelected {
            return [
                theme.elevatedBackground.opacity(0.98),
                theme.selectionBackground.opacity(theme.isDarkMode ? 0.9 : 0.65)
            ]
        }

        if isPromoted {
            return [
                theme.elevatedBackground.opacity(0.96),
                theme.cardBackground.opacity(0.9)
            ]
        }

        return [
            theme.cardBackground.opacity(0.95),
            theme.cardBackground.opacity(0.88)
        ]
    }

    private var borderColor: Color {
        if isSelected {
            return theme.accent.opacity(0.9)
        }

        if isPromoted {
            return theme.border.opacity(0.75)
        }

        return theme.border.opacity(0.42)
    }
}
