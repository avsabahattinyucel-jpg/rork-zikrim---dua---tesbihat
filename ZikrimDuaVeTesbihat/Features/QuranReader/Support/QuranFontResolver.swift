import SwiftUI
import UIKit

enum QuranFontResolver {
    private static let arabicFallbackCandidates = [
        "DecoTypeNaskh",
        "GeezaPro",
        "Damascus",
        "AlNile",
        "KufiStandardGK"
    ]

    static func arabicFont(for option: QuranFontOption, size: CGFloat, relativeTo textStyle: UIFont.TextStyle = .title2) -> Font {
        Font(scaledUIFont(for: option, size: size, relativeTo: textStyle))
    }

    static func resolvedFontName(for option: QuranFontOption) -> String? {
        (option.fontCandidates + arabicFallbackCandidates).first(where: { UIFont(name: $0, size: 18) != nil })
    }

    static func isUsingSystemFallback(for option: QuranFontOption) -> Bool {
        resolvedFontName(for: option) == nil
    }

    static func scaledUIFont(for option: QuranFontOption, size: CGFloat, relativeTo textStyle: UIFont.TextStyle) -> UIFont {
        if let fontName = resolvedFontName(for: option), let base = UIFont(name: fontName, size: size) {
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
        }

        if let fallbackName = arabicFallbackCandidates.first(where: { UIFont(name: $0, size: size) != nil }),
           let fallback = UIFont(name: fallbackName, size: size) {
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: fallback)
        }

        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: UIFont.systemFont(ofSize: size, weight: .regular))
    }
}
