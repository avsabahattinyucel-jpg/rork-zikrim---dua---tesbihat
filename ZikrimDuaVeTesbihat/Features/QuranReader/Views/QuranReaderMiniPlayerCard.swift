import SwiftUI

struct QuranReaderMiniPlayerCard: View {
    @ObservedObject var audioController: QuranAudioReaderViewModel
    let style: QuranReaderCanvasStyle
    let onOpen: () -> Void

    var body: some View {
        if audioController.shouldShowMiniPlayer {
            HStack(spacing: 14) {
                Button(action: onOpen) {
                    HStack(spacing: 14) {
                        Image(systemName: audioController.playbackState.isActivelyPlaying ? "waveform.circle.fill" : "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(style.chipForeground)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(audioController.nowPlayingTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(style.arabicText)
                                .lineLimit(1)

                            Text(audioController.nowPlayingSubtitle)
                                .font(.caption)
                                .foregroundStyle(style.translationText)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    transportButton(
                        systemImage: "backward.fill",
                        isEnabled: audioController.canSkipToPreviousAyah,
                        action: audioController.skipToPreviousAyah
                    )

                    Button {
                        audioController.triggerPrimaryPlayback()
                    } label: {
                        Image(systemName: audioController.primaryPlaybackButtonIcon)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(style.chipForeground)
                            .frame(width: 42, height: 42)
                            .background(style.chipBackground, in: Circle())
                    }
                    .buttonStyle(.plain)

                    transportButton(
                        systemImage: "forward.fill",
                        isEnabled: audioController.canSkipToNextAyah,
                        action: audioController.skipToNextAyah
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(style.audioSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(style.audioBorder, lineWidth: 1)
            )
            .overlay(alignment: .bottom) {
                ProgressView(value: audioController.currentProgress)
                    .tint(style.chipForeground)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .shadow(color: style.shadowColor, radius: 16, y: 8)
        }
    }

    private func transportButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isEnabled ? style.translationText : style.translationText.opacity(0.42))
                .frame(width: 34, height: 34)
                .background(style.secondaryBackground.opacity(isEnabled ? 0.78 : 0.38), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
