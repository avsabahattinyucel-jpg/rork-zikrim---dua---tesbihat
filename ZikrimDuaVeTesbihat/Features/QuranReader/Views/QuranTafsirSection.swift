import SwiftUI

struct QuranTafsirSection: View {
    @ObservedObject var viewModel: QuranReaderViewModel

    var body: some View {
        Section(QuranReaderStrings.tafsirSection) {
            Picker(selection: Binding(
                get: { viewModel.preferredTafsirSource },
                set: viewModel.updatePreferredTafsirSource
            )) {
                ForEach(QuranTafsirSource.allCases) { source in
                    Text(QuranReaderStrings.localized(source.localizationKey, source.defaultTitle))
                        .tag(source)
                }
            } label: {
                Text(QuranReaderStrings.preferredTafsirSource)
            }

            Toggle(QuranReaderStrings.showShortExplanationChip, isOn: Binding(
                get: { viewModel.preferences.showShortExplanationChip },
                set: viewModel.updateShowShortExplanationChip
            ))

            Toggle(QuranReaderStrings.inlineTafsirPreview, isOn: Binding(
                get: { viewModel.preferences.enableInlineTafsirPreview },
                set: viewModel.updateInlineTafsirPreview
            ))

            Picker(selection: Binding(
                get: { viewModel.preferences.defaultTafsirFallbackLanguage },
                set: viewModel.updateFallbackLanguage
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(QuranReaderStrings.languageName(language))
                        .tag(language)
                }
            } label: {
                Text(QuranReaderStrings.tafsirFallbackLanguage)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(QuranReaderStrings.localized(
                    viewModel.preferredTafsirSource.localizationKey,
                    viewModel.preferredTafsirSource.defaultTitle
                ))
                    .font(.subheadline.weight(.semibold))

                if let detail = QuranReaderStrings.tafsirSourceDetail(viewModel.preferredTafsirSource) {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }
}
