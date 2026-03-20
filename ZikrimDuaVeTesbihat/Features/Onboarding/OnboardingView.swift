import SwiftUI

struct OnboardingView: View {
    let authService: AuthService
    let onFinish: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selection: Int = 0
    @State private var showPaywall: Bool = false

    private let pages: [OnboardingPage] = [
        .init(
            imageName: "tesbih",
            titleKey: .onboardingTesbihTitle,
            subtitleKey: .onboardingTesbihSubtitle
        ),
        .init(
            imageName: "avlu",
            titleKey: .onboardingAvluTitle,
            subtitleKey: .onboardingAvluSubtitle
        ),
        .init(
            imageName: "rabia",
            titleKey: .onboardingRabiaTitle,
            subtitleKey: .onboardingRabiaSubtitle
        )
    ]

    private var theme: ActiveTheme {
        themeManager.current
    }

    var body: some View {
        GeometryReader { proxy in
            let compactScreen = proxy.size.height < 760 || dynamicTypeSize.isAccessibilitySize
            let cardWidth = min(max(proxy.size.width - 40, 0), 520)
            let imageHeight = min(
                max(min(proxy.size.height * (compactScreen ? 0.28 : 0.33), cardWidth * 0.72), 220),
                compactScreen ? 290 : 360
            )
            let bottomPadding = max(proxy.safeAreaInsets.bottom + 8, compactScreen ? 16 : 22)

            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(
                            page: page,
                            imageHeight: imageHeight,
                            isSelected: selection == index,
                            compactScreen: compactScreen
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: compactScreen ? 12 : 18) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == selection ? theme.accent : theme.textSecondary.opacity(0.24))
                                .frame(width: index == selection ? 18 : 7, height: 7)
                                .animation(.easeInOut(duration: 0.25), value: selection)
                        }
                    }

                    Button {
                        if selection < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                selection += 1
                            }
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Text(selection == pages.count - 1 ? .onboardingGetStarted : .onboardingContinue)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                theme.heroGradient,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.16 : 0.42), lineWidth: 1)
                            }
                            .shadow(color: theme.accent.opacity(theme.isDarkMode ? 0.30 : 0.20), radius: 16, y: 10)
                    }
                    .buttonStyle(.plain)

                    Button(.onboardingSkip) {
                        onFinish()
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, compactScreen ? 10 : 16)
                .padding(.bottom, bottomPadding)
            }
            .background(
                ZStack {
                    theme.backgroundView

                    RadialGradient(
                        colors: [
                            theme.accentSoft.opacity(theme.isDarkMode ? 0.24 : 0.16),
                            .clear
                        ],
                        center: .top,
                        startRadius: 40,
                        endRadius: 340
                    )
                }
                .ignoresSafeArea()
            )
            .sheet(isPresented: $showPaywall, onDismiss: onFinish) {
                PremiumView(authService: authService)
            }
        }
    }
}
