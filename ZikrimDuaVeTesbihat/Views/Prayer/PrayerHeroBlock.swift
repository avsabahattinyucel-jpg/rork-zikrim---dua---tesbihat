import SwiftUI
import UIKit

enum PrayerHeroBlockState {
    case loading
    case error(String)
    case loaded(PrayerViewModel)
}

struct PrayerHeroBlock: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: PrayerHeroBlockState
    let onTap: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            onTap()
        } label: {
            content
        }
        .buttonStyle(PrayerHeroButtonStyle(reduceMotion: reduceMotion))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            PrayerHeroSurface(
                theme: theme,
                style: PrayerGradientProvider.style(for: .night, theme: theme)
            ) {
                loadingContent
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "prayer_hero_loading_accessibility", defaultValue: "Namaz alanı yükleniyor"))
        case .error(let message):
            PrayerHeroSurface(
                theme: theme,
                style: PrayerGradientProvider.style(for: .night, theme: theme)
            ) {
                errorContent(message)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)
        case .loaded(let viewModel):
            PrayerHeroSurface(
                theme: theme,
                style: PrayerGradientProvider.style(for: viewModel.currentPrayer.id, theme: theme)
            ) {
                loadedContent(viewModel)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(viewModel.heroEyebrow), \(viewModel.currentPrayer.localizedName), \(viewModel.currentPrayer.formattedTime), \(viewModel.heroStatusText)"
            )
        }
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(String(localized: "prayer_stage_calc_label", defaultValue: "Diyanet vakitleri"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.84))

                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            }

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 96, height: 14)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 140, height: 32)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 150, height: 14)
            }

            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.9)
                Text(L10n.string(.namazVakitleriYukleniyor))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.82))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
    }

    private func errorContent(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(String(localized: "prayer_stage_calc_label", defaultValue: "Diyanet vakitleri"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.84))

                Spacer()

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.78))
            }

            Text(String(localized: "prayer_hero_error_title", defaultValue: "Vakitler hazır değil"))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

        }
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
    }

    private func loadedContent(_ viewModel: PrayerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "prayer_stage_calc_label", defaultValue: "Diyanet vakitleri"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.82))

                    Text(viewModel.currentPrayer.localizedName)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text(viewModel.heroStatusText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 10) {
                    PrayerIconView(assetName: viewModel.currentPrayer.iconType, size: 28)
                        .opacity(0.96)

                    Text(viewModel.currentPrayer.formattedTime)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
            }

            HStack(spacing: 8) {
                Text(viewModel.locationName)
                Text("•")
                Text(String(localized: "prayer_hero_open_label", defaultValue: "Dokun ve aç"))
                Spacer()
                Image(systemName: "arrow.up.forward.circle.fill")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.white.opacity(0.76))
        }
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
    }
}

struct PrayerMicroMessageView: View {
    let text: String
    let foregroundStyle: Color
    let backgroundStyle: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(foregroundStyle)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundStyle, in: Capsule())
    }
}

private struct PrayerHeroSurface<Content: View>: View {
    let theme: ActiveTheme
    let style: PrayerGradientProvider.Style
    let content: Content

    init(
        theme: ActiveTheme,
        style: PrayerGradientProvider.Style,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.style = style
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(style.heroGradient)

            Circle()
                .fill(style.glow)
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: -70, y: -90)

            Circle()
                .fill(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 26)
                .offset(x: 170, y: 120)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            content
                .padding(22)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.14 : 0.26), lineWidth: 1)
        )
        .shadow(color: style.glow.opacity(theme.isDarkMode ? 0.28 : 0.18), radius: 22, x: 0, y: 14)
    }
}

private struct PrayerHeroButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.98 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.8),
                value: configuration.isPressed
            )
    }
}

#Preview("PrayerHero Morning") {
    PrayerHeroBlock(
        state: .loaded(PrayerViewModel.preview(current: .fajr)),
        onTap: {}
    )
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}

#Preview("PrayerHero Night") {
    PrayerHeroBlock(
        state: .loaded(PrayerViewModel.preview(current: .isha)),
        onTap: {}
    )
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}

#Preview("Daily Layout Prayer First") {
    ScrollView {
        LazyVStack(spacing: 20) {
            PrayerHeroBlock(
                state: .loaded(PrayerViewModel.preview(current: .asr)),
                onTap: {}
            )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(height: 180)
                .overlay(Text("Günün Ayeti").foregroundStyle(.white))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(height: 180)
                .overlay(Text("Günün Hadisi").foregroundStyle(.white))
        }
        .padding(18)
    }
    .background(Color.black.ignoresSafeArea())
    .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}
