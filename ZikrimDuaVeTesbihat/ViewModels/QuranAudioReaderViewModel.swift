import Combine
import Foundation

@MainActor
final class QuranAudioReaderViewModel: ObservableObject {
    @Published private(set) var selectedReciter: Reciter
    @Published private(set) var availableReciters: [Reciter]
    @Published private(set) var playbackState: AudioPlaybackState
    @Published private(set) var nowPlayingSurah: QuranSurah?
    @Published private(set) var nowPlayingAyah: Int?
    @Published private(set) var currentProgress: Double
    @Published private(set) var activeWordRange: QuranActiveWordRange?
    @Published private(set) var errorState: PlayerErrorState?
    @Published private(set) var isAutoAdvanceEnabled: Bool
    @Published private(set) var isBackgroundListeningEnabled: Bool
    @Published private(set) var sleepTimerOption: QuranSleepTimerOption
    @Published private(set) var isPremiumUser: Bool
    @Published private(set) var resumeState: QuranAudioResumeState?
    @Published private(set) var repeatMode: QuranPlaybackRepeatMode

    let surahID: Int

    private weak var playerService: AyahAudioPlayerService?
    private var cancellables: Set<AnyCancellable> = []

    init(surahID: Int, playerService: AyahAudioPlayerService? = nil) {
        self.surahID = surahID
        self.selectedReciter = playerService?.selectedReciter ?? ReciterRegistry.defaultReciter
        self.availableReciters = playerService?.availableReciters ?? ReciterRegistry.all
        self.playbackState = playerService?.playbackState ?? .idle
        self.nowPlayingSurah = playerService?.nowPlayingSurah
        self.nowPlayingAyah = playerService?.nowPlayingAyah
        self.currentProgress = playerService?.currentProgress ?? 0
        self.activeWordRange = playerService?.activeWordRange
        self.errorState = playerService?.errorState
        self.isAutoAdvanceEnabled = playerService?.isAutoAdvanceEnabled ?? false
        self.isBackgroundListeningEnabled = playerService?.isBackgroundListeningEnabled ?? false
        self.sleepTimerOption = playerService?.sleepTimerOption ?? .off
        self.isPremiumUser = playerService?.isPremiumUser ?? false
        self.resumeState = playerService?.resumeState
        self.repeatMode = playerService?.repeatMode ?? .off

        if let playerService {
            bindIfNeeded(to: playerService)
        }
    }

    var browsingSurah: QuranSurah? {
        QuranSurahData.surahs.first(where: { $0.id == surahID })
    }

    var shouldShowMiniPlayer: Bool {
        nowPlayingAyah != nil
    }

    var currentAyahForSurah: Int? {
        guard nowPlayingSurah?.id == surahID else { return nil }
        return nowPlayingAyah
    }

    var canSkipToNextAyah: Bool {
        playerService?.canSkipToNext ?? false
    }

    var canSkipToPreviousAyah: Bool {
        playerService?.canSkipToPrevious ?? false
    }

    var nowPlayingTitle: String {
        if let surah = nowPlayingSurah, let ayah = nowPlayingAyah {
            return "\(surah.localizedTurkishName) • \(L10n.format(.quranAudioVerseFormat, Int64(ayah)))"
        }

        if let surah = browsingSurah {
            return surah.localizedTurkishName
        }

        return L10n.string(.kurAnIKerim)
    }

    var nowPlayingSubtitle: String {
        if nowPlayingSurah?.id == surahID, nowPlayingAyah != nil {
            return selectedReciter.localizedDisplayName
        }

        if nowPlayingSurah != nil {
            return "\(L10n.string(.quranAudioPlayingElsewhere)) • \(selectedReciter.localizedDisplayName)"
        }

        return L10n.string(.quranAudioThisSurahReady)
    }

    var capsuleEyebrow: String {
        nowPlayingSurah == nil ? L10n.string(.quranAudioContinueListening) : L10n.string(.quranAudioMiniPlayerNowPlaying)
    }

    var primaryPlaybackButtonIcon: String {
        if isCurrentSurahPlaying && playbackState.isActivelyPlaying {
            return "pause.fill"
        }

        return "play.fill"
    }

    var currentVerseLabel: String {
        guard let nowPlayingSurah, let nowPlayingAyah else { return "" }
        return "\(nowPlayingSurah.localizedTurkishName) • \(L10n.format(.quranAudioVerseFormat, Int64(nowPlayingAyah)))"
    }

    private var isCurrentSurahPlaying: Bool {
        nowPlayingSurah?.id == surahID
    }

    func bindIfNeeded(to playerService: AyahAudioPlayerService) {
        guard self.playerService !== playerService else { return }

        cancellables.removeAll()
        self.playerService = playerService

        availableReciters = playerService.availableReciters
        syncFromService(playerService)

        playerService.$selectedReciter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.selectedReciter = $0 }
            .store(in: &cancellables)

        playerService.$playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.playbackState = $0 }
            .store(in: &cancellables)

        playerService.$nowPlayingSurah
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.nowPlayingSurah = $0 }
            .store(in: &cancellables)

        playerService.$nowPlayingAyah
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.nowPlayingAyah = $0 }
            .store(in: &cancellables)

        playerService.$currentProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currentProgress = $0 }
            .store(in: &cancellables)

        playerService.$activeWordRange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.activeWordRange = $0 }
            .store(in: &cancellables)

        playerService.$errorState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.errorState = $0 }
            .store(in: &cancellables)

        playerService.$isAutoAdvanceEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAutoAdvanceEnabled = $0 }
            .store(in: &cancellables)

        playerService.$isBackgroundListeningEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isBackgroundListeningEnabled = $0 }
            .store(in: &cancellables)

        playerService.$sleepTimerOption
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sleepTimerOption = $0 }
            .store(in: &cancellables)

        playerService.$isPremiumUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isPremiumUser = $0 }
            .store(in: &cancellables)

        playerService.$resumeState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.resumeState = $0 }
            .store(in: &cancellables)

        playerService.$repeatMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.repeatMode = $0 }
            .store(in: &cancellables)
    }

    func prepare() {
        playerService?.prepareSurah(surahID)
    }

    func playAyah(surah: Int, ayah: Int) {
        playerService?.togglePlayback(surah: surah, ayah: ayah)
    }

    func playSurahContinuously(surah: Int, ayah: Int) {
        playerService?.playSurahContinuously(surah: surah, startingAt: ayah)
    }

    func pauseCurrent() {
        playerService?.pause()
    }

    func resumeCurrent() {
        playerService?.resume()
    }

    func stopPlayback() {
        playerService?.stop()
    }

    func skipToNextAyah() {
        playerService?.skipToNextAyah()
    }

    func skipToPreviousAyah() {
        playerService?.skipToPreviousAyah()
    }

    func switchReciter(_ reciter: Reciter) {
        playerService?.switchReciter(reciter)
    }

    func setAutoAdvanceEnabled(_ isEnabled: Bool) {
        playerService?.setAutoAdvanceEnabled(isEnabled)
    }

    func setBackgroundListeningEnabled(_ isEnabled: Bool) {
        playerService?.setBackgroundListeningEnabled(isEnabled)
    }

    func setSleepTimer(_ option: QuranSleepTimerOption) {
        playerService?.setSleepTimer(option)
    }

    func setRepeatMode(_ mode: QuranPlaybackRepeatMode) {
        playerService?.setRepeatMode(mode)
    }

    func requestPremiumFeature(_ feature: QuranAudioPremiumFeature) {
        playerService?.requestPremiumFeature(feature)
    }

    func isCurrentAyah(_ ayah: Int) -> Bool {
        nowPlayingSurah?.id == surahID && nowPlayingAyah == ayah
    }

    func isPlayingAyah(_ ayah: Int) -> Bool {
        isCurrentAyah(ayah) && playbackState == .playing
    }

    func isLoadingAyah(_ ayah: Int) -> Bool {
        isCurrentAyah(ayah) && playbackState.showsLoadingIndicator
    }

    func activeWordRange(for ayah: Int) -> ClosedRange<Int>? {
        guard let activeWordRange,
              activeWordRange.surahID == surahID,
              activeWordRange.ayahNumber == ayah else {
            return nil
        }

        return activeWordRange.startWordIndex...activeWordRange.endWordIndex
    }

    func isPausedAyah(_ ayah: Int) -> Bool {
        isCurrentAyah(ayah) && playbackState == .paused
    }

    func triggerPrimaryPlayback() {
        if isCurrentSurahPlaying {
            switch playbackState {
            case .playing, .buffering:
                pauseCurrent()
            case .paused, .idle, .stopped, .failed, .loading:
                resumeCurrent()
            }
            return
        }

        let initialAyah = (resumeState?.surahID == surahID ? resumeState?.ayahNumber : nil) ?? 1
        playSurahContinuously(surah: surahID, ayah: initialAyah)
    }

    private func syncFromService(_ playerService: AyahAudioPlayerService) {
        selectedReciter = playerService.selectedReciter
        playbackState = playerService.playbackState
        nowPlayingSurah = playerService.nowPlayingSurah
        nowPlayingAyah = playerService.nowPlayingAyah
        currentProgress = playerService.currentProgress
        activeWordRange = playerService.activeWordRange
        errorState = playerService.errorState
        isAutoAdvanceEnabled = playerService.isAutoAdvanceEnabled
        isBackgroundListeningEnabled = playerService.isBackgroundListeningEnabled
        sleepTimerOption = playerService.sleepTimerOption
        isPremiumUser = playerService.isPremiumUser
        resumeState = playerService.resumeState
        repeatMode = playerService.repeatMode
    }
}
