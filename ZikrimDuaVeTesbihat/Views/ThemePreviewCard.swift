import SwiftUI

struct ThemePreviewCard: View {
    let themeID: ThemeID
    let theme: AppTheme
    let isSelected: Bool
    let showProBadge: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                previewSurface

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(themeID.displayName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(theme.primaryText)

                        Text(themeID.subtitle)
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(theme.accent)
                    } else if showProBadge {
                        ThemeProBadge(theme: theme)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? theme.accent : theme.divider.opacity(0.75), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(
                color: isSelected ? theme.glow.opacity(theme.isDarkMode ? 0.24 : 0.14) : theme.shadowColor.opacity(0.08),
                radius: isSelected ? 18 : 12,
                x: 0,
                y: isSelected ? 10 : 6
            )
        }
        .buttonStyle(.plain)
    }

    private var previewSurface: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.overlayGradient)
                .frame(height: 148)
                .overlay(alignment: .top) {
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(theme.selectedTab)
                                .frame(width: 10, height: 10)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.primaryText.opacity(0.24))
                                .frame(width: 78, height: 10)

                            Spacer()

                            Image(systemName: themeID.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.selectedTab)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.cardBackground)
                                .frame(height: 68)
                                .overlay(alignment: .topLeading) {
                                    VStack(alignment: .leading, spacing: 7) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(theme.primaryText.opacity(0.22))
                                            .frame(width: 58, height: 8)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(theme.accent.opacity(0.50))
                                            .frame(width: 88, height: 8)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(theme.secondaryText.opacity(0.18))
                                            .frame(width: 42, height: 8)
                                    }
                                    .padding(12)
                                }

                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.elevatedCardBackground)
                                .frame(width: 68, height: 68)
                                .overlay {
                                    Circle()
                                        .fill(theme.accentSoft.opacity(theme.isDarkMode ? 0.40 : 0.32))
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            Image(systemName: "message.fill")
                                                .foregroundStyle(theme.rabiaAccent)
                                        }
                                }
                        }
                        .padding(.horizontal, 14)
                    }
                }

            Circle()
                .fill(theme.floatingButtonBackground)
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: theme.glow.opacity(theme.isDarkMode ? 0.38 : 0.20), radius: 14, x: 0, y: 8)
                .padding(14)
        }
    }
}

private struct ThemeProBadge: View {
    let theme: AppTheme

    var body: some View {
        Text(.pro)
            .font(.system(size: 10, weight: .heavy))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.badgeBackground)
            .foregroundStyle(theme.accent)
            .clipShape(Capsule())
    }
}
