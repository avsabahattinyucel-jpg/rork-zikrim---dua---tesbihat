import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class QuranReaderViewModel: ObservableObject {
    struct PresentedTafsir: Identifiable {
        let id: String
        let reference: AyahReference
        let payload: QuranTafsirPayload?
        let isLoading: Bool
    }

    struct PresentedVerseNoteEditor: Identifiable {
        let verse: QuranVerse
        let surahName: String
        let arabicText: String
        let translation: String
        let existingNote: QuranVerseNote?

        var id: String { verse.id }
    }

    @Published private(set) var surah: QuranSurah?
    @Published private(set) var verseItems: [QuranReaderVerseItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var translationSourceName: String = ""
    @Published private(set) var preferences: QuranReaderPreferences
    @Published var isSettingsPresented: Bool = false
    @Published var isMushafTranslationRevealed: Bool = false
    @Published var bannerMessage: String?
    @Published var presentedTafsir: PresentedTafsir?
    @Published var presentedVerseNoteEditor: PresentedVerseNoteEditor?

    let surahID: Int
    let audioController: QuranAudioReaderViewModel

    private let textRepository: any QuranTextRepository
    private let translationRepository: any QuranTranslationRepository
    private let transliterationRepository: any QuranTransliterationRepository
    private let wordByWordRepository: any QuranWordByWordRepository
    private let bookmarksRepository: any QuranBookmarksRepository
    private let verseNotesRepository: any QuranVerseNotesRepository
    private let progressRepository: any QuranReaderProgressRepository
    private let tafsirProvider: any QuranTafsirProviding
    private let preferencesStore: QuranReaderPreferencesStore
    private let featureGating: any QuranReaderFeatureGating
    private let sessionStore: QuranReadingSystemStore?
    private var lastVisibleAyahNumber: Int?

    init(
        surahID: Int,
        preferencesStore: QuranReaderPreferencesStore? = nil,
        textRepository: any QuranTextRepository,
        translationRepository: any QuranTranslationRepository,
        transliterationRepository: any QuranTransliterationRepository,
        wordByWordRepository: any QuranWordByWordRepository,
        bookmarksRepository: any QuranBookmarksRepository,
        verseNotesRepository: any QuranVerseNotesRepository,
        progressRepository: any QuranReaderProgressRepository,
        tafsirProvider: (any QuranTafsirProviding)? = nil,
        featureGating: (any QuranReaderFeatureGating)? = nil,
        audioController: QuranAudioReaderViewModel? = nil,
        sessionStore: QuranReadingSystemStore? = nil
    ) {
        self.surahID = surahID
        let resolvedPreferencesStore = preferencesStore ?? QuranReaderPreferencesStore()
        self.preferencesStore = resolvedPreferencesStore
        self.preferences = resolvedPreferencesStore.preferences
        self.textRepository = textRepository
        self.translationRepository = translationRepository
        self.transliterationRepository = transliterationRepository
        self.wordByWordRepository = wordByWordRepository
        self.bookmarksRepository = bookmarksRepository
        self.verseNotesRepository = verseNotesRepository
        self.progressRepository = progressRepository
        self.tafsirProvider = tafsirProvider ?? BundleQuranTafsirProvider()
        self.featureGating = featureGating ?? OpenQuranReaderFeatureGating()
        self.audioController = audioController ?? QuranAudioReaderViewModel(surahID: surahID)
        self.sessionStore = sessionStore
    }

    var language: AppLanguage {
        .current
    }

    var preferredTafsirSource: QuranTafsirSource {
        QuranTafsirSource.allCases.first(where: { $0.id == preferences.preferredTafsirSourceID }) ?? .zikrimShortExplanation
    }

    var preferredFullTafsirSource: QuranTafsirSource {
        preferredTafsirSource.id == QuranTafsirSource.zikrimShortExplanation.id
        ? .remoteMultiLanguageTafsir
        : preferredTafsirSource
    }

    var effectiveDisplayMode: QuranDisplayMode {
        if preferences.layoutMode == .mushafFocused,
           preferences.displayMode.showsTranslation,
           !isMushafTranslationRevealed,
           preferences.displayMode != .translationOnly {
            return .arabicOnly
        }
        return preferences.displayMode
    }

    var isTranslationVisible: Bool {
        effectiveDisplayMode.showsTranslation
    }

    var pageModeItems: [ReaderPageMode] {
        let chunkSize = preferences.compactMode ? 10 : 7
        return verseItems.chunked(into: chunkSize).enumerated().map {
            ReaderPageMode(index: $0.offset + 1, verses: $0.element)
        }
    }

    var verseModeItems: [ReaderVerseMode] {
        verseItems.map(ReaderVerseMode.init(item:))
    }

    var isMushafMode: Bool {
        preferences.layoutMode == .mushafFocused
    }

    var readingMode: QuranReadingMode {
        if preferences.layoutMode == .mushafFocused || preferences.displayMode == .arabicOnly {
            return .mushaf
        }

        if preferences.showWordByWord || preferences.enableInlineTafsirPreview || preferences.showShortExplanationChip {
            return .study
        }

        return .reading
    }

    func bindAudioIfNeeded(to service: AyahAudioPlayerService) {
        audioController.bindIfNeeded(to: service)
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            async let surahTask = textRepository.surah(withID: surahID)
            async let versesTask = textRepository.verses(forSurahID: surahID)
            async let translationsTask = translationRepository.translations(forSurahID: surahID, language: language)
            async let transliterationsTask = transliterationRepository.transliterations(forSurahID: surahID, language: language)
            async let wordByWordTask = wordByWordRepository.wordByWord(forSurahID: surahID, language: language)
            async let mushafArabicTask = QuranLocalDataStore.shared.arabicScriptText(
                forSurahId: surahID,
                script: preferences.mushafScriptOption
            )

            let resolvedSurah = try await surahTask
            let verses = try await versesTask
            let translations = try await translationsTask
            let transliterations = try await transliterationsTask
            let wordByWord = try await wordByWordTask
            let mushafArabic = await mushafArabicTask

            surah = resolvedSurah
            translationSourceName = translationRepository.sourceDisplayName(for: language)

            let translationLookup = Dictionary(uniqueKeysWithValues: translations.map {
                (AyahReference(surahNumber: $0.surahId, ayahNumber: $0.verseNumber), $0.text)
            })

            verseItems = verses.map { verse in
                let reference = AyahReference(surahNumber: verse.surahId, ayahNumber: verse.verseNumber)
                return QuranReaderVerseItem(
                    verse: verse,
                    translation: translationLookup[reference] ?? verse.localizedTranslation,
                    transliteration: transliterations[reference],
                    mushafArabicText: self.mushafArabicText(
                        for: reference,
                        defaultArabicText: verse.arabicText,
                        map: mushafArabic
                    ),
                    isBookmarked: bookmarksRepository.isBookmarked(verse),
                    verseNote: verseNotesRepository.note(for: verse),
                    shortExplanation: nil,
                    wordByWord: wordByWord[reference]
                )
            }

            lastVisibleAyahNumber = initialScrollTarget(explicitVerseNumber: nil)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func initialScrollTarget(explicitVerseNumber: Int?) -> Int? {
        if let explicitVerseNumber, explicitVerseNumber > 0 {
            return explicitVerseNumber
        }

        guard preferences.rememberLastPosition else { return nil }
        return progressRepository.loadLastAnchor(forSurahID: surahID)?.ayahNumber
    }

    func markVisible(_ verseItem: QuranReaderVerseItem) {
        guard preferences.rememberLastPosition else { return }
        lastVisibleAyahNumber = verseItem.verse.verseNumber
        let anchor = QuranReaderScrollAnchor(
            surahID: verseItem.verse.surahId,
            ayahNumber: verseItem.verse.verseNumber,
            layoutMode: preferences.layoutMode
        )
        progressRepository.save(anchor: anchor, surah: surah)
        syncReadingSession()
    }

    func toggleBookmark(for verseItem: QuranReaderVerseItem) {
        bookmarksRepository.toggleBookmark(for: verseItem.verse, surah: surah)
        if let index = verseItems.firstIndex(where: { $0.id == verseItem.id }) {
            var updated = verseItems[index]
            updated = QuranReaderVerseItem(
                verse: updated.verse,
                translation: updated.translation,
                transliteration: updated.transliteration,
                mushafArabicText: updated.mushafArabicText,
                isBookmarked: !updated.isBookmarked,
                verseNote: updated.verseNote,
                shortExplanation: updated.shortExplanation,
                wordByWord: updated.wordByWord
            )
            verseItems[index] = updated
        }
        sendSelectionFeedback()
    }

    func playAyah(_ verseItem: QuranReaderVerseItem) {
        lastVisibleAyahNumber = verseItem.verse.verseNumber
        syncReadingSession()
        audioController.playAyah(surah: verseItem.verse.surahId, ayah: verseItem.verse.verseNumber)
    }

    func translationVisibilityBinding() -> Binding<Bool> {
        Binding(
            get: { self.preferences.displayMode.showsTranslation },
            set: { self.setTranslationVisible($0) }
        )
    }

    func transliterationVisibilityBinding() -> Binding<Bool> {
        Binding(
            get: { self.preferences.displayMode.showsTransliteration },
            set: { self.setTransliterationVisible($0) }
        )
    }

    func updateAppearance(_ appearance: QuranReaderAppearance) {
        applyAppearancePreset(appearance)
        sendSelectionFeedback()
    }

    func updateFontOption(_ option: QuranFontOption) {
        guard !option.isPremiumCandidate || featureGating.isEnabled(.arabicFont(option)) else { return }
        updatePreferences {
            $0.fontOption = option
        }
        sendSelectionFeedback()
    }

    func updateDisplayMode(_ mode: QuranDisplayMode) {
        updatePreferences {
            $0.displayMode = mode
        }
        if mode != .translationOnly {
            isMushafTranslationRevealed = false
        }
        sendSelectionFeedback()
    }

    func updateLayoutMode(_ mode: QuranReaderLayoutMode) {
        guard mode != .mushafFocused || featureGating.isEnabled(.layout(mode)) else { return }
        updatePreferences {
            $0.layoutMode = mode
        }
        if mode != .mushafFocused {
            isMushafTranslationRevealed = false
        }
        sendSelectionFeedback()
    }

    func applyReadingMode(_ mode: QuranReadingMode) {
        updatePreferences {
            switch mode {
            case .mushaf:
                $0.layoutMode = .mushafFocused
                $0.displayMode = .arabicOnly
                $0.showWordByWord = false
                $0.enableInlineTafsirPreview = false
                $0.showShortExplanationChip = false
            case .reading:
                $0.layoutMode = .verseByVerse
                $0.displayMode = .arabicWithTranslation
                $0.showWordByWord = false
                $0.enableInlineTafsirPreview = false
                $0.showShortExplanationChip = false
            case .study:
                $0.layoutMode = .verseByVerse
                $0.displayMode = .arabicWithTransliterationAndTranslation
                $0.showWordByWord = true
                $0.enableInlineTafsirPreview = true
                $0.showShortExplanationChip = true
            }
        }
        isMushafTranslationRevealed = false
        sendSelectionFeedback()
    }

    func cycleReadingMode() {
        let allModes = QuranReadingMode.allCases
        guard let currentIndex = allModes.firstIndex(of: readingMode) else {
            applyReadingMode(.reading)
            return
        }

        let nextIndex = allModes.index(after: currentIndex)
        applyReadingMode(allModes[nextIndex == allModes.endIndex ? allModes.startIndex : nextIndex])
    }

    func updateMushafScriptOption(_ option: QuranArabicScriptOption) {
        updatePreferences {
            $0.mushafScriptOption = option
        }

        Task { [weak self] in
            await self?.refreshMushafArabicText()
        }
        sendSelectionFeedback()
    }

    func setTranslationVisible(_ isVisible: Bool) {
        updateDisplayMode(preferences.displayMode.updatingTranslationVisibility(isVisible))
    }

    func setTransliterationVisible(_ isVisible: Bool) {
        updateDisplayMode(preferences.displayMode.updatingTransliterationVisibility(isVisible))
    }

    func revealTranslationInMushafMode() {
        isMushafTranslationRevealed.toggle()
    }

    func exitMushafModeToStandardReading() {
        updatePreferences {
            $0.layoutMode = .verseByVerse
            $0.displayMode = .arabicWithTranslation
            $0.appearance = .standardDark
            $0.showWordByWord = false
            $0.enableInlineTafsirPreview = false
            $0.showShortExplanationChip = false
        }
        isMushafTranslationRevealed = false
        sendSelectionFeedback()
    }

    func updateArabicFontSize(_ value: Double) {
        updatePreferences { $0.arabicFontSize = min(max(value, 24), 42) }
    }

    func updateTranslationFontSize(_ value: Double) {
        updatePreferences { $0.translationFontSize = min(max(value, 13), 24) }
    }

    func updateTransliterationFontSize(_ value: Double) {
        updatePreferences { $0.transliterationFontSize = min(max(value, 12), 22) }
    }

    func nudgeArabicFontSize(by delta: Double) {
        updateArabicFontSize(preferences.arabicFontSize + delta)
    }

    func cycleAppearance() {
        let appearances = QuranReaderAppearance.allCases
        guard let currentIndex = appearances.firstIndex(of: preferences.appearance) else {
            updateAppearance(.standardDark)
            return
        }

        let nextIndex = appearances.index(after: currentIndex)
        updateAppearance(appearances[nextIndex == appearances.endIndex ? appearances.startIndex : nextIndex])
    }

    func updateArabicLineSpacing(_ value: Double) {
        updatePreferences { $0.arabicLineSpacing = value }
    }

    func updateTranslationLineSpacing(_ value: Double) {
        updatePreferences { $0.translationLineSpacing = value }
    }

    func updateKeepScreenAwake(_ value: Bool) {
        updatePreferences { $0.keepScreenAwake = value }
    }

    func updateAutoHideChrome(_ value: Bool) {
        updatePreferences { $0.autoHideChromeInMushafFocusedMode = value }
    }

    func updateRememberPosition(_ value: Bool) {
        updatePreferences { $0.rememberLastPosition = value }
    }

    func updateShowAyahNumbers(_ value: Bool) {
        updatePreferences { $0.showAyahNumbers = value }
    }

    func updateCompactMode(_ value: Bool) {
        updatePreferences { $0.compactMode = value }
    }

    func updatePreferredTafsirSource(_ source: QuranTafsirSource) {
        guard !source.isPremiumCandidate || featureGating.isEnabled(.tafsirSource(source.id)) else { return }
        updatePreferences { $0.preferredTafsirSourceID = source.id }
    }

    func updateShowShortExplanationChip(_ value: Bool) {
        updatePreferences { $0.showShortExplanationChip = value }
    }

    func updateInlineTafsirPreview(_ value: Bool) {
        updatePreferences { $0.enableInlineTafsirPreview = value }
    }

    func updateShowWordByWord(_ value: Bool) {
        updatePreferences { $0.showWordByWord = value }
    }

    func updateFallbackLanguage(_ language: AppLanguage) {
        updatePreferences { $0.defaultTafsirFallbackLanguage = language }
    }

    func copyVerse(_ verseItem: QuranReaderVerseItem) {
        let pieces = [
            verseItem.verse.arabicText,
            verseItem.translation,
            verseItem.transliteration
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        UIPasteboard.general.string = pieces.joined(separator: "\n\n")
        bannerMessage = QuranReaderStrings.copied
    }

    func noteTapped(for verseItem: QuranReaderVerseItem) {
        let surahName = surah?.localizedTurkishName ?? QuranReaderStrings.surahFallbackTitle
        presentedVerseNoteEditor = PresentedVerseNoteEditor(
            verse: verseItem.verse,
            surahName: surahName,
            arabicText: verseItem.mushafArabicText ?? verseItem.verse.arabicText,
            translation: verseItem.translation,
            existingNote: verseItem.verseNote
        )
    }

    func dismissVerseNoteEditor() {
        presentedVerseNoteEditor = nil
    }

    func saveVerseNote(_ noteText: String, for editor: PresentedVerseNoteEditor) {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        verseNotesRepository.save(noteText: trimmed, for: editor.verse, surahName: editor.surahName)
        let savedNote = verseNotesRepository.note(for: editor.verse)
        updateVerseNote(savedNote, for: editor.verse)
        presentedVerseNoteEditor = nil
        bannerMessage = QuranReaderStrings.noteSaved
        sendSelectionFeedback()
    }

    func deleteVerseNote(for editor: PresentedVerseNoteEditor) {
        verseNotesRepository.deleteNote(for: editor.verse)
        updateVerseNote(nil, for: editor.verse)
        presentedVerseNoteEditor = nil
        bannerMessage = QuranReaderStrings.noteDeleted
        sendSelectionFeedback()
    }

    func presentTafsir(for verseItem: QuranReaderVerseItem) {
        let source = preferredFullTafsirSource
        presentedTafsir = PresentedTafsir(
            id: verseItem.id,
            reference: verseItem.reference,
            payload: nil,
            isLoading: true
        )

        Task { [weak self] in
            guard let self else { return }
            let payload = try? await self.tafsirProvider.tafsir(
                for: verseItem.reference,
                language: self.language,
                source: source
            )

            await MainActor.run {
                self.presentedTafsir = PresentedTafsir(
                    id: verseItem.id,
                    reference: verseItem.reference,
                    payload: payload,
                    isLoading: false
                )
            }
        }
    }

    func loadShortExplanationIfNeeded(for verseItem: QuranReaderVerseItem) {
        guard preferences.showShortExplanationChip || preferences.enableInlineTafsirPreview else { return }
        guard verseItem.shortExplanation == nil else { return }

        Task { [weak self] in
            guard let self else { return }
            let payload = try? await self.tafsirProvider.shortExplanation(
                for: verseItem.reference,
                language: self.language,
                source: self.preferredTafsirSource
            )
            guard let payload else { return }

            await MainActor.run {
                guard let index = self.verseItems.firstIndex(where: { $0.id == verseItem.id }) else { return }
                let existing = self.verseItems[index]
                self.verseItems[index] = QuranReaderVerseItem(
                    verse: existing.verse,
                    translation: existing.translation,
                    transliteration: existing.transliteration,
                    mushafArabicText: existing.mushafArabicText,
                    isBookmarked: existing.isBookmarked,
                    verseNote: existing.verseNote,
                    shortExplanation: payload,
                    wordByWord: existing.wordByWord
                )
            }
        }
    }

    private func updatePreferences(_ mutate: (inout QuranReaderPreferences) -> Void) {
        preferencesStore.update(mutate)
        preferences = preferencesStore.preferences
        syncReadingSession()
    }

    private func refreshMushafArabicText() async {
        let map = await QuranLocalDataStore.shared.arabicScriptText(
            forSurahId: surahID,
            script: preferences.mushafScriptOption
        )

        verseItems = verseItems.map { item in
            QuranReaderVerseItem(
                verse: item.verse,
                translation: item.translation,
                transliteration: item.transliteration,
                mushafArabicText: mushafArabicText(
                    for: item.reference,
                    defaultArabicText: item.verse.arabicText,
                    map: map
                ),
                isBookmarked: item.isBookmarked,
                verseNote: item.verseNote,
                shortExplanation: item.shortExplanation,
                wordByWord: item.wordByWord
            )
        }
    }

    private func updateVerseNote(_ note: QuranVerseNote?, for verse: QuranVerse) {
        guard let index = verseItems.firstIndex(where: { $0.verse.id == verse.id }) else { return }
        let existing = verseItems[index]
        verseItems[index] = QuranReaderVerseItem(
            verse: existing.verse,
            translation: existing.translation,
            transliteration: existing.transliteration,
            mushafArabicText: existing.mushafArabicText,
            isBookmarked: existing.isBookmarked,
            verseNote: note,
            shortExplanation: existing.shortExplanation,
            wordByWord: existing.wordByWord
        )
    }

    private func mushafArabicText(
        for reference: AyahReference,
        defaultArabicText: String,
        map: [AyahReference: String]
    ) -> String? {
        guard preferences.mushafScriptOption != .standardUthmani,
              let text = map[reference],
              text != defaultArabicText else {
            return nil
        }
        return text
    }

    private func sendSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    private func applyAppearancePreset(_ appearance: QuranReaderAppearance) {
        updatePreferences {
            $0.appearance = appearance

            switch appearance {
            case .standardDark:
                $0.layoutMode = .verseByVerse
                $0.displayMode = .arabicWithTranslation
                $0.arabicFontSize = 31
                $0.translationFontSize = 17
                $0.translationLineSpacing = 0.38
                $0.arabicLineSpacing = 0.46
            case .mushaf:
                $0.layoutMode = .mushafFocused
                $0.displayMode = .arabicOnly
                $0.arabicFontSize = 34
                $0.translationFontSize = 16
                $0.translationLineSpacing = 0.32
                $0.arabicLineSpacing = 0.52
                $0.compactMode = false
            case .sepia:
                $0.layoutMode = .verseByVerse
                $0.displayMode = .arabicWithTranslation
                $0.arabicFontSize = 31
                $0.translationFontSize = 18
                $0.translationLineSpacing = 0.44
                $0.arabicLineSpacing = 0.48
            case .nightFocus:
                $0.layoutMode = .verseByVerse
                $0.displayMode = .arabicWithTranslation
                $0.arabicFontSize = 30
                $0.translationFontSize = 17
                $0.translationLineSpacing = 0.40
                $0.arabicLineSpacing = 0.46
            case .translationFocus:
                $0.layoutMode = .verseByVerse
                $0.displayMode = .arabicWithTranslation
                $0.arabicFontSize = 28
                $0.translationFontSize = 19
                $0.translationLineSpacing = 0.48
                $0.arabicLineSpacing = 0.42
                $0.showWordByWord = false
                $0.enableInlineTafsirPreview = false
            }
        }
    }

    private func syncReadingSession() {
        sessionStore?.updateReadingPreferences(
            surahId: surahID,
            ayahId: lastVisibleAyahNumber,
            preferences: preferences,
            selectedTafsirSourceID: preferredTafsirSource.id,
            reciterID: audioController.selectedReciter.id
        )
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
