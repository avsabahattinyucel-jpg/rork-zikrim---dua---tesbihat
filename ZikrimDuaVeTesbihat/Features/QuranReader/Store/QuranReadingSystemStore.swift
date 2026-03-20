import Combine
import Foundation

@MainActor
final class QuranReadingSystemStore: ObservableObject {
    @Published private(set) var currentReadingSession: QuranReadingSession?
    @Published private(set) var currentPlaybackSession: QuranPlaybackSession?
    @Published private(set) var recentReferences: [QuranRecentReference]

    private let defaults: UserDefaults
    private let readingKey = "quran.reading_system.current_reading_session"
    private let playbackKey = "quran.reading_system.current_playback_session"
    private let recentKey = "quran.reading_system.recent_references"
    private var cancellables: Set<AnyCancellable> = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.currentReadingSession = Self.load(QuranReadingSession.self, from: defaults, key: readingKey)
        self.currentPlaybackSession = Self.load(QuranPlaybackSession.self, from: defaults, key: playbackKey)
        self.recentReferences = Self.load([QuranRecentReference].self, from: defaults, key: recentKey) ?? []
    }

    func bootstrapIfNeeded(lastRead: QuranReadPosition?) {
        guard currentReadingSession == nil, let lastRead else { return }

        currentReadingSession = QuranReadingSession(
            surahId: lastRead.surahId,
            ayahId: lastRead.verseNumber,
            isTranslationVisible: true,
            selectedTafsirSourceID: QuranTafsirSource.zikrimShortExplanation.id,
            readingAppearancePreset: .standardDark,
            arabicFontScale: QuranReaderPreferences.default.arabicFontSize,
            translationFontScale: QuranReaderPreferences.default.translationFontSize,
            lineSpacing: QuranReaderPreferences.default.translationLineSpacing,
            lastReciterID: nil,
            lastOpenedAt: Date()
        )
        persist()
    }

    func bindAudioService(_ service: AyahAudioPlayerService) {
        cancellables.removeAll()

        service.$selectedReciter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$nowPlayingSurah
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$nowPlayingAyah
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$currentProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$isAutoAdvanceEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$repeatMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$sleepTimerOption
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$isBackgroundListeningEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)

        service.$resumeState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncPlayback(from: service) }
            .store(in: &cancellables)
    }

    func updateReadingSession(
        surahId: Int,
        ayahId: Int,
        preferences: QuranReaderPreferences,
        selectedTafsirSourceID: String,
        reciterID: String?
    ) {
        currentReadingSession = QuranReadingSession(
            surahId: surahId,
            ayahId: ayahId,
            isTranslationVisible: preferences.displayMode.showsTranslation,
            selectedTafsirSourceID: selectedTafsirSourceID,
            readingAppearancePreset: preferences.appearance,
            arabicFontScale: preferences.arabicFontSize,
            translationFontScale: preferences.translationFontSize,
            lineSpacing: preferences.translationLineSpacing,
            lastReciterID: reciterID,
            lastOpenedAt: Date()
        )

        pushRecentReference(surahId: surahId, ayahNumber: ayahId)
        persist()
    }

    func updateReadingPreferences(
        surahId: Int,
        ayahId: Int?,
        preferences: QuranReaderPreferences,
        selectedTafsirSourceID: String,
        reciterID: String?
    ) {
        let resolvedAyah = ayahId ?? currentReadingSession?.ayahId ?? 1
        updateReadingSession(
            surahId: surahId,
            ayahId: resolvedAyah,
            preferences: preferences,
            selectedTafsirSourceID: selectedTafsirSourceID,
            reciterID: reciterID
        )
    }

    func currentReadingRoute(fallbackSurahId: Int = 1) -> QuranReadingRoute {
        if let playback = currentPlaybackSession {
            return QuranReadingRoute(
                surahId: playback.surahId,
                ayahNumber: playback.ayahId,
                shouldResumePlayback: playback.isPlaying,
                preferredReciterID: playback.reciterId,
                preferredAppearance: currentReadingSession?.readingAppearancePreset
            )
        }

        if let reading = currentReadingSession {
            return QuranReadingRoute(
                surahId: reading.surahId,
                ayahNumber: reading.ayahId,
                preferredReciterID: reading.lastReciterID,
                preferredAppearance: reading.readingAppearancePreset
            )
        }

        return QuranReadingRoute(surahId: fallbackSurahId, ayahNumber: 1)
    }

    func continueListeningRoute(fallbackSurahId: Int = 1) -> QuranReadingRoute {
        if let playback = currentPlaybackSession {
            return QuranReadingRoute(
                surahId: playback.surahId,
                ayahNumber: playback.ayahId,
                shouldResumePlayback: true,
                preferredReciterID: playback.reciterId,
                preferredAppearance: currentReadingSession?.readingAppearancePreset
            )
        }

        if let reading = currentReadingSession {
            return QuranReadingRoute(
                surahId: reading.surahId,
                ayahNumber: reading.ayahId,
                shouldResumePlayback: true,
                preferredReciterID: reading.lastReciterID,
                preferredAppearance: reading.readingAppearancePreset
            )
        }

        return QuranReadingRoute(
            surahId: fallbackSurahId,
            ayahNumber: 1,
            shouldResumePlayback: true
        )
    }

    func listeningControlRoute(fallbackSurahId: Int = 1) -> QuranAudioControlRoute {
        if let playback = currentPlaybackSession {
            return QuranAudioControlRoute(surahId: playback.surahId, ayahNumber: playback.ayahId)
        }

        if let reading = currentReadingSession {
            return QuranAudioControlRoute(surahId: reading.surahId, ayahNumber: reading.ayahId)
        }

        return QuranAudioControlRoute(surahId: fallbackSurahId, ayahNumber: 1)
    }

    private func syncPlayback(from service: AyahAudioPlayerService) {
        syncPlayback(
            reciter: service.selectedReciter,
            playbackState: service.playbackState,
            surah: service.nowPlayingSurah,
            ayah: service.nowPlayingAyah,
            progress: service.currentProgress,
            autoAdvance: service.isAutoAdvanceEnabled,
            repeatMode: service.repeatMode,
            sleepTimer: service.sleepTimerOption,
            backgroundEnabled: service.isBackgroundListeningEnabled,
            resumeState: service.resumeState
        )
    }

    private func syncPlayback(
        reciter: Reciter,
        playbackState: AudioPlaybackState,
        surah: QuranSurah?,
        ayah: Int?,
        progress: Double,
        autoAdvance: Bool,
        repeatMode: QuranPlaybackRepeatMode,
        sleepTimer: QuranSleepTimerOption,
        backgroundEnabled: Bool,
        resumeState: QuranAudioResumeState?
    ) {
        let now = Date()

        if let surah, let ayah {
            currentPlaybackSession = QuranPlaybackSession(
                surahId: surah.id,
                ayahId: ayah,
                reciterId: reciter.id,
                progressInAyah: progress,
                isPlaying: playbackState.isActive,
                autoAdvance: autoAdvance,
                repeatMode: repeatMode,
                sleepTimerState: sleepTimer,
                backgroundPlaybackEnabled: backgroundEnabled,
                startedAt: currentPlaybackSession?.startedAt ?? now,
                updatedAt: now
            )
            pushRecentReference(surahId: surah.id, ayahNumber: ayah)
        } else if let resumeState {
            currentPlaybackSession = QuranPlaybackSession(
                surahId: resumeState.surahID,
                ayahId: resumeState.ayahNumber,
                reciterId: resumeState.reciterID,
                progressInAyah: resumeState.progress,
                isPlaying: playbackState.isActive,
                autoAdvance: autoAdvance,
                repeatMode: repeatMode,
                sleepTimerState: sleepTimer,
                backgroundPlaybackEnabled: backgroundEnabled,
                startedAt: currentPlaybackSession?.startedAt,
                updatedAt: now
            )
        } else if playbackState == .idle || playbackState == .stopped || playbackState == .failed {
            currentPlaybackSession = currentPlaybackSession.map {
                var copy = $0
                copy.isPlaying = false
                copy.updatedAt = now
                return copy
            }
        }

        persist()
    }

    private func pushRecentReference(surahId: Int, ayahNumber: Int) {
        let newReference = QuranRecentReference(
            surahId: surahId,
            ayahNumber: ayahNumber,
            lastOpenedAt: Date()
        )

        recentReferences.removeAll { $0.surahId == surahId && $0.ayahNumber == ayahNumber }
        recentReferences.insert(newReference, at: 0)
        recentReferences = Array(recentReferences.prefix(8))
    }

    private func persist() {
        Self.store(currentReadingSession, to: defaults, key: readingKey)
        Self.store(currentPlaybackSession, to: defaults, key: playbackKey)
        Self.store(recentReferences, to: defaults, key: recentKey)
    }

    private static func load<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func store<T: Encodable>(_ value: T?, to defaults: UserDefaults, key: String) {
        guard let value, let data = try? JSONEncoder().encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }
}
