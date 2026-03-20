import SwiftUI

struct ThemedScreen<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundView
                .ignoresSafeArea()

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.18), value: themeManager.currentTheme.runtimeSignature)
    }
}
