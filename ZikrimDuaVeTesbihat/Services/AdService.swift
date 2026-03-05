import Foundation
import GoogleMobileAds
import UIKit

@Observable
@MainActor
class AdService: NSObject {
    static let shared = AdService()

    private let bannerAdUnitID = "ca-app-pub-2903648008581200/3051008310"
    private let interstitialAdUnitID = "ca-app-pub-2903648008581200/9193056477"

    var isPremium: Bool = false
    var interstitialAd: GADInterstitialAd?
    var isInterstitialReady: Bool = false

    private override init() {
        super.init()
    }

    func configure() {
        GADMobileAds.sharedInstance().start { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.loadInterstitial()
            }
        }
    }

    func bannerAdUnitId() -> String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        return bannerAdUnitID
        #endif
    }

    func interstitialAdUnitId() -> String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        return interstitialAdUnitID
        #endif
    }

    func loadInterstitial() {
        guard !isPremium else { return }
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: interstitialAdUnitId(), request: request) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    _ = error
                    self.isInterstitialReady = false
                    return
                }
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                self.isInterstitialReady = true
            }
        }
    }

    func showInterstitial(from viewController: UIViewController? = nil) {
        guard !isPremium, isInterstitialReady, let ad = interstitialAd else { return }
        let vc = viewController ?? topViewController()
        guard let vc else { return }
        ad.present(fromRootViewController: vc)
        isInterstitialReady = false
        interstitialAd = nil
    }

    func updatePremiumStatus(_ premium: Bool) {
        isPremium = premium
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else { return nil }
        var topVC = window.rootViewController
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}

extension AdService: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: any GADFullScreenPresentingAd) {
        Task { @MainActor in
            self.loadInterstitial()
        }
    }

    nonisolated func ad(_ ad: any GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.isInterstitialReady = false
            self.loadInterstitial()
        }
    }
}
