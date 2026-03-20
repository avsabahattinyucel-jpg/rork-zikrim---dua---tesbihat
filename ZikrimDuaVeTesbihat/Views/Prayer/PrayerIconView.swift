import SwiftUI

struct PrayerIconView: View {
    let assetName: String
    var size: CGFloat = 24

    var body: some View {
        Image(assetName)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
