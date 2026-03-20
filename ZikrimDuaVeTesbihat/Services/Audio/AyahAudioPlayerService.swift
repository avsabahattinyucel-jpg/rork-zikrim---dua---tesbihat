import AVFoundation
import Combine
import MediaPlayer
import SwiftUI
import UIKit

@MainActor
final class AyahAudioPlayerService: ObservableObject {
    @Published private(set) var selectedReciter: Reciter
    @Published private(set) var currentRequest: AyahAudioRequest? = nil
    @Published private(set) var currentTrack: AyahAudioTrack? = nil
    @Published private(set) var playbackState: AudioPlaybackState
    @Published private(set) var currentProgress: Double
    @Published private(set) var currentElapsedTime: Double
    @Published private(set) var activeWordRange: QuranActiveWordRange? = nil
    @Published private(set) var errorState: PlayerErrorState? = nil
    @Published private(set) var queueMode: AudioQueueMode
    @Published private(set) var nowPlayingSurah: QuranSurah? = nil
    @Published private(set) var nowPlayingAyah: Int? = nil
    @Published private(set) var queue: [QuranAudioQueueItem]
    @Published private(set) var queueIndex: Int?
    @Published private(set) var isPremiumUser: Bool
    @Published private(set) var isBackgroundListeningEnabled: Bool
    @Published private(set) var sleepTimerOption: QuranSleepTimerOption
    @Published private(set) var resumeState: QuranAudioResumeState? = nil
    @Published private(set) var premiumPrompt: QuranAudioPremiumPrompt? = nil
    @Published private(set) var isAutoAdvanceEnabled: Bool
    @Published private(set) var repeatMode: QuranPlaybackRepeatMode

    let availableReciters: [Reciter]

    var currentReciter: Reciter {
        selectedReciter
    }

    var progress: Double {
        currentProgress
    }

    var canSkipToNext: Bool {
        guard let queueIndex else { return false }
        return queue.indices.contains(queueIndex + 1)
    }

    var canSkipToPrevious: Bool {
        if currentProgress > 0.05 {
            return true
        }

        guard let queueIndex else { return false }
        return queue.indices.contains(queueIndex - 1)
    }

    var effectiveBackgroundPlaybackEnabled: Bool {
        isPremiumUser && isBackgroundListeningEnabled
    }

    var displayState: QuranAudioResumeState? {
        if let nowPlayingSurah, let nowPlayingAyah {
            return QuranAudioResumeState(
                surahID: nowPlayingSurah.id,
                surahName: nowPlayingSurah.localizedTurkishName,
                ayahNumber: nowPlayingAyah,
                reciterID: selectedReciter.id,
                progress: currentProgress,
                continuesPlayback: continuesPlaybackForCurrentSession
            )
        }

        return resumeState
    }

    var miniPlayerState: QuranAudioResumeState? {
        guard playbackState != .idle, playbackState != .stopped, playbackState != .failed else {
            return nil
        }

        guard let nowPlayingSurah, let nowPlayingAyah else { return nil }

        return QuranAudioResumeState(
            surahID: nowPlayingSurah.id,
            surahName: nowPlayingSurah.localizedTurkishName,
            ayahNumber: nowPlayingAyah,
            reciterID: selectedReciter.id,
            progress: currentProgress,
            continuesPlayback: continuesPlaybackForCurrentSession
        )
    }

    private let cacheManager: AudioCacheManager
    private let offlineStorageManager: OfflineAudioStorageManager
    private let audioSessionManager: AudioSessionManager
    private let urlSession: URLSession
    private let defaults: UserDefaults
    private let player: AVPlayer
    private let providersByKind: [AudioProviderKind: any QuranAudioProvider]
    private let fallbackProviderKind: AudioProviderKind?

    private let selectedReciterKey = "quran_audio.selected_reciter_id"
    private let autoAdvanceKey = "quran_audio.auto_advance_enabled"
    private let backgroundListeningKey = "quran_audio.background_listening_enabled"
    private let resumeStateKey = "quran_audio.resume_state"
    private let repeatModeKey = "quran_audio.repeat_mode"

    private var playbackTask: Task<Void, Never>?
    private var prefetchTasks: [String: Task<Void, Never>] = [:]
    private var warmingChapterKeys: Set<String> = []
    private var preloadedChapterURLs: [String: [Int: URL]] = [:]
    private var shouldResumeAfterInterruption: Bool = false
    private var timeObserverToken: Any?
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var bufferObservation: NSKeyValueObservation?
    private var likelyToKeepUpObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var shouldSkipAudioSessionPreparation: Bool = false
    private var scenePhase: ScenePhase = .active
    private var pendingSeekProgress: Double?
    private var sleepTimerTask: Task<Void, Never>?
    private var progressPersistenceBucket: Int = -1
    private var continuesPlaybackForCurrentSession = false
    private var remoteCommandCenterConfigured = false
    private var currentTimingPayload: QuranAyahTimingPayload?
    private lazy var nowPlayingArtwork: MPMediaItemArtwork? = Self.makeNowPlayingArtwork()

    init(
        reciters: [Reciter] = ReciterRegistry.all,
        providers: [any QuranAudioProvider] = [
            BundledAyahAudioProvider(),
            QuranComAudioProvider(),
            EveryAyahAudioProvider()
        ],
        fallbackProviderKind: AudioProviderKind? = .everyAyah,
        cacheManager: AudioCacheManager = AudioCacheManager(),
        offlineStorageManager: OfflineAudioStorageManager = OfflineAudioStorageManager(),
        audioSessionManager: AudioSessionManager = AudioSessionManager(),
        urlSession: URLSession = .shared,
        defaults: UserDefaults = .standard,
        player: AVPlayer = AVPlayer(),
        isPremiumUser: Bool = false
    ) {
        self.availableReciters = reciters
        self.providersByKind = Dictionary(uniqueKeysWithValues: providers.map { ($0.kind, $0) })
        self.fallbackProviderKind = fallbackProviderKind
        self.cacheManager = cacheManager
        self.offlineStorageManager = offlineStorageManager
        self.audioSessionManager = audioSessionManager
        self.urlSession = urlSession
        self.defaults = defaults
        self.player = player
        self.isPremiumUser = isPremiumUser

        let storedReciterID = defaults.string(forKey: selectedReciterKey)
        let preferredReciter = reciters.first(where: { $0.id == storedReciterID }) ?? ReciterRegistry.defaultReciter
        let initialReciter = (!isPremiumUser && preferredReciter.isPremiumLocked)
            ? ReciterRegistry.defaultFreeReciter
            : preferredReciter
        let initialAutoAdvanceEnabled = isPremiumUser
            ? defaults.object(forKey: autoAdvanceKey) as? Bool ?? true
            : false
        let initialBackgroundListeningEnabled = isPremiumUser
            ? defaults.object(forKey: backgroundListeningKey) as? Bool ?? true
            : false

        self.selectedReciter = initialReciter
        self.isAutoAdvanceEnabled = initialAutoAdvanceEnabled
        self.isBackgroundListeningEnabled = initialBackgroundListeningEnabled
        self.queueMode = isPremiumUser && initialAutoAdvanceEnabled ? .autoAdvance : .singleAyah
        self.playbackState = .idle
        self.currentProgress = 0
        self.currentElapsedTime = 0
        self.queue = []
        self.queueIndex = nil
        self.sleepTimerOption = .off
        self.repeatMode = QuranPlaybackRepeatMode(
            rawValue: defaults.string(forKey: repeatModeKey) ?? ""
        ) ?? .off
        self.resumeState = Self.loadResumeState(from: defaults, key: resumeStateKey)

        player.automaticallyWaitsToMinimizeStalling = true

        configureRemoteCommandCenterIfNeeded()
        observePlayerLifetime()
        audioSessionManager.startObserving(
            onInterruption: { [weak self] type, shouldResume in
                self?.handleInterruption(type: type, shouldResume: shouldResume)
            },
            onRouteChange: { [weak self] reason in
                self?.handleRouteChange(reason)
            }
        )

        restoreDisplayStateIfAvailable()
    }
    func updatePremiumAccess(isPremium: Bool) {
        guard isPremiumUser != isPremium else { return }

        isPremiumUser = isPremium

        if !isPremium {
            if selectedReciter.isPremiumLocked {
                selectedReciter = ReciterRegistry.defaultFreeReciter
                defaults.set(selectedReciter.id, forKey: selectedReciterKey)
            }

            isAutoAdvanceEnabled = false
            isBackgroundListeningEnabled = false
            sleepTimerOption = .off
            repeatMode = .off
            sleepTimerTask?.cancel()
            sleepTimerTask = nil

            if let nowPlayingSurah, nowPlayingSurah.audioAccessLevel.requiresPremium {
                stop()
            }

            if scenePhase == .background && playbackState.isActivelyPlaying {
                enforceForegroundOnlyPlayback(showUpsell: false)
            }
        } else {
            isAutoAdvanceEnabled = defaults.object(forKey: autoAdvanceKey) as? Bool ?? true
            isBackgroundListeningEnabled = defaults.object(forKey: backgroundListeningKey) as? Bool ?? true
        }

        refreshQueueMode()
        rebuildQueueForCurrentContext()
        reconfigureAudioSessionIfNeeded()
        persistResumeState()
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        scenePhase = phase

        switch phase {
        case .active:
            reconfigureAudioSessionIfNeeded()
        case .background:
            if !effectiveBackgroundPlaybackEnabled {
                enforceForegroundOnlyPlayback(showUpsell: true)
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func dismissPremiumPrompt() {
        premiumPrompt = nil
    }

    func requestPremiumFeature(_ feature: QuranAudioPremiumFeature) {
        _ = canUsePremiumFeature(feature)
    }

    func prepareSurah(_ surah: Int) {
        guard let metadata = surahMetadata(for: surah) else { return }
        guard canAccess(surah: metadata, presentPrompt: false) else { return }
        warmChapterIndex(forSurah: surah, reciter: selectedReciter)
    }

    func isCurrentAyah(surah: Int, ayah: Int) -> Bool {
        nowPlayingSurah?.id == surah && nowPlayingAyah == ayah
    }

    func togglePlayback(surah: Int, ayah: Int) {
        guard let metadata = surahMetadata(for: surah) else { return }
        guard canAccess(surah: metadata) else { return }

        let isCurrentSelection = isCurrentAyah(surah: surah, ayah: ayah)

        if isCurrentSelection {
            switch playbackState {
            case .playing, .loading, .buffering:
                pause()
            case .paused:
                resume()
            case .idle, .stopped, .failed:
                beginPlayback(in: metadata, ayah: ayah, resumeProgress: currentProgress)
            }
            return
        }

        beginPlayback(in: metadata, ayah: ayah)
    }

    func playAyah(surah: Int, ayah: Int) {
        togglePlayback(surah: surah, ayah: ayah)
    }

    func playSurahContinuously(surah: Int, startingAt ayah: Int) {
        guard let metadata = surahMetadata(for: surah) else { return }
        guard canAccess(surah: metadata) else { return }
        beginPlayback(in: metadata, ayah: ayah, continuously: true)
    }

    func pause() {
        player.pause()

        if nowPlayingAyah != nil {
            playbackState = .paused
            persistResumeState()
            updateNowPlayingInfo()
        }
    }

    func resume() {
        if player.currentItem != nil {
            prepareAudioSessionIfPossible()
            player.play()
            updateNowPlayingInfo()
            return
        }

        if let currentItem = currentQueueItem {
            play(
                AyahAudioRequest(surah: currentItem.surahID, ayah: currentItem.ayahNumber, reciter: selectedReciter),
                autoplay: true,
                resumeProgress: currentProgress
            )
            return
        }

        guard let resumeState else { return }
        resumeFromLastState(resumeState)
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        player.pause()
        replaceCurrentItem(with: nil)
        currentTrack = nil
        currentRequest = nil
        currentProgress = 0
        currentElapsedTime = 0
        activeWordRange = nil
        currentTimingPayload = nil
        playbackState = .stopped
        continuesPlaybackForCurrentSession = false
        audioSessionManager.deactivate()
        persistResumeState()
        clearNowPlayingInfo()
    }

    func seek(to progress: Double) {
        let clampedProgress = max(0, min(progress, 0.999))
        currentProgress = clampedProgress
        progressPersistenceBucket = -1

        guard let item = player.currentItem else {
            pendingSeekProgress = clampedProgress
            persistResumeState()
            return
        }

        let duration = CMTimeGetSeconds(item.duration)
        guard duration.isFinite, duration > 0 else {
            pendingSeekProgress = clampedProgress
            persistResumeState()
            return
        }

        let targetTime = CMTime(seconds: duration * clampedProgress, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentElapsedTime = duration * clampedProgress
        refreshActiveWordRange(usingElapsedTime: currentElapsedTime)
        persistResumeState()
        updateNowPlayingInfo()
    }

    func skipToNextAyah() {
        guard let queueIndex else { return }
        let nextIndex = queueIndex + 1
        guard queue.indices.contains(nextIndex) else { return }

        playQueueItem(at: nextIndex)
    }

    func skipToPreviousAyah() {
        if currentProgress > 0.05 {
            seek(to: 0)
            return
        }

        guard let queueIndex else { return }
        let previousIndex = queueIndex - 1
        guard queue.indices.contains(previousIndex) else {
            seek(to: 0)
            return
        }

        playQueueItem(at: previousIndex)
    }

    func switchReciter(_ reciter: Reciter) {
        guard canAccess(reciter: reciter) else { return }
        guard selectedReciter.id != reciter.id else { return }

        selectedReciter = reciter
        defaults.set(reciter.id, forKey: selectedReciterKey)

        guard let currentItem = currentQueueItem else {
            persistResumeState()
            return
        }

        let shouldAutoplay = playbackState.isActivelyPlaying || playbackState == .loading
        play(
            AyahAudioRequest(surah: currentItem.surahID, ayah: currentItem.ayahNumber, reciter: reciter),
            autoplay: shouldAutoplay,
            resumeProgress: currentProgress
        )
        updateNowPlayingInfo()
    }

    func setAutoAdvanceEnabled(_ isEnabled: Bool) {
        guard isEnabled != isAutoAdvanceEnabled else { return }

        if isEnabled && !canUsePremiumFeature(.autoAdvance) {
            return
        }

        isAutoAdvanceEnabled = isPremiumUser ? isEnabled : false
        refreshQueueMode()
        defaults.set(isAutoAdvanceEnabled, forKey: autoAdvanceKey)
        if isEnabled {
            continuesPlaybackForCurrentSession = true
        }
        rebuildQueueForCurrentContext()
        persistResumeState()
        updateNowPlayingInfo()
    }

    func setBackgroundListeningEnabled(_ isEnabled: Bool) {
        guard isEnabled != isBackgroundListeningEnabled else { return }

        if isEnabled && !canUsePremiumFeature(.backgroundListening) {
            return
        }

        isBackgroundListeningEnabled = isPremiumUser ? isEnabled : false
        defaults.set(isBackgroundListeningEnabled, forKey: backgroundListeningKey)
        reconfigureAudioSessionIfNeeded()
        updateNowPlayingInfo()
    }

    func setSleepTimer(_ option: QuranSleepTimerOption) {
        if option != .off && !canUsePremiumFeature(.sleepTimer) {
            return
        }

        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerOption = option

        guard let duration = option.duration else { return }

        sleepTimerTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self?.pause()
                self?.playbackState = .stopped
                self?.sleepTimerOption = .off
                self?.updateNowPlayingInfo()
            }
        }
    }

    func setRepeatMode(_ mode: QuranPlaybackRepeatMode) {
        repeatMode = mode
        defaults.set(mode.rawValue, forKey: repeatModeKey)
        updateNowPlayingInfo()
    }

    private func resumeFromLastState(_ state: QuranAudioResumeState) {
        guard let metadata = surahMetadata(for: state.surahID) else { return }
        guard canAccess(surah: metadata) else { return }

        if let storedReciter = ReciterRegistry.reciter(withID: state.reciterID), canAccess(reciter: storedReciter, presentPrompt: false) {
            selectedReciter = storedReciter
            defaults.set(storedReciter.id, forKey: selectedReciterKey)
        } else if selectedReciter.isPremiumLocked {
            selectedReciter = ReciterRegistry.defaultFreeReciter
        }

        beginPlayback(
            in: metadata,
            ayah: state.ayahNumber,
            resumeProgress: state.progress,
            continuously: state.continuesPlayback
        )
    }

    private func beginPlayback(
        in surah: QuranSurah,
        ayah: Int,
        resumeProgress: Double = 0,
        continuously: Bool = false
    ) {
        continuesPlaybackForCurrentSession = continuously || isAutoAdvanceEnabled
        replaceQueue(
            with: makeQueue(
                for: surah,
                startingAt: ayah,
                forceContinuous: continuesPlaybackForCurrentSession
            )
        )
        play(
            AyahAudioRequest(surah: surah.id, ayah: ayah, reciter: selectedReciter),
            autoplay: true,
            resumeProgress: resumeProgress
        )
    }

    private func play(_ request: AyahAudioRequest, autoplay: Bool, resumeProgress: Double = 0) {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            await self?.startPlayback(for: request, autoplay: autoplay, resumeProgress: resumeProgress)
        }
    }

    private func startPlayback(for request: AyahAudioRequest, autoplay: Bool, resumeProgress: Double) async {
        errorState = nil
        currentRequest = request
        currentProgress = max(0, min(resumeProgress, 0.99))
        currentElapsedTime = 0
        progressPersistenceBucket = -1
        playbackState = .loading
        pendingSeekProgress = currentProgress > 0 ? currentProgress : nil
        syncQueueWithRequest(request)

        do {
            prepareAudioSessionIfPossible()

            let track = try await resolveTrack(for: request)
            guard !Task.isCancelled, currentRequest?.cacheKey == request.cacheKey else { return }

            currentTrack = track
            currentTimingPayload = await timingPayload(for: request, providerKind: track.providerKind)
            refreshActiveWordRangeForCurrentContext()
            replaceCurrentItem(with: AVPlayerItem(url: track.playbackURL))

            if autoplay {
                player.play()
            } else {
                player.pause()
                playbackState = .paused
            }

            prefetchNearbyAyahs(from: request)
            warmChapterIndex(forSurah: request.surah, reciter: request.reciter)
            persistResumeState()
            updateNowPlayingInfo()
        } catch is CancellationError {
            if currentRequest?.cacheKey == request.cacheKey, playbackState == .loading {
                playbackState = .idle
                updateNowPlayingInfo()
            }
        } catch {
            guard currentRequest?.cacheKey == request.cacheKey else { return }
            playbackState = .failed
#if DEBUG
            print("[AyahAudio] start_playback_failed verse=\(request.verseKey) reciter=\(request.reciter.id) error=\(error.localizedDescription)")
#endif
            publishError(
                code: .audioUnavailable,
                title: L10n.string(.baglantiHatasi),
                message: L10n.string(.quranAudioUnavailable),
                developerDescription: error.localizedDescription
            )
            updateNowPlayingInfo()
        }
    }

    private func replaceQueue(with queue: [QuranAudioQueueItem]) {
        self.queue = queue
        queueIndex = queue.isEmpty ? nil : 0
        syncNowPlayingFromQueue()
        refreshQueueMode(for: nowPlayingSurah)
        updateRemoteCommandAvailability()
    }

    private func syncQueueWithRequest(_ request: AyahAudioRequest) {
        if let matchedIndex = queue.firstIndex(where: {
            $0.surahID == request.surah && $0.ayahNumber == request.ayah
        }) {
            queueIndex = matchedIndex
        } else if let metadata = surahMetadata(for: request.surah) {
            replaceQueue(
                with: makeQueue(
                    for: metadata,
                    startingAt: request.ayah,
                    forceContinuous: continuesPlaybackForCurrentSession
                )
            )
            refreshQueueMode(for: metadata)
        }

        syncNowPlayingFromQueue()
    }

    private func rebuildQueueForCurrentContext() {
        guard let surah = nowPlayingSurah, let ayah = nowPlayingAyah else { return }
        refreshQueueMode(for: surah)
        replaceQueue(
            with: makeQueue(
                for: surah,
                startingAt: ayah,
                forceContinuous: continuesPlaybackForCurrentSession
            )
        )
    }

    private func makeQueue(for surah: QuranSurah, startingAt ayah: Int, forceContinuous: Bool = false) -> [QuranAudioQueueItem] {
        let totalAyahs = max(ayahCount(forSurah: surah.id), surah.totalVerses)
        let startAyah = min(max(ayah, 1), max(totalAyahs, 1))
        let endAyah = (forceContinuous || canAdvanceThroughSurah(surah)) ? totalAyahs : startAyah

        return (startAyah...endAyah).map {
            QuranAudioQueueItem(
                surahID: surah.id,
                surahName: surah.localizedTurkishName,
                ayahNumber: $0,
                totalAyahs: totalAyahs,
                accessLevel: surah.audioAccessLevel
            )
        }
    }

    private var currentQueueItem: QuranAudioQueueItem? {
        guard let queueIndex, queue.indices.contains(queueIndex) else { return nil }
        return queue[queueIndex]
    }

    private func syncNowPlayingFromQueue() {
        guard let currentQueueItem else { return }
        nowPlayingSurah = surahMetadata(for: currentQueueItem.surahID)
        nowPlayingAyah = currentQueueItem.ayahNumber
        persistResumeState()
        updateNowPlayingInfo()
    }

    private func restoreDisplayStateIfAvailable() {
        guard let resumeState else { return }
        guard let metadata = surahMetadata(for: resumeState.surahID) else { return }

        nowPlayingSurah = metadata
        nowPlayingAyah = resumeState.ayahNumber
        currentProgress = resumeState.progress
        currentElapsedTime = 0
        continuesPlaybackForCurrentSession = resumeState.continuesPlayback
        queue = makeQueue(
            for: metadata,
            startingAt: resumeState.ayahNumber,
            forceContinuous: resumeState.continuesPlayback
        )
        queueIndex = queue.isEmpty ? nil : 0
        playbackState = .paused
        refreshQueueMode(for: metadata)
        updateRemoteCommandAvailability()
        updateNowPlayingInfo()
    }

    private func persistResumeState() {
        guard let surah = nowPlayingSurah, let ayah = nowPlayingAyah else { return }

        let state = QuranAudioResumeState(
            surahID: surah.id,
            surahName: surah.localizedTurkishName,
            ayahNumber: ayah,
            reciterID: selectedReciter.id,
            progress: currentProgress,
            continuesPlayback: continuesPlaybackForCurrentSession
        )

        resumeState = state

        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: resumeStateKey)
        }
    }

    private static func loadResumeState(from defaults: UserDefaults, key: String) -> QuranAudioResumeState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(QuranAudioResumeState.self, from: data)
    }

    private func surahMetadata(for id: Int) -> QuranSurah? {
        QuranSurahData.surahs.first(where: { $0.id == id })
    }

    private func canAdvanceThroughSurah(_ surah: QuranSurah) -> Bool {
        if !surah.audioAccessLevel.requiresPremium {
            return true
        }

        return isPremiumUser && isAutoAdvanceEnabled
    }

    private func refreshQueueMode(for surah: QuranSurah? = nil) {
        if let surah {
            queueMode = (continuesPlaybackForCurrentSession || canAdvanceThroughSurah(surah)) ? .autoAdvance : .singleAyah
            return
        }

        queueMode = (continuesPlaybackForCurrentSession || (isPremiumUser && isAutoAdvanceEnabled)) ? .autoAdvance : .singleAyah
    }

    private func canAccess(surah: QuranSurah, presentPrompt: Bool = true) -> Bool {
        guard surah.audioAccessLevel.requiresPremium, !isPremiumUser else { return true }

        if presentPrompt {
            premiumPrompt = QuranAudioPremiumPrompt(
                feature: .fullQuranRecitation,
                title: L10n.string(.quranAudioPremiumPromptTitle),
                message: L10n.string(.quranAudioPremiumFullQuranMessage)
            )
        }

        return false
    }

    private func canAccess(reciter: Reciter, presentPrompt: Bool = true) -> Bool {
        guard reciter.isPremiumLocked, !isPremiumUser else { return true }

        if presentPrompt {
            premiumPrompt = QuranAudioPremiumPrompt(
                feature: .reciterSelection,
                title: L10n.string(.quranAudioPremiumPromptTitle),
                message: L10n.string(.quranAudioPremiumReciterMessage)
            )
        }

        return false
    }

    private func canUsePremiumFeature(_ feature: QuranAudioPremiumFeature) -> Bool {
        guard !isPremiumUser else { return true }

        let message: String
        switch feature {
        case .backgroundListening:
            message = L10n.string(.quranAudioPremiumBackgroundMessage)
        case .reciterSelection:
            message = L10n.string(.quranAudioPremiumReciterMessage)
        case .autoAdvance:
            message = L10n.string(.quranAudioPremiumAutoAdvanceMessage)
        case .sleepTimer:
            message = L10n.string(.quranAudioPremiumSleepTimerMessage)
        case .offlineListening:
            message = L10n.string(.quranAudioPremiumOfflineMessage)
        case .fullQuranRecitation:
            message = L10n.string(.quranAudioPremiumFullQuranMessage)
        }

        premiumPrompt = QuranAudioPremiumPrompt(
            feature: feature,
            title: L10n.string(.quranAudioPremiumPromptTitle),
            message: message
        )
        return false
    }

    private func prepareAudioSessionIfPossible() {
        guard !shouldSkipAudioSessionPreparation else { return }

        do {
            try audioSessionManager.configureForPlayback(allowsBackgroundPlayback: effectiveBackgroundPlaybackEnabled)
            try audioSessionManager.activate()
        } catch {
            shouldSkipAudioSessionPreparation = true
#if DEBUG
            print("[AyahAudio] session_warning error=\(error.localizedDescription)")
#endif
        }
    }

    private func reconfigureAudioSessionIfNeeded() {
        guard player.currentItem != nil else { return }
        shouldSkipAudioSessionPreparation = false
        prepareAudioSessionIfPossible()
    }

    private func resolveTrack(for request: AyahAudioRequest) async throws -> AyahAudioTrack {
        if let offlineFileURL = await offlineStorageManager.cachedFileURL(for: request) {
            return AyahAudioTrack(
                request: request,
                providerKind: request.reciter.providerKind,
                remoteURL: nil,
                localFileURL: offlineFileURL
            )
        }

        let cachedFileURL = await cacheManager.cachedFileURL(for: request)

        var lastError: Error?

        for providerKind in orderedProviderKinds(for: request.reciter) {
            guard let provider = providersByKind[providerKind], provider.supports(request.reciter) else {
                continue
            }

            do {
                let remoteURL = try await resolvedRemoteURL(
                    for: request,
                    provider: provider,
                    providerKind: providerKind
                )
                let cachedLocalURL: URL

                if let cachedFileURL {
                    cachedLocalURL = cachedFileURL
                } else {
                    cachedLocalURL = try await cacheManager.cacheRemoteFile(
                        from: remoteURL,
                        for: request,
                        session: urlSession
                    )
                }

                return AyahAudioTrack(
                    request: request,
                    providerKind: providerKind,
                    remoteURL: remoteURL,
                    localFileURL: cachedLocalURL
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
#if DEBUG
                print("[AyahAudio] provider_failed provider=\(providerKind.rawValue) verse=\(request.verseKey) reciter=\(request.reciter.id) error=\(error.localizedDescription)")
#endif
            }
        }

        if let cachedFileURL {
#if DEBUG
            print("[AyahAudio] using_cached_fallback verse=\(request.verseKey) reciter=\(request.reciter.id)")
#endif
            return AyahAudioTrack(
                request: request,
                providerKind: request.reciter.providerKind,
                remoteURL: nil,
                localFileURL: cachedFileURL
            )
        }

        throw lastError ?? QuranAudioProviderError.unsupportedReciter(
            provider: request.reciter.providerKind,
            reciterID: request.reciter.id
        )
    }

    private func resolvedRemoteURL(
        for request: AyahAudioRequest,
        provider: any QuranAudioProvider,
        providerKind: AudioProviderKind
    ) async throws -> URL {
        let chapterKey = chapterIndexKey(forSurah: request.surah, reciter: request.reciter)
        if let url = preloadedChapterURLs[chapterKey]?[request.ayah] {
            return url
        }

        return try await provider.resolveAudioURL(for: request)
    }

    private func orderedProviderKinds(for reciter: Reciter) -> [AudioProviderKind] {
        var orderedKinds: [AudioProviderKind] = [reciter.providerKind]

        if let fallbackProviderKind, fallbackProviderKind != reciter.providerKind {
            orderedKinds.append(fallbackProviderKind)
        }

        for providerKind in AudioProviderKind.allCases where !orderedKinds.contains(providerKind) {
            orderedKinds.append(providerKind)
        }

        return orderedKinds
    }

    private func prefetchNearbyAyahs(from request: AyahAudioRequest) {
        let totalAyahs = ayahCount(forSurah: request.surah)
        guard totalAyahs > 0 else { return }

        let candidateAyahs = [request.ayah + 1, request.ayah + 2]
            .filter { $0 <= totalAyahs }

        for ayah in candidateAyahs {
            let prefetchRequest = AyahAudioRequest(
                surah: request.surah,
                ayah: ayah,
                reciter: request.reciter
            )

            let taskKey = prefetchRequest.cacheKey
            guard prefetchTasks[taskKey] == nil else { continue }

            prefetchTasks[taskKey] = Task { [weak self] in
                guard let self else { return }

                defer {
                    self.prefetchTasks.removeValue(forKey: taskKey)
                }

                guard !(await self.cacheManager.exists(for: prefetchRequest)) else { return }

                do {
                    _ = try await self.resolveTrack(for: prefetchRequest)
                } catch {
                    // Nearby prefetch is opportunistic; failures should stay silent.
                }
            }
        }
    }

    private func warmChapterIndex(forSurah surah: Int, reciter: Reciter) {
        let cacheKey = chapterIndexKey(forSurah: surah, reciter: reciter)
        guard preloadedChapterURLs[cacheKey] == nil else { return }
        guard !warmingChapterKeys.contains(cacheKey) else { return }

        warmingChapterKeys.insert(cacheKey)

        Task { [weak self] in
            guard let self else { return }

            defer {
                self.warmingChapterKeys.remove(cacheKey)
            }

            for providerKind in self.orderedProviderKinds(for: reciter) {
                guard let provider = self.providersByKind[providerKind], provider.supports(reciter) else {
                    continue
                }

                do {
                    let urls = try await provider.preloadAudioURLs(forSurah: surah, reciter: reciter)
                    guard !urls.isEmpty else { continue }
                    self.preloadedChapterURLs[cacheKey] = urls
                    return
                } catch {
                    continue
                }
            }
        }
    }

    private func chapterIndexKey(forSurah surah: Int, reciter: Reciter) -> String {
        "\(reciter.id):\(surah)"
    }

    private func observePlayerLifetime() {
        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                self?.handleTimeControlStatus(player.timeControlStatus)
            }
        }

        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.updateProgress(with: time)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let finishedItem = notification.object as? AVPlayerItem,
                finishedItem == self.player.currentItem
            else {
                return
            }

            Task { @MainActor [weak self] in
                self?.handlePlaybackFinished()
            }
        }
    }

    private func observeCurrentItem(_ item: AVPlayerItem?) {
        itemStatusObservation?.invalidate()
        bufferObservation?.invalidate()
        likelyToKeepUpObservation?.invalidate()

        guard let item else { return }

        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.handleItemStatus(item.status, itemError: item.error)
            }
        }

        bufferObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard item.isPlaybackBufferEmpty else { return }
                guard self?.playbackState != .loading else { return }
                self?.playbackState = .buffering
            }
        }

        likelyToKeepUpObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard item.isPlaybackLikelyToKeepUp else { return }
                guard self?.playbackState == .buffering else { return }
                self?.playbackState = self?.player.rate == 0 ? .paused : .playing
            }
        }
    }

    private func replaceCurrentItem(with item: AVPlayerItem?) {
        observeCurrentItem(nil)
        player.replaceCurrentItem(with: item)
        observeCurrentItem(item)
    }

    private func handleItemStatus(_ status: AVPlayerItem.Status, itemError: Error?) {
        switch status {
        case .readyToPlay:
            performPendingSeekIfNeeded()

            if playbackState == .loading {
                playbackState = player.rate == 0 ? .paused : .playing
            }
            updateNowPlayingInfo()
        case .failed:
            playbackState = .failed
#if DEBUG
            print("[AyahAudio] item_failed error=\(itemError?.localizedDescription ?? "unknown")")
#endif
            publishError(
                code: .playbackFailed,
                title: L10n.string(.baglantiHatasi),
                message: L10n.string(.quranAudioUnavailable),
                developerDescription: itemError?.localizedDescription
            )
            updateNowPlayingInfo()
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func performPendingSeekIfNeeded() {
        guard let pendingSeekProgress, let item = player.currentItem else { return }

        let duration = CMTimeGetSeconds(item.duration)
        guard duration.isFinite, duration > 0 else {
            self.pendingSeekProgress = nil
            return
        }

        let time = CMTime(seconds: duration * pendingSeekProgress, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        self.pendingSeekProgress = nil
    }

    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        guard player.currentItem != nil else { return }

        switch status {
        case .playing:
            playbackState = .playing
        case .waitingToPlayAtSpecifiedRate:
            if playbackState != .loading {
                playbackState = .buffering
            }
        case .paused:
            guard playbackState != .stopped, playbackState != .failed else { return }
            if playbackState != .loading {
                playbackState = .paused
            }
        @unknown default:
            break
        }

        updateNowPlayingInfo()
    }

    private func updateProgress(with time: CMTime) {
        guard let currentItem = player.currentItem else {
            return
        }

        let duration = CMTimeGetSeconds(currentItem.duration)
        let currentTime = CMTimeGetSeconds(time)

        guard duration.isFinite, duration > 0, currentTime.isFinite else {
            return
        }

        currentElapsedTime = currentTime
        currentProgress = min(max(currentTime / duration, 0), 1)
        refreshActiveWordRange(usingElapsedTime: currentTime)

        let bucket = Int(currentProgress * 20)
        if bucket != progressPersistenceBucket {
            progressPersistenceBucket = bucket
            persistResumeState()
        }

        updateNowPlayingInfo()
    }

    private func handlePlaybackFinished() {
        if repeatMode == .repeatAyah, let currentItem = currentQueueItem {
            currentProgress = 0
            currentElapsedTime = 0
            activeWordRange = nil
            progressPersistenceBucket = -1
            play(
                AyahAudioRequest(surah: currentItem.surahID, ayah: currentItem.ayahNumber, reciter: selectedReciter),
                autoplay: true
            )
            return
        }

        currentProgress = 0
        currentElapsedTime = 0
        activeWordRange = nil
        progressPersistenceBucket = -1

        guard let queueIndex else {
            replaceCurrentItem(with: nil)
            currentTimingPayload = nil
            playbackState = .stopped
            persistResumeState()
            clearNowPlayingInfo()
            return
        }

        let nextIndex = queueIndex + 1
        guard queue.indices.contains(nextIndex) else {
            replaceCurrentItem(with: nil)
            playbackState = .stopped
            persistResumeState()
            clearNowPlayingInfo()
            return
        }

        self.queueIndex = nextIndex
        syncNowPlayingFromQueue()

        guard let nextItem = currentQueueItem else { return }
        play(
            AyahAudioRequest(surah: nextItem.surahID, ayah: nextItem.ayahNumber, reciter: selectedReciter),
            autoplay: true
        )
    }

    private func playQueueItem(at index: Int) {
        guard queue.indices.contains(index) else { return }

        queueIndex = index
        syncNowPlayingFromQueue()
        activeWordRange = nil

        guard let item = currentQueueItem else { return }
        play(
            AyahAudioRequest(surah: item.surahID, ayah: item.ayahNumber, reciter: selectedReciter),
            autoplay: shouldAutoplayCurrentContext()
        )
        updateNowPlayingInfo()
    }

    private func shouldAutoplayCurrentContext() -> Bool {
        playbackState.isActivelyPlaying || playbackState == .loading || playbackState == .buffering
    }

    private func handleInterruption(type: AVAudioSession.InterruptionType, shouldResume: Bool) {
        switch type {
        case .began:
            shouldResumeAfterInterruption = playbackState == .playing || playbackState == .buffering
            player.pause()
            if currentRequest != nil {
                playbackState = .paused
            }
            publishError(
                code: .interrupted,
                title: L10n.string(.baglantiHatasi),
                message: L10n.string(.quranAudioPlaybackInterrupted),
                developerDescription: nil
            )
            updateNowPlayingInfo()
        case .ended:
            guard shouldResume, shouldResumeAfterInterruption else {
                shouldResumeAfterInterruption = false
                return
            }

            shouldResumeAfterInterruption = false
            resume()
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ reason: AVAudioSession.RouteChangeReason) {
        guard reason == .oldDeviceUnavailable else { return }

        if playbackState.isActivelyPlaying {
            player.pause()
            playbackState = .paused
            publishError(
                code: .routeChanged,
                title: L10n.string(.baglantiHatasi),
                message: L10n.string(.quranAudioRouteChanged),
                developerDescription: "Audio route changed: \(reason.rawValue)"
            )
            updateNowPlayingInfo()
        }
    }

    private func publishError(
        code: PlayerErrorState.Code,
        title: String,
        message: String,
        developerDescription: String?
    ) {
        errorState = PlayerErrorState(
            code: code,
            title: title,
            message: message,
            developerDescription: developerDescription
        )
    }

    private func enforceForegroundOnlyPlayback(showUpsell: Bool) {
        guard playbackState.isActivelyPlaying || playbackState == .loading || playbackState == .buffering else { return }

        pause()
        replaceCurrentItem(with: nil)
        currentRequest = currentQueueItem.map {
            AyahAudioRequest(surah: $0.surahID, ayah: $0.ayahNumber, reciter: selectedReciter)
        }
        activeWordRange = nil
        audioSessionManager.deactivate()
        persistResumeState()
        clearNowPlayingInfo()

        if showUpsell {
            premiumPrompt = QuranAudioPremiumPrompt(
                feature: .backgroundListening,
                title: L10n.string(.quranAudioPremiumPromptTitle),
                message: L10n.string(.quranAudioPremiumBackgroundMessage)
            )
        }
    }

    private func cleanupObservers() {
        playbackTask?.cancel()
        prefetchTasks.values.forEach { $0.cancel() }
        prefetchTasks.removeAll()
        sleepTimerTask?.cancel()

        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        timeControlObservation?.invalidate()
        itemStatusObservation?.invalidate()
        bufferObservation?.invalidate()
        likelyToKeepUpObservation?.invalidate()
        audioSessionManager.stopObserving()
        activeWordRange = nil
        currentTimingPayload = nil
        clearNowPlayingInfo()
    }

    private func timingPayload(for request: AyahAudioRequest, providerKind: AudioProviderKind) async -> QuranAyahTimingPayload? {
        guard providerKind == .bundledAyahJSON,
              let resourceName = request.reciter.configuration(for: .bundledAyahJSON)?.remoteIdentifier else {
            return nil
        }

        return await BundledAyahAudioCatalog.shared.timingPayload(
            forVerseKey: request.verseKey,
            resourceName: resourceName
        )
    }

    private func refreshActiveWordRangeForCurrentContext() {
        guard currentElapsedTime > 0 else {
            if let currentTimingPayload, currentProgress > 0, currentProgress < 1 {
                let estimatedElapsed = (Double(currentTimingPayload.estimatedDurationMilliseconds) / 1000) * currentProgress
                refreshActiveWordRange(usingElapsedTime: estimatedElapsed)
            } else {
                activeWordRange = nil
            }
            return
        }

        refreshActiveWordRange(usingElapsedTime: currentElapsedTime)
    }

    private func refreshActiveWordRange(usingElapsedTime elapsedTime: Double) {
        guard let currentRequest, let currentTimingPayload else {
            activeWordRange = nil
            return
        }

        let elapsedMilliseconds = Int((elapsedTime * 1000).rounded())
        guard let segment = currentTimingPayload.resolvedSegment(at: elapsedMilliseconds) else {
            activeWordRange = nil
            return
        }

        activeWordRange = QuranActiveWordRange(
            surahID: currentRequest.surah,
            ayahNumber: currentRequest.ayah,
            startWordIndex: segment.startWordIndex,
            endWordIndex: segment.endWordIndex
        )
    }

    private func configureRemoteCommandCenterIfNeeded() {
        guard !remoteCommandCenterConfigured else { return }

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.resume()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.skipToNextAyah()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.skipToPreviousAyah()
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            Task { @MainActor [weak self] in
                self?.seekToElapsedTime(event.positionTime)
            }
            return .success
        }

        remoteCommandCenterConfigured = true
        updateRemoteCommandAvailability()
    }

    private func updateRemoteCommandAvailability() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = canSkipToNext
        commandCenter.previousTrackCommand.isEnabled = canSkipToPrevious
        commandCenter.changePlaybackPositionCommand.isEnabled = player.currentItem != nil
    }

    private func seekToElapsedTime(_ elapsedTime: TimeInterval) {
        guard let item = player.currentItem else { return }
        let duration = CMTimeGetSeconds(item.duration)
        guard duration.isFinite, duration > 0 else { return }
        seek(to: elapsedTime / duration)
    }

    private func updateNowPlayingInfo() {
        guard let surah = nowPlayingSurah, let ayah = nowPlayingAyah else {
            clearNowPlayingInfo()
            return
        }

        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = "\(surah.localizedTurkishName) • \(L10n.format(.quranAudioVerseFormat, Int64(ayah)))"
        info[MPMediaItemPropertyArtist] = selectedReciter.localizedDisplayName
        info[MPMediaItemPropertyAlbumTitle] = L10n.string(.kurAnIKerim)
        info[MPMediaItemPropertyArtwork] = nowPlayingArtwork
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedPlaybackTime
        info[MPMediaItemPropertyPlaybackDuration] = playbackDuration
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackState.isActivelyPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        updateRemoteCommandAvailability()
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        updateRemoteCommandAvailability()
    }

    private var elapsedPlaybackTime: TimeInterval {
        guard let item = player.currentItem else { return 0 }
        let current = CMTimeGetSeconds(item.currentTime())
        return current.isFinite ? current : 0
    }

    private var playbackDuration: TimeInterval {
        guard let item = player.currentItem else { return 0 }
        let duration = CMTimeGetSeconds(item.duration)
        return duration.isFinite ? duration : 0
    }

    private static func makeNowPlayingArtwork() -> MPMediaItemArtwork? {
        guard let image = UIImage(named: "MoreHeaderAppIcon") else {
            return nil
        }

        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }

#if DEBUG
    func queueForTesting(surahID: Int, startingAt ayah: Int) -> [QuranAudioQueueItem]? {
        guard let surah = surahMetadata(for: surahID) else { return nil }
        return makeQueue(for: surah, startingAt: ayah)
    }
#endif
}
