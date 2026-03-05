import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = context.coordinator.rootViewController()
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        func rootViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return nil }
            return window.rootViewController
        }
    }
}

struct ConditionalBannerAd: View {
    let isPremium: Bool

    var body: some View {
        if !isPremium {
            BannerAdView(adUnitID: AdService.shared.bannerAdUnitId())
                .frame(height: 50)
                .padding(.bottom, 15)
        }
    }
}
