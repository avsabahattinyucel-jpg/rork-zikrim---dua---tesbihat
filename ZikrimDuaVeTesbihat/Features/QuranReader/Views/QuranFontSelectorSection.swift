import SwiftUI

struct QuranFontSelectorSection: View {
    @ObservedObject var viewModel: QuranReaderViewModel

    var body: some View {
        Section(QuranReaderStrings.arabicTypographySection) {
            ForEach(QuranFontOption.allCases) { option in
                Button {
                    viewModel.updateFontOption(option)
                } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(QuranReaderStrings.localized(option.localizationKey, option.defaultTitle))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(QuranReaderStrings.localized(option.detailLocalizationKey, option.defaultDetail))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(option.previewSample)
                                .font(QuranFontResolver.arabicFont(
                                    for: option,
                                    size: 22,
                                    relativeTo: .title3
                                ))
                                .foregroundStyle(.primary)
                                .environment(\.layoutDirection, .rightToLeft)
                                .lineLimit(1)

                            Text(fontFootnote(for: option))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.preferences.fontOption == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        } else if option.isPremiumCandidate {
                            Text(QuranReaderStrings.proBadge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.12), in: Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 12) {
                LabeledContent(QuranReaderStrings.arabicFontSize, value: "\(Int(viewModel.preferences.arabicFontSize))")
                Slider(
                    value: Binding(
                        get: { viewModel.preferences.arabicFontSize },
                        set: viewModel.updateArabicFontSize
                    ),
                    in: 24...44
                )

                LabeledContent(QuranReaderStrings.arabicLineSpacing, value: String(format: "%.2f", viewModel.preferences.arabicLineSpacing))
                Slider(
                    value: Binding(
                        get: { viewModel.preferences.arabicLineSpacing },
                        set: viewModel.updateArabicLineSpacing
                    ),
                    in: 0.20...0.85
                )
            }

            Picker(selection: Binding(
                get: { viewModel.preferences.mushafScriptOption },
                set: viewModel.updateMushafScriptOption
            )) {
                ForEach(QuranArabicScriptOption.allCases) { option in
                    Text(QuranReaderStrings.localized(option.localizationKey, option.defaultTitle))
                        .tag(option)
                }
            } label: {
                Text(QuranReaderStrings.mushafTextStyle)
            }
            .disabled(viewModel.preferences.layoutMode != .mushafFocused)

            Text(QuranReaderStrings.mushafTextStyleHint)
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle(QuranReaderStrings.showAyahNumbers, isOn: Binding(
                get: { viewModel.preferences.showAyahNumbers },
                set: viewModel.updateShowAyahNumbers
            ))
        }
    }

    private func fontFootnote(for option: QuranFontOption) -> String {
        if let resolved = QuranFontResolver.resolvedFontName(for: option) {
            return String(
                format: QuranReaderStrings.localized(
                    "quran_reader_font_active_format",
                    "Active font: %@"
                ),
                resolved
            )
        }

        return QuranReaderStrings.localized(
            "quran_reader_font_fallback_note",
            "Using the iOS fallback font until the custom font is bundled."
        )
    }
}
