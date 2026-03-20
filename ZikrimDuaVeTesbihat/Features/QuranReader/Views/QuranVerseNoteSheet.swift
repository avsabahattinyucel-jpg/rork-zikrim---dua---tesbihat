import SwiftUI

struct QuranVerseNoteSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEditorFocused: Bool

    let editor: QuranReaderViewModel.PresentedVerseNoteEditor
    let style: QuranReaderCanvasStyle
    let onSave: (String) -> Void
    let onDelete: () -> Void

    @State private var noteDraft: String

    init(
        editor: QuranReaderViewModel.PresentedVerseNoteEditor,
        style: QuranReaderCanvasStyle,
        onSave: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.editor = editor
        self.style = style
        self.onSave = onSave
        self.onDelete = onDelete
        _noteDraft = State(initialValue: editor.existingNote?.noteText ?? "")
    }

    private var theme: ActiveTheme { themeManager.current }

    private var trimmedDraft: String {
        noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasExistingNote: Bool {
        editor.existingNote != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    reflectionCard
                    editorCard
                    actionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(sheetBackdrop.ignoresSafeArea())
            .navigationTitle(QuranReaderStrings.noteSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.navBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(QuranReaderStrings.close) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(QuranReaderStrings.noteSave) {
                        onSave(trimmedDraft)
                    }
                    .disabled(trimmedDraft.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if !hasExistingNote {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isEditorFocused = true
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(style.chipBackground.opacity(0.96))
                        .frame(width: 42, height: 42)

                    Image(systemName: "note.text")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(style.chipForeground)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(editor.surahName) • \(L10n.format(.quranAudioVerseFormat, Int64(editor.verse.verseNumber)))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(style.translationText)

                    Text(QuranReaderStrings.noteSheetSubtitle)
                        .font(.footnote)
                        .foregroundStyle(style.transliterationText)
                }

                Spacer(minLength: 0)
            }

            Text(editor.arabicText)
                .font(.system(size: 28, weight: .regular, design: .default))
                .foregroundStyle(style.arabicText)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

            Text(editor.translation)
                .font(.subheadline)
                .foregroundStyle(style.translationText)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            style.cardBackground,
                            style.secondaryBackground.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(style.border.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: style.shadowColor.opacity(0.42), radius: 16, y: 8)
    }

    private var reflectionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(style.chipForeground)
                .frame(width: 30, height: 30)
                .background(style.chipBackground.opacity(0.92), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(QuranReaderStrings.personalNoteTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.chipForeground)

                Text(QuranReaderStrings.noteEmptyState)
                    .font(.footnote)
                    .foregroundStyle(style.translationText)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(style.audioSurface.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(style.audioBorder.opacity(0.95), lineWidth: 1)
        )
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(QuranReaderStrings.personalNoteTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.translationText)

                Spacer()

                if let existingNote = editor.existingNote {
                    Text(existingNote.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(style.transliterationText)
                }
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(style.secondaryBackground.opacity(0.96))

                if trimmedDraft.isEmpty {
                    Text(QuranReaderStrings.notePlaceholder)
                        .font(.body)
                        .foregroundStyle(style.transliterationText.opacity(0.9))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $noteDraft)
                    .focused($isEditorFocused)
                    .font(.body)
                    .foregroundStyle(style.translationText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 220)
                    .background(Color.clear)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isEditorFocused ? style.chipForeground.opacity(0.55) : style.border.opacity(0.72),
                        lineWidth: 1
                    )
            )
        }
        .padding(18)
        .background(style.cardBackground.opacity(0.96), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(style.border.opacity(0.82), lineWidth: 1)
        )
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button {
                onSave(trimmedDraft)
            } label: {
                Text(QuranReaderStrings.noteSave)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.backgroundPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                style.chipForeground.opacity(0.92),
                                style.chipForeground.opacity(0.76)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(trimmedDraft.isEmpty)
            .opacity(trimmedDraft.isEmpty ? 0.45 : 1)

            if hasExistingNote {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text(QuranReaderStrings.noteDelete)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.red.opacity(theme.isDarkMode ? 0.92 : 0.82))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(style.secondaryBackground.opacity(0.94))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(style.cardBackground.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(style.border.opacity(0.8), lineWidth: 1)
        )
    }

    private var sheetBackdrop: some View {
        ZStack {
            style.background

            LinearGradient(
                colors: [
                    style.chipBackground.opacity(0.26),
                    .clear,
                    style.badgeBackground.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    style.chipForeground.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 16,
                endRadius: 220
            )
        }
    }
}
