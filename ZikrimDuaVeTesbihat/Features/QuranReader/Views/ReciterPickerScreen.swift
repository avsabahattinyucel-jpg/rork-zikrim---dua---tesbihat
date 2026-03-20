import SwiftUI

struct ReciterPickerScreen: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var highlightedReciterID: String
    @State private var premiumPrompt: QuranAudioPremiumPrompt?

    let reciters: [Reciter]
    let selectedReciter: Reciter
    let isPremiumUser: Bool
    let onSelect: (Reciter) -> Void

    private var theme: ActiveTheme { themeManager.current }

    init(
        reciters: [Reciter],
        selectedReciter: Reciter,
        isPremiumUser: Bool,
        onSelect: @escaping (Reciter) -> Void
    ) {
        self.reciters = reciters
        self.selectedReciter = selectedReciter
        self.isPremiumUser = isPremiumUser
        self.onSelect = onSelect
        _highlightedReciterID = State(initialValue: selectedReciter.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                reciterList
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .appScreenBackground(theme)
        .navigationTitle(L10n.string(.quranAudioReciterSheetTitle))
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
        .alert(item: $premiumPrompt) { prompt in
            Alert(
                title: Text(prompt.title),
                message: Text(prompt.message),
                dismissButton: .default(Text(L10n.string(.tamam2)))
            )
        }
        .onChange(of: selectedReciter.id) { _, newValue in
            highlightedReciterID = newValue
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string(.quranAudioReciterSheetTitle))
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)

            Text(L10n.string(.quranAudioReciterSheetSubtitle))
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
    }

    private var reciterList: some View {
        VStack(spacing: 12) {
            ForEach(reciters) { reciter in
                Button {
                    if reciter.isPremiumLocked && !isPremiumUser {
                        premiumPrompt = QuranAudioPremiumPrompt(
                            feature: .reciterSelection,
                            title: L10n.string(.quranAudioPremiumPromptTitle),
                            message: L10n.string(.quranAudioPremiumReciterMessage)
                        )
                    } else {
                        highlightedReciterID = reciter.id
                        onSelect(reciter)
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(reciter.id == highlightedReciterID ? 0.16 : 0.10))
                                .frame(width: 42, height: 42)

                            Image(systemName: reciter.id == highlightedReciterID ? "checkmark" : (reciter.isPremiumLocked ? "crown.fill" : "waveform"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.accent)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(reciter.localizedDisplayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.textPrimary)

                            Text(reciterMoodLine(for: reciter))
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }

                        Spacer()

                        Text(reciter.isPremiumLocked ? QuranReaderStrings.proBadge : L10n.string(.quranAudioFreeLabel))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(reciter.isPremiumLocked ? theme.accent : theme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                reciter.isPremiumLocked ? theme.accent.opacity(0.10) : theme.backgroundSecondary,
                                in: Capsule()
                            )

                        if reciter.id == highlightedReciterID {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(reciter.id == highlightedReciterID ? theme.selectionBackground : theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                reciter.id == highlightedReciterID ? theme.accent.opacity(0.45) : theme.border.opacity(0.55),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reciterMoodLine(for reciter: Reciter) -> String {
        switch reciter.id {
        case "alafasy":
            return AppLanguage.current == .tr ? "Temiz, dengeli ve gunluk dinleme icin en rahat secenek." : "Clean, balanced, and easy for everyday listening."
        case "abdul_basit":
            return AppLanguage.current == .tr ? "Klasik uslubu sevenler icin guclu ve tanidik bir kiraat." : "A rich classical style with a timeless feel."
        case "muaiqly":
            return AppLanguage.current == .tr ? "Akici ritmi ve sakin gecisleriyle uzun okumalar icin ideal." : "Smooth pacing with calm transitions for longer sessions."
        case "sudais":
            return AppLanguage.current == .tr ? "Harem atmosferini tasiyan net ve parlak bir tilavet." : "Bright and recognisable, with a Haramain atmosphere."
        case "minshawi":
            return AppLanguage.current == .tr ? "Daha agir, daha derin ve klasik hissi kuvvetli." : "Deeper, slower, and richly classical in tone."
        default:
            return ""
        }
    }
}
