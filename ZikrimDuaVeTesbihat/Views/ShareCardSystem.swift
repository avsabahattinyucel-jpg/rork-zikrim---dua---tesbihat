import SwiftUI
import UIKit

enum ShareCardMode {
    case preview
    case export
}

struct ShareTypography: Equatable {
    let arabicDisplay: CGFloat
    let title: CGFloat
    let body: CGFloat
    let subtitle: CGFloat
    let metadata: CGFloat
    let source: CGFloat
    let statValue: CGFloat
    let statLabel: CGFloat
    let footerTitle: CGFloat
    let footerSubtitle: CGFloat
    let titleLineSpacing: CGFloat
    let bodyLineSpacing: CGFloat
    let metadataLineSpacing: CGFloat
    let blockSpacing: CGFloat

    static let story = ShareTypography(
        arabicDisplay: 106,
        title: 72,
        body: 32,
        subtitle: 40,
        metadata: 22,
        source: 24,
        statValue: 52,
        statLabel: 24,
        footerTitle: 28,
        footerSubtitle: 22,
        titleLineSpacing: 8,
        bodyLineSpacing: 8,
        metadataLineSpacing: 6,
        blockSpacing: 28
    )

    static let adaptiveShort = ShareTypography(
        arabicDisplay: 92,
        title: 52,
        body: 46,
        subtitle: 30,
        metadata: 22,
        source: 24,
        statValue: 52,
        statLabel: 24,
        footerTitle: 26,
        footerSubtitle: 20,
        titleLineSpacing: 7,
        bodyLineSpacing: 12,
        metadataLineSpacing: 6,
        blockSpacing: 34
    )

    static let adaptiveMedium = ShareTypography(
        arabicDisplay: 84,
        title: 44,
        body: 38,
        subtitle: 28,
        metadata: 20,
        source: 22,
        statValue: 52,
        statLabel: 24,
        footerTitle: 24,
        footerSubtitle: 19,
        titleLineSpacing: 7,
        bodyLineSpacing: 10,
        metadataLineSpacing: 6,
        blockSpacing: 28
    )

    static let adaptiveLong = ShareTypography(
        arabicDisplay: 78,
        title: 38,
        body: 31,
        subtitle: 24,
        metadata: 18,
        source: 20,
        statValue: 52,
        statLabel: 24,
        footerTitle: 22,
        footerSubtitle: 18,
        titleLineSpacing: 6,
        bodyLineSpacing: 9,
        metadataLineSpacing: 5,
        blockSpacing: 22
    )

    static let adaptiveUltraLong = ShareTypography(
        arabicDisplay: 72,
        title: 34,
        body: 27,
        subtitle: 22,
        metadata: 16,
        source: 18,
        statValue: 52,
        statLabel: 24,
        footerTitle: 20,
        footerSubtitle: 16,
        titleLineSpacing: 5,
        bodyLineSpacing: 8,
        metadataLineSpacing: 4,
        blockSpacing: 18
    )
}

struct ShareCardTheme: Identifiable, Equatable {
    let id: String
    let displayNameKey: L10n.Key
    let backgroundAssetName: String
    let accentColor: Color
    let topOverlayOpacity: Double
    let bottomOverlayOpacity: Double
    let vignetteOpacity: Double
    let typography: ShareTypography

    var displayName: String {
        L10n.string(displayNameKey)
    }

    static let night = ShareCardTheme(
        id: "night",
        displayNameKey: .verseShareStyleDark,
        backgroundAssetName: "share_bg_moon_soft",
        accentColor: Color(red: 0.83, green: 0.71, blue: 0.45),
        topOverlayOpacity: 0.54,
        bottomOverlayOpacity: 0.92,
        vignetteOpacity: 0.40,
        typography: .story
    )

    static let dawn = ShareCardTheme(
        id: "dawn",
        displayNameKey: .verseShareStyleLight,
        backgroundAssetName: "share_bg_mosque_sunrise",
        accentColor: Color(red: 0.96, green: 0.78, blue: 0.43),
        topOverlayOpacity: 0.48,
        bottomOverlayOpacity: 0.88,
        vignetteOpacity: 0.34,
        typography: .story
    )

    static let emerald = ShareCardTheme(
        id: "emerald",
        displayNameKey: .verseShareStyleEmerald,
        backgroundAssetName: "gunluk_bg_summary_moon",
        accentColor: Color(red: 0.56, green: 0.87, blue: 0.78),
        topOverlayOpacity: 0.50,
        bottomOverlayOpacity: 0.90,
        vignetteOpacity: 0.38,
        typography: .story
    )

    static let kaaba = ShareCardTheme(
        id: "kaaba",
        displayNameKey: .verseShareStyleKaaba,
        backgroundAssetName: "kabe",
        accentColor: Color(red: 0.86, green: 0.74, blue: 0.53),
        topOverlayOpacity: 0.50,
        bottomOverlayOpacity: 0.90,
        vignetteOpacity: 0.36,
        typography: .story
    )

    static let alAqsa = ShareCardTheme(
        id: "al_aqsa",
        displayNameKey: .verseShareStyleAqsa,
        backgroundAssetName: "aksa",
        accentColor: Color(red: 0.65, green: 0.84, blue: 0.70),
        topOverlayOpacity: 0.48,
        bottomOverlayOpacity: 0.88,
        vignetteOpacity: 0.34,
        typography: .story
    )

    static let allThemes: [ShareCardTheme] = [.night, .dawn, .emerald, .kaaba, .alAqsa]
}

struct ShareCardMetrics: Equatable {
    static let exportCanvasSize = CGSize(width: 1080, height: 1920)
    static let aspectRatio = exportCanvasSize.height / exportCanvasSize.width

    let mode: ShareCardMode
    let canvasSize: CGSize
    let renderScale: CGFloat
    let typography: ShareTypography

    private let verticalCompression: CGFloat
    private let panelCompression: CGFloat
    private let textCompression: CGFloat

    static func make(
        for mode: ShareCardMode,
        typography: ShareTypography,
        availableWidth: CGFloat? = nil
    ) -> ShareCardMetrics {
        let canvasSize: CGSize

        switch mode {
        case .export:
            canvasSize = exportCanvasSize
        case .preview:
            let resolvedWidth = max(280, availableWidth ?? 320)
            canvasSize = CGSize(width: resolvedWidth, height: resolvedWidth * aspectRatio)
        }

        let renderScale = canvasSize.width / exportCanvasSize.width

        return ShareCardMetrics(
            mode: mode,
            canvasSize: canvasSize,
            renderScale: renderScale,
            typography: typography,
            verticalCompression: mode == .preview ? 0.88 : 1.0,
            panelCompression: mode == .preview ? 0.90 : 1.0,
            textCompression: mode == .preview ? 0.95 : 1.0
        )
    }

    static func preferredPreviewWidth(for screenWidth: CGFloat) -> CGFloat {
        let ratio: CGFloat
        switch screenWidth {
        case ..<360:
            ratio = 0.80
        case 430...:
            ratio = 0.84
        default:
            ratio = 0.82
        }

        return min(max(screenWidth * ratio, 280), 460)
    }

    var cardCornerRadius: CGFloat {
        mode == .preview ? 30 : 0
    }

    var previewShadowRadius: CGFloat {
        mode == .preview ? 20 : 0
    }

    var previewShadowYOffset: CGFloat {
        mode == .preview ? 10 : 0
    }

    var previewStrokeOpacity: Double {
        mode == .preview ? 0.08 : 0
    }

    var contentPadding: CGFloat {
        80 * renderScale
    }

    var topSafeArea: CGFloat {
        220 * renderScale * verticalCompression
    }

    var bottomSafeArea: CGFloat {
        300 * renderScale * (mode == .preview ? 0.80 : 1.0)
    }

    var heroBadgeSpacing: CGFloat {
        20 * renderScale * verticalCompression
    }

    var blockSpacingSmall: CGFloat {
        18 * renderScale * verticalCompression
    }

    var blockSpacingMedium: CGFloat {
        28 * renderScale * verticalCompression
    }

    var blockSpacingLarge: CGFloat {
        40 * renderScale * verticalCompression
    }

    var blockSpacingXLarge: CGFloat {
        54 * renderScale * verticalCompression
    }

    var accentRuleWidth: CGFloat {
        74 * renderScale
    }

    var accentRuleHeight: CGFloat {
        6 * renderScale
    }

    var badgeInnerSize: CGFloat {
        170 * renderScale * (mode == .preview ? 0.94 : 1.0)
    }

    var badgeOuterSize: CGFloat {
        194 * renderScale * (mode == .preview ? 0.94 : 1.0)
    }

    var badgeIconSize: CGFloat {
        86 * renderScale * (mode == .preview ? 0.94 : 1.0)
    }

    var badgeLabelFontSize: CGFloat {
        28 * renderScale * textCompression
    }

    var badgeLabelTracking: CGFloat {
        4.2 * renderScale
    }

    var quranSurahTitleFontSize: CGFloat {
        42 * renderScale * textCompression
    }

    var titleFontSize: CGFloat {
        typography.title * renderScale * textCompression
    }

    var subtitleFontSize: CGFloat {
        typography.subtitle * renderScale * textCompression
    }

    var arabicFontSize: CGFloat {
        typography.arabicDisplay * renderScale * textCompression
    }

    var arabicLineSpacing: CGFloat {
        20 * renderScale * verticalCompression
    }

    var titleLineSpacing: CGFloat {
        8 * renderScale * verticalCompression
    }

    var subtitleLineSpacing: CGFloat {
        8 * renderScale * verticalCompression
    }

    var footerDescriptorFontSize: CGFloat {
        24 * renderScale * textCompression
    }

    var referenceFontSize: CGFloat {
        50 * renderScale * textCompression
    }

    var dateFontSize: CGFloat {
        24 * renderScale * textCompression
    }

    var statPanelPadding: CGFloat {
        22 * renderScale * panelCompression
    }

    var statPanelCornerRadius: CGFloat {
        36 * renderScale * panelCompression
    }

    var statCardCornerRadius: CGFloat {
        30 * renderScale * panelCompression
    }

    var statCardHeight: CGFloat {
        232 * renderScale * (mode == .preview ? 0.88 : 1.0)
    }

    var statValueFontSize: CGFloat {
        typography.statValue * renderScale * textCompression
    }

    var statLabelFontSize: CGFloat {
        typography.statLabel * renderScale * textCompression
    }

    var statIconSize: CGFloat {
        26 * renderScale * textCompression
    }

    var infoBoxPadding: CGFloat {
        28 * renderScale * panelCompression
    }

    var infoBoxCornerRadius: CGFloat {
        34 * renderScale * panelCompression
    }

    var infoBoxShadowRadius: CGFloat {
        24 * renderScale * panelCompression
    }

    var infoBoxShadowYOffset: CGFloat {
        12 * renderScale * panelCompression
    }

    var footerPadding: CGFloat {
        28 * renderScale * panelCompression
    }

    var footerBrandTitleSize: CGFloat {
        typography.footerTitle * renderScale * textCompression
    }

    var footerBrandSubtitleSize: CGFloat {
        typography.footerSubtitle * renderScale * textCompression
    }

    var progressRingSize: CGFloat {
        320 * renderScale * (mode == .preview ? 0.92 : 1.0)
    }

    var progressLineWidth: CGFloat {
        24 * renderScale * (mode == .preview ? 0.92 : 1.0)
    }

    var progressValueFontSize: CGFloat {
        118 * renderScale * textCompression
    }

    var progressSymbolFontSize: CGFloat {
        36 * renderScale * textCompression
    }

    var progressLabelFontSize: CGFloat {
        28 * renderScale * textCompression
    }

    var wisdomTitleFontSize: CGFloat {
        24 * renderScale * textCompression
    }

    var wisdomTextFontSize: CGFloat {
        34 * renderScale * (mode == .preview ? 0.94 : 1.0)
    }

    var wisdomSubtitleFontSize: CGFloat {
        22 * renderScale * textCompression
    }

    var lessonNumberFontSize: CGFloat {
        20 * renderScale * textCompression
    }

    var lessonNumberSize: CGFloat {
        42 * renderScale
    }

    var lessonTextFontSize: CGFloat {
        28 * renderScale * (mode == .preview ? 0.96 : 1.0)
    }

    var weeklyTaskIconSize: CGFloat {
        56 * renderScale * panelCompression
    }

    var weeklyTaskSymbolSize: CGFloat {
        26 * renderScale * textCompression
    }

    var weeklyTaskTitleFontSize: CGFloat {
        20 * renderScale * textCompression
    }

    var weeklyTaskTextFontSize: CGFloat {
        30 * renderScale * textCompression
    }

    var mainThemeTextFontSize: CGFloat {
        32 * renderScale * textCompression
    }

    var footerMinHeight: CGFloat {
        mode == .preview ? 0 : 0
    }

    var overlayOpacityMultiplier: Double {
        mode == .preview ? 0.96 : 1.0
    }

    var minimumFlexibleSpacer: CGFloat {
        120 * renderScale * verticalCompression
    }

    func adaptiveFontSize(
        for text: String?,
        base: CGFloat,
        shortTextLength: Int,
        longTextLength: Int,
        minimumScale: CGFloat = 0.80,
        maximumScale: CGFloat = 1.08
    ) -> CGFloat {
        let characterCount = trimmedCharacterCount(for: text)
        guard characterCount > 0 else { return base }

        let resolvedShort = max(1, shortTextLength)
        let resolvedLong = max(resolvedShort + 1, longTextLength)

        if characterCount <= resolvedShort {
            let progress = 1 - (CGFloat(characterCount) / CGFloat(resolvedShort))
            let growth = progress * (maximumScale - 1)
            return base * min(maximumScale, 1 + growth)
        }

        let progress = min(
            max(CGFloat(characterCount - resolvedShort) / CGFloat(resolvedLong - resolvedShort), 0),
            1
        )
        let scale = 1 - (progress * (1 - minimumScale))
        return base * max(minimumScale, scale)
    }

    private func trimmedCharacterCount(for text: String?) -> Int {
        text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .count ?? 0
    }
}

struct ShareMetric: Identifiable, Equatable {
    let id: String
    let value: String
    let label: String
    let icon: String

    init(id: String? = nil, value: String, label: String, icon: String) {
        self.id = id ?? "\(label)-\(icon)"
        self.value = value
        self.label = label
        self.icon = icon
    }
}

struct QuranShareCardContent {
    let surahName: String
    let surahArabicName: String
    let verseNumber: Int
    let arabicText: String?
    let translationText: String?
    let translationSourceName: String
    let brandingTitle: String
    let brandingSubtitle: String
}

struct DhikrShareCardContent {
    let completedLabel: String
    let arabicText: String?
    let title: String
    let translationText: String?
    let stats: [ShareMetric]
    let dateText: String
    let brandingTitle: String
    let brandingSubtitle: String
}

struct IslamicDailyShareCardContent {
    let title: String
    let dateText: String
    let progress: Double
    let progressLabel: String
    let metrics: [ShareMetric]
    let quoteText: String
    let quoteReference: String
    let brandingTitle: String
    let brandingSubtitle: String
}

struct KhutbahShareCardContent {
    let title: String
    let dateText: String
    let mainTheme: String
    let lessons: [String]
    let weeklyTask: String?
    let fallbackText: String
    let brandingTitle: String
    let brandingSubtitle: String
}

struct DiyanetShareCardContent {
    let title: String
    let typeText: String
    let categoryText: String
    let summaryTitle: String
    let summaryText: String
    let sourceTitle: String
    let sourceSubtitle: String
    let fullBodyText: String
    let ctaText: String?
    let brandingTitle: String
    let brandingSubtitle: String
}

struct HadithShareCardContent {
    let title: String
    let referenceText: String?
    let bodyText: String
    let fullBodyText: String
    let arabicText: String?
    let explanationText: String?
    let narratorText: String?
    let gradeText: String?
    let brandingTitle: String
    let brandingSubtitle: String
}

struct ShareCardPayload: Identifiable {
    let id: String
    let cardType: ShareCardType
    let navigationTitle: String
    let initialTheme: ShareCardTheme
    let availableThemes: [ShareCardTheme]
    let showsThemePicker: Bool

    init(
        id: String,
        cardType: ShareCardType,
        navigationTitle: String,
        initialTheme: ShareCardTheme = .night,
        availableThemes: [ShareCardTheme] = ShareCardTheme.allThemes,
        showsThemePicker: Bool = true
    ) {
        self.id = id
        self.cardType = cardType
        self.navigationTitle = navigationTitle
        self.initialTheme = initialTheme
        self.availableThemes = availableThemes
        self.showsThemePicker = showsThemePicker
    }
}

enum ShareCardVisualStyle: String, CaseIterable, Identifiable {
    case standard
    case minimal
    case longText
    case summaryFocus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            return "Standart"
        case .minimal:
            return "Sade"
        case .longText:
            return "Uzun Metin"
        case .summaryFocus:
            return "Özet Odaklı"
        }
    }

    var subtitle: String {
        switch self {
        case .standard:
            return "Dengeli klasik düzen"
        case .minimal:
            return "Sade ama lüks görünüm"
        case .longText:
            return "Tam metin okunabilirliği"
        case .summaryFocus:
            return "Özet kutusu vurgulu"
        }
    }

    var systemImage: String {
        switch self {
        case .standard:
            return "square.text.square.fill"
        case .minimal:
            return "rectangle.compress.vertical"
        case .longText:
            return "text.alignleft"
        case .summaryFocus:
            return "text.quote"
        }
    }

    var previewTint: Color {
        switch self {
        case .standard:
            return Color(red: 0.83, green: 0.71, blue: 0.45)
        case .minimal:
            return Color(red: 0.73, green: 0.81, blue: 0.86)
        case .longText:
            return Color(red: 0.64, green: 0.83, blue: 0.75)
        case .summaryFocus:
            return Color(red: 0.94, green: 0.78, blue: 0.53)
        }
    }

    var badgeScale: CGFloat {
        switch self {
        case .standard:
            return 1.0
        case .minimal:
            return 0.76
        case .longText:
            return 0.82
        case .summaryFocus:
            return 0.88
        }
    }

    var primaryPanelOpacity: Double {
        switch self {
        case .standard:
            return 0.42
        case .minimal:
            return 0.24
        case .longText:
            return 0.54
        case .summaryFocus:
            return 0.60
        }
    }

    var secondaryPanelOpacity: Double {
        switch self {
        case .standard:
            return 0.40
        case .minimal:
            return 0.20
        case .longText:
            return 0.42
        case .summaryFocus:
            return 0.46
        }
    }

    var prefersCompactFooter: Bool {
        self != .standard
    }

    var prefersPanelEmphasis: Bool {
        switch self {
        case .standard:
            return false
        case .minimal:
            return false
        case .longText, .summaryFocus:
            return true
        }
    }
}

enum ShareCardContentKind {
    case hadith
    case diyanet
}

enum ShareContentClassification: String {
    case compact
    case balanced
    case extended
    case summaryFirst
}

struct ShareCardMetadataItem: Identifiable, Hashable {
    let id: String
    let label: String
    let value: String
    let systemImage: String

    init(id: String? = nil, label: String, value: String, systemImage: String) {
        self.id = id ?? "\(label)-\(value)"
        self.label = label
        self.value = value
        self.systemImage = systemImage
    }
}

struct ShareCardContent {
    let kind: ShareCardContentKind
    let eyebrow: String?
    let category: String?
    let title: String?
    let shortBody: String?
    let fullBody: String
    let shareSummary: String?
    let sourceTitle: String?
    let sourceText: String?
    let sourceDetail: String?
    let metadata: [ShareCardMetadataItem]
    let explanation: String?
    let supportingBody: String?
    let ctaText: String?
    let brandingTitle: String
    let brandingSubtitle: String
}

struct ShareLayoutPreset {
    let classification: ShareContentClassification
    let contentAlignment: Alignment
    let textAlignment: TextAlignment
    let topPaddingMultiplier: CGFloat
    let iconScale: CGFloat
    let sectionSpacingMultiplier: CGFloat
    let sourceBoxHeightMultiplier: CGFloat
    let footerHeightMultiplier: CGFloat
    let overlayBoost: Double
    let secondaryOverlayBoost: Double
    let summaryPanelOpacity: Double
    let secondaryPanelOpacity: Double
    let compactFooter: Bool
    let bodyPanelUsesGlass: Bool
    let showsCTA: Bool

    func tightened() -> ShareLayoutPreset {
        ShareLayoutPreset(
            classification: classification,
            contentAlignment: contentAlignment,
            textAlignment: textAlignment,
            topPaddingMultiplier: topPaddingMultiplier * 0.92,
            iconScale: iconScale * 0.94,
            sectionSpacingMultiplier: sectionSpacingMultiplier * 0.88,
            sourceBoxHeightMultiplier: sourceBoxHeightMultiplier * 0.90,
            footerHeightMultiplier: footerHeightMultiplier * 0.88,
            overlayBoost: overlayBoost + 0.05,
            secondaryOverlayBoost: secondaryOverlayBoost + 0.04,
            summaryPanelOpacity: min(summaryPanelOpacity + 0.05, 0.82),
            secondaryPanelOpacity: min(secondaryPanelOpacity + 0.05, 0.72),
            compactFooter: true,
            bodyPanelUsesGlass: bodyPanelUsesGlass,
            showsCTA: showsCTA
        )
    }

    static func make(
        kind: ShareCardContentKind,
        classification: ShareContentClassification,
        style: ShareCardVisualStyle
    ) -> ShareLayoutPreset {
        switch (kind, classification, style) {
        case (.hadith, .compact, .minimal):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .center,
                textAlignment: .center,
                topPaddingMultiplier: 1.10,
                iconScale: 0.88,
                sectionSpacingMultiplier: 1.08,
                sourceBoxHeightMultiplier: 0.90,
                footerHeightMultiplier: 0.84,
                overlayBoost: 0.04,
                secondaryOverlayBoost: 0.02,
                summaryPanelOpacity: 0.46,
                secondaryPanelOpacity: 0.30,
                compactFooter: false,
                bodyPanelUsesGlass: false,
                showsCTA: false
            )
        case (.hadith, .compact, _):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .center,
                textAlignment: .center,
                topPaddingMultiplier: 1.14,
                iconScale: 1.00,
                sectionSpacingMultiplier: 1.14,
                sourceBoxHeightMultiplier: 1.00,
                footerHeightMultiplier: 1.00,
                overlayBoost: 0.02,
                secondaryOverlayBoost: 0.01,
                summaryPanelOpacity: 0.48,
                secondaryPanelOpacity: 0.28,
                compactFooter: false,
                bodyPanelUsesGlass: false,
                showsCTA: false
            )
        case (.hadith, .balanced, .longText), (.hadith, .extended, _), (.hadith, .summaryFirst, _):
            return ShareLayoutPreset(
                classification: classification == .summaryFirst ? .extended : classification,
                contentAlignment: .center,
                textAlignment: .center,
                topPaddingMultiplier: 0.94,
                iconScale: 0.84,
                sectionSpacingMultiplier: 0.90,
                sourceBoxHeightMultiplier: 0.92,
                footerHeightMultiplier: 0.82,
                overlayBoost: 0.10,
                secondaryOverlayBoost: 0.07,
                summaryPanelOpacity: 0.62,
                secondaryPanelOpacity: 0.46,
                compactFooter: true,
                bodyPanelUsesGlass: true,
                showsCTA: false
            )
        case (.hadith, .balanced, _):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .center,
                textAlignment: .center,
                topPaddingMultiplier: 1.00,
                iconScale: 0.92,
                sectionSpacingMultiplier: 1.00,
                sourceBoxHeightMultiplier: 0.98,
                footerHeightMultiplier: 0.92,
                overlayBoost: 0.06,
                secondaryOverlayBoost: 0.04,
                summaryPanelOpacity: 0.54,
                secondaryPanelOpacity: 0.36,
                compactFooter: false,
                bodyPanelUsesGlass: false,
                showsCTA: false
            )
        case (.diyanet, .summaryFirst, _):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .leading,
                textAlignment: .leading,
                topPaddingMultiplier: 0.98,
                iconScale: 0.82,
                sectionSpacingMultiplier: 0.96,
                sourceBoxHeightMultiplier: 0.96,
                footerHeightMultiplier: 0.82,
                overlayBoost: 0.09,
                secondaryOverlayBoost: 0.07,
                summaryPanelOpacity: 0.68,
                secondaryPanelOpacity: 0.42,
                compactFooter: true,
                bodyPanelUsesGlass: true,
                showsCTA: true
            )
        case (.diyanet, .extended, _), (.diyanet, .balanced, .longText):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .leading,
                textAlignment: .leading,
                topPaddingMultiplier: 0.92,
                iconScale: 0.78,
                sectionSpacingMultiplier: 0.86,
                sourceBoxHeightMultiplier: 0.88,
                footerHeightMultiplier: 0.78,
                overlayBoost: 0.12,
                secondaryOverlayBoost: 0.08,
                summaryPanelOpacity: 0.72,
                secondaryPanelOpacity: 0.46,
                compactFooter: true,
                bodyPanelUsesGlass: true,
                showsCTA: true
            )
        case (.diyanet, .compact, .minimal):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .leading,
                textAlignment: .leading,
                topPaddingMultiplier: 1.04,
                iconScale: 0.72,
                sectionSpacingMultiplier: 1.02,
                sourceBoxHeightMultiplier: 0.90,
                footerHeightMultiplier: 0.78,
                overlayBoost: 0.05,
                secondaryOverlayBoost: 0.03,
                summaryPanelOpacity: 0.58,
                secondaryPanelOpacity: 0.34,
                compactFooter: true,
                bodyPanelUsesGlass: true,
                showsCTA: false
            )
        case (.diyanet, .compact, _):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .leading,
                textAlignment: .leading,
                topPaddingMultiplier: 1.02,
                iconScale: 0.76,
                sectionSpacingMultiplier: 1.00,
                sourceBoxHeightMultiplier: 0.94,
                footerHeightMultiplier: 0.82,
                overlayBoost: 0.04,
                secondaryOverlayBoost: 0.03,
                summaryPanelOpacity: 0.62,
                secondaryPanelOpacity: 0.36,
                compactFooter: false,
                bodyPanelUsesGlass: true,
                showsCTA: true
            )
        case (.diyanet, .balanced, _):
            return ShareLayoutPreset(
                classification: classification,
                contentAlignment: .leading,
                textAlignment: .leading,
                topPaddingMultiplier: 0.98,
                iconScale: 0.80,
                sectionSpacingMultiplier: 0.94,
                sourceBoxHeightMultiplier: 0.92,
                footerHeightMultiplier: 0.84,
                overlayBoost: 0.07,
                secondaryOverlayBoost: 0.05,
                summaryPanelOpacity: 0.66,
                secondaryPanelOpacity: 0.40,
                compactFooter: false,
                bodyPanelUsesGlass: true,
                showsCTA: true
            )
        }
    }
}

enum ShareCardType {
    case quran(QuranShareCardContent)
    case dhikr(DhikrShareCardContent)
    case islamicDaily(IslamicDailyShareCardContent)
    case khutbah(KhutbahShareCardContent)
    case diyanet(DiyanetShareCardContent)
    case hadith(HadithShareCardContent)

    var supportsLanguageSelection: Bool {
        if case .quran = self {
            return true
        }
        return false
    }

    var supportsStyleSelection: Bool {
        true
    }
}

@MainActor
enum ShareCardRenderer {
    static func render(
        cardType: ShareCardType,
        theme: ShareCardTheme,
        quranDisplayMode: QuranShareDisplayMode = .both,
        shareStyle: ShareCardVisualStyle = .standard
    ) async -> UIImage? {
        let metrics = ShareCardMetrics.make(for: .export, typography: theme.typography)
        let content = ShareCardView(
            cardType: cardType,
            theme: theme,
            mode: .export,
            quranDisplayMode: quranDisplayMode,
            shareStyle: shareStyle
        )
        .frame(width: metrics.canvasSize.width, height: metrics.canvasSize.height)
        .background(Color.black)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1.0
        renderer.proposedSize = ProposedViewSize(metrics.canvasSize)

        await Task.yield()

        guard let image = renderer.uiImage,
              image.size.width > 0,
              image.size.height > 0 else {
            return nil
        }

        return image
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

typealias ShareSheet = ActivityShareSheet

struct SharePreviewScreen<AccessoryContent: View>: View {
    let cardType: ShareCardType
    let initialTheme: ShareCardTheme
    let availableThemes: [ShareCardTheme]
    let showsThemePicker: Bool
    let backgroundColor: Color
    let accessoryContent: () -> AccessoryContent

    @State private var selectedTheme: ShareCardTheme
    @State private var quranDisplayMode: QuranShareDisplayMode = .both
    @State private var selectedShareStyle: ShareCardVisualStyle = .standard
    @State private var renderedImage: UIImage?
    @State private var isPreparingShare: Bool = false
    @State private var isShareSheetPresented: Bool = false
    @State private var shareErrorMessage: String?

    init(
        cardType: ShareCardType,
        initialTheme: ShareCardTheme = .night,
        availableThemes: [ShareCardTheme] = ShareCardTheme.allThemes,
        showsThemePicker: Bool = true,
        backgroundColor: Color = Color(.systemGroupedBackground),
        @ViewBuilder accessoryContent: @escaping () -> AccessoryContent
    ) {
        self.cardType = cardType
        self.initialTheme = initialTheme
        self.availableThemes = availableThemes
        self.showsThemePicker = showsThemePicker
        self.backgroundColor = backgroundColor
        self.accessoryContent = accessoryContent
        _selectedTheme = State(initialValue: initialTheme)
    }

    var body: some View {
        GeometryReader { proxy in
            let previewWidth = ShareCardMetrics.preferredPreviewWidth(for: proxy.size.width)
            let previewMetrics = ShareCardMetrics.make(
                for: .preview,
                typography: selectedTheme.typography,
                availableWidth: previewWidth
            )

            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        SharePreviewContainer(metrics: previewMetrics) {
                            ShareCardView(
                                cardType: cardType,
                                theme: selectedTheme,
                                mode: .preview,
                                quranDisplayMode: quranDisplayMode,
                                shareStyle: selectedShareStyle,
                                availableWidth: previewWidth
                            )
                        }

                        if showsThemePicker {
                            ShareBackgroundSelector(
                                themes: availableThemes,
                                selectedTheme: $selectedTheme
                            )
                        }

                        if cardType.supportsLanguageSelection {
                            ShareModeSelector(selection: $quranDisplayMode)
                        }

                        if cardType.supportsStyleSelection {
                            ShareStyleSelector(selection: $selectedShareStyle, accentColor: selectedTheme.accentColor)
                        }

                        VStack(spacing: 12) {
                            SharePrimaryButton(
                                titleKey: .commonShare,
                                systemImage: "square.and.arrow.up",
                                accentColor: selectedTheme.accentColor,
                                isLoading: isPreparingShare
                            ) {
                                Task {
                                    await shareRenderedCard()
                                }
                            }
                            .disabled(isPreparingShare)

                            ShareSecondaryButton(
                                titleKey: .verseShareSaveGallery,
                                systemImage: "photo.badge.plus",
                                isLoading: false
                            ) {
                                Task {
                                    await saveRenderedCardToPhotos()
                                }
                            }
                            .disabled(isPreparingShare)
                        }
                        .padding(.top, 12)

                        accessoryContent()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 20) + 44)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let renderedImage {
                ActivityShareSheet(items: [renderedImage])
            }
        }
        .alert(L10n.string(.paylas), isPresented: Binding(
            get: { shareErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    shareErrorMessage = nil
                }
            }
        )) {
            Button(L10n.string(.tamam2), role: .cancel) {
                shareErrorMessage = nil
            }
        } message: {
            Text(shareErrorMessage ?? L10n.string(.errorUnexpectedTryAgain))
        }
        .onChange(of: selectedTheme) { _, _ in
            renderedImage = nil
        }
        .onChange(of: quranDisplayMode) { _, _ in
            renderedImage = nil
        }
        .onChange(of: selectedShareStyle) { _, _ in
            renderedImage = nil
        }
    }

    @MainActor
    private func shareRenderedCard() async {
        guard let image = await prepareRenderedCard() else { return }
        renderedImage = image
        isShareSheetPresented = true
    }

    @MainActor
    private func saveRenderedCardToPhotos() async {
        guard let image = await prepareRenderedCard() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    @MainActor
    private func prepareRenderedCard() async -> UIImage? {
        guard !isPreparingShare else { return nil }
        isPreparingShare = true
        shareErrorMessage = nil

        defer {
            isPreparingShare = false
        }

        if let renderedImage {
            return renderedImage
        }

        let image = await ShareCardRenderer.render(
            cardType: cardType,
            theme: selectedTheme,
            quranDisplayMode: quranDisplayMode,
            shareStyle: selectedShareStyle
        )

        guard let image else {
            shareErrorMessage = L10n.string(.errorUnexpectedTryAgain)
            return nil
        }

        renderedImage = image
        return image
    }
}

extension SharePreviewScreen where AccessoryContent == EmptyView {
    init(
        cardType: ShareCardType,
        initialTheme: ShareCardTheme = .night,
        availableThemes: [ShareCardTheme] = ShareCardTheme.allThemes,
        showsThemePicker: Bool = true,
        backgroundColor: Color = Color(.systemGroupedBackground)
    ) {
        self.init(
            cardType: cardType,
            initialTheme: initialTheme,
            availableThemes: availableThemes,
            showsThemePicker: showsThemePicker,
            backgroundColor: backgroundColor
        ) {
            EmptyView()
        }
    }
}

struct SharePreviewContainer<Content: View>: View {
    let metrics: ShareCardMetrics
    let content: Content

    @State private var isVisible: Bool = false

    init(metrics: ShareCardMetrics, @ViewBuilder content: () -> Content) {
        self.metrics = metrics
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(metrics.previewStrokeOpacity), lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(metrics.mode == .preview ? 0.20 : 0),
                radius: metrics.previewShadowRadius,
                y: metrics.previewShadowYOffset
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.985)
            .animation(.easeOut(duration: 0.28), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct ShareBackgroundSelector: View {
    let themes: [ShareCardTheme]
    @Binding var selectedTheme: ShareCardTheme

    var body: some View {
        VStack(spacing: 14) {
            Text(.dhikrShareBackgroundsTitle)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(themes) { theme in
                        Button {
                            withAnimation(.spring(duration: 0.24)) {
                                selectedTheme = theme
                            }
                        } label: {
                            themeButtonContent(for: theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(minHeight: 118)
        }
        .padding(.bottom, 10)
    }

    private func themeButtonContent(for theme: ShareCardTheme) -> some View {
        let isSelected = selectedTheme.id == theme.id

        return VStack(spacing: 10) {
            thumbnailImage(for: theme, isSelected: isSelected)
            thumbnailLabel(for: theme, isSelected: isSelected)
        }
        .frame(width: 80)
        .frame(minHeight: 108, alignment: .top)
        .padding(.vertical, 2)
    }

    private func thumbnailImage(for theme: ShareCardTheme, isSelected: Bool) -> some View {
        let thumbnailShape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        let strokeColor = isSelected ? theme.accentColor : Color.white.opacity(0.08)
        let strokeWidth: CGFloat = isSelected ? 2.5 : 1
        let shadowColor = theme.accentColor.opacity(isSelected ? 0.24 : 0)

        return Image(theme.backgroundAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: 68, height: 68)
            .clipShape(thumbnailShape)
            .overlay(thumbnailShape.fill(Color.black.opacity(0.18)))
            .overlay(thumbnailShape.stroke(strokeColor, lineWidth: strokeWidth))
            .shadow(color: shadowColor, radius: 14, y: 6)
    }

    private func thumbnailLabel(for theme: ShareCardTheme, isSelected: Bool) -> some View {
        let labelColor = isSelected
            ? Color(uiColor: .label)
            : Color(uiColor: .label).opacity(0.72)

        return Text(theme.displayName)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(labelColor)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

struct ShareModeSelector: View {
    @Binding var selection: QuranShareDisplayMode

    var body: some View {
        VStack(spacing: 10) {
            Text(.verseShareContentPicker)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker(L10n.string(.verseShareContentPicker), selection: $selection) {
                ForEach(QuranShareDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.localizedTitle).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct ShareStyleSelector: View {
    @Binding var selection: ShareCardVisualStyle
    let accentColor: Color

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Paylaşım stili")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("Kart düzeni metnin yoğunluğuna göre otomatik uyarlanır; burada görsel dili seçiyorsun.")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(ShareCardVisualStyle.allCases) { style in
                        Button {
                            withAnimation(.spring(duration: 0.24)) {
                                selection = style
                            }
                        } label: {
                            ShareStyleOptionCard(
                                style: style,
                                isSelected: selection == style,
                                accentColor: accentColor
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ShareStyleOptionCard: View {
    let style: ShareCardVisualStyle
    let isSelected: Bool
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            stylePreview

            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(style.previewTint.opacity(isSelected ? 0.28 : 0.18))
                        .frame(width: 34, height: 34)

                    Image(systemName: style.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(style.previewTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.88))

                    Text(style.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .frame(width: 196)
        .padding(14)
        .background(cardBackground)
        .overlay(cardStroke)
        .shadow(color: shadowColor, radius: 18, y: 10)
        .scaleEffect(isSelected ? 1.0 : 0.985)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isSelected
                        ? [
                            Color.white.opacity(0.96),
                            accentColor.opacity(0.10)
                        ]
                        : [
                            Color(uiColor: .secondarySystemGroupedBackground),
                            Color.white.opacity(0.86)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(
                isSelected ? accentColor.opacity(0.34) : Color.black.opacity(0.06),
                lineWidth: isSelected ? 1.5 : 1
            )
    }

    private var shadowColor: Color {
        isSelected ? accentColor.opacity(0.18) : Color.black.opacity(0.08)
    }

    private var stylePreview: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.82),
                            style.previewTint.opacity(0.32),
                            Color.black.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 132)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(height: 132)

            VStack(alignment: .leading, spacing: previewSpacing) {
                Capsule()
                    .fill(style.previewTint.opacity(0.92))
                    .frame(width: previewBadgeWidth, height: 6)

                previewBlocks

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color.white.opacity(0.26))
                        .frame(width: 28, height: 4)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .frame(width: previewFooterWidth, height: 16)
                }
            }
            .padding(14)
        }
    }

    @ViewBuilder
    private var previewBlocks: some View {
        switch style {
        case .standard:
            VStack(alignment: .leading, spacing: 10) {
                previewLine(width: 0.76, height: 10, opacity: 0.90)
                previewLine(width: 0.58, height: 10, opacity: 0.72)
                roundedPanel(width: 1.0, height: 42, fill: 0.18)
            }
        case .minimal:
            VStack(alignment: .leading, spacing: 8) {
                previewLine(width: 0.52, height: 8, opacity: 0.88)
                previewLine(width: 0.42, height: 8, opacity: 0.68)
                HStack(spacing: 8) {
                    previewLine(width: 0.20, height: 5, opacity: 0.34)
                    previewLine(width: 0.36, height: 5, opacity: 0.18)
                }
            }
        case .longText:
            VStack(alignment: .leading, spacing: 7) {
                previewLine(width: 0.80, height: 9, opacity: 0.90)
                previewLine(width: 0.84, height: 9, opacity: 0.78)
                previewLine(width: 0.82, height: 9, opacity: 0.68)
                previewLine(width: 0.70, height: 9, opacity: 0.56)
                roundedPanel(width: 1.0, height: 24, fill: 0.14)
            }
        case .summaryFocus:
            VStack(alignment: .leading, spacing: 10) {
                previewLine(width: 0.60, height: 8, opacity: 0.76)
                roundedPanel(width: 1.0, height: 48, fill: 0.24)
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 5) {
                        previewLine(width: 0.34, height: 6, opacity: 0.62)
                        previewLine(width: 0.48, height: 6, opacity: 0.42)
                    }
                }
            }
        }
    }

    private var previewSpacing: CGFloat {
        switch style {
        case .longText:
            return 8
        default:
            return 10
        }
    }

    private var previewBadgeWidth: CGFloat {
        switch style {
        case .minimal:
            return 30
        case .summaryFocus:
            return 42
        default:
            return 36
        }
    }

    private var previewFooterWidth: CGFloat {
        switch style {
        case .minimal:
            return 42
        case .longText:
            return 54
        default:
            return 68
        }
    }

    private func previewLine(width: CGFloat, height: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(Color.white.opacity(opacity))
            .frame(width: 150 * width, height: height)
    }

    private func roundedPanel(width: CGFloat, height: CGFloat, fill: Double) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(fill))
            .frame(width: 168 * width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct SharePrimaryButton: View {
    let titleKey: L10n.Key
    let systemImage: String
    let accentColor: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(titleKey)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .themedPrimaryButton(cornerRadius: 18, fill: accentColor)
        }
        .buttonStyle(.plain)
    }
}

struct ShareSecondaryButton: View {
    let titleKey: L10n.Key
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(titleKey)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .themedSecondaryButton(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

struct ShareCardView: View {
    let cardType: ShareCardType
    let theme: ShareCardTheme
    let mode: ShareCardMode
    let quranDisplayMode: QuranShareDisplayMode
    let shareStyle: ShareCardVisualStyle
    let availableWidth: CGFloat?

    init(
        cardType: ShareCardType,
        theme: ShareCardTheme,
        mode: ShareCardMode,
        quranDisplayMode: QuranShareDisplayMode = .both,
        shareStyle: ShareCardVisualStyle = .standard,
        availableWidth: CGFloat? = nil
    ) {
        self.cardType = cardType
        self.theme = theme
        self.mode = mode
        self.quranDisplayMode = quranDisplayMode
        self.shareStyle = shareStyle
        self.availableWidth = availableWidth
    }

    private var metrics: ShareCardMetrics {
        ShareCardMetrics.make(for: mode, typography: theme.typography, availableWidth: availableWidth)
    }

    var body: some View {
        switch cardType {
        case .quran(let content):
            QuranShareCardView(
                content: content,
                theme: theme,
                metrics: metrics,
                quranDisplayMode: quranDisplayMode,
                shareStyle: shareStyle
            )
        case .dhikr(let content):
            DhikrShareCardView(content: content, theme: theme, metrics: metrics, shareStyle: shareStyle)
        case .islamicDaily(let content):
            IslamicDailyShareCardView(content: content, theme: theme, metrics: metrics, shareStyle: shareStyle)
        case .khutbah(let content):
            KhutbahShareCardView(content: content, theme: theme, metrics: metrics, shareStyle: shareStyle)
        case .diyanet(let content):
            DiyanetShareCardView(content: content, theme: theme, metrics: metrics, shareStyle: shareStyle)
        case .hadith(let content):
            HadithShareCardView(content: content, theme: theme, metrics: metrics, shareStyle: shareStyle)
        }
    }
}

struct ShareCardCanvas<Content: View>: View {
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let content: Content

    init(theme: ShareCardTheme, metrics: ShareCardMetrics, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.metrics = metrics
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.05, blue: 0.10)

            Image(theme.backgroundAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: metrics.canvasSize.width, height: metrics.canvasSize.height)
                .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(theme.topOverlayOpacity * metrics.overlayOpacityMultiplier),
                    Color.black.opacity(0.34 * metrics.overlayOpacityMultiplier),
                    Color.black.opacity(theme.bottomOverlayOpacity * metrics.overlayOpacityMultiplier)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    theme.accentColor.opacity(0.16),
                    Color.clear,
                    Color.black.opacity(theme.vignetteOpacity * metrics.overlayOpacityMultiplier)
                ],
                center: .center,
                startRadius: 120 * metrics.renderScale,
                endRadius: 980 * metrics.renderScale
            )

            content
                .padding(.horizontal, metrics.contentPadding)
        }
        .frame(width: metrics.canvasSize.width, height: metrics.canvasSize.height)
        .clipped()
    }
}

private struct AdaptiveShareCardResolution {
    let classification: ShareContentClassification
    let typography: ShareTypography
    let preset: ShareLayoutPreset
    let estimatedHeight: CGFloat
    let bodyLineLimit: Int?
    let summaryLineLimit: Int?
    let usesFade: Bool
}

private enum AdaptiveShareCardResolver {
    static func resolve(
        content: ShareCardContent,
        metrics: ShareCardMetrics,
        style: ShareCardVisualStyle
    ) -> AdaptiveShareCardResolution {
        let classification = classify(content: content, style: style, metrics: metrics)
        let baseTypography = typography(for: classification, style: style)
        let basePreset = ShareLayoutPreset.make(kind: content.kind, classification: classification, style: style)
        let smallerTypography = downgradedTypography(from: baseTypography, style: style)
        let smallestTypography = downgradedTypography(from: smallerTypography, style: style)
        let tighterPreset = basePreset.tightened()
        let alternatePreset = alternatePreset(from: basePreset, content: content, style: style)

        let candidates: [(ShareTypography, ShareLayoutPreset, Int?, Int?, Bool)] = [
            (baseTypography, basePreset, nil, nil, false),
            (smallerTypography, basePreset, nil, nil, false),
            (smallestTypography, basePreset, nil, nil, false),
            (smallerTypography, tighterPreset, nil, nil, false),
            (smallestTypography, tighterPreset, nil, nil, false),
            (smallerTypography, alternatePreset, nil, nil, false),
            (smallestTypography, alternatePreset, nil, nil, false),
            (smallestTypography, alternatePreset, fallbackBodyLimit(for: content, style: style), fallbackSummaryLimit(for: content, style: style), style != .longText)
        ]

        for (typography, preset, bodyLimit, summaryLimit, usesFade) in candidates {
            let estimatedHeight = estimateHeight(
                content: content,
                metrics: metrics,
                typography: typography,
                preset: preset,
                bodyLineLimit: bodyLimit,
                summaryLineLimit: summaryLimit
            )

            if estimatedHeight <= availableHeight(metrics: metrics) || usesFade {
                return AdaptiveShareCardResolution(
                    classification: classification,
                    typography: typography,
                    preset: preset,
                    estimatedHeight: estimatedHeight,
                    bodyLineLimit: bodyLimit,
                    summaryLineLimit: summaryLimit,
                    usesFade: usesFade
                )
            }
        }

        return AdaptiveShareCardResolution(
            classification: classification,
            typography: smallestTypography,
            preset: alternatePreset,
            estimatedHeight: estimateHeight(
                content: content,
                metrics: metrics,
                typography: smallestTypography,
                preset: alternatePreset,
                bodyLineLimit: fallbackBodyLimit(for: content, style: style),
                summaryLineLimit: fallbackSummaryLimit(for: content, style: style)
            ),
            bodyLineLimit: fallbackBodyLimit(for: content, style: style),
            summaryLineLimit: fallbackSummaryLimit(for: content, style: style),
            usesFade: style != .longText
        )
    }

    private static func classify(
        content: ShareCardContent,
        style: ShareCardVisualStyle,
        metrics: ShareCardMetrics
    ) -> ShareContentClassification {
        if style == .summaryFocus, content.shareSummary?.trimmedNilIfEmpty != nil {
            return .summaryFirst
        }

        let titleLength = content.title?.trimmedNilIfEmpty?.count ?? 0
        let bodyLength = content.shortBody?.trimmedNilIfEmpty?.count ?? 0
        let summaryLength = content.shareSummary?.trimmedNilIfEmpty?.count ?? 0
        let hasSecondaryContent = !content.metadata.isEmpty || content.sourceText?.trimmedNilIfEmpty != nil || content.category?.trimmedNilIfEmpty != nil
        let renderDensity = CGFloat(titleLength + bodyLength + summaryLength) / max(metrics.canvasSize.height, 1)

        if content.kind == .diyanet, summaryLength > 0, (style == .summaryFocus || summaryLength >= 180) {
            return .summaryFirst
        }

        if renderDensity < 0.12, titleLength < 38, bodyLength < 180, summaryLength < 170, hasSecondaryContent {
            return .compact
        }

        if style == .longText || bodyLength > 340 || summaryLength > 280 || titleLength > 92 || renderDensity > 0.28 {
            return .extended
        }

        return .balanced
    }

    private static func typography(for classification: ShareContentClassification, style: ShareCardVisualStyle) -> ShareTypography {
        if style == .longText {
            switch classification {
            case .compact:
                return .adaptiveMedium
            case .balanced:
                return .adaptiveLong
            case .extended, .summaryFirst:
                return .adaptiveUltraLong
            }
        }

        switch (classification, style) {
        case (.compact, .minimal):
            return ShareTypography(
                arabicDisplay: ShareTypography.adaptiveShort.arabicDisplay,
                title: 46,
                body: 40,
                subtitle: 26,
                metadata: 20,
                source: 22,
                statValue: ShareTypography.adaptiveShort.statValue,
                statLabel: ShareTypography.adaptiveShort.statLabel,
                footerTitle: 24,
                footerSubtitle: 18,
                titleLineSpacing: 6,
                bodyLineSpacing: 11,
                metadataLineSpacing: 5,
                blockSpacing: 28
            )
        case (.compact, _):
            return .adaptiveShort
        case (.extended, _), (.summaryFirst, _):
            return .adaptiveLong
        default:
            return .adaptiveMedium
        }
    }

    private static func downgradedTypography(from typography: ShareTypography, style: ShareCardVisualStyle) -> ShareTypography {
        if style == .longText {
            if typography == .adaptiveMedium {
                return .adaptiveLong
            }
            if typography == .adaptiveLong {
                return .adaptiveUltraLong
            }
            return .adaptiveUltraLong
        }

        if typography == .adaptiveShort {
            return .adaptiveMedium
        }
        if typography == .adaptiveMedium {
            return .adaptiveLong
        }
        return .adaptiveLong
    }

    private static func alternatePreset(
        from preset: ShareLayoutPreset,
        content: ShareCardContent,
        style: ShareCardVisualStyle
    ) -> ShareLayoutPreset {
        switch content.kind {
        case .hadith:
            return ShareLayoutPreset.make(kind: .hadith, classification: .extended, style: style)
        case .diyanet:
            return ShareLayoutPreset.make(kind: .diyanet, classification: .summaryFirst, style: style)
        }
    }

    private static func fallbackBodyLimit(for content: ShareCardContent, style: ShareCardVisualStyle) -> Int? {
        if style == .longText {
            return nil
        }
        switch content.kind {
        case .hadith:
            return 14
        case .diyanet:
            return nil
        }
    }

    private static func fallbackSummaryLimit(for content: ShareCardContent, style: ShareCardVisualStyle) -> Int? {
        if style == .longText {
            return nil
        }
        switch content.kind {
        case .hadith:
            return nil
        case .diyanet:
            return 10
        }
    }

    private static func availableHeight(metrics: ShareCardMetrics) -> CGFloat {
        metrics.canvasSize.height - (180 * metrics.renderScale)
    }

    private static func estimateHeight(
        content: ShareCardContent,
        metrics: ShareCardMetrics,
        typography: ShareTypography,
        preset: ShareLayoutPreset,
        bodyLineLimit: Int?,
        summaryLineLimit: Int?
    ) -> CGFloat {
        switch content.kind {
        case .hadith:
            return estimateHadithHeight(
                content: content,
                metrics: metrics,
                typography: typography,
                preset: preset,
                bodyLineLimit: bodyLineLimit
            )
        case .diyanet:
            return estimateDiyanetHeight(
                content: content,
                metrics: metrics,
                typography: typography,
                preset: preset,
                summaryLineLimit: summaryLineLimit
            )
        }
    }

    private static func estimateHadithHeight(
        content: ShareCardContent,
        metrics: ShareCardMetrics,
        typography: ShareTypography,
        preset: ShareLayoutPreset,
        bodyLineLimit: Int?
    ) -> CGFloat {
        let width = metrics.canvasSize.width - (metrics.contentPadding * 2)
        let bodyWidth = width * (preset.bodyPanelUsesGlass ? 0.88 : 0.92)
        let spacing = typography.blockSpacing * metrics.renderScale * preset.sectionSpacingMultiplier
        var total = (metrics.topSafeArea * preset.topPaddingMultiplier) + (150 * metrics.renderScale * preset.iconScale)

        total += textHeight(
            content.eyebrow,
            width: width,
            fontSize: typography.metadata * metrics.renderScale,
            weight: .semibold,
            lineSpacing: typography.metadataLineSpacing * metrics.renderScale,
            lineLimit: 1
        )

        total += textHeight(
            content.title,
            width: width * 0.86,
            fontSize: typography.title * metrics.renderScale * 0.72,
            weight: .semibold,
            lineSpacing: typography.titleLineSpacing * metrics.renderScale,
            lineLimit: 3
        )

        total += textHeight(
            content.shortBody,
            width: bodyWidth,
            fontSize: typography.body * metrics.renderScale,
            weight: .semibold,
            lineSpacing: typography.bodyLineSpacing * metrics.renderScale,
            lineLimit: bodyLineLimit
        )

        if preset.bodyPanelUsesGlass {
            total += 72 * metrics.renderScale
        }

        total += textHeight(
            content.supportingBody,
            width: width * 0.84,
            fontSize: typography.metadata * metrics.renderScale * 1.05,
            weight: .medium,
            lineSpacing: typography.metadataLineSpacing * metrics.renderScale,
            lineLimit: 4
        )

        total += textHeight(
            content.explanation,
            width: width * 0.88,
            fontSize: typography.metadata * metrics.renderScale,
            weight: .regular,
            lineSpacing: typography.metadataLineSpacing * metrics.renderScale,
            lineLimit: 5
        )

        if !content.metadata.isEmpty {
            total += CGFloat(content.metadata.count) * (typography.metadata * metrics.renderScale * 1.8)
            total += 46 * metrics.renderScale
        }

        total += (110 * metrics.renderScale * preset.footerHeightMultiplier)
        total += metrics.bottomSafeArea * 0.62
        total += spacing * 4

        return total
    }

    private static func estimateDiyanetHeight(
        content: ShareCardContent,
        metrics: ShareCardMetrics,
        typography: ShareTypography,
        preset: ShareLayoutPreset,
        summaryLineLimit: Int?
    ) -> CGFloat {
        let width = metrics.canvasSize.width - (metrics.contentPadding * 2)
        let spacing = typography.blockSpacing * metrics.renderScale * preset.sectionSpacingMultiplier
        var total = (metrics.topSafeArea * preset.topPaddingMultiplier) + (70 * metrics.renderScale * preset.iconScale)

        total += textHeight(
            content.eyebrow,
            width: width,
            fontSize: typography.metadata * metrics.renderScale,
            weight: .semibold,
            lineSpacing: typography.metadataLineSpacing * metrics.renderScale,
            lineLimit: 1
        )

        total += textHeight(
            content.category,
            width: width * 0.82,
            fontSize: typography.metadata * metrics.renderScale * 0.96,
            weight: .medium,
            lineSpacing: typography.metadataLineSpacing * metrics.renderScale,
            lineLimit: 2
        )

        total += textHeight(
            content.title,
            width: width * 0.92,
            fontSize: typography.title * metrics.renderScale,
            weight: .bold,
            lineSpacing: typography.titleLineSpacing * metrics.renderScale,
            lineLimit: 4
        )

        total += textHeight(
            content.shareSummary,
            width: width * 0.88,
            fontSize: typography.body * metrics.renderScale,
            weight: .medium,
            lineSpacing: typography.bodyLineSpacing * metrics.renderScale,
            lineLimit: summaryLineLimit
        )
        total += 120 * metrics.renderScale

        total += textHeight(
            content.sourceText,
            width: width * 0.56,
            fontSize: typography.source * metrics.renderScale,
            weight: .semibold,
            lineSpacing: typography.metadataLineSpacing * metrics.renderScale,
            lineLimit: 2
        )
        total += textHeight(
            content.sourceDetail,
            width: width * 0.56,
            fontSize: typography.metadata * metrics.renderScale * 0.94,
            weight: .regular,
            lineSpacing: typography.metadataLineSpacing * metrics.renderScale,
            lineLimit: 2
        )
        total += 120 * metrics.renderScale * preset.sourceBoxHeightMultiplier

        if preset.showsCTA, content.ctaText?.trimmedNilIfEmpty != nil {
            total += 44 * metrics.renderScale
        }

        total += (98 * metrics.renderScale * preset.footerHeightMultiplier)
        total += metrics.bottomSafeArea * 0.54
        total += spacing * 4

        return total
    }

    private static func textHeight(
        _ text: String?,
        width: CGFloat,
        fontSize: CGFloat,
        weight: UIFont.Weight,
        lineSpacing: CGFloat,
        lineLimit: Int?
    ) -> CGFloat {
        guard let text = text?.trimmedNilIfEmpty else { return 0 }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: weight),
            .paragraphStyle: paragraphStyle
        ]
        let bounding = NSAttributedString(string: text, attributes: attributes)
            .boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )

        let naturalHeight = ceil(bounding.height)
        guard let lineLimit else { return naturalHeight }

        let singleLine = ceil(UIFont.systemFont(ofSize: fontSize, weight: weight).lineHeight + lineSpacing)
        return min(naturalHeight, singleLine * CGFloat(lineLimit))
    }
}

struct AdaptiveShareCard: View {
    let content: ShareCardContent
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let shareStyle: ShareCardVisualStyle

    private var resolution: AdaptiveShareCardResolution {
        AdaptiveShareCardResolver.resolve(content: content, metrics: metrics, style: shareStyle)
    }

    private var isPremiumStyle: Bool {
        shareStyle != .standard
    }

    private var isMinimalStyle: Bool {
        shareStyle == .minimal
    }

    private var isLongTextStyle: Bool {
        shareStyle == .longText
    }

    private var isSummaryFocusStyle: Bool {
        shareStyle == .summaryFocus
    }

    var body: some View {
        let resolved = resolution

        ShareCardCanvas(theme: theme, metrics: metrics) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.10 + resolved.preset.overlayBoost + theme.backgroundContrastBias * 0.06),
                        Color.black.opacity(0.18 + resolved.preset.secondaryOverlayBoost),
                        Color.black.opacity(0.26 + resolved.preset.overlayBoost + (resolved.estimatedHeight / max(metrics.canvasSize.height, 1)) * 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if isPremiumStyle {
                    RadialGradient(
                        colors: [
                            theme.accentColor.opacity(isSummaryFocusStyle ? 0.22 : 0.16),
                            Color.clear
                        ],
                        center: isLongTextStyle ? .topLeading : .center,
                        startRadius: 40 * metrics.renderScale,
                        endRadius: 420 * metrics.renderScale
                    )
                }

                switch content.kind {
                case .hadith:
                    hadithBody(resolution: resolved)
                case .diyanet:
                    diyanetBody(resolution: resolved)
                }
            }
        }
    }

    private func hadithBody(resolution: AdaptiveShareCardResolution) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: metrics.topSafeArea * resolution.preset.topPaddingMultiplier)

            VStack(
                alignment: isLongTextStyle ? .leading : .center,
                spacing: resolution.typography.blockSpacing * metrics.renderScale * resolution.preset.sectionSpacingMultiplier
            ) {
                hadithHeader(resolution: resolution)

                if resolution.preset.bodyPanelUsesGlass || isLongTextStyle || isSummaryFocusStyle {
                    AdaptivePanel(metrics: metrics, fillOpacity: resolution.preset.summaryPanelOpacity) {
                        hadithBodyText(resolution: resolution)
                    }
                } else {
                    hadithBodyText(resolution: resolution)
                        .padding(.horizontal, 10 * metrics.renderScale)
                }

                if let supportingBody = content.supportingBody?.trimmedNilIfEmpty {
                    AdaptivePanel(metrics: metrics, fillOpacity: resolution.preset.secondaryPanelOpacity) {
                        Text(supportingBody)
                            .font(.system(size: resolution.typography.metadata * metrics.renderScale * 1.05, weight: .medium, design: .serif))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .multilineTextAlignment(isLongTextStyle ? .leading : .trailing)
                            .lineSpacing(resolution.typography.metadataLineSpacing * metrics.renderScale * (isLongTextStyle ? 1.1 : 1.0))
                            .environment(\.layoutDirection, isLongTextStyle ? .leftToRight : .rightToLeft)
                    }
                }

                if let explanation = content.explanation?.trimmedNilIfEmpty {
                    AdaptivePanel(metrics: metrics, fillOpacity: resolution.preset.secondaryPanelOpacity) {
                        VStack(alignment: .leading, spacing: 10 * metrics.renderScale) {
                            Text("Kısa Açıklama")
                                .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.92, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.accentColor.opacity(0.92))
                            Text(explanation)
                                .font(.system(size: resolution.typography.metadata * metrics.renderScale, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.82))
                                .lineSpacing(resolution.typography.metadataLineSpacing * metrics.renderScale)
                                .lineLimit(resolution.usesFade ? 5 : nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if !content.metadata.isEmpty {
                    AdaptivePanel(metrics: metrics, fillOpacity: resolution.preset.secondaryPanelOpacity * 0.92) {
                        VStack(alignment: .leading, spacing: 12 * metrics.renderScale) {
                            ForEach(content.metadata) { item in
                                HStack(alignment: .top, spacing: 12 * metrics.renderScale) {
                                    Image(systemName: item.systemImage)
                                        .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.92, weight: .semibold))
                                        .foregroundStyle(theme.accentColor.opacity(0.94))
                                        .frame(width: 18 * metrics.renderScale)

                                    VStack(alignment: .leading, spacing: 3 * metrics.renderScale) {
                                        Text(item.label)
                                            .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.82, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.6))
                                        Text(item.value)
                                            .font(.system(size: resolution.typography.metadata * metrics.renderScale, weight: .medium, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.86))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Spacer(minLength: metrics.minimumFlexibleSpacer * 0.32)

            ShareCardBottomDecoration(metrics: metrics)
            .padding(.bottom, metrics.bottomSafeArea * 0.70)
        }
    }

    private func hadithBodyText(resolution: AdaptiveShareCardResolution) -> some View {
        VStack(spacing: 0) {
            Text(content.shortBody?.trimmedNilIfEmpty ?? content.fullBody)
                .font(.system(size: resolution.typography.body * metrics.renderScale, weight: isLongTextStyle ? .medium : .semibold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(isLongTextStyle ? .leading : .center)
                .lineSpacing(resolution.typography.bodyLineSpacing * metrics.renderScale)
                .lineLimit(resolution.bodyLineLimit)
                .frame(maxWidth: .infinity, alignment: isLongTextStyle ? .leading : .center)
                .overlay(alignment: .bottom) {
                    if resolution.usesFade {
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.44)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80 * metrics.renderScale)
                        .allowsHitTesting(false)
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func diyanetBody(resolution: AdaptiveShareCardResolution) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: metrics.topSafeArea * resolution.preset.topPaddingMultiplier)

            VStack(alignment: .leading, spacing: resolution.typography.blockSpacing * metrics.renderScale * resolution.preset.sectionSpacingMultiplier) {
                diyanetHeader(resolution: resolution)

                AdaptivePanel(metrics: metrics, fillOpacity: resolution.preset.summaryPanelOpacity) {
                    VStack(alignment: .leading, spacing: 12 * metrics.renderScale) {
                        if content.shareSummary?.trimmedNilIfEmpty != nil || content.sourceTitle?.trimmedNilIfEmpty != nil {
                            Text(content.shareSummary?.trimmedNilIfEmpty == nil ? (content.sourceTitle?.trimmedNilIfEmpty ?? "Öne Çıkan Metin") : "Kısa Özet")
                                .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.9, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.accentColor.opacity(0.96))
                        }

                        Text(content.shareSummary?.trimmedNilIfEmpty ?? content.shortBody?.trimmedNilIfEmpty ?? content.fullBody)
                            .font(.system(size: resolution.typography.body * metrics.renderScale, weight: .medium, design: .serif))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(resolution.typography.bodyLineSpacing * metrics.renderScale)
                            .lineLimit(resolution.summaryLineLimit)
                            .overlay(alignment: .bottom) {
                                if resolution.usesFade {
                                    LinearGradient(
                                        colors: [.clear, Color.black.opacity(0.48)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 86 * metrics.renderScale)
                                    .allowsHitTesting(false)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                AdaptivePanel(metrics: metrics, fillOpacity: resolution.preset.secondaryPanelOpacity) {
                    HStack(alignment: .center, spacing: 16 * metrics.renderScale) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.94))
                            Image("diyanetlogo")
                                .resizable()
                                .scaledToFit()
                                .padding(12 * metrics.renderScale)
                        }
                        .frame(width: 74 * metrics.renderScale, height: 74 * metrics.renderScale)

                        VStack(alignment: .leading, spacing: 6 * metrics.renderScale) {
                            if let sourceTitle = content.sourceTitle?.trimmedNilIfEmpty {
                                Text(sourceTitle)
                                    .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.84, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.62))
                            }
                            if let sourceText = content.sourceText?.trimmedNilIfEmpty {
                                Text(sourceText)
                                    .font(.system(size: resolution.typography.source * metrics.renderScale, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                            }
                            if let sourceDetail = content.sourceDetail?.trimmedNilIfEmpty {
                                Text(sourceDetail)
                                    .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.92, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.74))
                                    .lineLimit(2)
                            }
                            if resolution.preset.showsCTA, let ctaText = content.ctaText?.trimmedNilIfEmpty {
                                Text(ctaText)
                                    .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.84, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.accentColor.opacity(0.96))
                                    .padding(.top, 4 * metrics.renderScale)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 104 * metrics.renderScale * resolution.preset.sourceBoxHeightMultiplier, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: metrics.minimumFlexibleSpacer * 0.28)

            ShareCardBottomDecoration(metrics: metrics)
            .padding(.bottom, metrics.bottomSafeArea * 0.68)
        }
    }

    @ViewBuilder
    private func diyanetHeader(resolution: AdaptiveShareCardResolution) -> some View {
        VStack(spacing: 16 * metrics.renderScale) {
            if let title = content.title?.trimmedNilIfEmpty {
                ShareCardDecorativeHeader(
                    title: title,
                    fontSize: resolution.typography.title * metrics.renderScale,
                    metrics: metrics
                )
            }

            diyanetHeaderTexts(resolution: resolution)
        }
    }

    @ViewBuilder
    private func diyanetHeaderTexts(resolution: AdaptiveShareCardResolution) -> some View {
        VStack(alignment: .leading, spacing: 8 * metrics.renderScale) {
            if let eyebrow = content.eyebrow?.trimmedNilIfEmpty {
                Text(eyebrow.uppercased(with: Locale(identifier: "tr_TR")))
                    .font(.system(size: resolution.typography.metadata * metrics.renderScale * 0.92, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentColor.opacity(0.96))
                    .tracking((isMinimalStyle ? 0.9 : 1.4) * metrics.renderScale)
            }

            if let category = content.category?.trimmedNilIfEmpty {
                Text(category)
                    .font(.system(size: resolution.typography.metadata * metrics.renderScale, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(isMinimalStyle ? 0.82 : 0.74))
                    .lineLimit(isLongTextStyle ? 3 : 2)
            }
        }
    }

    @ViewBuilder
    private func hadithHeader(resolution: AdaptiveShareCardResolution) -> some View {
        VStack(spacing: 16 * metrics.renderScale) {
            if let title = content.title?.trimmedNilIfEmpty {
                ShareCardDecorativeHeader(
                    title: title,
                    fontSize: resolution.typography.title * metrics.renderScale * 0.72,
                    metrics: metrics
                )
            }

            hadithHeaderTexts(resolution: resolution, alignment: isLongTextStyle ? .leading : .center)
        }
        .frame(maxWidth: .infinity, alignment: isLongTextStyle ? .leading : .center)
    }

    @ViewBuilder
    private func hadithHeaderTexts(resolution: AdaptiveShareCardResolution, alignment: TextAlignment) -> some View {
        if let eyebrow = content.eyebrow?.trimmedNilIfEmpty {
            Text(eyebrow.uppercased(with: Locale(identifier: "tr_TR")))
                .font(.system(size: resolution.typography.metadata * metrics.renderScale, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accentColor.opacity(0.96))
                .tracking((isMinimalStyle ? 1.3 : 2.2) * metrics.renderScale)
                .frame(maxWidth: .infinity, alignment: isLongTextStyle ? .leading : .center)
        }

    }

    @ViewBuilder
    private func styleChip(title: String) -> some View {
        HStack(spacing: 8 * metrics.renderScale) {
            Circle()
                .fill(theme.accentColor)
                .frame(width: 8 * metrics.renderScale, height: 8 * metrics.renderScale)

            Text(title)
                .font(.system(size: 16 * metrics.renderScale, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.accentColor.opacity(0.96))
        }
        .padding(.horizontal, 14 * metrics.renderScale)
        .padding(.vertical, 10 * metrics.renderScale)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.24))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(theme.accentColor.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

struct AdaptivePanel<Content: View>: View {
    let metrics: ShareCardMetrics
    let fillOpacity: Double
    let content: Content

    init(metrics: ShareCardMetrics, fillOpacity: Double, @ViewBuilder content: () -> Content) {
        self.metrics = metrics
        self.fillOpacity = fillOpacity
        self.content = content()
    }

    var body: some View {
        content
            .padding(24 * metrics.renderScale)
            .background(
                RoundedRectangle(cornerRadius: 30 * metrics.renderScale, style: .continuous)
                    .fill(Color.black.opacity(fillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30 * metrics.renderScale, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.20), radius: 18 * metrics.renderScale, y: 10 * metrics.renderScale)
    }
}

struct AdaptiveBrandingFooter: View {
    let title: String
    let subtitle: String
    let accentColor: Color
    let metrics: ShareCardMetrics
    let typography: ShareTypography
    let compact: Bool
    let premium: Bool
    let minimal: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14 * metrics.renderScale) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(accentColor)
                .frame(width: compact ? 34 * metrics.renderScale : (premium ? 54 * metrics.renderScale : 46 * metrics.renderScale), height: minimal ? 3 * metrics.renderScale : 4 * metrics.renderScale)

            VStack(alignment: .leading, spacing: 2 * metrics.renderScale) {
                Text(title)
                    .font(.system(size: typography.footerTitle * metrics.renderScale * (compact ? 0.86 : 1.0), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: typography.footerSubtitle * metrics.renderScale * (compact ? 0.88 : 1.0), weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22 * metrics.renderScale)
        .padding(.vertical, compact ? 16 * metrics.renderScale : 20 * metrics.renderScale)
        .background(
            RoundedRectangle(cornerRadius: 26 * metrics.renderScale, style: .continuous)
                .fill(Color.black.opacity(minimal ? 0.22 : (compact ? 0.34 : (premium ? 0.46 : 0.40))))
                .overlay(
                    RoundedRectangle(cornerRadius: 26 * metrics.renderScale, style: .continuous)
                        .stroke((premium ? accentColor.opacity(0.12) : Color.white.opacity(0.08)), lineWidth: 1)
                )
        )
    }
}

private extension ShareCardTheme {
    var backgroundContrastBias: Double {
        switch id {
        case "dawn":
            return 0.22
        case "emerald", "al_aqsa":
            return 0.14
        case "kaaba":
            return 0.18
        default:
            return 0.10
        }
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

struct QuranShareCardView: View {
    let content: QuranShareCardContent
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let quranDisplayMode: QuranShareDisplayMode
    let shareStyle: ShareCardVisualStyle

    private var displayedArabicText: String? {
        guard quranDisplayMode != .turkishOnly else { return nil }
        return content.arabicText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var displayedTranslation: String? {
        guard quranDisplayMode != .arabicOnly else { return nil }
        return content.translationText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var referenceText: String {
        L10n.format(.verseShareSurahVerseFormat, content.surahName, content.verseNumber)
    }

    private var surahTitleFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: content.surahArabicName,
            base: metrics.quranSurahTitleFontSize,
            shortTextLength: 10,
            longTextLength: 28,
            minimumScale: 0.88,
            maximumScale: 1.06
        )
    }

    private var arabicFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: displayedArabicText,
            base: metrics.arabicFontSize,
            shortTextLength: 48,
            longTextLength: 180,
            minimumScale: 0.72,
            maximumScale: 1.04
        )
    }

    private var translationFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: displayedTranslation,
            base: metrics.subtitleFontSize,
            shortTextLength: 70,
            longTextLength: 180,
            minimumScale: 0.82,
            maximumScale: 1.05
        )
    }

    private var referenceFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: referenceText,
            base: metrics.referenceFontSize,
            shortTextLength: 22,
            longTextLength: 44,
            minimumScale: 0.84,
            maximumScale: 1.04
        )
    }

    private var footerDescriptor: String {
        quranDisplayMode == .arabicOnly
            ? L10n.string(.quranDisplayModeArabic)
            : content.translationSourceName
    }

    var body: some View {
        ShareCardCanvas(theme: theme, metrics: metrics) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: metrics.topSafeArea)

                ShareCardDecorativeHeader(
                    title: content.surahArabicName,
                    fontSize: surahTitleFontSize,
                    metrics: metrics
                )

                if let displayedArabicText {
                    Text(displayedArabicText)
                        .font(.system(size: arabicFontSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(metrics.arabicLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.top, metrics.blockSpacingXLarge)
                        .shadow(color: .black.opacity(0.34), radius: 18 * metrics.renderScale, y: 8 * metrics.renderScale)
                }

                Text(referenceText)
                    .font(.system(size: referenceFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentColor.opacity(0.98))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .padding(.top, displayedArabicText == nil ? metrics.blockSpacingXLarge : metrics.blockSpacingLarge)
                    .shadow(color: .black.opacity(0.22), radius: 10 * metrics.renderScale, y: 6 * metrics.renderScale)

                if let displayedTranslation {
                    Group {
                        if shareStyle.prefersPanelEmphasis {
                            AdaptivePanel(metrics: metrics, fillOpacity: shareStyle.primaryPanelOpacity) {
                                Text(displayedTranslation)
                                    .font(.system(size: translationFontSize, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.92))
                                    .multilineTextAlignment(shareStyle == .longText ? .leading : .center)
                                    .lineSpacing(metrics.subtitleLineSpacing + (2 * metrics.renderScale))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: shareStyle == .longText ? .leading : .center)
                            }
                        } else {
                            Text(displayedTranslation)
                                .font(.system(size: translationFontSize, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .lineSpacing(metrics.subtitleLineSpacing + (2 * metrics.renderScale))
                                .fixedSize(horizontal: false, vertical: true)
                                .shadow(color: .black.opacity(0.24), radius: 12 * metrics.renderScale, y: 6 * metrics.renderScale)
                        }
                    }
                    .padding(.top, metrics.blockSpacingMedium)
                }

                Spacer(minLength: metrics.minimumFlexibleSpacer)

                VStack(spacing: 16 * metrics.renderScale) {
                    Text(footerDescriptor)
                        .font(.system(size: metrics.footerDescriptorFontSize * (shareStyle == .minimal ? 0.9 : 1.0), weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .multilineTextAlignment(.center)

                    ShareCardBottomDecoration(metrics: metrics)
                }
                .padding(.bottom, metrics.bottomSafeArea)
            }
        }
    }
}

struct DhikrShareCardView: View {
    let content: DhikrShareCardContent
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let shareStyle: ShareCardVisualStyle

    private var appLocale: Locale {
        Locale(identifier: RabiaAppLanguage.currentCode())
    }

    private var trimmedArabic: String? {
        content.arabicText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var arabicFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: trimmedArabic,
            base: metrics.arabicFontSize,
            shortTextLength: 28,
            longTextLength: 110,
            minimumScale: 0.78,
            maximumScale: 1.05
        )
    }

    private var titleFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: content.title,
            base: metrics.titleFontSize,
            shortTextLength: 24,
            longTextLength: 64,
            minimumScale: 0.76,
            maximumScale: 1.07
        )
    }

    private var translationFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: content.translationText,
            base: metrics.subtitleFontSize,
            shortTextLength: 48,
            longTextLength: 130,
            minimumScale: 0.82,
            maximumScale: 1.04
        )
    }

    var body: some View {
        ShareCardCanvas(theme: theme, metrics: metrics) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: metrics.topSafeArea)

                ShareCardDecorativeHeader(
                    title: content.title,
                    fontSize: titleFontSize,
                    metrics: metrics
                )

                Text(content.completedLabel.uppercased(with: appLocale))
                        .font(.system(size: metrics.badgeLabelFontSize * (shareStyle == .minimal ? 0.9 : 1.0), weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accentColor.opacity(0.95))
                        .tracking(shareStyle == .minimal ? metrics.badgeLabelTracking * 0.6 : metrics.badgeLabelTracking)
                        .padding(.top, metrics.blockSpacingMedium)

                if let arabicText = trimmedArabic {
                    Text(arabicText)
                        .font(.system(size: arabicFontSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(metrics.arabicLineSpacing * 0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.top, metrics.blockSpacingXLarge)
                        .shadow(color: .black.opacity(0.34), radius: 18 * metrics.renderScale, y: 8 * metrics.renderScale)
                }

                if let translationText = content.translationText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
                    Group {
                        if shareStyle.prefersPanelEmphasis {
                            AdaptivePanel(metrics: metrics, fillOpacity: shareStyle.primaryPanelOpacity) {
                                Text(translationText)
                                    .font(.system(size: translationFontSize, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.90))
                                    .multilineTextAlignment(shareStyle == .longText ? .leading : .center)
                                    .lineSpacing(metrics.subtitleLineSpacing)
                                    .lineLimit(shareStyle == .longText ? nil : (metrics.mode == .preview ? 4 : 5))
                                    .frame(maxWidth: .infinity, alignment: shareStyle == .longText ? .leading : .center)
                            }
                        } else {
                            Text(translationText)
                                .font(.system(size: translationFontSize, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.86))
                                .multilineTextAlignment(.center)
                                .lineSpacing(metrics.subtitleLineSpacing)
                                .lineLimit(metrics.mode == .preview ? 3 : 4)
                                .minimumScaleFactor(0.80)
                                .shadow(color: .black.opacity(0.24), radius: 12 * metrics.renderScale, y: 6 * metrics.renderScale)
                        }
                    }
                    .padding(.top, metrics.blockSpacingMedium * 0.9)
                }

                Spacer(minLength: metrics.minimumFlexibleSpacer)

                ShareMetricsPanel(metrics: content.stats, accentColor: theme.accentColor, layout: metrics)

                Spacer(minLength: metrics.blockSpacingLarge)

                VStack(spacing: 16 * metrics.renderScale) {
                    Text(content.dateText)
                        .font(.system(size: metrics.dateFontSize * 1.08, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.76))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    ShareCardBottomDecoration(metrics: metrics)
                }
                .padding(.bottom, metrics.bottomSafeArea)
            }
        }
    }
}

struct IslamicDailyShareCardView: View {
    let content: IslamicDailyShareCardContent
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let shareStyle: ShareCardVisualStyle

    private var progressPercentText: String {
        L10n.format(.numberFormat, Int64(Int(content.progress * 100)))
    }

    private var titleFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: content.title,
            base: metrics.titleFontSize * 0.62,
            shortTextLength: 20,
            longTextLength: 56,
            minimumScale: 0.84,
            maximumScale: 1.06
        )
    }

    private var quoteTextFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: content.quoteText,
            base: metrics.wisdomTextFontSize,
            shortTextLength: 90,
            longTextLength: 260,
            minimumScale: 0.82,
            maximumScale: 1.04
        )
    }

    var body: some View {
        ShareCardCanvas(theme: theme, metrics: metrics) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: metrics.topSafeArea)

                ShareCardDecorativeHeader(
                    title: content.title,
                    fontSize: titleFontSize,
                    metrics: metrics
                )

                Text(content.dateText)
                    .font(.system(size: metrics.dateFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, metrics.blockSpacingMedium)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: metrics.progressLineWidth)
                        .frame(width: metrics.progressRingSize, height: metrics.progressRingSize)

                    Circle()
                        .trim(from: 0, to: content.progress)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    theme.accentColor.opacity(0.78),
                                    .white,
                                    theme.accentColor
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: metrics.progressLineWidth, lineCap: .round)
                        )
                        .frame(width: metrics.progressRingSize, height: metrics.progressRingSize)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 10 * metrics.renderScale) {
                        Text(progressPercentText)
                            .font(.system(size: metrics.progressValueFontSize, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.72)

                        Text(L10n.string(.percentSymbol))
                            .font(.system(size: metrics.progressSymbolFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accentColor.opacity(0.94))

                        Text(content.progressLabel)
                            .font(.system(size: metrics.progressLabelFontSize, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.76))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .padding(.top, metrics.blockSpacingXLarge * 0.95)

                HStack(spacing: 18 * metrics.renderScale) {
                    ForEach(content.metrics) { metric in
                        ShareMetricCard(metric: metric, accentColor: theme.accentColor, layout: metrics)
                    }
                }
                .padding(.top, metrics.blockSpacingXLarge * 0.86)

                Group {
                    if shareStyle.prefersPanelEmphasis {
                        AdaptivePanel(metrics: metrics, fillOpacity: shareStyle.primaryPanelOpacity) {
                            dailyQuoteContent(quoteTextFontSize: quoteTextFontSize)
                        }
                    } else {
                        ShareFooterPanel(metrics: metrics) {
                            dailyQuoteContent(quoteTextFontSize: quoteTextFontSize)
                        }
                    }
                }
                .padding(.top, metrics.blockSpacingLarge)

                Spacer(minLength: metrics.blockSpacingLarge)

                ShareCardBottomDecoration(metrics: metrics)
                .padding(.bottom, metrics.bottomSafeArea)
            }
        }
    }

    @ViewBuilder
    private func dailyQuoteContent(quoteTextFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: metrics.blockSpacingSmall * 0.9) {
            Text(content.quoteText)
                .font(.system(size: quoteTextFontSize, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(metrics.subtitleLineSpacing)
                .lineLimit(shareStyle == .longText ? nil : (metrics.mode == .preview ? 6 : nil))
                .fixedSize(horizontal: false, vertical: true)

            Text(content.quoteReference)
                .font(.system(size: metrics.wisdomTitleFontSize * 0.92, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.accentColor.opacity(0.96))
        }
    }
}

struct DiyanetShareCardView: View {
    let content: DiyanetShareCardContent
    let theme: ShareCardTheme
    let metrics: ShareCardMetrics
    let shareStyle: ShareCardVisualStyle

    var body: some View {
        AdaptiveShareCard(
            content: ShareCardContent(
                kind: .diyanet,
                eyebrow: content.typeText,
                category: content.categoryText,
                title: content.title,
                shortBody: nil,
                fullBody: content.fullBodyText,
                shareSummary: content.summaryText,
                sourceTitle: content.sourceTitle,
                sourceText: content.sourceSubtitle,
                sourceDetail: L10n.string(.diyanetIsleriBaskanligi),
                metadata: [],
                explanation: nil,
                supportingBody: nil,
                ctaText: content.ctaText,
                brandingTitle: content.brandingTitle,
                brandingSubtitle: content.brandingSubtitle
            ),
            theme: theme,
            metrics: metrics,
            shareStyle: shareStyle
        )
    }
}

struct ShareStoryBadge: View {
    let icon: String
    let accentColor: Color
    let metrics: ShareCardMetrics

    var body: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.16))
                .frame(width: metrics.badgeInnerSize, height: metrics.badgeInnerSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

            Circle()
                .stroke(accentColor.opacity(0.52), lineWidth: max(1.5, 3 * metrics.renderScale))
                .frame(width: metrics.badgeOuterSize, height: metrics.badgeOuterSize)

            Image(systemName: icon)
                .font(.system(size: metrics.badgeIconSize, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, accentColor.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

struct ShareMetricsPanel: View {
    let metrics: [ShareMetric]
    let accentColor: Color
    let layout: ShareCardMetrics

    var body: some View {
        HStack(spacing: 18 * layout.renderScale) {
            ForEach(metrics) { metric in
                ShareMetricCard(metric: metric, accentColor: accentColor, layout: layout)
            }
        }
        .padding(layout.statPanelPadding)
        .background(
            RoundedRectangle(cornerRadius: layout.statPanelCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.40))
                .overlay(
                    RoundedRectangle(cornerRadius: layout.statPanelCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: layout.infoBoxShadowRadius, y: layout.infoBoxShadowYOffset)
    }
}

struct ShareMetricCard: View {
    let metric: ShareMetric
    let accentColor: Color
    let layout: ShareCardMetrics

    var body: some View {
        VStack(spacing: 12 * layout.renderScale) {
            Image(systemName: metric.icon)
                .font(.system(size: layout.statIconSize, weight: .semibold))
                .foregroundStyle(accentColor.opacity(0.95))

            Text(metric.value)
                .font(.system(size: layout.statValueFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Text(metric.label)
                .font(.system(size: layout.statLabelFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.78))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: layout.statCardHeight)
        .padding(.horizontal, 12 * layout.renderScale)
        .background(
            RoundedRectangle(cornerRadius: layout.statCardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: layout.statCardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.11), lineWidth: 1)
                )
        )
    }
}

struct ShareFooterPanel<Content: View>: View {
    let metrics: ShareCardMetrics
    let content: Content

    init(metrics: ShareCardMetrics, @ViewBuilder content: () -> Content) {
        self.metrics = metrics
        self.content = content()
    }

    var body: some View {
        content
            .padding(metrics.footerPadding)
            .frame(minHeight: metrics.footerMinHeight)
            .background(
                RoundedRectangle(cornerRadius: metrics.infoBoxCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.42))
                    .overlay(
                        RoundedRectangle(cornerRadius: metrics.infoBoxCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.24), radius: metrics.infoBoxShadowRadius, y: metrics.infoBoxShadowYOffset)
    }
}

struct ShareCardDecorativeHeader: View {
    let title: String
    let fontSize: CGFloat
    let metrics: ShareCardMetrics

    var body: some View {
        VStack(spacing: 18 * metrics.renderScale) {
            Image("sharecardust1")
                .resizable()
                .scaledToFit()
                .frame(width: 260 * metrics.renderScale)
                .shadow(color: .black.opacity(0.18), radius: 10 * metrics.renderScale, y: 6 * metrics.renderScale)

            Text(title)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8 * metrics.renderScale)
                .lineLimit(3)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 30 * metrics.renderScale)
                .shadow(color: .black.opacity(0.30), radius: 12 * metrics.renderScale, y: 6 * metrics.renderScale)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShareCardBottomDecoration: View {
    let metrics: ShareCardMetrics

    var body: some View {
        Image("sharecardalt1")
            .resizable()
            .scaledToFit()
            .frame(width: 240 * metrics.renderScale)
            .shadow(color: .black.opacity(0.18), radius: 10 * metrics.renderScale, y: 6 * metrics.renderScale)
            .frame(maxWidth: .infinity)
    }
}

struct ShareBrandingFooter: View {
    let title: String
    let subtitle: String
    let accentColor: Color
    let isTrailing: Bool
    let metrics: ShareCardMetrics

    private var titleFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: title,
            base: metrics.footerBrandTitleSize,
            shortTextLength: 18,
            longTextLength: 36,
            minimumScale: 0.84,
            maximumScale: 1.03
        )
    }

    private var subtitleFontSize: CGFloat {
        metrics.adaptiveFontSize(
            for: subtitle,
            base: metrics.footerBrandSubtitleSize,
            shortTextLength: 22,
            longTextLength: 40,
            minimumScale: 0.88,
            maximumScale: 1.02
        )
    }

    var body: some View {
        VStack(alignment: isTrailing ? .trailing : .leading, spacing: 8 * metrics.renderScale) {
            Text(title)
                .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(isTrailing ? .trailing : .leading)
                .lineLimit(2)

            Text(subtitle)
                .font(.system(size: subtitleFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(accentColor.opacity(0.88))
                .multilineTextAlignment(isTrailing ? .trailing : .leading)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#if DEBUG
private enum AdaptiveShareCardPreviewData {
    static let shortHadith = ShareCardType.hadith(
        HadithShareCardContent(
            title: "Merhamet",
            referenceText: "Riyazus Salihin",
            bodyText: "Merhamet etmeyene merhamet olunmaz.",
            fullBodyText: "Merhamet etmeyene merhamet olunmaz.",
            arabicText: nil,
            explanationText: "Kısa ama çok derin bir uyarı: kulun kalbindeki merhamet, ilişkilerinin dilini belirler.",
            narratorText: "Ebû Hüreyre (r.a.)",
            gradeText: "Sahih",
            brandingTitle: AppName.full,
            brandingSubtitle: ShareCardBranding.storeSubtitle
        )
    )

    static let longHadith = ShareCardType.hadith(
        HadithShareCardContent(
            title: "İman ve Kardeşlik",
            referenceText: "Buhârî • Müslim",
            bodyText: "Sizden biriniz kendisi için sevdiğini din kardeşi için de sevmedikçe gerçek anlamda iman etmiş olmaz. Bu ölçü, kalpte başlayan samimiyetin davranışlara taşınmasını ve müminin kendi iyiliğini kardeşi için de istemesini öğretir.",
            fullBodyText: "Sizden biriniz kendisi için sevdiğini din kardeşi için de sevmedikçe gerçek anlamda iman etmiş olmaz. Bu ölçü, kalpte başlayan samimiyetin davranışlara taşınmasını ve müminin kendi iyiliğini kardeşi için de istemesini öğretir.",
            arabicText: nil,
            explanationText: "Hadis, imanı sadece bireysel bir duygu olarak değil, başkası için iyi istemeyi de içine alan bir ahlak olarak tarif eder.",
            narratorText: "Enes b. Mâlik (r.a.)",
            gradeText: "Müttefekun Aleyh",
            brandingTitle: AppName.full,
            brandingSubtitle: ShareCardBranding.storeSubtitle
        )
    )

    static let shortDiyanet = ShareCardType.diyanet(
        DiyanetShareCardContent(
            title: "Yolculukta namazların birleştirilmesi",
            typeText: "Soru-Cevap",
            categoryText: "İbadet • Namaz",
            summaryTitle: "Kısa Özet",
            summaryText: "Seferilik şartları oluştuğunda dört rekâtlı farz namazlar iki rekât olarak kılınabilir. Zaruret ve ihtiyaç durumları ayrıca mezheplere göre değerlendirilir.",
            sourceTitle: "Kaynak",
            sourceSubtitle: "Din İşleri Yüksek Kurulu",
            fullBodyText: "Seferilik şartları oluştuğunda dört rekâtlı farz namazlar iki rekât olarak kılınabilir. Zaruret ve ihtiyaç durumları ayrıca mezheplere göre değerlendirilir.",
            ctaText: "Devamı uygulamada",
            brandingTitle: AppName.full,
            brandingSubtitle: ShareCardBranding.storeSubtitle
        )
    )

    static let longDiyanet = ShareCardType.diyanet(
        DiyanetShareCardContent(
            title: "Dijital ortamda görülen dini içeriklerin güvenilirliği nasıl değerlendirilmelidir?",
            typeText: "Mütalaa",
            categoryText: "Güncel Meseleler • Medya • Dini Bilgi",
            summaryTitle: "Kısa Özet",
            summaryText: "Dini içeriklerin güvenilirliğinde kaynağın resmiyeti, ilmi yetkinlik, kullanılan delillerin açıklığı ve bağlamın korunması temel ölçütlerdir. Özellikle sosyal medyada kısa ve dikkat çekici anlatımlar, hükmün şartlarını veya istisnalarını görünmez kılabildiği için doğrulama yapılmadan paylaşılmamalıdır. Kullanıcı, mümkün olduğunda resmi kurum açıklamasına ve bütün metne ulaşarak değerlendirme yapmalıdır.",
            sourceTitle: "Kaynak",
            sourceSubtitle: "Din İşleri Yüksek Kurulu",
            fullBodyText: "Dini içeriklerin güvenilirliğinde kaynağın resmiyeti, ilmi yetkinlik, kullanılan delillerin açıklığı ve bağlamın korunması temel ölçütlerdir. Özellikle sosyal medyada kısa ve dikkat çekici anlatımlar, hükmün şartlarını veya istisnalarını görünmez kılabildiği için doğrulama yapılmadan paylaşılmamalıdır. Kullanıcı, mümkün olduğunda resmi kurum açıklamasına ve bütün metne ulaşarak değerlendirme yapmalıdır.",
            ctaText: "Devamı uygulamada",
            brandingTitle: AppName.full,
            brandingSubtitle: ShareCardBranding.storeSubtitle
        )
    )
}

struct AdaptiveShareCardPreviews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                previewCard(title: "Short Hadith", cardType: AdaptiveShareCardPreviewData.shortHadith, style: .standard)
                previewCard(title: "Long Hadith", cardType: AdaptiveShareCardPreviewData.longHadith, style: .longText)
                previewCard(title: "Short Diyanet", cardType: AdaptiveShareCardPreviewData.shortDiyanet, style: .summaryFocus)
                previewCard(title: "Long Diyanet", cardType: AdaptiveShareCardPreviewData.longDiyanet, style: .longText)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private static func previewCard(title: String, cardType: ShareCardType, style: ShareCardVisualStyle) -> some View {
        let width: CGFloat = 320
        let metrics = ShareCardMetrics.make(for: .preview, typography: ShareCardTheme.emerald.typography, availableWidth: width)

        return VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)

            SharePreviewContainer(metrics: metrics) {
                ShareCardView(
                    cardType: cardType,
                    theme: .emerald,
                    mode: .preview,
                    shareStyle: style,
                    availableWidth: width
                )
            }
        }
    }
}
#endif
