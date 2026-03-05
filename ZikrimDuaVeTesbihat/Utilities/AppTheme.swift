import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 18
    static let smallCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 14
    static let horizontalPadding: CGFloat = 18
    static let iconCornerRadius: CGFloat = 10
}

struct PremiumFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontDesign(.rounded)
    }
}

extension View {
    func premiumStyle() -> some View {
        modifier(PremiumFontModifier())
    }
}
