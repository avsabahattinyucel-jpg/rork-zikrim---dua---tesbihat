import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let imageHeight: CGFloat
    let isSelected: Bool
    let compactScreen: Bool

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isActive: Bool = false

    private var theme: ActiveTheme {
        themeManager.current
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: compactScreen ? 20 : 28) {
                    Spacer(minLength: compactScreen ? 8 : 14)

                    imageCard

                    VStack(spacing: compactScreen ? 10 : 14) {
                        Text(page.titleKey)
                            .font(titleFont)
                            .foregroundStyle(theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 560, alignment: .center)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(2)
                            .padding(.horizontal, 20)

                        Text(page.subtitleKey)
                            .font(.body)
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .frame(maxWidth: 620, alignment: .center)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: compactScreen ? 8 : 18)
                }
                .padding(.horizontal, 20)
                .padding(.top, compactScreen ? 6 : 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            if isSelected {
                isActive = true
            }
        }
        .onChange(of: isSelected) { _, newValue in
            isActive = newValue
        }
    }

    private var titleFont: Font {
        compactScreen
        ? .system(.title2, design: .serif).weight(.semibold)
        : .system(.largeTitle, design: .serif).weight(.semibold)
    }

    private var imageCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous)
                .fill(theme.elevatedCardBackground.opacity(theme.isDarkMode ? 0.92 : 0.98))

            RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous)
                .fill(theme.heroGradient)
                .opacity(theme.isDarkMode ? 0.18 : 0.10)

            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: imageHeight - (compactScreen ? 28 : 36))
                .padding(.horizontal, compactScreen ? 12 : 16)
                .padding(.vertical, compactScreen ? 14 : 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous)
                .stroke(theme.divider.opacity(theme.isDarkMode ? 0.55 : 0.36), lineWidth: 1)
        }
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.26 : 0.10), radius: 24, y: 14)
        .scaleEffect(isActive ? 1.01 : 1.0)
        .animation(
            .easeInOut(duration: 8).repeatForever(autoreverses: true),
            value: isActive
        )
    }

    private var imageCornerRadius: CGFloat {
        compactScreen ? 24 : 26
    }
}
