import SwiftUI

struct AyahRowView: View {
    let verse: QuranVerse
    let translationText: String
    let displayMode: QuranShareDisplayMode
    let arabicFontSize: CGFloat
    let translationFontSize: CGFloat
    let isBookmarked: Bool
    let isCurrentAyah: Bool
    let playbackState: AudioPlaybackState
    let isBookmarkHighlighted: Bool
    let theme: ActiveTheme
    let onBookmark: () -> Void
    let onPlayPause: () -> Void
    let onShare: () -> Void

    private var isLoading: Bool {
        isCurrentAyah && playbackState.showsLoadingIndicator
    }

    private var isPlaying: Bool {
        isCurrentAyah && playbackState == .playing
    }

    private var isPaused: Bool {
        isCurrentAyah && playbackState == .paused
    }

    private var isHighlighted: Bool {
        isCurrentAyah && playbackState.isActive
    }

    private var resolvedArabicFontSize: CGFloat {
        QuranResponsiveMetrics.isVeryCompactPhone ? max(arabicFontSize - 6, 18) : (QuranResponsiveMetrics.isCompactPhone ? max(arabicFontSize - 4, 18) : arabicFontSize)
    }

    private var resolvedTranslationFontSize: CGFloat {
        QuranResponsiveMetrics.isVeryCompactPhone ? max(translationFontSize - 2, 12) : (QuranResponsiveMetrics.isCompactPhone ? max(translationFontSize - 1, 12) : translationFontSize)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            headerRow

            if displayMode == .both || displayMode == .arabicOnly {
                arabicPanel
            }

            if displayMode == .both || displayMode == .turkishOnly {
                translationPanel
            }

            controlRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.accent.opacity(isHighlighted ? 0.06 : 0))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(theme.heroGradient.opacity(isHighlighted ? (theme.isDarkMode ? 0.14 : 0.08) : 0))
                        }
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    isHighlighted ? theme.accent.opacity(0.55) : theme.border.opacity(0.55),
                    lineWidth: isHighlighted ? 1.2 : 1
                )
        )
        .shadow(
            color: isHighlighted ? theme.accent.opacity(0.10) : theme.shadowColor.opacity(0.05),
            radius: isHighlighted ? 16 : 8,
            x: 0,
            y: isHighlighted ? 8 : 4
        )
        .scaleEffect(isHighlighted ? 1.008 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isHighlighted)
        .animation(.easeInOut(duration: 0.22), value: isBookmarkHighlighted)
    }

    private var arabicPanel: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if displayMode == .both {
                decorativeDivider
            }

            Text(verse.arabicText)
                .font(.system(size: resolvedArabicFontSize, weight: .regular))
                .foregroundStyle(theme.textPrimary)
                .lineSpacing(12)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.quranArabicBackground.opacity(isHighlighted ? 0.92 : 0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(theme.border.opacity(0.26), lineWidth: 1)
                }
        )
    }

    private var translationPanel: some View {
        Text(translationText)
            .font(.system(size: resolvedTranslationFontSize))
            .foregroundStyle(theme.textSecondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(6)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.quranTranslationBackground.opacity(displayMode == .both ? 0.52 : 0.68))
            )
            .padding(.top, displayMode == .both ? 2 : 0)
    }

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                verseNumberBadge

                if isCurrentAyah {
                    HStack(spacing: 6) {
                        QuranWaveformView(isAnimating: isPlaying || isLoading, tint: theme.accent)

                        Text(statusLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.accent)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(theme.accent.opacity(0.08))
                    .clipShape(.capsule)
                }
            }

            Spacer(minLength: 12)

            if isCurrentAyah && playbackState == .buffering {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(theme.accent)

                    Text(.quranAudioBuffering)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.accent)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(theme.accent.opacity(0.08))
                .clipShape(.capsule)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button(action: onPlayPause) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(isCurrentAyah ? 0.14 : 0.10))
                            .frame(width: 34, height: 34)

                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(theme.accent)
                        } else {
                            Image(systemName: playbackSymbolName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(theme.accent)
                        }
                    }

                    Text(isPlaying ? L10n.string(.quranAudioStop) : L10n.string(.quranAudioResume))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(theme.quranActionBackground.opacity(0.52), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onShare) {
                Label {
                    Text(.commonShare)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(theme.backgroundSecondary.opacity(0.74), in: Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onBookmark) {
                Label {
                    Text(isBookmarked ? L10n.string(.favorilerim) : L10n.string(.favorilereKaydet2))
                } icon: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isBookmarked ? theme.accent : theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    (isBookmarked ? theme.accent.opacity(0.12) : theme.backgroundSecondary.opacity(0.74)),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var decorativeDivider: some View {
        HStack(spacing: 10) {
            Capsule(style: .continuous)
                .fill(theme.accent.opacity(0.28))
                .frame(width: 34, height: 2)

            Image(systemName: "sparkles")
                .font(.caption2)
                .foregroundStyle(theme.accent.opacity(0.72))

            Capsule(style: .continuous)
                .fill(theme.accent.opacity(0.28))
                .frame(width: 34, height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var verseNumberBadge: some View {
        HStack {
            Text("\(verse.verseNumber)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.quranBadgeText)
                .frame(width: 32, height: 32)
                .background(theme.palette.quranBadgeBackground, in: Circle())
        }
    }

    private var playbackSymbolName: String {
        if isPlaying {
            return "pause.fill"
        }

        if isPaused {
            return "play.fill"
        }

        return "play.fill"
    }

    private var statusLabel: String {
        if isLoading {
            return L10n.string(.quranAudioLoadingAyah)
        }

        if isPlaying {
            return L10n.string(.quranAudioMiniPlayerNowPlaying)
        }

        if isPaused {
            return L10n.string(.quranAudioResume)
        }

        return L10n.format(.quranAudioVerseFormat, Int64(verse.verseNumber))
    }
}
