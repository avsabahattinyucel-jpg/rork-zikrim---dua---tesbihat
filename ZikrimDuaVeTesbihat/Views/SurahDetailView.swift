import SwiftUI

struct SurahDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var ayahAudioPlayerService: AyahAudioPlayerService

    let route: QuranReadingRoute
    let quranService: QuranService
    let storage: StorageService
    let readingSystemStore: QuranReadingSystemStore

    @StateObject private var readerViewModel: QuranReaderViewModel
    @State private var selectedVerseItem: QuranReaderVerseItem?
    @State private var isAudioScreenPresented = false
    @State private var playbackContextRoute: QuranReadingRoute?

    init(
        route: QuranReadingRoute,
        quranService: QuranService,
        storage: StorageService,
        readingSystemStore: QuranReadingSystemStore
    ) {
        self.route = route
        self.quranService = quranService
        self.storage = storage
        self.readingSystemStore = readingSystemStore

        let preferencesStore = QuranReaderPreferencesStore()
        _readerViewModel = StateObject(wrappedValue: QuranReaderViewModel(
            surahID: route.surahId,
            preferencesStore: preferencesStore,
            textRepository: ZikrimQuranTextRepository(),
            translationRepository: ZikrimQuranTranslationRepository(),
            transliterationRepository: ZikrimQuranTransliterationRepository(),
            wordByWordRepository: ZikrimQuranWordByWordRepository(),
            bookmarksRepository: ZikrimQuranBookmarksRepository(quranService: quranService, storage: storage),
            verseNotesRepository: ZikrimQuranVerseNotesRepository(),
            progressRepository: ZikrimQuranProgressRepository(quranService: quranService),
            tafsirProvider: BundleQuranTafsirProvider(fallbackLanguage: preferencesStore.preferences.defaultTafsirFallbackLanguage),
            sessionStore: readingSystemStore
        ))
    }

    private var theme: ActiveTheme { themeManager.current }
    private var surah: QuranSurah? {
        QuranSurahData.surahs.first(where: { $0.id == route.surahId })
    }

    var body: some View {
        QuranReaderScreen(
            viewModel: readerViewModel,
            scrollTarget: route.ayahNumber,
            onShare: { selectedVerseItem = $0 },
            onOpenCurrentPlaybackContext: openCurrentPlaybackContext
        )
        .appScreenBackground(theme)
        .navigationTitle(surah?.localizedTurkishName ?? QuranReaderStrings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.navBarBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        .task {
            readerViewModel.bindAudioIfNeeded(to: ayahAudioPlayerService)
            readingSystemStore.bindAudioService(ayahAudioPlayerService)
            await handleInitialRoute()
        }
        .navigationDestination(isPresented: $isAudioScreenPresented) {
            QuranAudioExperienceScreen(audioController: readerViewModel.audioController) {
                openCurrentPlaybackContext()
            }
        }
        .navigationDestination(item: $playbackContextRoute) { nextRoute in
            SurahDetailView(
                route: nextRoute,
                quranService: quranService,
                storage: storage,
                readingSystemStore: readingSystemStore
            )
        }
        .sheet(item: $selectedVerseItem) { item in
            VerseShareView(
                verse: item.verse,
                translationText: item.translation,
                surahName: surah?.localizedTurkishName ?? "",
                surahArabicName: surah?.arabicName ?? "",
                translationSourceName: readerViewModel.translationSourceName
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAudioScreenPresented = true
                } label: {
                    Image(systemName: "waveform")
                }
                .accessibilityLabel(QuranReaderStrings.openAudio)
            }
        }
    }

    private func handleInitialRoute() async {
        if let preferredAppearance = route.preferredAppearance,
           readerViewModel.preferences.appearance != preferredAppearance {
            readerViewModel.updateAppearance(preferredAppearance)
        }

        if let reciterID = route.preferredReciterID,
           let reciter = ReciterRegistry.reciter(withID: reciterID),
           readerViewModel.audioController.selectedReciter.id != reciter.id {
            readerViewModel.audioController.switchReciter(reciter)
        }

        guard route.shouldResumePlayback else { return }

        if let activeSurah = ayahAudioPlayerService.nowPlayingSurah?.id,
           activeSurah == route.surahId,
           ayahAudioPlayerService.nowPlayingAyah == route.ayahNumber,
           ayahAudioPlayerService.playbackState.isActive {
            ayahAudioPlayerService.resume()
            return
        }

        let ayahNumber = route.ayahNumber ?? readingSystemStore.currentPlaybackSession?.ayahId ?? 1
        readerViewModel.audioController.playSurahContinuously(surah: route.surahId, ayah: ayahNumber)

        if route.shouldOpenListeningControls {
            isAudioScreenPresented = true
        }
    }

    private func openCurrentPlaybackContext() {
        let playbackRoute = readingSystemStore.continueListeningRoute(fallbackSurahId: route.surahId)

        if playbackRoute.surahId == route.surahId {
            return
        }

        playbackContextRoute = playbackRoute
    }
}
