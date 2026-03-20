import SwiftUI

enum HadithDetailState: Equatable, Sendable {
    case loading
    case content(Hadith)
    case empty
    case error(message: String)
}

struct HadithDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let state: HadithDetailState
    private let appLanguageCode: String
    private let onRetry: (() -> Void)?
    private let onShare: ((Hadith) -> Void)?

    @State private var isArabicExpanded: Bool
    @State private var isTextExpanded: Bool
    @State private var isExplanationExpanded: Bool

    init(
        state: HadithDetailState,
        appLanguageCode: String,
        shareRouter: (any HadithShareRouting)? = nil,
        onShare: ((Hadith) -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.state = state
        self.appLanguageCode = appLanguageCode
        self.onRetry = onRetry
        if let onShare {
            self.onShare = onShare
        } else if let shareRouter {
            self.onShare = { hadith in
                shareRouter.share(hadith: hadith)
            }
        } else {
            self.onShare = nil
        }
        _isArabicExpanded = State(initialValue: appLanguageCode.hasPrefix("ar"))
        _isTextExpanded = State(initialValue: false)
        _isExplanationExpanded = State(initialValue: false)
    }

    init(
        hadith: Hadith,
        appLanguageCode: String,
        shareRouter: (any HadithShareRouting)? = nil,
        onShare: ((Hadith) -> Void)? = nil
    ) {
        self.init(
            state: .content(hadith),
            appLanguageCode: appLanguageCode,
            shareRouter: shareRouter,
            onShare: onShare,
            onRetry: nil
        )
    }

    private var theme: ActiveTheme {
        themeManager.palette(using: colorScheme)
    }

    private var palette: HadithDetailPalette {
        HadithDetailPalette(theme: theme)
    }

    private var stateAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.01)
            : .easeInOut(duration: 0.28)
    }

    private var contentHadith: Hadith? {
        guard case let .content(hadith) = state, !hadith.hadeeth.trimmed.isEmpty else {
            return nil
        }

        return hadith
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            HadithDetailBackdrop(palette: palette)
                .ignoresSafeArea()

            Group {
                switch state {
                case .loading:
                    HadithLoadingView(palette: palette)
                        .transition(.opacity)
                case .empty:
                    HadithEmptyView(palette: palette)
                        .transition(.opacity)
                case let .error(message):
                    HadithErrorView(
                        message: message,
                        palette: palette,
                        onRetry: onRetry
                    )
                    .transition(.opacity)
                case let .content(hadith):
                    if hadith.hadeeth.trimmed.isEmpty {
                        HadithEmptyView(palette: palette)
                            .transition(.opacity)
                    } else {
                        contentView(for: hadith)
                            .transition(.opacity)
                    }
                }
            }
            .animation(stateAnimation, value: state)
        }
        .navigationTitle(L10n.string(.hadithDetailNavigationTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.navBarBackground.opacity(theme.isDarkMode ? 0.88 : 0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if let hadith = contentHadith, let onShare {
                HadithShareBar(
                    hadith: hadith,
                    palette: palette,
                    shareLabel: L10n.string(.commonShare),
                    onShare: onShare
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func contentView(for hadith: Hadith) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HadithHeaderView(hadith: hadith, palette: palette)

                HadithTextCard(
                    hadith: hadith,
                    palette: palette,
                    isExpanded: isTextExpanded,
                    onToggle: toggleTextSection
                )

                if let arabicText = hadith.hadeethArabic?.trimmedNilIfEmpty {
                    ArabicExpandableSection(
                        title: L10n.string(.hadithDetailArabicOriginal),
                        subtitle: L10n.string(.hadithDetailArabicSubtitle),
                        text: arabicText,
                        isExpanded: isArabicExpanded,
                        palette: palette,
                        onToggle: toggleArabicSection
                    )
                }

                if let explanation = hadith.explanation?.trimmedNilIfEmpty {
                    HadithExplanationSection(
                        title: L10n.string(.hadithDetailMeaningTitle),
                        text: explanation,
                        palette: palette,
                        isExpanded: isExplanationExpanded,
                        onToggle: toggleExplanationSection
                    )
                }

                if !hadith.hints.isEmpty {
                    HadithHintsSection(
                        title: L10n.string(.hadithDetailLessonsTitle),
                        hints: hadith.hints,
                        palette: palette
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
    }

    private func toggleArabicSection() {
        if reduceMotion {
            isArabicExpanded.toggle()
        } else {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                isArabicExpanded.toggle()
            }
        }
    }

    private func toggleTextSection() {
        if reduceMotion {
            isTextExpanded.toggle()
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
                isTextExpanded.toggle()
            }
        }
    }

    private func toggleExplanationSection() {
        if reduceMotion {
            isExplanationExpanded.toggle()
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
                isExplanationExpanded.toggle()
            }
        }
    }
}

// MARK: - Subviews

private struct HadithHeaderView: View {
    let hadith: Hadith
    let palette: HadithDetailPalette

    private var compactSummary: String {
        hadith.heroSummary
    }

    private var headline: String {
        hadith.title.trimmedNilIfEmpty ?? compactSummary
    }

    private var supportingSummary: String? {
        guard compactSummary.localizedCaseInsensitiveCompare(headline) != .orderedSame else {
            return nil
        }

        return compactSummary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(.hadithDetailPrelude)
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(palette.supportingText)
                        .tracking(0.3)

                    HStack(spacing: 8) {
                        Text(.hadithDetailBadge)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(palette.badgeText)
                            .tracking(0.6)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(palette.badgeFill)
                            )

                        if let languageName = HadithLanguageDisplayName.name(for: hadith.language) {
                            Text(verbatim: languageName)
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(palette.supportingText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(palette.secondaryCapsuleFill)
                                )
                        }
                    }

                    Text(verbatim: headline)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                        .lineSpacing(3)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    if let supportingSummary {
                        Text(verbatim: supportingSummary)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(4)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if hadith.grade?.trimmedNilIfEmpty != nil || hadith.attribution?.trimmedNilIfEmpty != nil {
                        HadithMetadataRow(
                            grade: hadith.grade,
                            attribution: hadith.attribution,
                            palette: palette
                        )
                    }
                }

                Spacer(minLength: 12)

                HadithHeaderOrnament(palette: palette)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(palette.headerFill)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(palette.headerGlow)
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                        .offset(x: 40, y: -56)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(palette.theme.isDarkMode ? 0.04 : 0.18),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(palette.stroke, lineWidth: 1)
                )
                .shadow(color: palette.shadow, radius: 26, x: 0, y: 18)
        )
    }
}

private struct HadithMetadataRow: View {
    let grade: String?
    let attribution: String?
    let palette: HadithDetailPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let grade = grade?.trimmedNilIfEmpty {
                HadithMetadataChip(
                    icon: "checkmark.seal.fill",
                    text: grade,
                    palette: palette
                )
            }

            if let attribution = attribution?.trimmedNilIfEmpty {
                HadithMetadataChip(
                    icon: "books.vertical.fill",
                    text: attribution,
                    palette: palette
                )
            }
        }
    }
}

private struct HadithMetadataChip: View {
    let icon: String
    let text: String
    let palette: HadithDetailPalette

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.metadataIcon)

            Text(verbatim: text)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.secondarySurfaceFill)
        )
    }
}

private struct HadithTextCard: View {
    let hadith: Hadith
    let palette: HadithDetailPalette
    let isExpanded: Bool
    let onToggle: () -> Void

    private var isLong: Bool {
        hadith.hadeeth.count > 420 || hadith.hadeeth.components(separatedBy: .newlines).count > 5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(palette.quoteBadgeFill)
                        .frame(width: 34, height: 34)

                    Image(systemName: "quote.opening")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.quoteBadgeText)
                }

                Text(.hadithDetailTextLabel)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(palette.supportingText)
                    .tracking(0.4)
            }

            Group {
                if isExpanded || !isLong {
                    Text(verbatim: hadith.hadeeth)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundStyle(palette.primaryText)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                } else {
                    Text(verbatim: hadith.hadeeth)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundStyle(palette.primaryText)
                        .lineSpacing(8)
                        .lineLimit(9)
                }
            }

            if isLong {
                HadithExpandButton(
                    isExpanded: isExpanded,
                    expandLabel: L10n.string(.hadithDetailReadMore),
                    collapseLabel: L10n.string(.hadithDetailShowLess),
                    palette: palette,
                    action: onToggle
                )
            }

            HStack(spacing: 8) {
                Capsule()
                    .fill(palette.accent.opacity(0.82))
                    .frame(width: 24, height: 4)

                Text(isExpanded ? .hadithDetailPreservedText : .hadithDetailPreviewText)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(palette.supportingText)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(palette.primarySurfaceFill)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    palette.accent.opacity(palette.theme.isDarkMode ? 0.12 : 0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(palette.stroke, lineWidth: 1)
                )
                .shadow(color: palette.shadow, radius: 20, x: 0, y: 12)
        )
        .accessibilityElement(children: .contain)
    }
}

private struct ArabicExpandableSection: View {
    let title: String
    let subtitle: String
    let text: String
    let isExpanded: Bool
    let palette: HadithDetailPalette
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: title)
                            .font(.system(.headline, design: .serif, weight: .semibold))
                            .foregroundStyle(palette.primaryText)

                        Text(verbatim: subtitle)
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .foregroundStyle(palette.supportingText)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(palette.accent)
                }
                .contentShape(Rectangle())
                .padding(22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isExpanded ? .hadithDetailHideArabic : .hadithDetailShowArabic))

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(palette.divider)
                        .frame(height: 1)
                        .padding(.horizontal, 22)

                    Text(verbatim: text)
                        .font(.system(size: 21, weight: .medium, design: .serif))
                        .foregroundStyle(palette.arabicText)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .lineSpacing(12)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(22)
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    )
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(palette.arabicSurfaceFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(palette.arabicStroke, lineWidth: 1)
                )
        )
    }
}

private struct HadithExplanationSection: View {
    let title: String
    let text: String
    let palette: HadithDetailPalette
    let isExpanded: Bool
    let onToggle: () -> Void

    private var isLong: Bool {
        text.count > 360 || text.components(separatedBy: .newlines).count > 4
    }

    var body: some View {
        HadithSectionContainer(title: title, palette: palette) {
            VStack(alignment: .leading, spacing: 14) {
                Group {
                    if isExpanded || !isLong {
                        Text(verbatim: text)
                            .font(.system(.body, design: .serif, weight: .regular))
                            .foregroundStyle(palette.primaryText)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    } else {
                        Text(verbatim: text)
                            .font(.system(.body, design: .serif, weight: .regular))
                            .foregroundStyle(palette.primaryText)
                            .lineSpacing(8)
                            .lineLimit(7)
                    }
                }

                if isLong {
                    HadithExpandButton(
                        isExpanded: isExpanded,
                        expandLabel: L10n.string(.hadithDetailReadMeaning),
                        collapseLabel: L10n.string(.hadithDetailShowLess),
                        palette: palette,
                        action: onToggle
                    )
                }
            }
        }
    }
}

private struct HadithExpandButton: View {
    let isExpanded: Bool
    let expandLabel: String
    let collapseLabel: String
    let palette: HadithDetailPalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(verbatim: isExpanded ? collapseLabel : expandLabel)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(palette.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(palette.secondarySurfaceFill)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HadithHintsSection: View {
    let title: String
    let hints: [String]
    let palette: HadithDetailPalette

    var body: some View {
        HadithSectionContainer(title: title, palette: palette) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(hints.enumerated()), id: \.offset) { index, hint in
                    HadithHintRow(
                        index: index + 1,
                        text: hint,
                        palette: palette
                    )
                }
            }
        }
    }
}

private struct HadithHintRow: View {
    let index: Int
    let text: String
    let palette: HadithDetailPalette

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(verbatim: "\(index)")
                .font(.system(.footnote, design: .rounded, weight: .bold))
                .foregroundStyle(palette.lessonNumberText)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(palette.lessonNumberFill)
                )

            Text(verbatim: text)
                .font(.system(.body, design: .serif, weight: .regular))
                .foregroundStyle(palette.primaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.secondarySurfaceFill)
        )
    }
}

private struct HadithSectionContainer<Content: View>: View {
    let title: String
    let palette: HadithDetailPalette
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(verbatim: title)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(palette.primarySurfaceFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(palette.stroke, lineWidth: 1)
                )
        )
    }
}

private struct HadithShareBar: View {
    let hadith: Hadith
    let palette: HadithDetailPalette
    let shareLabel: String
    let onShare: ((Hadith) -> Void)?

    var body: some View {
        if let onShare {
            Button {
                onShare(hadith)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 34, height: 34)

                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text(verbatim: shareLabel)
                        .font(.system(.headline, design: .rounded, weight: .semibold))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.74))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: palette.shareGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: palette.shareShadow, radius: 20, x: 0, y: 12)
            }
            .buttonStyle(HadithPressButtonStyle())
            .accessibilityLabel(Text(.commonShare))
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .padding(.horizontal, -8)
                    .padding(.vertical, -8)
                    .blur(radius: 0.4)
            )
        }
    }
}

private struct HadithLoadingView: View {
    let palette: HadithDetailPalette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                loadingCard(height: 180)
                loadingCard(height: 280)
                loadingCard(height: 170)
                loadingCard(height: 220)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 10) {
                Text(.hadithDetailLoadingTitle)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.primaryText)

                Text(.hadithDetailLoadingSubtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(palette.supportingText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
    }

    private func loadingCard(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(palette.primarySurfaceFill)
            .frame(height: height)
            .overlay(
                VStack(alignment: .leading, spacing: 14) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(palette.placeholderFill)
                        .frame(width: 92, height: 14)

                    ShimmerPlaceholder()
                }
                .padding(22)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(palette.stroke, lineWidth: 1)
            )
    }
}

private struct HadithEmptyView: View {
    let palette: HadithDetailPalette

    var body: some View {
        HadithStateContainer(palette: palette) {
            Image(systemName: "text.page.slash")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(palette.accent)

            Text(.hadithDetailEmptyTitle)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            Text(.hadithDetailEmptyMessage)
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundStyle(palette.supportingText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}

private struct HadithErrorView: View {
    let message: String
    let palette: HadithDetailPalette
    let onRetry: (() -> Void)?

    var body: some View {
        HadithStateContainer(palette: palette) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(palette.accent)

            Text(.hadithDetailErrorTitle)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            Text(verbatim: message)
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundStyle(palette.supportingText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if let onRetry {
                Button(action: onRetry) {
                    Label(.hadithDetailRetry, systemImage: "arrow.clockwise")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: palette.shareGradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(HadithPressButtonStyle())
            }
        }
    }
}

private struct HadithStateContainer<Content: View>: View {
    let palette: HadithDetailPalette
    @ViewBuilder let content: Content

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                content
            }
            .padding(28)
            .frame(maxWidth: 460)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(palette.primarySurfaceFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(palette.stroke, lineWidth: 1)
                    )
                    .shadow(color: palette.shadow, radius: 24, x: 0, y: 16)
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
    }
}

private struct HadithDetailBackdrop: View {
    let palette: HadithDetailPalette

    var body: some View {
        ZStack {
            palette.background

            LinearGradient(
                colors: palette.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(palette.ambientGlow)
                .frame(width: 280, height: 280)
                .blur(radius: 34)
                .offset(x: 110, y: -240)

            Circle()
                .fill(palette.secondaryAmbientGlow)
                .frame(width: 250, height: 250)
                .blur(radius: 44)
                .offset(x: -120, y: -180)

            Ellipse()
                .fill(palette.tertiaryAmbientGlow)
                .frame(width: 320, height: 200)
                .blur(radius: 54)
                .offset(x: 0, y: 260)
        }
    }
}

private struct HadithHeaderOrnament: View {
    let palette: HadithDetailPalette

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.ornamentStroke, lineWidth: 1)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0.18, to: 0.82)
                .stroke(
                    LinearGradient(
                        colors: [palette.accent.opacity(0.8), palette.goldAccent.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-30))

            Circle()
                .fill(palette.accent.opacity(0.14))
                .frame(width: 8, height: 8)
                .offset(x: 18, y: -12)
        }
        .frame(width: 72, height: 72)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.secondarySurfaceFill)
        )
    }
}

private struct HadithPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Theme

private struct HadithDetailPalette {
    let theme: ActiveTheme

    var background: Color {
        theme.backgroundBase
    }

    var backgroundGradient: [Color] {
        [
            theme.backgroundGradientTop.opacity(theme.isDarkMode ? 0.90 : 0.72),
            theme.backgroundGradientBottom,
            warmWash
        ]
    }

    var primarySurfaceFill: Color {
        theme.cardBackground.opacity(theme.isDarkMode ? 0.90 : 0.94)
    }

    var secondarySurfaceFill: Color {
        theme.elevatedCardBackground.opacity(theme.isDarkMode ? 0.88 : 0.86)
    }

    var arabicSurfaceFill: Color {
        theme.isDarkMode
            ? Color(red: 0.09, green: 0.15, blue: 0.13).opacity(0.94)
            : Color(red: 0.95, green: 0.98, blue: 0.96).opacity(0.96)
    }

    var headerFill: Color {
        theme.isDarkMode
            ? Color.white.opacity(0.07)
            : Color.white.opacity(0.74)
    }

    var badgeFill: Color {
        accent.opacity(theme.isDarkMode ? 0.18 : 0.12)
    }

    var secondaryCapsuleFill: Color {
        theme.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.035)
    }

    var placeholderFill: Color {
        theme.isDarkMode ? Color.white.opacity(0.07) : Color.black.opacity(0.05)
    }

    var stroke: Color {
        theme.divider.opacity(theme.isDarkMode ? 0.40 : 0.22)
    }

    var arabicStroke: Color {
        accent.opacity(theme.isDarkMode ? 0.32 : 0.18)
    }

    var divider: Color {
        theme.divider.opacity(theme.isDarkMode ? 0.46 : 0.22)
    }

    var primaryText: Color {
        theme.textPrimary
    }

    var secondaryText: Color {
        theme.textSecondary
    }

    var supportingText: Color {
        theme.mutedText.opacity(theme.isDarkMode ? 0.96 : 1)
    }

    var arabicText: Color {
        theme.isDarkMode
            ? Color(red: 0.95, green: 0.97, blue: 0.95)
            : Color(red: 0.10, green: 0.20, blue: 0.16)
    }

    var accent: Color {
        Color(
            red: theme.isDarkMode ? 0.56 : 0.18,
            green: theme.isDarkMode ? 0.82 : 0.47,
            blue: theme.isDarkMode ? 0.70 : 0.43
        )
    }

    var goldAccent: Color {
        Color(
            red: theme.isDarkMode ? 0.84 : 0.76,
            green: theme.isDarkMode ? 0.71 : 0.63,
            blue: theme.isDarkMode ? 0.48 : 0.45
        )
    }

    var metadataIcon: Color {
        goldAccent.opacity(theme.isDarkMode ? 0.92 : 0.88)
    }

    var badgeText: Color {
        accent.opacity(theme.isDarkMode ? 1 : 0.92)
    }

    var lessonNumberFill: Color {
        accent.opacity(theme.isDarkMode ? 0.24 : 0.14)
    }

    var lessonNumberText: Color {
        accent
    }

    var ambientGlow: Color {
        accent.opacity(theme.isDarkMode ? 0.24 : 0.16)
    }

    var secondaryAmbientGlow: Color {
        goldAccent.opacity(theme.isDarkMode ? 0.18 : 0.10)
    }

    var ornamentStroke: Color {
        theme.isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }

    var shareGradient: [Color] {
        [
            accent,
            goldAccent.opacity(theme.isDarkMode ? 0.82 : 0.92)
        ]
    }

    var shareShadow: Color {
        accent.opacity(theme.isDarkMode ? 0.36 : 0.22)
    }

    var shadow: Color {
        theme.shadowColor.opacity(theme.isDarkMode ? 0.36 : 0.16)
    }

    var headerGlow: Color {
        goldAccent.opacity(theme.isDarkMode ? 0.18 : 0.22)
    }

    var quoteBadgeFill: Color {
        accent.opacity(theme.isDarkMode ? 0.18 : 0.12)
    }

    var quoteBadgeText: Color {
        goldAccent
    }

    var tertiaryAmbientGlow: Color {
        Color.white.opacity(theme.isDarkMode ? 0.06 : 0.22)
    }

    private var warmWash: Color {
        theme.isDarkMode
            ? Color(red: 0.09, green: 0.10, blue: 0.12)
            : Color(red: 0.98, green: 0.96, blue: 0.93)
    }
}

// MARK: - Localization

private enum HadithLanguageDisplayName {
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

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedNilIfEmpty: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}

private extension Hadith {
    var heroSummary: String {
        let source = hadeeth.trimmedNilIfEmpty ?? title
        let normalized = source
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmed

        let sentenceStops = CharacterSet(charactersIn: ".!?")
        if let range = normalized.rangeOfCharacter(from: sentenceStops) {
            let firstSentence = String(normalized[..<range.upperBound]).trimmed
            if firstSentence.count >= 70 {
                return firstSentence
            }
        }

        if normalized.count <= 220 {
            return normalized
        }

        let index = normalized.index(normalized.startIndex, offsetBy: 220)
        return String(normalized[..<index]).trimmed + "..."
    }
}

nonisolated extension L10n.Key {
    static let hadithDetailNavigationTitle = L10n.Key("hadith_detail_navigation_title", fallback: "Hadis")
    static let hadithDetailBadge = L10n.Key("hadith_detail_badge", fallback: "Hadis")
    static let hadithDetailPrelude = L10n.Key("hadith_detail_prelude", fallback: "Bugün kalbine dokunabilecek bir rivayet")
    static let hadithDetailArabicOriginal = L10n.Key("hadith_detail_arabic_original", fallback: "Arapça metin")
    static let hadithDetailArabicSubtitle = L10n.Key("hadith_detail_arabic_subtitle", fallback: "Orijinal hali")
    static let hadithDetailMeaningTitle = L10n.Key("hadith_detail_meaning_title", fallback: "Kısaca ne anlatıyor?")
    static let hadithDetailLessonsTitle = L10n.Key("hadith_detail_lessons_title", fallback: "Bugüne kalan notlar")
    static let hadithDetailTextLabel = L10n.Key("hadith_detail_text_label", fallback: "Rivayet metni")
    static let hadithDetailPreservedText = L10n.Key("hadith_detail_preserved_text", fallback: "Metni kaynakta geçtiği haliyle paylaştık.")
    static let hadithDetailPreviewText = L10n.Key("hadith_detail_preview_text", fallback: "Şimdilik kısa görünüm açık, istersen tamamını açabilirsin.")
    static let hadithDetailShowArabic = L10n.Key("hadith_detail_show_arabic", fallback: "Arapça aslını göster")
    static let hadithDetailHideArabic = L10n.Key("hadith_detail_hide_arabic", fallback: "Arapça aslını gizle")
    static let hadithDetailReadMore = L10n.Key("hadith_detail_read_more", fallback: "Devamını oku")
    static let hadithDetailReadMeaning = L10n.Key("hadith_detail_read_meaning", fallback: "Açıklamanın devamını oku")
    static let hadithDetailShowLess = L10n.Key("hadith_detail_show_less", fallback: "Kısalt")
    static let hadithDetailLoadingTitle = L10n.Key("hadith_detail_loading_title", fallback: "Hadis hazırlanıyor")
    static let hadithDetailLoadingSubtitle = L10n.Key("hadith_detail_loading_subtitle", fallback: "Birazdan daha sade bir okuma düzeniyle hazır olacak.")
    static let hadithDetailEmptyTitle = L10n.Key("hadith_detail_empty_title", fallback: "Burada hadis görünmüyor")
    static let hadithDetailEmptyMessage = L10n.Key("hadith_detail_empty_message", fallback: "Bu içerik şu an açılamadı. İstersen başka bir hadise geçebilir ya da biraz sonra tekrar deneyebilirsin.")
    static let hadithDetailErrorTitle = L10n.Key("hadith_detail_error_title", fallback: "Küçük bir aksilik oldu")
    static let hadithDetailRetry = L10n.Key("hadith_detail_retry", fallback: "Yeniden Dene")
}

// MARK: - Previews

#Preview("Turkish") {
    HadithDetailPreviewContainer(
        state: .content(.previewTurkish),
        appLanguageCode: "tr",
        appearanceMode: .light
    )
}

#Preview("English") {
    HadithDetailPreviewContainer(
        state: .content(.previewEnglish),
        appLanguageCode: "en",
        appearanceMode: .light
    )
}

#Preview("Arabic") {
    HadithDetailPreviewContainer(
        state: .content(.previewArabic),
        appLanguageCode: "ar",
        appearanceMode: .light
    )
}

#Preview("Long Content") {
    HadithDetailPreviewContainer(
        state: .content(.previewLongForm),
        appLanguageCode: "en",
        appearanceMode: .light
    )
}

#Preview("Dark Mode") {
    HadithDetailPreviewContainer(
        state: .content(.previewTurkish),
        appLanguageCode: "tr",
        appearanceMode: .dark
    )
}

private struct HadithDetailPreviewContainer: View {
    @StateObject private var themeManager: ThemeManager

    private let state: HadithDetailState
    private let appLanguageCode: String

    init(
        state: HadithDetailState,
        appLanguageCode: String,
        appearanceMode: AppAppearanceMode
    ) {
        self.state = state
        self.appLanguageCode = appLanguageCode
        _themeManager = StateObject(
            wrappedValue: ThemeManager.preview(
                theme: .defaultTheme,
                appearanceMode: appearanceMode
            )
        )
    }

    var body: some View {
        NavigationStack {
            HadithDetailView(
                state: state,
                appLanguageCode: appLanguageCode,
                onShare: { _ in }
            )
        }
        .environmentObject(themeManager)
        .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

private extension Hadith {
    static let previewTurkish = Hadith(
        id: 101,
        language: "tr",
        title: "Allah sizin suretlerinize değil, kalplerinize bakar",
        fullHadith: "Şüphesiz Allah sizin suretlerinize ve mallarınıza bakmaz. O sizin kalplerinize ve amellerinize bakar.",
        grade: "Sahih",
        attribution: "Müslim",
        explanation: "Bu hadis, insanın dış görünüşünden çok niyetinin, kalbinin ve davranışlarının kıymetli olduğunu hatırlatır. Manevi derinlik, gösterişten değil samimiyetten doğar.",
        hints: [
            "İnsanı değerli kılan şey görünüşü değil, iç dünyasının temizliğidir.",
            "İbadet ve iyilikler, niyetle birlikte anlam kazanır.",
            "Kalbi korumak, davranışları güzelleştirmenin merkezinde yer alır."
        ],
        hadeethArabic: "إِنَّ اللَّهَ لاَ يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ"
    )

    static let previewEnglish = Hadith(
        id: 102,
        language: "en",
        title: "Mercy is shown to those who are merciful",
        fullHadith: "The Most Merciful shows mercy to those who are merciful. Be merciful to those on the earth and the One above the heavens will have mercy upon you.",
        grade: "Authentic",
        attribution: "Jami' al-Tirmidhi",
        explanation: "Mercy is not a distant virtue in this hadith; it is a living practice. The believer is invited to soften speech, show patience, and meet people with compassion in order to live beneath divine mercy.",
        hints: [
            "Mercy begins in the ordinary moments of daily life.",
            "How we treat others shapes the spiritual atmosphere of our own heart.",
            "Compassion is both a discipline and a form of worship."
        ],
        hadeethArabic: "الرَّاحِمُونَ يَرْحَمُهُمُ الرَّحْمَنُ، ارْحَمُوا مَنْ فِي الأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ"
    )

    static let previewArabic = Hadith(
        id: 103,
        language: "ar",
        title: "الدين النصيحة",
        fullHadith: "الدِّينُ النَّصِيحَةُ. قُلْنَا: لِمَنْ؟ قَالَ: لِلَّهِ وَلِكِتَابِهِ وَلِرَسُولِهِ وَلِأَئِمَّةِ الْمُسْلِمِينَ وَعَامَّتِهِمْ.",
        grade: "صحيح",
        attribution: "صحيح مسلم",
        explanation: "يُظهر هذا الحديث أن الدين ليس طقوسًا مجردة، بل صدقٌ في العلاقة مع الله، وإخلاصٌ في التعامل مع الناس، وحرصٌ على الخير في القول والعمل.",
        hints: [
            "النصيحة تعني الإخلاص والصدق والحرص على الخير.",
            "صلاح القلب ينعكس على طريقة الحديث والمعاملة.",
            "المؤمن يطلب الخير لنفسه ولغيره في هدوء وأمانة."
        ],
        hadeethArabic: "الدِّينُ النَّصِيحَةُ. قُلْنَا: لِمَنْ؟ قَالَ: لِلَّهِ وَلِكِتَابِهِ وَلِرَسُولِهِ وَلِأَئِمَّةِ الْمُسْلِمِينَ وَعَامَّتِهِمْ."
    )

    static let previewLongForm = Hadith(
        id: 104,
        language: "en",
        title: "A believer continues returning to what benefits the heart",
        fullHadith: """
        The Messenger of Allah taught that strength in faith is joined with humility, patience, and steady return to what is beneficial. The heart is not nourished by intensity alone, but by constancy, sincerity, and trust in Allah in every condition.

        When a person meets ease, they show gratitude. When they meet hardship, they show patience. When they make a mistake, they repent quickly and do not remain distant from mercy. In all of this there is goodness for the believer, because every state becomes a path back to Allah.

        This narration invites a life of gentle discipline: to seek what truly benefits, to avoid becoming trapped in regret, and to remember that spiritual steadiness is often quieter than people imagine.
        """,
        grade: "Hasan",
        attribution: "Preview Sample",
        explanation: """
        This long-form sample stresses the screen with multiple paragraphs and a reflective tone. It demonstrates how the layout handles sustained reading, layered spacing, and section rhythm without becoming visually heavy.

        In product terms, this area should feel editorial rather than technical. The line height stays generous, the container remains quiet, and the eye can move naturally from one paragraph to the next.
        """,
        hints: [
            "Benefit in sacred reading often comes through repetition and consistency.",
            "The layout should remain calm even when the content becomes long.",
            "Whitespace is part of the reading experience, not empty space.",
            "The share action should stay reachable without crowding the text."
        ],
        hadeethArabic: "إِنَّ مَعَ الْعَمَلِ الْقَلِيلِ الدَّائِمِ بَرَكَةً، وَإِنَّ الْقَلْبَ إِذَا صَدَقَ فِي رُجُوعِهِ إِلَى اللَّهِ وَجَدَ السَّكِينَةَ وَالطُّمَأْنِينَةَ."
    )
}
