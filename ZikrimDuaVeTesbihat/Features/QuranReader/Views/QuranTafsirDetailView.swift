import SwiftUI

struct QuranTafsirDetailView: View {
    let presented: QuranReaderViewModel.PresentedTafsir

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if presented.isLoading {
                    ProgressView(QuranReaderStrings.loading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let payload = presented.payload {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(payload.title)
                                .font(.title3.weight(.semibold))

                            Text(payload.body)
                                .font(.body)
                                .foregroundStyle(.primary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(QuranReaderStrings.sourceAttribution)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text(QuranReaderStrings.localized(payload.source.localizationKey, payload.source.defaultTitle))
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                if let detailText = QuranReaderStrings.tafsirSourceDetail(payload.source) {
                                    Text(detailText)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                if let licenseNote = QuranReaderStrings.tafsirSourceLicense(payload.source) {
                                    Divider()

                                    Text("\(QuranReaderStrings.license): \(licenseNote)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .padding(20)
                    }
                } else {
                    ContentUnavailableView(
                        QuranReaderStrings.openTafsir,
                        systemImage: "text.book.closed",
                        description: Text(QuranReaderStrings.fallbackTafsirMessage)
                    )
                }
            }
            .navigationTitle(QuranReaderStrings.openTafsir)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(QuranReaderStrings.close) {
                        dismiss()
                    }
                }
            }
        }
    }
}
