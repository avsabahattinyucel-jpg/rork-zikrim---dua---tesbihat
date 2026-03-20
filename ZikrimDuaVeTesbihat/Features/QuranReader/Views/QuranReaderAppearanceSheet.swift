import SwiftUI

struct QuranReaderAppearanceSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: QuranReaderViewModel

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            Form {
                Section(QuranReaderStrings.appearanceSection) {
                    ForEach(QuranReaderAppearance.allCases) { appearance in
                        let style = QuranReaderAppearanceEngine.style(for: appearance, theme: theme)
                        Button {
                            viewModel.updateAppearance(appearance)
                        } label: {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(style.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(style.border, lineWidth: 1)
                                    )
                                    .overlay(alignment: .bottomTrailing) {
                                        Circle()
                                            .fill(style.badgeBackground)
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Circle()
                                                    .stroke(style.badgeForeground.opacity(0.22), lineWidth: 1)
                                            )
                                            .padding(8)
                                    }
                                    .frame(width: 56, height: 56)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(QuranReaderStrings.localized(appearance.localizationKey, appearance.defaultTitle))
                                        .foregroundStyle(.primary)
                                    Text(previewSubtitle(for: appearance))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if viewModel.preferences.appearance == appearance {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                QuranFontSelectorSection(viewModel: viewModel)
                QuranDisplaySettingsSection(viewModel: viewModel)
                QuranAudioSettingsSection(viewModel: viewModel)
                QuranTafsirSection(viewModel: viewModel)
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundView)
            .navigationTitle(QuranReaderStrings.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(QuranReaderStrings.settingsDone) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func previewSubtitle(for appearance: QuranReaderAppearance) -> String {
        switch appearance {
        case .standardDark:
            return QuranReaderStrings.localized("quran_reader_appearance_standard_dark_subtitle", "Elegant dark canvas with refined contrast.")
        case .mushaf:
            return QuranReaderStrings.localized("quran_reader_appearance_mushaf_subtitle", "Minimal chrome and Arabic-first focus.")
        case .sepia:
            return QuranReaderStrings.localized("quran_reader_appearance_sepia_subtitle", "Warm paper tone for longer sessions.")
        case .nightFocus:
            return QuranReaderStrings.localized("quran_reader_appearance_night_focus_subtitle", "Softened dark palette for late sessions.")
        case .translationFocus:
            return QuranReaderStrings.localized("quran_reader_appearance_translation_focus_subtitle", "Balanced spacing tuned for comprehension.")
        }
    }
}
