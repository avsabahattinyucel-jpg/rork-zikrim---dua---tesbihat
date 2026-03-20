import SwiftUI

struct VerseShareView: View {
    let verse: QuranVerse
    let translationText: String
    let surahName: String
    let surahArabicName: String
    let translationSourceName: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SharePreviewScreen(
                cardType: .quran(makeShareContent()),
                initialTheme: .night,
                showsThemePicker: true
            )
            .navigationTitle(L10n.string(.verseShareNavTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.commonClose) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func makeShareContent() -> QuranShareCardContent {
        QuranShareCardContent(
            surahName: surahName,
            surahArabicName: surahArabicName,
            verseNumber: verse.verseNumber,
            arabicText: verse.arabicText.trimmedNilIfEmpty,
            translationText: translationText.trimmedNilIfEmpty,
            translationSourceName: translationSourceName,
            brandingTitle: AppName.full,
            brandingSubtitle: ShareCardBranding.storeSubtitle
        )
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
