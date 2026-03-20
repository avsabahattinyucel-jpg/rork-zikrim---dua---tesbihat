import SwiftUI

struct QuranAudioSettingsSection: View {
    @State private var premiumPrompt: QuranAudioPremiumPrompt?

    @ObservedObject var viewModel: QuranReaderViewModel

    private var audio: QuranAudioReaderViewModel { viewModel.audioController }

    var body: some View {
        Section(QuranReaderStrings.audioSection) {
            NavigationLink {
                ReciterPickerScreen(
                    reciters: audio.availableReciters,
                    selectedReciter: audio.selectedReciter,
                    isPremiumUser: audio.isPremiumUser,
                    onSelect: audio.switchReciter
                )
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.string(.quranAudioReciterSheetTitle))
                            .foregroundStyle(.primary)
                        Text(audio.selectedReciter.localizedDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if audio.selectedReciter.isPremiumLocked && !audio.isPremiumUser {
                        Text(QuranReaderStrings.proBadge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.12), in: Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }

            Toggle(L10n.string(.quranAudioAutoAdvance), isOn: Binding(
                get: { audio.isAutoAdvanceEnabled },
                set: handleAutoAdvanceChange
            ))

            Toggle(L10n.string(.quranAudioBackgroundListening), isOn: Binding(
                get: { audio.isBackgroundListeningEnabled },
                set: handleBackgroundListeningChange
            ))
        }
        .alert(item: $premiumPrompt) { prompt in
            Alert(
                title: Text(prompt.title),
                message: Text(prompt.message),
                dismissButton: .default(Text(L10n.string(.tamam2)))
            )
        }
    }

    private func handleAutoAdvanceChange(_ isEnabled: Bool) {
        guard isEnabled || audio.isPremiumUser else {
            premiumPrompt = makePremiumPrompt(for: .autoAdvance)
            return
        }

        audio.setAutoAdvanceEnabled(isEnabled)
    }

    private func handleBackgroundListeningChange(_ isEnabled: Bool) {
        guard isEnabled || audio.isPremiumUser else {
            premiumPrompt = makePremiumPrompt(for: .backgroundListening)
            return
        }

        audio.setBackgroundListeningEnabled(isEnabled)
    }

    private func makePremiumPrompt(for feature: QuranAudioPremiumFeature) -> QuranAudioPremiumPrompt {
        let message: String
        switch feature {
        case .backgroundListening:
            message = L10n.string(.quranAudioPremiumBackgroundMessage)
        case .reciterSelection:
            message = L10n.string(.quranAudioPremiumReciterMessage)
        case .autoAdvance:
            message = L10n.string(.quranAudioPremiumAutoAdvanceMessage)
        case .sleepTimer:
            message = L10n.string(.quranAudioPremiumSleepTimerMessage)
        case .offlineListening:
            message = L10n.string(.quranAudioPremiumOfflineMessage)
        case .fullQuranRecitation:
            message = L10n.string(.quranAudioPremiumFullQuranMessage)
        }

        return QuranAudioPremiumPrompt(
            feature: feature,
            title: L10n.string(.quranAudioPremiumPromptTitle),
            message: message
        )
    }
}
