import SwiftUI

struct DailyHadithCard: View, Equatable {
    let hadith: Hadith
    let onOpen: () -> Void
    let onShare: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat = 30
    private let contentPadding: CGFloat = 22

    static func == (lhs: DailyHadithCard, rhs: DailyHadithCard) -> Bool {
        lhs.hadith == rhs.hadith
    }

    private var cardText: String {
        hadith.shortCardText ?? hadith.title
    }

    private var metadata: (text: String, systemImage: String)? {
        if let attribution = hadith.attribution?.trimmingCharacters(in: .whitespacesAndNewlines), !attribution.isEmpty {
            return (attribution, "books.vertical.fill")
        }

        if let grade = hadith.grade?.trimmingCharacters(in: .whitespacesAndNewlines), !grade.isEmpty {
            return (grade, "checkmark.seal.fill")
        }

        return nil
    }

    private var subtitleText: String {
        if cardText == hadith.title {
            return metadata?.text ?? hadith.title
        }

        return hadith.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(colorScheme == .dark ? 0.12 : 0.44))
                        .frame(width: 46, height: 46)

                    Image(systemName: "quote.opening")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(.dailyHadithCardTitle)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(primaryTextColor)

                    Text(verbatim: subtitleText)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Text(DailyHadithLanguageDisplayName.name(for: hadith.language) ?? hadith.language.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(secondaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white.opacity(colorScheme == .dark ? 0.10 : 0.30))
                    )
            }

            Text(verbatim: cardText)
                .font(.system(.body, design: .serif).weight(.medium))
                .foregroundStyle(primaryTextColor)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 12) {
                if let metadata {
                    Label(metadata.text, systemImage: metadata.systemImage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(1)
                } else {
                    Text(.dailyHadithCardRenewsDaily)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(secondaryTextColor)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onOpen) {
                    Label(.dailyHadithCardTitle, systemImage: "arrow.right.circle.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(buttonPrimaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(buttonPrimaryFill)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(primaryTextColor)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(.white.opacity(colorScheme == .dark ? 0.12 : 0.34))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.commonShare))
            }
        }
        .padding(contentPadding)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(colorScheme == .dark ? 0.14 : 0.42), lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: 24, x: 0, y: 16)
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundGradient)

            Circle()
                .fill(Color(red: 0.57, green: 0.88, blue: 0.78).opacity(colorScheme == .dark ? 0.18 : 0.34))
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: -90, y: -115)

            Circle()
                .fill(Color(red: 0.98, green: 0.85, blue: 0.60).opacity(colorScheme == .dark ? 0.15 : 0.30))
                .frame(width: 170, height: 170)
                .blur(radius: 20)
                .offset(x: 140, y: 118)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.13))
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.05, green: 0.12, blue: 0.14),
                    Color(red: 0.08, green: 0.20, blue: 0.23),
                    Color(red: 0.18, green: 0.13, blue: 0.10)
                ]
                : [
                    Color(red: 0.96, green: 0.99, blue: 0.98),
                    Color(red: 0.87, green: 0.95, blue: 0.92),
                    Color(red: 0.99, green: 0.94, blue: 0.86)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentColor: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.84, blue: 0.57)
            : Color(red: 0.64, green: 0.43, blue: 0.10)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.08, green: 0.14, blue: 0.15)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.76)
            : Color(red: 0.19, green: 0.28, blue: 0.28).opacity(0.78)
    }

    private var buttonPrimaryFill: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color.white.opacity(0.16),
                    Color.white.opacity(0.08)
                ]
                : [
                    Color(red: 0.17, green: 0.34, blue: 0.31),
                    Color(red: 0.36, green: 0.53, blue: 0.44)
                ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var buttonPrimaryTextColor: Color {
        colorScheme == .dark ? .white : Color.white
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.30)
            : Color(red: 0.33, green: 0.46, blue: 0.43).opacity(0.18)
    }
}

nonisolated private extension L10n.Key {
    static let dailyHadithCardTitle = L10n.Key("daily_hadith_card_title", fallback: "Günün Hadisi")
    static let dailyHadithCardRenewsDaily = L10n.Key("daily_hadith_card_renews_daily", fallback: "Her gün yenilenir")
    static let dailyHadithCardLoadingTitle = L10n.Key("daily_hadith_card_loading_title", fallback: "Günün hadisi hazırlanıyor")
    static let dailyHadithCardLoadingSubtitle = L10n.Key("daily_hadith_card_loading_subtitle", fallback: "Metin sakin ve okunaklı bir sunum için hazırlanıyor.")
    static let dailyHadithCardErrorTitle = L10n.Key("daily_hadith_card_error_title", fallback: "Günün hadisi yüklenemedi")
    static let dailyHadithCardErrorSubtitle = L10n.Key("daily_hadith_card_error_subtitle", fallback: "İçerik şu anda alınamadı. Birkaç saniye sonra yeniden deneyebilirsin.")
    static let dailyHadithCardRetry = L10n.Key("daily_hadith_card_retry", fallback: "Tekrar Dene")
}

private enum DailyHadithLanguageDisplayName {
    static func name(for code: String) -> String? {
        switch code.lowercased() {
        case "tr": return "Türkçe"
        case "ar": return "العربية"
        case "en": return "English"
        case "fr": return "Français"
        case "de": return "Deutsch"
        case "id": return "Indonesia"
        case "ms": return "Melayu"
        case "fa": return "فارسی"
        case "ru": return "Русский"
        case "es": return "Español"
        case "ur": return "اردو"
        default: return nil
        }
    }
}

struct DailyHadithLoadingCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.dailyHadithCardLoadingTitle)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(primaryTextColor)

            Text(.dailyHadithCardLoadingSubtitle)
                .font(.subheadline)
                .foregroundStyle(primaryTextColor.opacity(0.72))

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45))
                .frame(width: 160, height: 14)

            ShimmerPlaceholder()
                .frame(height: 90)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.42))
                    .frame(height: 48)

                Circle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.42))
                    .frame(width: 48, height: 48)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.05, green: 0.11, blue: 0.13), Color(red: 0.09, green: 0.18, blue: 0.21)]
                            : [Color(red: 0.96, green: 0.99, blue: 0.98), Color(red: 0.89, green: 0.96, blue: 0.93)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.08, green: 0.14, blue: 0.15)
    }
}

struct DailyHadithErrorCard: View {
    let onRetry: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.dailyHadithCardErrorTitle)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(primaryTextColor)

            Text(.dailyHadithCardErrorSubtitle)
                .font(.subheadline)
                .foregroundStyle(secondaryTextColor)

            Button(action: onRetry) {
                Label(.dailyHadithCardRetry, systemImage: "arrow.clockwise")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.18, green: 0.40, blue: 0.36),
                                        Color(red: 0.55, green: 0.67, blue: 0.49)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.36), lineWidth: 1)
        )
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.08, green: 0.14, blue: 0.15)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.74) : Color(red: 0.25, green: 0.31, blue: 0.31)
    }
}

#Preview("Light") {
    DailyHadithCard(
        hadith: .dailyPreviewSample,
        onOpen: {},
        onShare: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark") {
    DailyHadithCard(
        hadith: .dailyPreviewSample,
        onOpen: {},
        onShare: {}
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

private extension Hadith {
    static let dailyPreviewSample = Hadith(
        id: 2941,
        language: "tr",
        title: "Büyük günahların en ağırını size haber vereyim mi?",
        fullHadith: "Nebi -sallallahu aleyhi ve sellem- şöyle buyurmuştur: Büyük günahların en ağırını size haber vereyim mi? Allah’a şirk koşmak, ana babaya itaatsizlik etmek ve yalan söz.",
        grade: "Sahih Hadis",
        attribution: "Muttefekun aleyh",
        explanation: nil,
        hints: [],
        hadeethArabic: nil
    )
}
