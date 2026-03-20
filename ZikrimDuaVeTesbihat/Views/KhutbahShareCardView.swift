import SwiftUI

struct KhutbahShareCardView: View {
    let content: KhutbahShareCardContent
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let shareStyle: ShareCardVisualStyle

    private var trimmedTheme: String? {
        content.mainTheme.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var trimmedFallback: String {
        content.fallbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var titleFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: content.title,
            base: metrics.titleFontSize * 0.84,
            shortTextLength: 28,
            longTextLength: 96,
            minimumScale: 0.78,
            maximumScale: 1.06
        )
    }

    private var mainThemeFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: trimmedTheme,
            base: metrics.mainThemeTextFontSize,
            shortTextLength: 65,
            longTextLength: 180,
            minimumScale: 0.82,
            maximumScale: 1.04
        )
    }

    private var fallbackFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: trimmedFallback,
            base: metrics.weeklyTaskTextFontSize,
            shortTextLength: 70,
            longTextLength: 220,
            minimumScale: 0.82,
            maximumScale: 1.04
        )
    }

    private func weeklyTaskFontSize(for text: String) -> CGFloat {
        metrics.adaptiveFontSize(
            for: text,
            base: metrics.weeklyTaskTextFontSize,
            shortTextLength: 55,
            longTextLength: 180,
            minimumScale: 0.82,
            maximumScale: 1.04
        )
    }

    private func lessonFontSize(for text: String) -> CGFloat {
        metrics.adaptiveFontSize(
            for: text,
            base: metrics.lessonTextFontSize,
            shortTextLength: 42,
            longTextLength: 140,
            minimumScale: 0.84,
            maximumScale: 1.04
        )
    }

    var body: some View {
        ShareCardCanvas(theme: theme, metrics: metrics) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: metrics.topSafeArea)

                ShareCardDecorativeHeader(
                    title: content.title,
                    fontSize: titleFontSize,
                    metrics: metrics
                )

                VStack(spacing: 10 * metrics.renderScale) {
                    Text(L10n.string(.shareCardFridayKhutbah))
                        .font(.system(size: metrics.badgeLabelFontSize * (shareStyle == .minimal ? 0.9 : 1.0), weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accentColor.opacity(0.95))
                        .tracking(shareStyle == .minimal ? metrics.badgeLabelTracking * 0.6 : metrics.badgeLabelTracking)

                    if let dateText = content.dateText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
                        Text(dateText)
                            .font(.system(size: metrics.dateFontSize, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.76))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, metrics.blockSpacingMedium)

                if let trimmedTheme {
                    Group {
                        if shareStyle.prefersPanelEmphasis {
                            AdaptivePanel(metrics: metrics, fillOpacity: shareStyle.primaryPanelOpacity) {
                                khutbahThemeContent(trimmedTheme: trimmedTheme, fontSize: mainThemeFontSize)
                            }
                        } else {
                            ShareFooterPanel(metrics: metrics) {
                                khutbahThemeContent(trimmedTheme: trimmedTheme, fontSize: mainThemeFontSize)
                            }
                        }
                    }
                    .padding(.top, metrics.blockSpacingXLarge * 0.85)
                }

                VStack(spacing: metrics.blockSpacingSmall) {
                    if !content.lessons.isEmpty {
                        VStack(alignment: .leading, spacing: metrics.blockSpacingSmall * 0.78) {
                            Text(L10n.string(.shareCardThreeKeyLessons))
                                .font(.system(size: metrics.wisdomTitleFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.78))

                            ForEach(Array(content.lessons.prefix(3).enumerated()), id: \.offset) { index, lesson in
                                khutbahLessonRow(index: index + 1, text: lesson)
                            }
                        }
                    } else {
                        ShareFooterPanel(metrics: metrics) {
                            Text(trimmedFallback)
                                .font(.system(size: fallbackFontSize, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.88))
                                .lineSpacing(metrics.subtitleLineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let weeklyTask = content.weeklyTask?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
                        Group {
                            if shareStyle.prefersPanelEmphasis {
                                AdaptivePanel(metrics: metrics, fillOpacity: shareStyle.secondaryPanelOpacity) {
                                    weeklyTaskContent(weeklyTask)
                                }
                            } else {
                                ShareFooterPanel(metrics: metrics) {
                                    weeklyTaskContent(weeklyTask)
                                }
                            }
                        }
                    }
                }
                .padding(.top, metrics.blockSpacingLarge * 0.75)

                Spacer(minLength: metrics.blockSpacingLarge)

                ShareCardBottomDecoration(metrics: metrics)
                .padding(.bottom, metrics.bottomSafeArea)
            }
        }
    }

    @ViewBuilder
    private func khutbahThemeContent(trimmedTheme: String, fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: metrics.blockSpacingSmall * 0.78) {
            Text(L10n.string(.shareCardMainTheme))
                .font(.system(size: metrics.wisdomTitleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accentColor.opacity(0.95))

            Text(trimmedTheme)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineSpacing(metrics.subtitleLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func weeklyTaskContent(_ weeklyTask: String) -> some View {
        HStack(alignment: .top, spacing: 16 * metrics.renderScale) {
            ZStack {
                RoundedRectangle(cornerRadius: 14 * metrics.renderScale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.9), theme.accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: metrics.weeklyTaskIconSize, height: metrics.weeklyTaskIconSize)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: metrics.weeklyTaskSymbolSize, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 10 * metrics.renderScale) {
                Text(L10n.string(.shareCardWeeklyTask))
                    .font(.system(size: metrics.weeklyTaskTitleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentColor.opacity(0.94))

                Text(weeklyTask)
                    .font(.system(size: weeklyTaskFontSize(for: weeklyTask), weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(metrics.subtitleLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func khutbahLessonRow(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 16 * metrics.renderScale) {
            Text(L10n.format(.indexNumberFormat, Int64(index)))
                .font(.system(size: metrics.lessonNumberFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: metrics.lessonNumberSize, height: metrics.lessonNumberSize)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor, Color.white.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(text)
                .font(.system(size: lessonFontSize(for: text), weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineSpacing(metrics.subtitleLineSpacing * 0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(metrics.infoBoxPadding * 0.78)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: metrics.statCardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(shareStyle == .minimal ? 0.24 : 0.38))
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.statCardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
