import SwiftUI

struct SurahDetailView: View {
    let surahId: Int
    let scrollToVerse: Int?
    let quranService: QuranService
    let storage: StorageService

    @State private var selectedVerse: QuranVerse?
    @State private var showShareSheet: Bool = false

    private var surah: QuranSurah? {
        QuranSurahData.surahs.first(where: { $0.id == surahId })
    }

    var body: some View {
        Group {
            if quranService.isLoading {
                loadingView
            } else if let error = quranService.errorMessage, quranService.verses.isEmpty {
                errorView(error)
            } else {
                verseList
            }
        }
        .navigationTitle(surah?.turkishName ?? "Sure")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await quranService.loadVerses(for: surahId)
        }
        .sheet(item: $selectedVerse) { verse in
            VerseShareView(verse: verse, surahName: surah?.turkishName ?? "", surahArabicName: surah?.arabicName ?? "")
        }
    }

    private var verseList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if surahId != 9 {
                        bismillahHeader
                    }

                    surahHeaderCard

                    ForEach(quranService.verses) { verse in
                        VerseRowView(
                            verse: verse,
                            displayMode: quranService.displayMode,
                            arabicFontSize: quranService.arabicFontSize,
                            turkishFontSize: quranService.turkishFontSize,
                            isBookmarked: quranService.isBookmarked(verse: verse),
                            isPlayingAudio: quranService.playingVerseKey == "\(surahId):\(verse.verseNumber)",
                            onBookmark: {
                                quranService.toggleBookmark(verse: verse, surahName: surah?.turkishName ?? "")
                                quranService.saveLastRead(surahId: surahId, verseNumber: verse.verseNumber, surahName: surah?.turkishName ?? "")
                                let favorite = FavoriteItem(
                                    id: verse.id,
                                    type: .quran,
                                    title: "\(surah?.turkishName ?? "Sure") \(verse.verseNumber). Ayet",
                                    subtitle: surah?.arabicName ?? "",
                                    detail: verse.turkishTranslation
                                )
                                storage.toggleFavorite(favorite)
                            },
                            onPlayAudio: {
                                Task {
                                    await quranService.playVerseAudio(surahId: surahId, verseNumber: verse.verseNumber)
                                }
                            },
                            onShare: { selectedVerse = verse }
                        )
                        .id(verse.verseNumber)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                if let target = scrollToVerse, target > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private var bismillahHeader: some View {
        Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
            .font(.system(size: 22, weight: .medium))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .environment(\.layoutDirection, .rightToLeft)
    }

    private var surahHeaderCard: some View {
        Group {
            if let surah {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(surah.turkishName)
                            .font(.title2.bold())
                        HStack(spacing: 8) {
                            Text(surah.revelationTypeTurkish)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(surah.revelationType == "Meccan" ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                                .foregroundStyle(surah.revelationType == "Meccan" ? .orange : .blue)
                                .clipShape(.capsule)
                            Text("\(surah.totalVerses) Ayet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(surah.arabicName)
                        .font(.system(size: 28, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Sure yükleniyor...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Bağlantı Hatası")
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await quranService.loadVerses(for: surahId) }
            } label: {
                Label("Tekrar Dene", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VerseRowView: View {
    let verse: QuranVerse
    let displayMode: QuranDisplayMode
    let arabicFontSize: CGFloat
    let turkishFontSize: CGFloat
    let isBookmarked: Bool
    let isPlayingAudio: Bool
    let onBookmark: () -> Void
    let onPlayAudio: () -> Void
    let onShare: () -> Void

    @State private var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .trailing, spacing: 12) {
                verseNumberBadge

                if displayMode == .both || displayMode == .arabicOnly {
                    Text(verse.arabicText)
                        .font(.system(size: arabicFontSize, weight: .regular))
                        .lineSpacing(10)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }

                if displayMode == .both || displayMode == .turkishOnly {
                    Text(verse.turkishTranslation)
                        .font(.system(size: turkishFontSize))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(4)
                }

                HStack(spacing: 16) {
                    Spacer()

                    Button(action: onPlayAudio) {
                        Image(systemName: isPlayingAudio ? "stop.circle.fill" : "play.circle")
                            .font(.body)
                            .foregroundStyle(isPlayingAudio ? .teal : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.body)
                            .foregroundStyle(isBookmarked ? .teal : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()
                .padding(.horizontal, 20)
        }
        .background(isHighlighted ? Color.teal.opacity(0.05) : Color(.systemGroupedBackground))
    }

    private var verseNumberBadge: some View {
        HStack {
            ZStack {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.teal.opacity(0.2))
                Text("\(verse.verseNumber)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.teal)
            }
            Spacer()
        }
    }
}
