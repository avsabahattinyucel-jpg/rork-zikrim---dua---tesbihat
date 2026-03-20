import SwiftUI

struct PremiumCallToActionButton: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                }

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .themedPrimaryButton(cornerRadius: 22)
        }
        .buttonStyle(PremiumPressButtonStyle(reduceMotion: reduceMotion))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.58)
    }
}

private struct PremiumPressButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.12)
                    : .spring(response: 0.24, dampingFraction: 0.82),
                value: configuration.isPressed
            )
    }
}
