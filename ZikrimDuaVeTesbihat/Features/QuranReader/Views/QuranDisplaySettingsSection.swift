import SwiftUI

struct QuranDisplaySettingsSection: View {
    @ObservedObject var viewModel: QuranReaderViewModel

    var body: some View {
        Section(QuranReaderStrings.translationSection) {
            LabeledContent(QuranReaderStrings.translationFontSize, value: "\(Int(viewModel.preferences.translationFontSize))")
            Slider(
                value: Binding(
                    get: { viewModel.preferences.translationFontSize },
                    set: viewModel.updateTranslationFontSize
                ),
                in: 13...24
            )

            LabeledContent(QuranReaderStrings.transliterationFontSize, value: "\(Int(viewModel.preferences.transliterationFontSize))")
            Slider(
                value: Binding(
                    get: { viewModel.preferences.transliterationFontSize },
                    set: viewModel.updateTransliterationFontSize
                ),
                in: 12...22
            )

            LabeledContent(QuranReaderStrings.translationLineSpacing, value: String(format: "%.2f", viewModel.preferences.translationLineSpacing))
            Slider(
                value: Binding(
                    get: { viewModel.preferences.translationLineSpacing },
                    set: viewModel.updateTranslationLineSpacing
                ),
                in: 0.10...0.70
            )

            Toggle(QuranReaderStrings.compactMode, isOn: Binding(
                get: { viewModel.preferences.compactMode },
                set: viewModel.updateCompactMode
            ))
        }

        Section(QuranReaderStrings.layoutSection) {
            Picker(selection: Binding(
                get: { viewModel.preferences.displayMode },
                set: viewModel.updateDisplayMode
            )) {
                ForEach(QuranDisplayMode.allCases) { mode in
                    Text(QuranReaderStrings.localized(mode.localizationKey, mode.defaultTitle))
                        .tag(mode)
                }
            } label: {
                Text(QuranReaderStrings.localized("quran_reader_content_mode", "Content Mode"))
            }

            Picker(selection: Binding(
                get: { viewModel.preferences.layoutMode },
                set: viewModel.updateLayoutMode
            )) {
                ForEach(QuranReaderLayoutMode.allCases) { mode in
                    Text(QuranReaderStrings.localized(mode.localizationKey, mode.defaultTitle))
                        .tag(mode)
                }
            } label: {
                Text(QuranReaderStrings.localized("quran_reader_layout_picker", "Layout Style"))
            }

            Toggle(QuranReaderStrings.showTranslation, isOn: viewModel.translationVisibilityBinding())
            Toggle(QuranReaderStrings.showTransliteration, isOn: viewModel.transliterationVisibilityBinding())
            Toggle(QuranReaderStrings.showWordByWord, isOn: Binding(
                get: { viewModel.preferences.showWordByWord },
                set: viewModel.updateShowWordByWord
            ))
            Toggle(QuranReaderStrings.showShortExplanationChip, isOn: Binding(
                get: { viewModel.preferences.showShortExplanationChip },
                set: viewModel.updateShowShortExplanationChip
            ))
        }

        Section(QuranReaderStrings.behaviorSection) {
            Toggle(QuranReaderStrings.keepScreenAwake, isOn: Binding(
                get: { viewModel.preferences.keepScreenAwake },
                set: viewModel.updateKeepScreenAwake
            ))

            Toggle(QuranReaderStrings.autoHideChrome, isOn: Binding(
                get: { viewModel.preferences.autoHideChromeInMushafFocusedMode },
                set: viewModel.updateAutoHideChrome
            ))

            Toggle(QuranReaderStrings.rememberLastPosition, isOn: Binding(
                get: { viewModel.preferences.rememberLastPosition },
                set: viewModel.updateRememberPosition
            ))
        }
    }
}
