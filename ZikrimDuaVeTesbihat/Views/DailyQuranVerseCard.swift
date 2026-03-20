import SwiftUI

struct DailyQuranVerseCard: View, Equatable {
    let verse: DailyVerseProvider.DailyVerse
    let onOpen: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    private let cornerRadius: CGFloat = 28
    private let contentPadding: CGFloat = 22

    init(verse: DailyVerseProvider.DailyVerse, onOpen: (() -> Void)? = nil) {
        self.verse = verse
        self.onOpen = onOpen
    }

    static func == (lhs: DailyQuranVerseCard, rhs: DailyQuranVerseCard) -> Bool {
        lhs.verse == rhs.verse
    }

    var body: some View {
        Group {
            if let onOpen {
                Button(action: onOpen) {
                    cardContent
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(openVerseAccessibilityHint)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundGradient)

            decorativeGlow

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18))

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(colorScheme == .dark ? 0.16 : 0.42))
                            .frame(width: 42, height: 42)
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(.dailyQuranVerseTitle)
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(primaryTextColor)
                        Text(verse.metadataText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(secondaryTextColor)
                    }

                    Spacer(minLength: 0)

                    if onOpen != nil {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(primaryTextColor.opacity(0.88))
                    }
                }

                Text(verse.translation)
                    .font(.system(.body, design: .serif).weight(.medium))
                    .foregroundStyle(primaryTextColor)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("\(verse.translation) \(verse.metadataText)")

                if let translationSource = verse.translationSource, !translationSource.isEmpty {
                    Text(translationSource)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(secondaryTextColor.opacity(0.9))
                }

                HStack(spacing: 8) {
                    Capsule()
                        .fill(accentColor.opacity(colorScheme == .dark ? 0.8 : 0.7))
                        .frame(width: 24, height: 4)

                    Text(.dailyQuranVerseRenewsDaily)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryTextColor)

                    Spacer(minLength: 0)

                    if onOpen != nil {
                        Text(openVerseLabel)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(primaryTextColor.opacity(0.88))
                    }
                }
            }
            .padding(contentPadding)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(colorScheme == .dark ? 0.14 : 0.42), lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: 22, x: 0, y: 14)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.05, green: 0.12, blue: 0.15),
                    Color(red: 0.10, green: 0.24, blue: 0.28),
                    Color(red: 0.21, green: 0.14, blue: 0.09)
                ]
                : [
                    Color(red: 0.93, green: 0.98, blue: 0.97),
                    Color(red: 0.84, green: 0.93, blue: 0.91),
                    Color(red: 0.98, green: 0.92, blue: 0.82)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var decorativeGlow: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.80, green: 0.95, blue: 0.88).opacity(colorScheme == .dark ? 0.18 : 0.45))
                .frame(width: 210, height: 210)
                .blur(radius: 18)
                .offset(x: -70, y: -95)

            Circle()
                .fill(Color(red: 0.98, green: 0.86, blue: 0.60).opacity(colorScheme == .dark ? 0.16 : 0.36))
                .frame(width: 170, height: 170)
                .blur(radius: 20)
                .offset(x: 150, y: 110)
        }
    }

    private var accentColor: Color {
        colorScheme == .dark
            ? Color(red: 0.97, green: 0.83, blue: 0.53)
            : Color(red: 0.72, green: 0.45, blue: 0.09)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.10, green: 0.16, blue: 0.16)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.78)
            : Color(red: 0.19, green: 0.28, blue: 0.28).opacity(0.78)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.28)
            : Color(red: 0.41, green: 0.53, blue: 0.49).opacity(0.18)
    }

    private var openVerseLabel: String {
        AppLanguage.current == .tr ? "Ayeti ac" : "Open verse"
    }

    private var openVerseAccessibilityHint: String {
        AppLanguage.current == .tr
            ? "Kuran ekraninda ilgili ayete gider"
            : "Opens this verse in the Quran screen"
    }
}

private extension DailyVerseProvider.DailyVerse {
    static let previewCardSample = DailyVerseProvider.DailyVerse(
        surahId: 13,
        ayahNumber: 28,
        surahName: "Ra'd",
        translation: "Bilesiniz ki kalpler ancak Allah'ı anmakla huzur bulur.",
        languageCode: "tr",
        translationSource: L10n.string(.diyanetIsleriBaskanligi)
    )
}

#Preview("Light") {
    DailyQuranVerseCard(verse: .previewCardSample)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Dark") {
    DailyQuranVerseCard(verse: .previewCardSample)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
