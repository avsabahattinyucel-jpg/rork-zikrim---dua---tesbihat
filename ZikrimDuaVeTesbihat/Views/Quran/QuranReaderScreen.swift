import SwiftUI
import UIKit

struct QuranReaderScreen: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ObservedObject var viewModel: QuranReaderViewModel

    let scrollTarget: Int?
    let onShare: (QuranReaderVerseItem) -> Void
    let onOpenCurrentPlaybackContext: () -> Void

    @State private var hasScrolledToTarget = false
    @State private var isControlSheetPresented = false
    @State private var scrollOffset: CGFloat = 0
    @State private var mushafExitDragOffset: CGFloat = 0

    private var audioController: QuranAudioReaderViewModel {
        viewModel.audioController
    }

    private var theme: ActiveTheme { themeManager.current }
    private var style: QuranReaderCanvasStyle {
        QuranReaderAppearanceEngine.style(for: viewModel.preferences.appearance, theme: theme)
    }

    private var shouldHideChrome: Bool {
        viewModel.preferences.layoutMode == .mushafFocused && viewModel.preferences.autoHideChromeInMushafFocusedMode
    }

    private var collapseProgress: CGFloat {
        min(max((-scrollOffset - 12) / 130, 0), 1)
    }

    private var layoutDirection: LayoutDirection {
        switch AppLanguage.current {
        case .ar, .fa, .ur:
            return .rightToLeft
        default:
            return .leftToRight
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                content(proxy: proxy)

                if viewModel.surah != nil {
                    CompactSurahHeader(
                        surah: viewModel.surah,
                        style: style,
                        translationSourceName: viewModel.translationSourceName,
                        isVisible: collapseProgress > 0.55
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .opacity(collapseProgress > 0.55 ? 1 : 0)
                    .animation(animation, value: collapseProgress)
                }
            }
            .background(readerBackdrop.ignoresSafeArea())
            .overlay(alignment: layoutDirection == .rightToLeft ? .topTrailing : .topLeading) {
                if viewModel.isMushafMode {
                    mushafExitButton
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .opacity(shouldHideChrome ? 0.92 : 0)
                        .offset(x: layoutDirection == .rightToLeft ? -min(mushafExitDragOffset, 0) * 0.18 : max(mushafExitDragOffset, 0) * 0.18)
                        .animation(animation, value: shouldHideChrome)
                }
            }
            .toolbar(shouldHideChrome ? .hidden : .visible, for: .navigationBar)
            .toolbar(shouldHideChrome ? .hidden : .visible, for: .tabBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isControlSheetPresented = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel(QuranReaderStrings.openAppearance)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .trailing, spacing: 12) {
                    if audioController.shouldShowMiniPlayer {
                        QuranReaderMiniPlayerCard(
                            audioController: audioController,
                            style: style,
                            onOpen: onOpenCurrentPlaybackContext
                        )
                        .padding(.horizontal, 16)
                    }

                    if shouldHideChrome {
                        Button {
                            isControlSheetPresented = true
                        } label: {
                            Label(readerCopy.quickSettings, systemImage: "slider.horizontal.3")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(style.chipForeground)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(style.audioSurface, in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(style.audioBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 10)
            }
            .overlay(alignment: .top) {
                if let banner = viewModel.bannerMessage {
                    Text(banner)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(style.audioSurface, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(style.audioBorder, lineWidth: 1)
                        )
                        .padding(.top, collapseProgress > 0.55 ? 64 : 14)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(item: $viewModel.presentedTafsir) { presented in
                QuranTafsirDetailView(presented: presented)
            }
            .sheet(item: $viewModel.presentedVerseNoteEditor) { editor in
                QuranVerseNoteSheet(
                    editor: editor,
                    style: style,
                    onSave: { viewModel.saveVerseNote($0, for: editor) },
                    onDelete: { viewModel.deleteVerseNote(for: editor) }
                )
                .environmentObject(themeManager)
            }
            .sheet(isPresented: $isControlSheetPresented) {
                QuranReaderControlSheet(viewModel: viewModel, audioController: audioController, style: style)
                    .environmentObject(themeManager)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                audioController.prepare()
                if viewModel.surah == nil && viewModel.verseItems.isEmpty {
                    await viewModel.load()
                }
                scrollIfNeeded(using: proxy)
            }
            .onChange(of: viewModel.verseItems.count) { _, _ in
                scrollIfNeeded(using: proxy)
            }
            .onChange(of: audioController.nowPlayingAyah) { _, ayah in
                guard audioController.nowPlayingSurah?.id == viewModel.surahID, let ayah else { return }
                withAnimation(animation) {
                    proxy.scrollTo(ayah, anchor: .center)
                }
            }
            .onChange(of: viewModel.bannerMessage) { _, newValue in
                guard newValue != nil else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.6))
                    withAnimation(animation) {
                        viewModel.bannerMessage = nil
                    }
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = viewModel.preferences.keepScreenAwake
            }
            .onChange(of: viewModel.preferences.keepScreenAwake) { _, isEnabled in
                UIApplication.shared.isIdleTimerDisabled = isEnabled
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .simultaneousGesture(mushafExitGesture)
        }
    }

    @ViewBuilder
    private func content(proxy: ScrollViewProxy) -> some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(style.chipForeground)
                Text(QuranReaderStrings.loading)
                    .foregroundStyle(style.translationText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage, viewModel.verseItems.isEmpty {
            ContentUnavailableView(QuranReaderStrings.title, systemImage: "wifi.exclamationmark", description: Text(error))
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: viewModel.preferences.compactMode ? 14 : 20) {
                    ReaderOffsetReader()
                        .frame(height: 0)

                    SurahHeaderHero(
                        surah: viewModel.surah,
                        style: style,
                        translationSourceName: viewModel.translationSourceName,
                        readingAppearance: viewModel.preferences.appearance,
                        isTranslationVisible: viewModel.isTranslationVisible,
                        collapseProgress: collapseProgress
                    )

                    LazyVStack(spacing: viewModel.preferences.compactMode ? 12 : 16) {
                        ForEach(viewModel.verseModeItems) { verseMode in
                            verseBlock(for: verseMode.item)
                        }
                    }
                }
                .padding(.horizontal, viewModel.preferences.layoutMode == .mushafFocused ? 14 : 16)
                .padding(.top, viewModel.preferences.layoutMode == .mushafFocused ? 12 : 18)
                .padding(.bottom, 20)
                .environment(\.layoutDirection, layoutDirection)
                .onPreferenceChange(ReaderScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            .coordinateSpace(name: "quran_reader_scroll")
            .scrollIndicators(.hidden)
        }
    }

    private func verseBlock(for item: QuranReaderVerseItem) -> some View {
        let isPlaybackFocused = audioController.isCurrentAyah(item.verse.verseNumber)

        return QuranVerseBlockView(
            item: item,
            style: style,
            displayMode: viewModel.effectiveDisplayMode,
            preferences: viewModel.preferences,
            isCurrentAyah: isPlaybackFocused,
            activeWordRange: audioController.activeWordRange(for: item.verse.verseNumber),
            isPlaying: audioController.isPlayingAyah(item.verse.verseNumber),
            isLoading: audioController.isLoadingAyah(item.verse.verseNumber),
            isMushafFocused: viewModel.preferences.layoutMode == .mushafFocused,
            onPlay: { viewModel.playAyah(item) },
            onBookmark: { viewModel.toggleBookmark(for: item) },
            onShare: { onShare(item) },
            onCopy: { viewModel.copyVerse(item) },
            onNote: { viewModel.noteTapped(for: item) },
            onOpenTafsir: { viewModel.presentTafsir(for: item) },
            onAppear: {
                viewModel.markVisible(item)
                viewModel.loadShortExplanationIfNeeded(for: item)
            }
        )
        .id(item.verse.verseNumber)
    }

    private func scrollIfNeeded(using proxy: ScrollViewProxy) {
        guard !hasScrolledToTarget else { return }
        guard let target = viewModel.initialScrollTarget(explicitVerseNumber: scrollTarget) else { return }
        guard viewModel.verseItems.contains(where: { $0.verse.verseNumber == target }) else { return }

        hasScrolledToTarget = true
        DispatchQueue.main.async {
            withAnimation(animation) {
                proxy.scrollTo(target, anchor: .top)
            }
        }
    }

    private var animation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.25)
    }

    private var readerBackdrop: some View {
        ZStack {
            style.background

            LinearGradient(
                colors: [
                    style.heroGlow.opacity(0.18),
                    .clear,
                    style.selectionHighlight.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    style.heroGlow.opacity(0.20),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 260
            )

            RadialGradient(
                colors: [
                    style.chipBackground.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 260
            )
        }
    }

    private var readerCopy: QuranReaderCopy {
        QuranReaderCopy(language: AppLanguage.current)
    }


    private var mushafExitButton: some View {
        Button {
            withAnimation(animation) {
                viewModel.exitMushafModeToStandardReading()
            }
        } label: {
            Image(systemName: "chevron.backward")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.chipForeground)
                .frame(width: 34, height: 34)
                .background(style.audioSurface.opacity(0.94), in: Circle())
                .overlay(
                    Circle()
                        .stroke(style.audioBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppLanguage.current == .tr ? "Standart görünüme dön" : "Return to standard view")
    }

    private var mushafExitGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onChanged { value in
                guard viewModel.isMushafMode else { return }
                guard isBackSwipeTranslation(value.translation) else { return }
                mushafExitDragOffset = value.translation.width
            }
            .onEnded { value in
                guard viewModel.isMushafMode else {
                    mushafExitDragOffset = 0
                    return
                }

                defer {
                    withAnimation(animation) {
                        mushafExitDragOffset = 0
                    }
                }

                guard isBackSwipeTranslation(value.translation) else { return }
                guard abs(value.translation.width) > 90 else { return }

                withAnimation(animation) {
                    viewModel.exitMushafModeToStandardReading()
                }
            }
    }

    private func isBackSwipeTranslation(_ translation: CGSize) -> Bool {
        guard abs(translation.width) > abs(translation.height) * 1.35 else { return false }
        if layoutDirection == .rightToLeft {
            return translation.width < 0
        }
        return translation.width > 0
    }
}

struct QuranAudioExperienceScreen: View {
    @EnvironmentObject private var themeManager: ThemeManager

    @ObservedObject var audioController: QuranAudioReaderViewModel
    let onOpenCurrentContext: () -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var style: QuranReaderCanvasStyle {
        QuranReaderAppearanceEngine.style(for: .standardDark, theme: theme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                listeningHero
                playbackTransport
                listeningSettings
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .background(style.background.ignoresSafeArea())
        .navigationTitle(AppLanguage.current == .tr ? "Dinleme" : "Listening")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.navBarBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
    }

    private var listeningHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                QuranWaveformView(
                    isAnimating: audioController.playbackState.isActivelyPlaying,
                    tint: style.chipForeground
                )
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLanguage.current == .tr ? "Şu anki tilavet" : "Current recitation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(style.translationText.opacity(0.75))

                    Text(audioController.nowPlayingTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(style.arabicText)

                    Text(audioController.nowPlayingSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(style.translationText)
                }
            }

            Button(action: onOpenCurrentContext) {
                Label(
                    AppLanguage.current == .tr ? "Ayet konumuna dön" : "Return to reading context",
                    systemImage: "arrow.uturn.backward.circle.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(style.chipForeground, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(style.heroGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: style.heroGlow.opacity(0.32), radius: 24, y: 12)
    }

    private var playbackTransport: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLanguage.current == .tr ? "Kontroller" : "Controls")
                .font(.headline.weight(.semibold))
                .foregroundStyle(style.arabicText)

            ProgressView(value: audioController.currentProgress)
                .tint(style.chipForeground)

            HStack(spacing: 12) {
                transportButton("backward.fill", action: audioController.skipToPreviousAyah)
                transportButton(audioController.primaryPlaybackButtonIcon, prominent: true, action: audioController.triggerPrimaryPlayback)
                transportButton("forward.fill", action: audioController.skipToNextAyah)
            }
        }
        .padding(18)
        .background(style.audioSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(style.audioBorder, lineWidth: 1)
        )
    }

    private var listeningSettings: some View {
        QuranReaderControlContent(viewModel: nil, audioController: audioController, style: style)
            .padding(18)
            .background(style.audioSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(style.audioBorder, lineWidth: 1)
            )
    }

    private func transportButton(_ systemImage: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(prominent ? style.background : style.chipForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    (prominent ? style.chipForeground : style.chipBackground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}

struct QuranReaderAdvancedSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var viewModel: QuranReaderViewModel

    var body: some View {
        QuranReaderControlSheet(
            viewModel: viewModel,
            audioController: viewModel.audioController,
            style: QuranReaderAppearanceEngine.style(for: viewModel.preferences.appearance, theme: themeManager.current)
        )
    }
}

private struct SurahHeaderHero: View {
    let surah: QuranSurah?
    let style: QuranReaderCanvasStyle
    let translationSourceName: String
    let readingAppearance: QuranReaderAppearance
    let isTranslationVisible: Bool
    let collapseProgress: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLanguage.current == .tr ? "Okuma alanın" : "Reading sanctuary")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .tracking(0.7)

                    Text(surah?.localizedTurkishName ?? QuranReaderStrings.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))

                    if let surah {
                        Text("\(surah.localizedRevelationType) • \(surah.totalVerses) ayet")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.76))
                    }
                }

                Spacer(minLength: 12)

                Text(surah?.arabicName ?? "")
                    .font(QuranFontResolver.arabicFont(for: .classicMushaf, size: 30, relativeTo: .title2))
                    .foregroundStyle(.white.opacity(0.94))
                    .environment(\.layoutDirection, .rightToLeft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            HStack(spacing: 8) {
                heroChip(QuranReaderStrings.localized(readingAppearance.localizationKey, readingAppearance.defaultTitle))

                if isTranslationVisible && !translationSourceName.isEmpty {
                    heroChip(translationSourceName)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(style.heroGradient)
                .overlay(alignment: .topTrailing) {
                    ReaderArchOrnament()
                        .fill(.white.opacity(0.08))
                        .frame(width: 170, height: 170)
                        .padding(.top, -22)
                        .padding(.trailing, -18)
                }
                .overlay {
                    QuranHeroPattern()
                        .stroke(.white.opacity(0.07), lineWidth: 1)
                        .padding(16)
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: style.heroGlow.opacity(0.34), radius: 26, y: 14)
        .scaleEffect(1 - collapseProgress * 0.03)
        .opacity(Double(1 - collapseProgress * 0.8))
    }

    private func heroChip(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.10), in: Capsule())
    }
}

private struct CompactSurahHeader: View {
    let surah: QuranSurah?
    let style: QuranReaderCanvasStyle
    let translationSourceName: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(surah?.localizedTurkishName ?? QuranReaderStrings.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.arabicText)
                    .lineLimit(1)

                if !translationSourceName.isEmpty {
                    Text(translationSourceName)
                        .font(.caption)
                        .foregroundStyle(style.translationText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(surah?.arabicName ?? "")
                .font(QuranFontResolver.arabicFont(for: .classicMushaf, size: 24, relativeTo: .title3))
                .foregroundStyle(style.arabicText)
                .environment(\.layoutDirection, .rightToLeft)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(style.audioSurface.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(style.audioBorder, lineWidth: 1)
        )
        .shadow(color: style.shadowColor.opacity(0.18), radius: 16, y: 10)
        .allowsHitTesting(isVisible)
    }
}

private struct QuranReaderControlSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: QuranReaderViewModel
    @ObservedObject var audioController: QuranAudioReaderViewModel
    let style: QuranReaderCanvasStyle

    var body: some View {
        NavigationStack {
            ScrollView {
                QuranReaderControlContent(viewModel: viewModel, audioController: audioController, style: style)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(style.background.ignoresSafeArea())
            .navigationTitle(AppLanguage.current == .tr ? "Okuma Deneyimi" : "Reading Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(QuranReaderStrings.settingsDone) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct QuranReaderControlContent: View {
    let viewModel: QuranReaderViewModel?
    @ObservedObject var audioController: QuranAudioReaderViewModel
    let style: QuranReaderCanvasStyle

    private var preferredTafsirSource: QuranTafsirSource? {
        guard let viewModel else { return nil }
        return viewModel.preferredTafsirSource
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let viewModel {
                controlCard(title: AppLanguage.current == .tr ? "Görünüm presetleri" : "Appearance presets") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(QuranReaderAppearance.allCases) { appearance in
                                Button {
                                    viewModel.updateAppearance(appearance)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Image(systemName: appearance.iconName)
                                            .font(.headline.weight(.semibold))
                                        Text(QuranReaderStrings.localized(appearance.localizationKey, appearance.defaultTitle))
                                            .font(.caption.weight(.semibold))
                                            .multilineTextAlignment(.leading)
                                    }
                                    .foregroundStyle(viewModel.preferences.appearance == appearance ? style.background : style.arabicText)
                                    .padding(14)
                                    .frame(width: 124, alignment: .leading)
                                    .background(
                                        (viewModel.preferences.appearance == appearance ? style.chipForeground : style.secondaryBackground),
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                controlCard(title: AppLanguage.current == .tr ? "Hızlı ayarlar" : "Quick settings") {
                    VStack(spacing: 10) {
                        controlRow(
                            title: viewModel.isTranslationVisible ? "Meali Gizle" : "Meali Göster",
                            subtitle: viewModel.isTranslationVisible ? "Ayet merkezli daha sakin görünüm" : "Meal satırlarını tekrar görünür yap"
                        ) {
                            viewModel.setTranslationVisible(!viewModel.preferences.displayMode.showsTranslation)
                        }

                        controlRow(
                            title: viewModel.preferences.displayMode.showsTransliteration ? "Okunuşu Gizle" : "Okunuşu Göster",
                            subtitle: viewModel.preferences.displayMode.showsTransliteration ? "Latin okunuş satırlarını kaldır" : "Latin okunuş satırlarını görünür yap"
                        ) {
                            viewModel.setTransliterationVisible(!viewModel.preferences.displayMode.showsTransliteration)
                        }

                        controlRow(
                            title: viewModel.preferences.showWordByWord ? "Kelime kelimeyi gizle" : "Kelime kelimeyi göster",
                            subtitle: viewModel.preferences.showWordByWord ? "Ayet altındaki kelime açıklamalarını kaldır" : "Ayetleri kelime kelime takip et"
                        ) {
                            viewModel.updateShowWordByWord(!viewModel.preferences.showWordByWord)
                        }

                        sliderRow(
                            title: AppLanguage.current == .tr ? "Arapça boyutu" : "Arabic size",
                            value: viewModel.preferences.arabicFontSize,
                            range: 24...42
                        ) {
                            viewModel.updateArabicFontSize($0)
                        }

                        sliderRow(
                            title: AppLanguage.current == .tr ? "Meal boyutu" : "Translation size",
                            value: viewModel.preferences.translationFontSize,
                            range: 13...24
                        ) {
                            viewModel.updateTranslationFontSize($0)
                        }

                        sliderRow(
                            title: AppLanguage.current == .tr ? "Okunuş boyutu" : "Transliteration size",
                            value: viewModel.preferences.transliterationFontSize,
                            range: 12...22
                        ) {
                            viewModel.updateTransliterationFontSize($0)
                        }

                        sliderRow(
                            title: AppLanguage.current == .tr ? "Satır aralığı" : "Line spacing",
                            value: viewModel.preferences.translationLineSpacing,
                            range: 0.28...0.56
                        ) {
                            viewModel.updateTranslationLineSpacing($0)
                        }
                    }
                }

                controlCard(title: AppLanguage.current == .tr ? "Tefsir kaynağı" : "Tafsir source") {
                    ForEach(QuranTafsirSource.allCases) { source in
                        controlRow(
                            title: QuranReaderStrings.localized(source.localizationKey, source.defaultTitle),
                            subtitle: source.attribution.sourceName
                        ) {
                            viewModel.updatePreferredTafsirSource(source)
                        }
                        .overlay(alignment: .trailing) {
                            if preferredTafsirSource?.id == source.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(style.chipForeground)
                            }
                        }
                    }
                }
            }

            controlCard(title: AppLanguage.current == .tr ? "Dinleme" : "Listening") {
                VStack(spacing: 10) {
                    Menu {
                        ForEach(audioController.availableReciters) { reciter in
                            Button(reciter.localizedDisplayName) {
                                audioController.switchReciter(reciter)
                            }
                        }
                    } label: {
                        menuRow(
                            title: AppLanguage.current == .tr ? "Okuyucu" : "Reciter",
                            value: audioController.selectedReciter.localizedDisplayName
                        )
                    }
                    .buttonStyle(.plain)

                    ToggleRow(
                        title: AppLanguage.current == .tr ? "Otomatik ilerleme" : "Auto advance",
                        isOn: Binding(
                            get: { audioController.isAutoAdvanceEnabled },
                            set: { audioController.setAutoAdvanceEnabled($0) }
                        ),
                        style: style
                    )

                    ToggleRow(
                        title: AppLanguage.current == .tr ? "Arka planda oynat" : "Background playback",
                        isOn: Binding(
                            get: { audioController.isBackgroundListeningEnabled },
                            set: { audioController.setBackgroundListeningEnabled($0) }
                        ),
                        style: style
                    )

                    Menu {
                        ForEach(QuranPlaybackRepeatMode.allCases) { mode in
                            Button(mode.localizedTitle) {
                                audioController.setRepeatMode(mode)
                            }
                        }
                    } label: {
                        menuRow(
                            title: AppLanguage.current == .tr ? "Tekrar modu" : "Repeat mode",
                            value: audioController.repeatMode.localizedTitle
                        )
                    }
                    .buttonStyle(.plain)

                    Menu {
                        ForEach(QuranSleepTimerOption.allCases) { option in
                            Button(option.localizedTitle) {
                                audioController.setSleepTimer(option)
                            }
                        }
                    } label: {
                        menuRow(
                            title: AppLanguage.current == .tr ? "Uyku zamanlayıcısı" : "Sleep timer",
                            value: audioController.sleepTimerOption.localizedTitle
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func controlCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(style.arabicText)

            content()
        }
        .padding(18)
        .background(style.audioSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(style.audioBorder, lineWidth: 1)
        )
    }

    private func controlRow(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(style.arabicText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(style.translationText)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.translationText)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func sliderRow(title: String, value: Double, range: ClosedRange<Double>, action: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.arabicText)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.chipForeground)
            }

            Slider(
                value: Binding(
                    get: { value },
                    set: action
                ),
                in: range
            )
            .tint(style.chipForeground)
        }
    }

    private func menuRow(title: String, value: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.arabicText)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(style.translationText)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(style.translationText)
        }
        .padding(.vertical, 4)
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let style: QuranReaderCanvasStyle

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.arabicText)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(style.chipForeground)
        }
    }
}

private struct ReaderOffsetReader: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: ReaderScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("quran_reader_scroll")).minY
                )
        }
    }
}

private struct ReaderArchOrnament: Shape {
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

private struct QuranHeroPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / 6

        for index in 0...6 {
            let x = rect.minX + CGFloat(index) * step
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        for index in 0...3 {
            let y = rect.minY + CGFloat(index) * (rect.height / 3)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

private struct ReaderScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct QuranReaderCopy {
    let language: AppLanguage

    var quickSettings: String {
        language == .tr ? "Ayarlar" : "Settings"
    }
}
