import SwiftUI
import UIKit

struct PrayerHeroStageView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewModel: PrayerViewModel
    let now: Date
    let heroHeight: CGFloat
    @Binding var selectedPrayer: PrayerName?
    let transitionNamespace: Namespace.ID?
    let onTap: (PrayerName) -> Void
    
    @State private var activePrayerID: PrayerName?
    @State private var lastHapticPrayerID: PrayerName?
    @State private var isBreathing: Bool = false

    private var theme: ActiveTheme { themeManager.current }
    private var activeItem: PrayerDisplayItem {
        viewModel.items.first(where: { $0.id == activePrayerID })
            ?? viewModel.displayedPrayer
    }
    private var activeStyle: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: activeItem.id, theme: theme)
    }
    private var shortDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter.string(from: now)
    }

    var body: some View {
        VStack(spacing: 18) {
            header

            GeometryReader { proxy in
                stackedCards(in: proxy)
            }
            .frame(height: max(heroHeight - 92, 330))
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: heroHeight, alignment: .top)
        .background(stageBackground)
        .animation(.easeInOut(duration: 0.45), value: activePrayerID)
        .onAppear {
            let initialPrayer = selectedPrayer ?? viewModel.currentPrayer.id
            activePrayerID = initialPrayer
            lastHapticPrayerID = initialPrayer
            if selectedPrayer == nil {
                selectedPrayer = initialPrayer
            }
            startBreathingIfNeeded()
        }
        .onChange(of: selectedPrayer) { _, newValue in
            let resolved = newValue ?? viewModel.currentPrayer.id
            guard resolved != activePrayerID else { return }

            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                activePrayerID = resolved
            }
        }
        .onChange(of: activePrayerID) { oldValue, newValue in
            guard let newValue else { return }
            selectedPrayer = newValue

            guard oldValue != nil, lastHapticPrayerID != newValue else {
                lastHapticPrayerID = newValue
                return
            }

            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            lastHapticPrayerID = newValue
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.locationName)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)

                Text(shortDateText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(String(localized: "prayer_stage_calc_label", defaultValue: "Diyanet vakitleri"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textPrimary.opacity(0.92))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Color.white.opacity(theme.isDarkMode ? 0.07 : 0.46),
                    in: Capsule()
                )
        }
    }

    private var stageBackground: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        theme.cardBackground.opacity(theme.isDarkMode ? 0.94 : 0.98),
                        activeStyle.glow.opacity(theme.isDarkMode ? 0.18 : 0.10),
                        theme.cardBackground.opacity(theme.isDarkMode ? 0.88 : 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                ZStack {
                    Circle()
                        .fill(activeStyle.glow)
                        .frame(width: 280, height: 280)
                        .blur(radius: 38)
                        .offset(x: -110, y: -95)

                    Circle()
                        .fill(activeStyle.accent.opacity(theme.isDarkMode ? 0.14 : 0.10))
                        .frame(width: 240, height: 240)
                        .blur(radius: 42)
                        .offset(x: 135, y: 112)
                }
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.30), lineWidth: 1)
            )
            .shadow(color: activeStyle.glow.opacity(theme.isDarkMode ? 0.12 : 0.07), radius: 28, x: 0, y: 18)
    }

    private func stackedCards(in proxy: GeometryProxy) -> some View {
        let cardWidth = min(max(proxy.size.width * 0.74, 274), 356)

        return ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(viewModel.items) { item in
                    GeometryReader { cardProxy in
                        let metrics = cardMetrics(for: cardProxy, in: proxy)

                        prayerCard(for: item)
                            .scaleEffect(metrics.scale)
                            .rotationEffect(.degrees(metrics.rotation))
                            .opacity(metrics.opacity)
                            .offset(x: metrics.xOffset, y: metrics.yOffset)
                            .zIndex(metrics.zIndex)
                    }
                    .frame(width: cardWidth, height: max(proxy.size.height - 16, 320))
                    .id(item.id)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content.opacity(phase.isIdentity ? 1 : 0.96)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .contentMargins(.horizontal, max((proxy.size.width - cardWidth) / 2, 0), for: .scrollContent)
        .scrollPosition(id: $activePrayerID, anchor: .center)
        .coordinateSpace(name: "PrayerHeroStageScroll")
    }

    private func cardMetrics(for cardProxy: GeometryProxy, in outerProxy: GeometryProxy) -> (scale: CGFloat, opacity: CGFloat, xOffset: CGFloat, yOffset: CGFloat, rotation: CGFloat, zIndex: Double) {
        let frame = cardProxy.frame(in: .named("PrayerHeroStageScroll"))
        let center = outerProxy.size.width / 2
        let distance = abs(frame.midX - center)
        let progress = min(distance / outerProxy.size.width, 1)
        let direction = frame.midX < center ? -1.0 : 1.0

        return (
            scale: 1 - (progress * 0.12),
            opacity: 1 - (progress * 0.32),
            xOffset: progress * -22 * direction,
            yOffset: progress * 22,
            rotation: progress * 3.2 * direction,
            zIndex: 1 - Double(progress)
        )
    }

    private func countdownText(for item: PrayerDisplayItem) -> String {
        switch item.state {
        case .current:
            return "\(viewModel.nextTransitionPrayer.localizedName) vaktine \(viewModel.countdownText)"
        case .upcoming:
            return "\(item.localizedName) vaktine \(PrayerViewModel.countdownText(from: now, to: item.time, calendar: .current))"
        case .past:
            return String(localized: "prayer_stage_past_label", defaultValue: "Bugün tamamlandı")
        }
    }

    @ViewBuilder
    private func prayerCard(for item: PrayerDisplayItem) -> some View {
        let card = PrayerHeroStageCard(
            item: item,
            countdownText: countdownText(for: item),
            isActive: activePrayerID == item.id,
            breathPhase: isBreathing,
            style: PrayerGradientProvider.style(for: item.id, theme: theme),
            reduceMotion: reduceMotion,
            onTap: {
                handleTap(on: item)
            }
        )

        if let transitionNamespace {
            card.matchedTransitionSource(id: item.id, in: transitionNamespace)
        } else {
            card
        }
    }

    private func handleTap(on item: PrayerDisplayItem) {
        if activePrayerID == item.id {
            onTap(item.id)
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            activePrayerID = item.id
        }
    }

    private func startBreathingIfNeeded() {
        guard !reduceMotion else { return }
        guard !isBreathing else { return }

        withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }
}

private struct PrayerHeroStageCard: View {
    let item: PrayerDisplayItem
    let countdownText: String
    let isActive: Bool
    let breathPhase: Bool
    let style: PrayerGradientProvider.Style
    let reduceMotion: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(style.heroGradient)

                Circle()
                    .fill(style.glow)
                    .frame(width: 176, height: 176)
                    .blur(radius: 24)
                    .offset(x: -34, y: -48)

                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 164, height: 164)
                    .blur(radius: 28)
                    .offset(x: 142, y: 128)

                VStack(alignment: .leading, spacing: 14) {
                    Spacer(minLength: 0)

                    Text(item.localizedName)
                        .font(.system(size: isActive ? 34 : 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(item.formattedTime)
                        .font(.system(size: isActive ? 54 : 50, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text(countdownText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text(item.primaryMessage)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(isActive ? 0.24 : 0.12), lineWidth: 1)
            )
            .shadow(color: style.glow.opacity(isActive ? 0.28 : 0.12), radius: isActive ? 24 : 14, x: 0, y: isActive ? 16 : 10)
            .scaleEffect(isActive && !reduceMotion ? (breathPhase ? 1.015 : 0.995) : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.localizedName), \(item.formattedTime), \(countdownText)")
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: isActive)
    }
}

#Preview("Prayer Stage Morning") {
    PrayerHeroStagePreview(current: .fajr)
        .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}

#Preview("Prayer Stage Night") {
    PrayerHeroStagePreview(current: .isha)
        .environmentObject(ThemeManager.preview(theme: .nightMosque, appearanceMode: .dark))
}

private struct PrayerHeroStagePreview: View {
    @State private var selectedPrayer: PrayerName?

    let current: PrayerName

    var body: some View {
        PrayerHeroStageView(
            viewModel: PrayerViewModel.preview(current: current),
            now: Date(),
            heroHeight: 460,
            selectedPrayer: $selectedPrayer,
            transitionNamespace: nil,
            onTap: { _ in }
        )
        .padding()
        .background(Color.black)
    }
}
