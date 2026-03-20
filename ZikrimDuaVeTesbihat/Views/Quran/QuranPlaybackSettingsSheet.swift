import SwiftUI

struct QuranPlaybackSettingsSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var playerService: AyahAudioPlayerService
    @Environment(\.dismiss) private var dismiss

    @State private var showReciterSheet: Bool = false
    @State private var premiumPrompt: QuranAudioPremiumPrompt?

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    playbackFeaturesCard
                    sleepTimerCard
                    reciterCard

                    if !playerService.isPremiumUser {
                        Text(L10n.string(.quranAudioPrayerSurahsFree))
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .appScreenBackground(theme)
            .navigationTitle(L10n.string(.quranAudioPlaybackSettings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.tamam2) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showReciterSheet) {
            ReciterPickerSheet(
                reciters: playerService.availableReciters,
                selectedReciter: playerService.selectedReciter,
                isPremiumUser: playerService.isPremiumUser,
                onSelect: { playerService.switchReciter($0) },
                onAttemptPremiumFeature: handleReciterPremiumAttempt
            )
        }
        .alert(item: $premiumPrompt) { prompt in
            Alert(
                title: Text(prompt.title),
                message: Text(prompt.message),
                dismissButton: .default(Text(L10n.string(.tamam2)))
            )
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string(.quranAudioPlaybackSettingsSubtitle))
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)

            if let state = playerService.displayState {
                HStack(spacing: 12) {
                    QuranWaveformView(
                        isAnimating: playerService.playbackState.isActivelyPlaying,
                        tint: theme.accent
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(state.surahName) • \(L10n.format(.quranAudioVerseFormat, Int64(state.ayahNumber)))")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(theme.textPrimary)

                        Text(playerService.selectedReciter.localizedDisplayName)
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
        }
        .padding(18)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(0.48), lineWidth: 1)
        )
    }

    private var playbackFeaturesCard: some View {
        VStack(spacing: 0) {
            premiumAwareToggleRow(
                title: L10n.string(.quranAudioAutoAdvance),
                subtitle: L10n.string(.quranAudioAutoAdvanceHint),
                isOn: playerService.isAutoAdvanceEnabled,
                action: handleAutoAdvanceChange
            )

            Divider()
                .overlay(theme.border.opacity(0.42))
                .padding(.leading, 18)

            premiumAwareToggleRow(
                title: L10n.string(.quranAudioBackgroundListening),
                subtitle: L10n.string(.quranAudioBackgroundListeningHint),
                isOn: playerService.isBackgroundListeningEnabled,
                action: handleBackgroundListeningChange
            )
        }
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(0.48), lineWidth: 1)
        )
    }

    private var sleepTimerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string(.quranAudioSleepTimer))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    Text(playerService.isPremiumUser
                         ? playerService.sleepTimerOption.localizedTitle
                         : L10n.string(.quranAudioLockedLabel))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                if !playerService.isPremiumUser {
                    premiumBadge
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
                ForEach(QuranSleepTimerOption.allCases) { option in
                    Button {
                        playerService.setSleepTimer(option)
                    } label: {
                        Text(option.localizedTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(option == playerService.sleepTimerOption ? theme.accent : theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(option == playerService.sleepTimerOption ? theme.accent.opacity(0.12) : theme.backgroundSecondary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(0.48), lineWidth: 1)
        )
    }

    private var reciterCard: some View {
        Button {
            showReciterSheet = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string(.quranAudioReciterSheetTitle))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    Text(playerService.selectedReciter.localizedDisplayName)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                if playerService.selectedReciter.isPremiumLocked {
                    premiumBadge
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(18)
        }
        .buttonStyle(.plain)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(0.48), lineWidth: 1)
        )
    }

    private func premiumAwareToggleRow(
        title: String,
        subtitle: String,
        isOn: Bool,
        action: @escaping (Bool) -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    if !playerService.isPremiumUser {
                        premiumBadge
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer(minLength: 12)

            if playerService.isPremiumUser {
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: action
                ))
                .labelsHidden()
                .tint(theme.accent)
            } else {
                Button {
                    action(true)
                } label: {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .frame(width: 32, height: 32)
                        .background(theme.accent.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
    }

    private func handleReciterPremiumAttempt() {
        showReciterSheet = false

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            premiumPrompt = makePremiumPrompt(for: .reciterSelection)
        }
    }

    private func handleAutoAdvanceChange(_ isEnabled: Bool) {
        guard isEnabled || playerService.isPremiumUser else {
            premiumPrompt = makePremiumPrompt(for: .autoAdvance)
            return
        }

        playerService.setAutoAdvanceEnabled(isEnabled)
    }

    private func handleBackgroundListeningChange(_ isEnabled: Bool) {
        guard isEnabled || playerService.isPremiumUser else {
            premiumPrompt = makePremiumPrompt(for: .backgroundListening)
            return
        }

        playerService.setBackgroundListeningEnabled(isEnabled)
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

    private var premiumBadge: some View {
        Text(L10n.string(.quranAudioLockedLabel))
            .font(.caption2.weight(.bold))
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(theme.accent.opacity(0.10), in: Capsule())
    }
}
