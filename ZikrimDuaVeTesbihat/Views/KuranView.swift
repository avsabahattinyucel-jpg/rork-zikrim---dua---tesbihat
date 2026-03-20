import SwiftUI

struct KuranView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var ayahAudioPlayerService: AyahAudioPlayerService

    let storage: StorageService
    let authService: AuthService

    @State private var quranService = QuranService()
    @StateObject private var readingSystemStore = QuranReadingSystemStore()
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var navigationPath = NavigationPath()
    @State private var filteredSurahResults: [QuranSurah] = QuranSurahData.surahs
    @State private var localVerseSearchResults: [VerifiedQuranHit] = []
    @State private var searchDebounceTask: Task<Void, Never>?

    private var theme: ActiveTheme { themeManager.current }
    private var trimmedQuery: String { debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var layoutDirection: LayoutDirection {
        switch AppLanguage.current {
        case .ar, .fa, .ur:
            return .rightToLeft
        default:
            return .leftToRight
        }
    }

    private var activePlaybackRoute: QuranReadingRoute {
        readingSystemStore.continueListeningRoute(fallbackSurahId: currentResumeSurah?.id ?? 1)
    }

    private var activeReadingRoute: QuranReadingRoute {
        readingSystemStore.currentReadingRoute(fallbackSurahId: currentResumeSurah?.id ?? 1)
    }

    private var listeningControlsRoute: QuranAudioControlRoute {
        readingSystemStore.listeningControlRoute(fallbackSurahId: currentResumeSurah?.id ?? 1)
    }

    private var currentResumeSurah: QuranSurah? {
        if let playback = readingSystemStore.currentPlaybackSession {
            return QuranSurahData.surahs.first(where: { $0.id == playback.surahId })
        }

        if let reading = readingSystemStore.currentReadingSession {
            return QuranSurahData.surahs.first(where: { $0.id == reading.surahId })
        }

        if let lastRead = quranService.lastReadPosition {
            return QuranSurahData.surahs.first(where: { $0.id == lastRead.surahId })
        }

        return QuranSurahData.surahs.first
    }

    var body: some View {
        ThemedScreen {
            NavigationStack(path: $navigationPath) {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        QuranSearchBar(
                            text: $searchText,
                            theme: theme,
                            onClear: clearSearch
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 10)

                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 20) {
                                if trimmedQuery.isEmpty {
                                    QuranResumeHeroCard(
                                        theme: theme,
                                        surah: currentResumeSurah,
                                        readingSession: readingSystemStore.currentReadingSession,
                                        playbackSession: readingSystemStore.currentPlaybackSession,
                                        reciterName: currentReciterName,
                                        onContinue: openContinueReading,
                                        onListen: openContinueListening,
                                        onMushaf: openMushafMode
                                    )

                                    if let playback = readingSystemStore.currentPlaybackSession,
                                       let surah = QuranSurahData.surahs.first(where: { $0.id == playback.surahId }) {
                                        CurrentPlaybackCard(
                                            theme: theme,
                                            surah: surah,
                                            playbackSession: playback,
                                            reciterName: currentReciterName,
                                            isPlaying: ayahAudioPlayerService.playbackState.isActivelyPlaying,
                                            onOpenContext: openContinueListening,
                                            onOpenControls: openListeningControls
                                        )
                                    }

                                    quickAccessSection(proxy: proxy)
                                    progressSection
                                }

                                if !trimmedQuery.isEmpty && !localVerseSearchResults.isEmpty {
                                    localMatchesSection
                                }

                                surahSection
                                    .id(QuranHomeAnchor.surahList.rawValue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .padding(.bottom, 120)
                        }
                        .background {
                            QuranLandingBackdrop(theme: theme)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .environment(\.layoutDirection, layoutDirection)
                    .navigationTitle(L10n.string(.kurAnIKerim))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(theme.navBarBackground, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
                    .navigationDestination(for: QuranNavDestination.self) { destination in
                        switch destination {
                        case let .reader(route):
                            SurahDetailView(
                                route: route,
                                quranService: quranService,
                                storage: storage,
                                readingSystemStore: readingSystemStore
                            )
                        case .bookmarks:
                            QuranBookmarksView(
                                quranService: quranService,
                                notes: QuranStoredNotesProvider().loadNotes(),
                                onNavigate: { surahId, ayahNumber in
                                    navigationPath.append(QuranNavDestination.reader(QuranReadingRoute(surahId: surahId, ayahNumber: ayahNumber)))
                                }
                            )
                        case .juzs:
                            QuranJuzListView(
                                currentReadingSession: readingSystemStore.currentReadingSession ?? makeFallbackReadingSession(),
                                onSelect: { surahId, ayahNumber in
                                    navigationPath.append(QuranNavDestination.reader(QuranReadingRoute(surahId: surahId, ayahNumber: ayahNumber)))
                                }
                            )
                        case let .audioControls(route):
                            QuranAudioHubView(route: route) {
                                navigationPath.append(QuranNavDestination.reader(activePlaybackRoute))
                            }
                            .environmentObject(ayahAudioPlayerService)
                        }
                    }
                    .onChange(of: searchText) { _, newValue in
                        searchDebounceTask?.cancel()
                        searchDebounceTask = Task {
                            try? await Task.sleep(for: .milliseconds(220))
                            guard !Task.isCancelled else { return }
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            await MainActor.run {
                                debouncedSearchText = trimmed
                                updateLocalSearchResults(for: trimmed)
                            }
                        }
                    }
                    .task {
                        readingSystemStore.bootstrapIfNeeded(lastRead: quranService.lastReadPosition)
                        readingSystemStore.bindAudioService(ayahAudioPlayerService)
                        updateLocalSearchResults(for: "")
                        handlePendingNavigationRequest()
                    }
                    .onDisappear {
                        searchDebounceTask?.cancel()
                    }
                    .onChange(of: appState.quranNavigationRequest?.id) { _, _ in
                        handlePendingNavigationRequest()
                    }
                }
            }
        }
        .id(themeManager.navigationRefreshID)
    }

    private var currentReciterName: String? {
        if let playback = readingSystemStore.currentPlaybackSession {
            return ReciterRegistry.reciter(withID: playback.reciterId)?.localizedDisplayName
        }

        if let reading = readingSystemStore.currentReadingSession,
           let reciterId = reading.lastReciterID {
            return ReciterRegistry.reciter(withID: reciterId)?.localizedDisplayName
        }

        return nil
    }

    private func quickAccessSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            QuranSectionTitle(
                title: homeCopy.quickAccessTitle,
                subtitle: homeCopy.quickAccessSubtitle,
                theme: theme
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                QuranQuickAccessCard(
                    title: homeCopy.surahsTitle,
                    subtitle: homeCopy.surahsSubtitle,
                    systemImage: "text.line.first.and.arrowtriangle.forward",
                    theme: theme
                ) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        proxy.scrollTo(QuranHomeAnchor.surahList.rawValue, anchor: .top)
                    }
                }

                QuranQuickAccessCard(
                    title: homeCopy.juzsTitle,
                    subtitle: homeCopy.juzsSubtitle,
                    systemImage: "square.grid.2x2",
                    theme: theme
                ) {
                    navigationPath.append(QuranNavDestination.juzs)
                }

                QuranQuickAccessCard(
                    title: homeCopy.bookmarksTitle,
                    subtitle: quranService.bookmarks.isEmpty ? homeCopy.noBookmarksSubtitle : "\(quranService.bookmarks.count)",
                    systemImage: "bookmark",
                    theme: theme
                ) {
                    navigationPath.append(QuranNavDestination.bookmarks)
                }

                QuranQuickAccessCard(
                    title: homeCopy.audioTitle,
                    subtitle: readingSystemStore.currentPlaybackSession == nil ? homeCopy.audioReadySubtitle : homeCopy.audioLiveSubtitle,
                    systemImage: "waveform",
                    theme: theme
                ) {
                    openListeningControls()
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuranSectionTitle(
                title: homeCopy.progressTitle,
                subtitle: homeCopy.progressSubtitle,
                theme: theme
            )

            HStack(spacing: 12) {
                StatMiniCard(
                    theme: theme,
                    title: homeCopy.lastAyahTitle,
                    value: lastAyahValue,
                    subtitle: currentResumeSurah?.localizedTurkishName ?? homeCopy.beginningLabel
                )

                StatMiniCard(
                    theme: theme,
                    title: homeCopy.reciterTitle,
                    value: currentReciterName ?? "Alafasy",
                    subtitle: homeCopy.listeningLabel
                )
            }
        }
    }

    private var localMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuranSectionTitle(title: L10n.string(.ayetlerdeEslesmeler), subtitle: homeCopy.searchResultsSubtitle, theme: theme)

            ForEach(localVerseSearchResults, id: \.verseID) { hit in
                Button {
                    navigationPath.append(QuranNavDestination.reader(QuranReadingRoute(surahId: hit.surahId, ayahNumber: hit.verseNumber)))
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "quote.opening")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.accent)
                                .frame(width: 34, height: 34)
                                .background(theme.accent.opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.format(.surahVerseFormat, hit.surahName, hit.verseNumber))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(theme.textPrimary)

                                Text(hit.localizedTranslation)
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                                    .lineLimit(3)
                            }

                            Spacer(minLength: 10)

                            Image(systemName: layoutDirection == .rightToLeft ? "arrow.up.left" : "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .padding(18)
                    .quranSurfaceCard(theme, cornerRadius: 24)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var surahSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuranSectionTitle(
                title: L10n.string(.sureler),
                subtitle: trimmedQuery.isEmpty ? homeCopy.surahListSubtitle : homeCopy.searchResultsSubtitle,
                theme: theme
            )

            ForEach(filteredSurahResults) { surah in
                NavigationLink(value: QuranNavDestination.reader(QuranReadingRoute(surahId: surah.id, ayahNumber: nil))) {
                    SurahRow(surah: surah, theme: theme, layoutDirection: layoutDirection)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var lastAyahValue: String {
        if let ayah = readingSystemStore.currentPlaybackSession?.ayahId {
            return "\(ayah)"
        }
        if let ayah = readingSystemStore.currentReadingSession?.ayahId {
            return "\(ayah)"
        }
        return "1"
    }

    private var homeCopy: QuranLandingCopy {
        QuranLandingCopy(language: AppLanguage.current)
    }

    private func clearSearch() {
        searchText = ""
        debouncedSearchText = ""
        updateLocalSearchResults(for: "")
    }

    private func updateLocalSearchResults(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            filteredSurahResults = QuranSurahData.surahs
            localVerseSearchResults = []
            return
        }

        let matchingByName = QuranSurahData.surahs.filter {
            $0.localizedTurkishName.localizedStandardContains(trimmed) ||
            $0.turkishName.localizedStandardContains(trimmed) ||
            $0.arabicName.contains(trimmed) ||
            "\($0.id)".contains(trimmed)
        }

        let matchingByMeal = QuranSurahData.offlineVerses
            .lazy
            .filter { _, verses in
                verses.contains {
                    $0.localizedTranslation.localizedStandardContains(trimmed) ||
                    $0.arabicText.contains(trimmed) ||
                    "\($0.verseNumber)".contains(trimmed)
                }
            }
            .compactMap { surahId, _ in
                QuranSurahData.surahs.first(where: { $0.id == surahId })
            }

        filteredSurahResults = Array(Set(matchingByName + matchingByMeal)).sorted(by: { $0.id < $1.id })
        localVerseSearchResults = RabiaVerifiedSourceStore.shared.searchQuran(query: trimmed, limit: 12)
    }

    private func openContinueReading() {
        navigationPath.append(QuranNavDestination.reader(activeReadingRoute))
    }

    private func openContinueListening() {
        navigationPath.append(QuranNavDestination.reader(activePlaybackRoute))
    }

    private func openListeningControls() {
        navigationPath.append(QuranNavDestination.audioControls(listeningControlsRoute))
    }

    private func openMushafMode() {
        var route = activeReadingRoute
        route = QuranReadingRoute(
            surahId: route.surahId,
            ayahNumber: route.ayahNumber,
            shouldResumePlayback: false,
            shouldOpenListeningControls: false,
            preferredReciterID: route.preferredReciterID,
            preferredAppearance: .mushaf
        )
        navigationPath.append(QuranNavDestination.reader(route))
    }

    private func handlePendingNavigationRequest() {
        guard let request = appState.quranNavigationRequest else { return }

        switch request.destination {
        case .reader(let route):
            navigationPath = NavigationPath()
            navigationPath.append(QuranNavDestination.reader(route))
        }

        appState.consumeQuranNavigationRequest(request.id)
    }

    private func makeFallbackReadingSession() -> QuranReadingSession {
        QuranReadingSession(
            surahId: currentResumeSurah?.id ?? 1,
            ayahId: readingSystemStore.currentReadingSession?.ayahId ?? 1,
            isTranslationVisible: true,
            selectedTafsirSourceID: QuranTafsirSource.zikrimShortExplanation.id,
            readingAppearancePreset: .standardDark,
            arabicFontScale: QuranReaderPreferences.default.arabicFontSize,
            translationFontScale: QuranReaderPreferences.default.translationFontSize,
            lineSpacing: QuranReaderPreferences.default.translationLineSpacing,
            lastReciterID: readingSystemStore.currentPlaybackSession?.reciterId ?? readingSystemStore.currentReadingSession?.lastReciterID,
            lastOpenedAt: Date()
        )
    }
}

private struct QuranArchOrnament: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.15)
        )
        path.closeSubpath()
        return path
    }
}

private enum QuranHomeAnchor: String {
    case surahList
}

enum QuranNavDestination: Hashable {
    case reader(QuranReadingRoute)
    case bookmarks
    case juzs
    case audioControls(QuranAudioControlRoute)
}

private struct QuranSearchBar: View {
    @Binding var text: String
    let theme: ActiveTheme
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.textSecondary)

            TextField("", text: $text, prompt: Text(AppLanguage.current == .tr ? "Sure, ayet veya meal ara" : "Search surah, ayah, translation").foregroundStyle(theme.textSecondary))
                .foregroundStyle(theme.textPrimary)

            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.backgroundSecondary.opacity(theme.isDarkMode ? 0.88 : 0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.border.opacity(0.26), lineWidth: 1)
        )
    }
}

private struct QuranSectionTitle: View {
    let title: String
    let subtitle: String?
    let theme: ActiveTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                    .tracking(0.8)
            }

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 2)
    }
}

private struct QuranResumeHeroCard: View {
    let theme: ActiveTheme
    let surah: QuranSurah?
    let readingSession: QuranReadingSession?
    let playbackSession: QuranPlaybackSession?
    let reciterName: String?
    let onContinue: () -> Void
    let onListen: () -> Void
    let onMushaf: () -> Void

    private var currentAyah: Int {
        playbackSession?.ayahId ?? readingSession?.ayahId ?? 1
    }

    private var subtitle: String {
        var parts: [String] = [
            L10n.format(.quranAudioVerseFormat, Int64(currentAyah))
        ]

        if let reciterName {
            parts.append(reciterName)
        }

        if let lastOpened = readingSession?.lastOpenedAt {
            parts.append(lastOpened.formatted(date: .abbreviated, time: .shortened))
        }

        return parts.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLanguage.current == .tr ? "Kaldığın yer" : "Continue Reading")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .tracking(0.9)

                    Text(surah?.localizedTurkishName ?? L10n.string(.kurAnIKerim))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                Text(surah?.arabicName ?? "القرآن الكريم")
                    .font(QuranFontResolver.arabicFont(for: .classicMushaf, size: 30, relativeTo: .title2))
                    .foregroundStyle(.white.opacity(0.94))
                    .environment(\.layoutDirection, .rightToLeft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            HStack(spacing: 10) {
                Button(action: onContinue) {
                    Text(AppLanguage.current == .tr ? "Devam Et" : "Continue")
                        .font(.headline)
                        .foregroundStyle(theme.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.white.opacity(0.95), in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onListen) {
                    Label(AppLanguage.current == .tr ? "Dinleyerek Devam Et" : "Continue with Audio", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(.white.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button(action: onMushaf) {
                Text(AppLanguage.current == .tr ? "Mushaf Modunda Aç" : "Open in Mushaf Mode")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.26, blue: 0.46),
                            Color(red: 0.07, green: 0.44, blue: 0.48),
                            theme.backgroundSecondary.opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    QuranArchOrnament()
                        .fill(.white.opacity(0.08))
                        .frame(width: 190, height: 190)
                        .padding(.top, -24)
                        .padding(.trailing, -18)
                }
                .overlay {
                    QuranGeometricPattern(color: .white.opacity(0.07), lineOpacity: 0.45, tileSize: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.17, green: 0.52, blue: 0.65).opacity(0.24), radius: 26, y: 16)
    }
}

private struct CurrentPlaybackCard: View {
    let theme: ActiveTheme
    let surah: QuranSurah
    let playbackSession: QuranPlaybackSession
    let reciterName: String?
    let isPlaying: Bool
    let onOpenContext: () -> Void
    let onOpenControls: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(AppLanguage.current == .tr ? "Şimdi çalan" : "Now playing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                Text(isPlaying ? (AppLanguage.current == .tr ? "Canlı" : "Live") : (AppLanguage.current == .tr ? "Duraklatıldı" : "Paused"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
            }

            Text(surah.localizedTurkishName)
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.textPrimary)

            Text("\(L10n.format(.quranAudioVerseFormat, Int64(playbackSession.ayahId))) • \(reciterName ?? "Alafasy")")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)

            ProgressView(value: playbackSession.progressInAyah)
                .tint(theme.accent)

            HStack(spacing: 10) {
                actionButton(title: AppLanguage.current == .tr ? "Ayet'e Dön" : "Open Ayah", theme: theme, filled: true, action: onOpenContext)
                actionButton(title: AppLanguage.current == .tr ? "Dinleme" : "Listening", theme: theme, filled: false, action: onOpenControls)
            }
        }
        .padding(18)
        .quranSurfaceCard(theme, cornerRadius: 26)
    }

    private func actionButton(title: String, theme: ActiveTheme, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(filled ? theme.backgroundPrimary : theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    (filled ? Color.white.opacity(0.94) : theme.accent.opacity(0.10)),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct QuranQuickAccessCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let theme: ActiveTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 38, height: 38)
                    .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
            .padding(16)
            .quranSurfaceCard(theme, cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }
}

private struct QuranRecentActivityCard: View {
    let theme: ActiveTheme
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 48, height: 48)
                    .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.textSecondary)
                        .tracking(0.7)

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                Text(actionTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.accent.opacity(0.10), in: Capsule())
            }
            .padding(18)
            .quranSurfaceCard(theme, cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }
}

private struct StatMiniCard: View {
    let theme: ActiveTheme
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .padding(16)
        .quranSurfaceCard(theme, cornerRadius: 22)
    }
}

private struct SurahRow: View {
    let surah: QuranSurah
    let theme: ActiveTheme
    let layoutDirection: LayoutDirection

    var body: some View {
        HStack(spacing: 16) {
            Text(L10n.format(.numberFormat, Int64(surah.id)))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.quranBadgeText)
                .frame(width: 42, height: 42)
                .background(theme.palette.quranBadgeBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(surah.localizedTurkishName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)

                    Text(surah.arabicName)
                        .font(QuranFontResolver.arabicFont(for: .traditionalNaskh, size: 24, relativeTo: .title3))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text("\(surah.localizedRevelationType) • \(L10n.format(.verseCount, surah.totalVerses))")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(theme.cardBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(0.32), lineWidth: 1)
        )
    }
}

private struct QuranLandingBackdrop: View {
    let theme: ActiveTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundPrimary,
                    theme.backgroundSecondary.opacity(theme.isDarkMode ? 0.96 : 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            QuranGeometricPattern(
                color: theme.textPrimary.opacity(theme.isDarkMode ? 0.022 : 0.018),
                lineOpacity: theme.isDarkMode ? 0.44 : 0.34,
                tileSize: 58
            )
        }
    }
}

private struct QuranGeometricPattern: View {
    let color: Color
    let lineOpacity: Double
    var tileSize: CGFloat = 40

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let stroke = StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
                let columns = Int(ceil(size.width / tileSize)) + 1
                let rows = Int(ceil(size.height / tileSize)) + 1

                for row in 0...rows {
                    for column in 0...columns {
                        let origin = CGPoint(x: CGFloat(column) * tileSize, y: CGFloat(row) * tileSize)
                        var diamond = Path()
                        diamond.move(to: CGPoint(x: origin.x + tileSize * 0.5, y: origin.y))
                        diamond.addLine(to: CGPoint(x: origin.x + tileSize, y: origin.y + tileSize * 0.5))
                        diamond.addLine(to: CGPoint(x: origin.x + tileSize * 0.5, y: origin.y + tileSize))
                        diamond.addLine(to: CGPoint(x: origin.x, y: origin.y + tileSize * 0.5))
                        diamond.closeSubpath()

                        context.stroke(diamond, with: .color(color.opacity(lineOpacity)), style: stroke)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct QuranJuzListView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let currentReadingSession: QuranReadingSession
    let onSelect: (Int, Int) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let currentJuz = QuranJuzReference.current(for: currentReadingSession) {
                    QuranRecentActivityCard(
                        theme: theme,
                        eyebrow: AppLanguage.current == .tr ? "Kaldığın cüz" : "Current juz",
                        title: currentJuz.localizedTitle,
                        subtitle: currentJuz.localizedReference,
                        systemImage: "circle.grid.2x1.fill",
                        actionTitle: AppLanguage.current == .tr ? "Devam Et" : "Continue"
                    ) {
                        onSelect(currentJuz.surahId, currentJuz.ayahNumber)
                    }
                }

                LazyVStack(spacing: 12) {
                    ForEach(QuranJuzReference.allCases) { juz in
                        JuzRowCard(
                            theme: theme,
                            juz: juz,
                            status: juz.status(for: currentReadingSession)
                        ) {
                            onSelect(juz.surahId, juz.ayahNumber)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .appScreenBackground(theme)
        .navigationTitle(AppLanguage.current == .tr ? "Cüzler" : "Juzs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.navBarBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
    }
}

private struct JuzRowCard: View {
    let theme: ActiveTheme
    let juz: QuranJuzReference
    let status: QuranJuzStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(status.tint.opacity(0.24), lineWidth: 6)
                        .frame(width: 42, height: 42)

                    Circle()
                        .trim(from: 0, to: status.ringProgress)
                        .stroke(status.tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 42, height: 42)

                    Text("\(juz.id)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(status.tint)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(juz.localizedTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    Text(juz.localizedReference)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)

                    Text(status.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(status.tint)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(18)
            .quranSurfaceCard(theme, cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }
}

private enum QuranJuzStatus {
    case notStarted
    case inProgress
    case completed

    var ringProgress: CGFloat {
        switch self {
        case .notStarted: return 0.18
        case .inProgress: return 0.58
        case .completed: return 1
        }
    }

    var tint: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return Color(red: 0.33, green: 0.75, blue: 0.80)
        case .completed: return Color(red: 0.40, green: 0.84, blue: 0.56)
        }
    }

    var label: String {
        switch self {
        case .notStarted:
            return AppLanguage.current == .tr ? "Başlanmadı" : "Not started"
        case .inProgress:
            return AppLanguage.current == .tr ? "Devam ediyor" : "In progress"
        case .completed:
            return AppLanguage.current == .tr ? "Tamamlandı" : "Completed"
        }
    }
}

private enum QuranJuzReference: Int, CaseIterable, Identifiable {
    case one = 1, two, three, four, five, six, seven, eight, nine, ten
    case eleven, twelve, thirteen, fourteen, fifteen, sixteen, seventeen, eighteen, nineteen, twenty
    case twentyOne, twentyTwo, twentyThree, twentyFour, twentyFive, twentySix, twentySeven, twentyEight, twentyNine, thirty

    var id: Int { rawValue }

    var surahId: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        case .three: return 2
        case .four: return 3
        case .five: return 4
        case .six: return 4
        case .seven: return 5
        case .eight: return 6
        case .nine: return 7
        case .ten: return 8
        case .eleven: return 9
        case .twelve: return 11
        case .thirteen: return 12
        case .fourteen: return 15
        case .fifteen: return 17
        case .sixteen: return 18
        case .seventeen: return 21
        case .eighteen: return 23
        case .nineteen: return 25
        case .twenty: return 27
        case .twentyOne: return 29
        case .twentyTwo: return 33
        case .twentyThree: return 36
        case .twentyFour: return 39
        case .twentyFive: return 41
        case .twentySix: return 46
        case .twentySeven: return 51
        case .twentyEight: return 58
        case .twentyNine: return 67
        case .thirty: return 78
        }
    }

    var ayahNumber: Int {
        switch self {
        case .one: return 1
        case .two: return 142
        case .three: return 253
        case .four: return 93
        case .five: return 24
        case .six: return 148
        case .seven: return 82
        case .eight: return 111
        case .nine: return 88
        case .ten: return 41
        case .eleven: return 93
        case .twelve: return 6
        case .thirteen: return 53
        case .fourteen: return 1
        case .fifteen: return 1
        case .sixteen: return 75
        case .seventeen: return 1
        case .eighteen: return 1
        case .nineteen: return 21
        case .twenty: return 56
        case .twentyOne: return 46
        case .twentyTwo: return 31
        case .twentyThree: return 28
        case .twentyFour: return 32
        case .twentyFive: return 47
        case .twentySix: return 1
        case .twentySeven: return 31
        case .twentyEight: return 1
        case .twentyNine: return 1
        case .thirty: return 1
        }
    }

    var localizedTitle: String {
        AppLanguage.current == .tr ? "Cüz \(rawValue)" : "Juz \(rawValue)"
    }

    var localizedReference: String {
        let surahName = QuranSurahData.surahs.first(where: { $0.id == surahId })?.localizedTurkishName ?? ""
        return "\(surahName) • \(L10n.format(.quranAudioVerseFormat, Int64(ayahNumber)))"
    }

    func status(for session: QuranReadingSession) -> QuranJuzStatus {
        let current = Self.current(for: session)
        guard let current else { return .notStarted }
        if current.id > id { return .completed }
        if current.id == id { return .inProgress }
        return .notStarted
    }

    static func current(for session: QuranReadingSession) -> QuranJuzReference? {
        allCases.last(where: {
            $0.surahId < session.surahId || ($0.surahId == session.surahId && $0.ayahNumber <= session.ayahId)
        })
    }
}

private struct QuranAudioHubView: View {
    @EnvironmentObject private var playerService: AyahAudioPlayerService

    let route: QuranAudioControlRoute
    let onOpenCurrentContext: () -> Void

    @StateObject private var audioController: QuranAudioReaderViewModel

    init(route: QuranAudioControlRoute, onOpenCurrentContext: @escaping () -> Void) {
        self.route = route
        self.onOpenCurrentContext = onOpenCurrentContext
        _audioController = StateObject(wrappedValue: QuranAudioReaderViewModel(surahID: route.surahId))
    }

    var body: some View {
        QuranAudioExperienceScreen(audioController: audioController, onOpenCurrentContext: onOpenCurrentContext)
            .task {
                audioController.bindIfNeeded(to: playerService)
                audioController.prepare()
            }
    }
}

struct QuranBookmarksView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let quranService: QuranService
    let notes: [QuranVerseNote]
    let onNavigate: (Int, Int) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !notes.isEmpty {
                    QuranSectionTitle(
                        title: AppLanguage.current == .tr ? "Notlar" : "Notes",
                        subtitle: AppLanguage.current == .tr ? "Kişisel tefekkürlerin" : "Your personal reflections",
                        theme: theme
                    )

                    ForEach(notes.sorted(by: { $0.updatedAt > $1.updatedAt })) { note in
                        Button {
                            onNavigate(note.surahId, note.verseNumber)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(note.surahName) • \(L10n.format(.quranAudioVerseFormat, Int64(note.verseNumber)))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.textPrimary)

                                Text(note.noteText)
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                                    .lineLimit(2)
                            }
                            .padding(18)
                            .quranSurfaceCard(theme, cornerRadius: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }

                QuranSectionTitle(
                    title: L10n.string(.yerImlerim),
                    subtitle: AppLanguage.current == .tr ? "Kaydettiğin ayetler" : "Saved ayahs",
                    theme: theme
                )

                if quranService.bookmarks.isEmpty {
                    ContentUnavailableView(
                        L10n.string(.yerImiYok),
                        systemImage: "bookmark.slash",
                        description: Text(.ayetEkranindaYerImiEkleyebilirsiniz)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(quranService.bookmarks.sorted(by: { $0.addedAt > $1.addedAt })) { bookmark in
                        Button {
                            onNavigate(bookmark.surahId, bookmark.verseNumber)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(theme.accent)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(QuranSurahData.surahs.first(where: { $0.id == bookmark.surahId })?.localizedTurkishName ?? bookmark.surahName)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(theme.textPrimary)
                                    Text(L10n.format(.verseNumberLabel, bookmark.verseNumber))
                                        .font(.caption)
                                        .foregroundStyle(theme.textSecondary)
                                }

                                Spacer()

                                Text(QuranSurahData.surahs.first(where: { $0.id == bookmark.surahId })?.arabicName ?? "")
                                    .font(.system(size: 16))
                                    .foregroundStyle(theme.textSecondary)
                            }
                            .padding(18)
                            .quranSurfaceCard(theme, cornerRadius: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .appScreenBackground(theme)
        .navigationTitle(L10n.string(.yerImlerim))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.navBarBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
    }
}

private struct QuranStoredNotesProvider {
    private let defaults: UserDefaults = .standard
    private let key = "quran_reader_verse_notes"

    func loadNotes() -> [QuranVerseNote] {
        guard let data = defaults.data(forKey: key),
              let notes = try? JSONDecoder().decode([String: QuranVerseNote].self, from: data) else {
            return []
        }

        return Array(notes.values)
    }
}

private struct QuranLandingCopy {
    let language: AppLanguage

    var continueButtonTitle: String { language == .tr ? "Devam Et" : "Continue" }
    var quickAccessTitle: String { language == .tr ? "Hızlı erişim" : "Quick access" }
    var quickAccessSubtitle: String { language == .tr ? "Kutsal kütüphanendeki ana yollar" : "Core paths in your sacred library" }
    var surahsTitle: String { language == .tr ? "Sureler" : "Surahs" }
    var surahsSubtitle: String { language == .tr ? "Tüm sure listesi" : "Browse all surahs" }
    var juzsTitle: String { language == .tr ? "Cüzler" : "Juzs" }
    var juzsSubtitle: String { language == .tr ? "Durum ve başlangıç bilgileriyle" : "With progress and starting references" }
    var bookmarksTitle: String { language == .tr ? "Yer İmleri" : "Bookmarks" }
    var noBookmarksSubtitle: String { language == .tr ? "Henüz kayıt yok" : "No saved ayahs yet" }
    var audioTitle: String { language == .tr ? "Dinleme" : "Listening" }
    var audioReadySubtitle: String { language == .tr ? "Ayarları aç" : "Open listening setup" }
    var audioLiveSubtitle: String { language == .tr ? "Şimdi çalan bağlama git" : "Open current recitation" }
    var recentTitle: String { language == .tr ? "Son açılanlar" : "Recently opened" }
    var recentSubtitle: String { language == .tr ? "Kaldığın akışı kaybetmeden devam et" : "Resume your latest reading contexts" }
    var lastReadTitle: String { language == .tr ? "Son okunan" : "Last opened" }
    var surahListSubtitle: String { language == .tr ? "Sure veya ayet arayarak sakin bir şekilde devam et" : "Search and continue gently from any surah or ayah" }
    var searchResultsSubtitle: String { language == .tr ? "Aramana en yakın sonuçlar" : "Closest matches for your search" }
    var progressTitle: String { language == .tr ? "Bugünkü akış" : "Today's flow" }
    var progressSubtitle: String { language == .tr ? "Okuma ve dinleme sürekliliğin" : "Your reading and listening continuity" }
    var lastAyahTitle: String { language == .tr ? "Son ayet" : "Last ayah" }
    var reciterTitle: String { language == .tr ? "Okuyucu" : "Reciter" }
    var listeningLabel: String { language == .tr ? "Dinleme" : "Listening" }
    var beginningLabel: String { language == .tr ? "Başlangıç" : "Beginning" }
}
