import SwiftUI

struct PremiumEntranceModifier: ViewModifier {
    let isVisible: Bool
    let index: Int
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(reduceMotion ? 1 : (isVisible ? 1 : 0.985))
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : 18))
            .animation(animation, value: isVisible)
    }

    private var animation: Animation {
        if reduceMotion {
            return .easeOut(duration: 0.22).delay(Double(index) * 0.03)
        }

        return .spring(response: 0.72, dampingFraction: 0.88).delay(Double(index) * 0.06)
    }
}

extension View {
    func premiumEntrance(isVisible: Bool, index: Int, reduceMotion: Bool) -> some View {
        modifier(PremiumEntranceModifier(isVisible: isVisible, index: index, reduceMotion: reduceMotion))
    }
}
