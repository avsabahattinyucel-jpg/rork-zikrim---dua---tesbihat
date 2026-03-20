import SwiftUI

enum QuranReaderAppearanceEngine {
    static func style(for appearance: QuranReaderAppearance, theme: ActiveTheme) -> QuranReaderCanvasStyle {
        switch appearance {
        case .standardDark:
            return QuranReaderCanvasStyle(
                background: Color(red: 0.050, green: 0.064, blue: 0.082),
                secondaryBackground: Color(red: 0.080, green: 0.097, blue: 0.125),
                cardBackground: Color(red: 0.096, green: 0.118, blue: 0.148).opacity(0.92),
                border: Color.white.opacity(0.10),
                divider: Color.white.opacity(0.07),
                arabicText: Color(red: 0.97, green: 0.98, blue: 0.95),
                translationText: Color(red: 0.84, green: 0.87, blue: 0.89),
                transliterationText: Color(red: 0.67, green: 0.73, blue: 0.76),
                badgeBackground: Color(red: 0.13, green: 0.27, blue: 0.31),
                badgeForeground: Color(red: 0.72, green: 0.88, blue: 0.90),
                chipBackground: Color(red: 0.11, green: 0.25, blue: 0.28),
                chipForeground: Color(red: 0.67, green: 0.86, blue: 0.85),
                selectionHighlight: Color(red: 0.29, green: 0.58, blue: 0.57).opacity(0.30),
                activeWordFill: Color(red: 0.22, green: 0.46, blue: 0.47).opacity(0.28),
                activeWordStroke: Color(red: 0.63, green: 0.88, blue: 0.86).opacity(0.78),
                activeWordText: Color(red: 0.99, green: 1.0, blue: 0.98),
                audioSurface: Color(red: 0.071, green: 0.090, blue: 0.116).opacity(0.98),
                audioBorder: Color.white.opacity(0.10),
                shadowColor: Color.black.opacity(0.24),
                heroGradient: LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.28, blue: 0.39),
                        Color(red: 0.08, green: 0.40, blue: 0.47),
                        Color(red: 0.05, green: 0.12, blue: 0.19)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                heroGlow: Color(red: 0.30, green: 0.72, blue: 0.79).opacity(0.28)
            )
        case .mushaf:
            return QuranReaderCanvasStyle(
                background: Color(red: 0.026, green: 0.031, blue: 0.040),
                secondaryBackground: Color(red: 0.045, green: 0.053, blue: 0.064),
                cardBackground: Color(red: 0.036, green: 0.041, blue: 0.050).opacity(0.84),
                border: Color.white.opacity(0.06),
                divider: Color.white.opacity(0.05),
                arabicText: Color(red: 0.98, green: 0.97, blue: 0.91),
                translationText: Color(red: 0.76, green: 0.77, blue: 0.74),
                transliterationText: Color(red: 0.60, green: 0.64, blue: 0.62),
                badgeBackground: Color(red: 0.17, green: 0.21, blue: 0.18),
                badgeForeground: Color(red: 0.80, green: 0.86, blue: 0.70),
                chipBackground: Color(red: 0.12, green: 0.15, blue: 0.13),
                chipForeground: Color(red: 0.78, green: 0.82, blue: 0.68),
                selectionHighlight: Color(red: 0.46, green: 0.54, blue: 0.36).opacity(0.22),
                activeWordFill: Color(red: 0.36, green: 0.42, blue: 0.24).opacity(0.24),
                activeWordStroke: Color(red: 0.78, green: 0.82, blue: 0.66).opacity(0.70),
                activeWordText: Color(red: 0.99, green: 0.98, blue: 0.92),
                audioSurface: Color(red: 0.038, green: 0.043, blue: 0.050).opacity(0.96),
                audioBorder: Color.white.opacity(0.08),
                shadowColor: Color.black.opacity(0.28),
                heroGradient: LinearGradient(
                    colors: [
                        Color(red: 0.14, green: 0.18, blue: 0.12),
                        Color(red: 0.08, green: 0.12, blue: 0.10),
                        Color(red: 0.03, green: 0.04, blue: 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                heroGlow: Color(red: 0.55, green: 0.66, blue: 0.41).opacity(0.16)
            )
        case .sepia:
            return QuranReaderCanvasStyle(
                background: Color(red: 0.956, green: 0.936, blue: 0.895),
                secondaryBackground: Color(red: 0.985, green: 0.966, blue: 0.927),
                cardBackground: Color(red: 0.991, green: 0.974, blue: 0.940),
                border: Color(red: 0.79, green: 0.69, blue: 0.55).opacity(0.58),
                divider: Color(red: 0.76, green: 0.66, blue: 0.53).opacity(0.52),
                arabicText: Color(red: 0.23, green: 0.17, blue: 0.11),
                translationText: Color(red: 0.39, green: 0.29, blue: 0.18),
                transliterationText: Color(red: 0.48, green: 0.36, blue: 0.22),
                badgeBackground: Color(red: 0.91, green: 0.84, blue: 0.72),
                badgeForeground: Color(red: 0.47, green: 0.31, blue: 0.16),
                chipBackground: Color(red: 0.91, green: 0.84, blue: 0.72),
                chipForeground: Color(red: 0.47, green: 0.31, blue: 0.16),
                selectionHighlight: Color(red: 0.86, green: 0.77, blue: 0.62).opacity(0.46),
                activeWordFill: Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.34),
                activeWordStroke: Color(red: 0.56, green: 0.37, blue: 0.19).opacity(0.78),
                activeWordText: Color(red: 0.20, green: 0.14, blue: 0.09),
                audioSurface: Color(red: 0.984, green: 0.964, blue: 0.924),
                audioBorder: Color(red: 0.75, green: 0.65, blue: 0.51).opacity(0.56),
                shadowColor: Color.black.opacity(0.06),
                heroGradient: LinearGradient(
                    colors: [
                        Color(red: 0.76, green: 0.60, blue: 0.37),
                        Color(red: 0.84, green: 0.70, blue: 0.45),
                        Color(red: 0.94, green: 0.88, blue: 0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                heroGlow: Color(red: 0.80, green: 0.64, blue: 0.42).opacity(0.18)
            )
        case .nightFocus:
            return QuranReaderCanvasStyle(
                background: Color(red: 0.030, green: 0.035, blue: 0.048),
                secondaryBackground: Color(red: 0.053, green: 0.061, blue: 0.078),
                cardBackground: Color(red: 0.068, green: 0.076, blue: 0.098),
                border: Color.white.opacity(0.08),
                divider: Color.white.opacity(0.06),
                arabicText: Color(red: 0.90, green: 0.92, blue: 0.90),
                translationText: Color(red: 0.72, green: 0.76, blue: 0.80),
                transliterationText: Color(red: 0.59, green: 0.64, blue: 0.67),
                badgeBackground: Color(red: 0.12, green: 0.18, blue: 0.21),
                badgeForeground: Color(red: 0.63, green: 0.82, blue: 0.88),
                chipBackground: Color(red: 0.11, green: 0.17, blue: 0.19),
                chipForeground: Color(red: 0.64, green: 0.84, blue: 0.86),
                selectionHighlight: Color(red: 0.25, green: 0.39, blue: 0.42).opacity(0.30),
                activeWordFill: Color(red: 0.19, green: 0.29, blue: 0.34).opacity(0.30),
                activeWordStroke: Color(red: 0.58, green: 0.80, blue: 0.84).opacity(0.72),
                activeWordText: Color(red: 0.96, green: 0.98, blue: 0.97),
                audioSurface: Color(red: 0.052, green: 0.061, blue: 0.077).opacity(0.98),
                audioBorder: Color.white.opacity(0.09),
                shadowColor: Color.black.opacity(0.28),
                heroGradient: LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.16, blue: 0.24),
                        Color(red: 0.10, green: 0.22, blue: 0.25),
                        Color(red: 0.04, green: 0.06, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                heroGlow: Color(red: 0.42, green: 0.70, blue: 0.82).opacity(0.18)
            )
        case .translationFocus:
            return QuranReaderCanvasStyle(
                background: Color(red: 0.066, green: 0.077, blue: 0.098),
                secondaryBackground: Color(red: 0.090, green: 0.102, blue: 0.126),
                cardBackground: Color(red: 0.106, green: 0.118, blue: 0.144).opacity(0.94),
                border: Color.white.opacity(0.11),
                divider: Color.white.opacity(0.07),
                arabicText: Color(red: 0.95, green: 0.97, blue: 0.96),
                translationText: Color(red: 0.88, green: 0.90, blue: 0.92),
                transliterationText: Color(red: 0.75, green: 0.79, blue: 0.82),
                badgeBackground: Color(red: 0.11, green: 0.28, blue: 0.31),
                badgeForeground: Color(red: 0.73, green: 0.90, blue: 0.89),
                chipBackground: Color(red: 0.12, green: 0.23, blue: 0.27),
                chipForeground: Color(red: 0.70, green: 0.88, blue: 0.87),
                selectionHighlight: Color(red: 0.27, green: 0.58, blue: 0.60).opacity(0.34),
                activeWordFill: Color(red: 0.20, green: 0.47, blue: 0.49).opacity(0.30),
                activeWordStroke: Color(red: 0.69, green: 0.91, blue: 0.89).opacity(0.80),
                activeWordText: Color(red: 0.98, green: 1.0, blue: 0.99),
                audioSurface: Color(red: 0.082, green: 0.094, blue: 0.118).opacity(0.98),
                audioBorder: Color.white.opacity(0.10),
                shadowColor: Color.black.opacity(0.22),
                heroGradient: LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.27, blue: 0.39),
                        Color(red: 0.09, green: 0.42, blue: 0.50),
                        Color(red: 0.08, green: 0.16, blue: 0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                heroGlow: Color(red: 0.45, green: 0.82, blue: 0.84).opacity(0.24)
            )
        }
    }
}
