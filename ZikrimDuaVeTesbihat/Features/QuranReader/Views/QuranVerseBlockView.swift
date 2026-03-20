import SwiftUI
import UIKit

struct QuranVerseBlockView: View {
    let item: QuranReaderVerseItem
    let style: QuranReaderCanvasStyle
    let displayMode: QuranDisplayMode
    let preferences: QuranReaderPreferences
    let isCurrentAyah: Bool
    let activeWordRange: ClosedRange<Int>?
    let isPlaying: Bool
    let isLoading: Bool
    let isMushafFocused: Bool
    let onPlay: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onCopy: () -> Void
    let onNote: () -> Void
    let onOpenTafsir: () -> Void
    let onAppear: () -> Void

    @State private var selectedWordID: String?

    private var arabicFont: Font {
        QuranFontResolver.arabicFont(
            for: preferences.fontOption,
            size: CGFloat(preferences.arabicFontSize),
            relativeTo: .title2
        )
    }

    private var wordByWordEntries: [QuranWordByWordEntry] {
        item.wordByWord ?? []
    }

    private var displayedArabicText: String {
        if isMushafFocused, let mushafArabicText = item.mushafArabicText, !mushafArabicText.isEmpty {
            return mushafArabicText
        }
        return item.verse.arabicText
    }

    private var contentLayoutDirection: LayoutDirection {
        switch AppLanguage.current {
        case .ar, .fa, .ur:
            return .rightToLeft
        default:
            return .leftToRight
        }
    }

    private var contentAlignment: Alignment {
        contentLayoutDirection == .rightToLeft ? .trailing : .leading
    }

    private var textAlignment: TextAlignment {
        contentLayoutDirection == .rightToLeft ? .trailing : .leading
    }

    private var selectedWord: QuranWordByWordEntry? {
        wordByWordEntries.first(where: { $0.id == selectedWordID })
    }

    private var highlightedArabicText: AttributedString {
        guard let activeWordRange, isCurrentAyah else {
            var text = AttributedString(displayedArabicText)
            text.foregroundColor = currentAyahArabicColor
            return text
        }

        return ArabicWordHighlightRenderer.highlightedText(
            displayedArabicText,
            activeWordRange: activeWordRange,
            underlineColor: UIColor(style.activeWordStroke),
            foregroundColor: UIColor(style.activeWordText),
            baseForegroundColor: UIColor(currentAyahArabicColor)
        )
    }

    private var currentAyahArabicColor: Color {
        isCurrentAyah ? style.activeWordStroke : style.arabicText
    }

    private var shortExplanationPreview: String? {
        guard let text = item.shortExplanation?.text.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }

        let maxLength = preferences.compactMode ? 150 : 210
        guard text.count > maxLength else { return text }
        let prefix = text.prefix(maxLength).trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(prefix)…"
    }

    private var notePreview: String? {
        guard let text = item.verseNote?.noteText.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }

        let maxLength = preferences.compactMode ? 52 : 76
        guard text.count > maxLength else { return text }
        let prefix = text.prefix(maxLength).trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(prefix)…"
    }

    private var noteActionTitle: String {
        item.verseNote == nil ? QuranReaderStrings.note : QuranReaderStrings.editNote
    }

    private var isStudyLayerVisible: Bool {
        preferences.showWordByWord || preferences.showShortExplanationChip || notePreview != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: preferences.compactMode ? 14 : 18) {
            header

            if let notePreview {
                notePreviewCard(notePreview)
            }

            if displayMode.showsArabic {
                arabicSection
            }

            if displayMode.showsTransliteration, let transliteration = item.transliteration, !transliteration.isEmpty {
                Text(transliteration)
                    .font(.system(size: preferences.transliterationFontSize))
                    .foregroundStyle(style.transliterationText.opacity(0.82))
                    .lineSpacing(CGFloat(preferences.translationFontSize * preferences.translationLineSpacing))
                    .multilineTextAlignment(textAlignment)
                    .frame(maxWidth: .infinity, alignment: contentAlignment)
                    .environment(\.layoutDirection, contentLayoutDirection)
            }

            if displayMode.showsTranslation {
                Text(item.translation)
                    .font(.system(size: preferences.translationFontSize))
                    .foregroundStyle(style.translationText.opacity(isMushafFocused ? 0.9 : 0.96))
                    .lineSpacing(CGFloat(preferences.translationFontSize * preferences.translationLineSpacing))
                    .multilineTextAlignment(textAlignment)
                    .frame(maxWidth: .infinity, alignment: contentAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.layoutDirection, contentLayoutDirection)
            }

            if isStudyLayerVisible {
                studyLayer
            }

            if !isMushafFocused {
                actionRow
            }
        }
        .padding(.horizontal, preferences.compactMode ? 16 : 20)
        .padding(.vertical, preferences.compactMode ? 16 : 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(isCurrentAyah ? style.selectionHighlight.opacity(0.18) : style.cardBackground.opacity(0.54))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(isCurrentAyah ? style.chipForeground.opacity(0.20) : style.border.opacity(0.42), lineWidth: 1)
        )
        .shadow(color: style.shadowColor.opacity(isCurrentAyah ? 0.38 : 0.16), radius: isCurrentAyah ? 18 : 10, y: isCurrentAyah ? 10 : 4)
        .contextMenu {
            Button(QuranReaderStrings.audioPlay, action: onPlay)
            Button(QuranReaderStrings.bookmark, action: onBookmark)
            Button(QuranReaderStrings.copy, action: onCopy)
            Button(QuranReaderStrings.share, action: onShare)
            Button(noteActionTitle, action: onNote)
            Button(QuranReaderStrings.openTafsir, action: onOpenTafsir)
        }
        .onAppear(perform: onAppear)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            if preferences.showAyahNumbers {
                Text("\(item.verse.verseNumber)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(style.badgeForeground)
                    .frame(width: 30, height: 30)
                    .background(style.badgeBackground.opacity(0.92), in: Circle())
            }

            if isCurrentAyah {
                Label(isPlaying ? QuranReaderStrings.audioPause : QuranReaderStrings.audioPlay, systemImage: isLoading ? "waveform" : "play.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(style.chipForeground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(style.chipBackground.opacity(0.94), in: Capsule())
            }

            Spacer()

            if item.isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(style.chipForeground)
            }

            Menu {
                Button(QuranReaderStrings.audioPlay, action: onPlay)
                Button(QuranReaderStrings.bookmark, action: onBookmark)
                Button(QuranReaderStrings.copy, action: onCopy)
                Button(QuranReaderStrings.share, action: onShare)
                Button(noteActionTitle, action: onNote)
                Button(QuranReaderStrings.openTafsir, action: onOpenTafsir)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(style.transliterationText)
            }
        }
    }

    private var arabicSection: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(highlightedArabicText)
                .font(arabicFont)
                .lineSpacing(CGFloat(preferences.arabicFontSize * preferences.arabicLineSpacing))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityLabel(Text(QuranReaderStrings.ayahAccessibilityLabel(item.verse.verseNumber)))
        }
        .padding(.horizontal, preferences.compactMode ? 2 : 4)
        .padding(.top, displayMode.showsTranslation || displayMode.showsTransliteration || isStudyLayerVisible ? 4 : 8)
    }

    private var studyLayer: some View {
        VStack(alignment: .leading, spacing: 12) {
            if preferences.showWordByWord, !wordByWordEntries.isEmpty {
                wordByWordSection
            }

            if preferences.showShortExplanationChip, let shortExplanationPreview {
                TafsirPreview(
                    title: QuranReaderStrings.shortExplanation,
                    content: shortExplanationPreview,
                    sourceLabel: item.shortExplanation?.didUseFallbackLanguage == true
                    ? QuranReaderStrings.languageName(item.shortExplanation?.language ?? .en)
                    : nil,
                    style: style,
                    compact: preferences.compactMode,
                    actionTitle: QuranReaderStrings.openTafsir,
                    action: onOpenTafsir
                )
            }
        }
    }

    private var wordByWordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(QuranReaderStrings.wordByWord)
                .font(.caption.weight(.semibold))
                .foregroundStyle(style.chipForeground)

            WordChipFlow(
                entries: wordByWordEntries,
                selectedWordID: $selectedWordID,
                activeWordRange: activeWordRange,
                style: style,
                preferences: preferences
            )

            if let selectedWord {
                TafsirPreview(
                    title: selectedWord.arabic,
                    content: selectedWord.translation ?? item.translation,
                    sourceLabel: L10n.format(.quranAudioVerseFormat, Int64(item.verse.verseNumber)),
                    style: style,
                    compact: true,
                    actionTitle: nil,
                    action: nil
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionButton(title: QuranReaderStrings.audioPlay, systemImage: isPlaying ? "pause.fill" : "play.fill", action: onPlay)
            actionButton(title: QuranReaderStrings.bookmark, systemImage: item.isBookmarked ? "bookmark.fill" : "bookmark", action: onBookmark)
            actionButton(title: QuranReaderStrings.openTafsir, systemImage: "text.book.closed", action: onOpenTafsir)
            actionButton(title: noteActionTitle, systemImage: "note.text", action: onNote)
        }
    }

    private func notePreviewCard(_ notePreview: String) -> some View {
        Button(action: onNote) {
            HStack(spacing: 10) {
                Image(systemName: "note.text")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(style.chipForeground)
                    .frame(width: 28, height: 28)
                    .background(style.chipBackground.opacity(0.94), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLanguage.current == .tr ? "Kişisel notun var" : "You have a personal note")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(style.chipForeground)

                    Text(notePreview)
                        .font(.caption)
                        .foregroundStyle(style.translationText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.transliterationText)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(style.secondaryBackground.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(style.chipForeground.opacity(0.14), lineWidth: 1)
        )
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.translationText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(style.secondaryBackground.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(style.border.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct WordChipFlow: View {
    let entries: [QuranWordByWordEntry]
    @Binding var selectedWordID: String?
    let activeWordRange: ClosedRange<Int>?
    let style: QuranReaderCanvasStyle
    let preferences: QuranReaderPreferences

    private let columns = [
        GridItem(.adaptive(minimum: 82, maximum: 160), spacing: 8, alignment: .trailing)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .trailing, spacing: 8) {
            ForEach(entries) { entry in
                WordChip(
                    entry: entry,
                    isSelected: selectedWordID == entry.id,
                    isActivelyPlaying: activeWordRange?.contains(entry.wordIndex) == true,
                    style: style,
                    preferences: preferences
                ) {
                    UISelectionFeedbackGenerator().selectionChanged()
                    selectedWordID = selectedWordID == entry.id ? nil : entry.id
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private struct WordChip: View {
    let entry: QuranWordByWordEntry
    let isSelected: Bool
    let isActivelyPlaying: Bool
    let style: QuranReaderCanvasStyle
    let preferences: QuranReaderPreferences
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(entry.arabic)
                    .font(QuranFontResolver.arabicFont(
                        for: preferences.fontOption,
                        size: max(19, CGFloat(preferences.arabicFontSize * 0.54)),
                        relativeTo: .headline
                    ))
                    .foregroundStyle(isActivelyPlaying ? style.activeWordText : style.arabicText)
                    .lineLimit(1)
                    .environment(\.layoutDirection, .rightToLeft)

                if let translation = entry.translation, !translation.isEmpty {
                    Text(translation)
                        .font(.system(size: max(10, preferences.translationFontSize - 5)))
                        .foregroundStyle(isActivelyPlaying ? style.activeWordText.opacity(0.92) : style.translationText.opacity(0.84))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: preferences.compactMode ? 58 : 64)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                isActivelyPlaying
                        ? style.secondaryBackground.opacity(0.72)
                        : (isSelected ? style.chipBackground.opacity(0.92) : style.secondaryBackground.opacity(0.55))
                            )
                    )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isActivelyPlaying
                        ? style.activeWordStroke
                        : (isSelected ? style.chipForeground.opacity(0.28) : style.border.opacity(0.34)),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isActivelyPlaying ? style.activeWordStroke.opacity(0.22) : .clear,
                radius: isActivelyPlaying ? 10 : 0,
                y: isActivelyPlaying ? 4 : 0
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isActivelyPlaying)
    }
}

private enum ArabicWordHighlightRenderer {
    static func highlightedText(
        _ text: String,
        activeWordRange: ClosedRange<Int>,
        underlineColor: UIColor,
        foregroundColor: UIColor,
        baseForegroundColor: UIColor
    ) -> AttributedString {
        let mutable = NSMutableAttributedString(string: text)
        let nsText = text as NSString
        let matches = try? NSRegularExpression(pattern: "\\S+")
        let wordMatches = matches?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right

        mutable.addAttributes([
            .foregroundColor: baseForegroundColor,
            .paragraphStyle: paragraph
        ], range: NSRange(location: 0, length: nsText.length))

        for (offset, match) in wordMatches.enumerated() {
            let wordIndex = offset + 1
            guard activeWordRange.contains(wordIndex) else { continue }

            mutable.addAttributes([
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: underlineColor,
                .foregroundColor: foregroundColor,
                .strokeColor: underlineColor.withAlphaComponent(0.30),
                .strokeWidth: -0.35
            ], range: match.range)
        }

        if let attributed = try? AttributedString(mutable, including: \.uiKit) {
            return attributed
        }

        return AttributedString(text)
    }
}

private struct TafsirPreview: View {
    let title: String
    let content: String
    let sourceLabel: String?
    let style: QuranReaderCanvasStyle
    let compact: Bool
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.chipForeground)

                if let sourceLabel, !sourceLabel.isEmpty {
                    Text(sourceLabel)
                        .font(.caption2)
                        .foregroundStyle(style.transliterationText)
                }

                Spacer(minLength: 8)

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(style.chipForeground)
                        .buttonStyle(.plain)
                }
            }

            Text(content)
                .font(compact ? .footnote : .subheadline)
                .foregroundStyle(style.translationText)
                .lineLimit(compact ? 3 : 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, compact ? 12 : 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(style.secondaryBackground.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style.border.opacity(0.34), lineWidth: 1)
        )
    }
}

#Preview {
    let previewPreferences: QuranReaderPreferences = {
        var preferences = QuranReaderPreferences.default
        preferences.showWordByWord = true
        return preferences
    }()

    let sample = QuranReaderVerseItem(
        verse: QuranVerse(
            surahId: 112,
            verseNumber: 1,
            arabicText: "قُلْ هُوَ ٱللَّهُ أَحَدٌ",
            turkishTranslation: "De ki: O Allah birdir."
        ),
        translation: "Say, He is Allah, One.",
        transliteration: "Qul huwa Allahu ahad",
        mushafArabicText: nil,
        isBookmarked: false,
        verseNote: QuranVerseNote(
            surahId: 112,
            verseNumber: 1,
            surahName: "İhlas",
            noteText: "Tevhid vurgusunu hatırlatan bu ayeti sabah okumalarında kalbe yerleştirmek istiyorum."
        ),
        shortExplanation: QuranShortExplanationPayload(
            text: "A concise declaration of tawhid.",
            source: .zikrimShortExplanation,
            language: .en,
            attribution: QuranTafsirSource.zikrimShortExplanation.attribution,
            didUseFallbackLanguage: false
        ),
        wordByWord: [
            QuranWordByWordEntry(surahNumber: 112, ayahNumber: 1, wordIndex: 1, arabic: "قُلْ", translation: "Say"),
            QuranWordByWordEntry(surahNumber: 112, ayahNumber: 1, wordIndex: 2, arabic: "هُوَ", translation: "He"),
            QuranWordByWordEntry(surahNumber: 112, ayahNumber: 1, wordIndex: 3, arabic: "ٱللَّهُ", translation: "Allah"),
            QuranWordByWordEntry(surahNumber: 112, ayahNumber: 1, wordIndex: 4, arabic: "أَحَدٌ", translation: "One")
        ]
    )

    QuranVerseBlockView(
        item: sample,
        style: QuranReaderAppearanceEngine.style(
            for: .sepia,
            theme: AppTheme.resolved(themeID: .amberMihrab, appearanceMode: .light, systemColorScheme: .light)
        ),
        displayMode: .arabicWithTransliterationAndTranslation,
        preferences: previewPreferences,
        isCurrentAyah: false,
        activeWordRange: nil,
        isPlaying: false,
        isLoading: false,
        isMushafFocused: false,
        onPlay: {},
        onBookmark: {},
        onShare: {},
        onCopy: {},
        onNote: {},
        onOpenTafsir: {},
        onAppear: {}
    )
    .padding()
}
