import Foundation
import FirebaseCore

struct LocalBootstrapSnapshot: Sendable {
    let hasCompletedOnboarding: Bool
    let preferredLanguageCode: String
}

enum AppServices {
    @MainActor
    static func configureCoreServicesIfNeeded(isRunningTests: Bool = false) {
        guard !isRunningTests else { return }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("[AppServices] Firebase configured for auth and messaging")
        }

        // Keep the review build on a no-tracking, no-ad-serving path: no ATT prompt, no
        // cross-app tracking, and no ad network initialization.
        RevenueCatService.shared.configure()
    }

    static func preloadLocalSettings(defaults: UserDefaults = .standard) -> LocalBootstrapSnapshot {
        LocalBootstrapSnapshot(
            hasCompletedOnboarding: defaults.bool(forKey: OnboardingStore.storageKey),
            preferredLanguageCode: RabiaAppLanguage.currentCode()
        )
    }

    @MainActor
    static func warmDailyContentCache() {
        _ = DailyVerseProvider.shared.verseForDate()
    }

    @MainActor
    static func warmBackgroundCachesIfNeeded(isRunningTests: Bool = false) {
        guard !isRunningTests else { return }

        Task { @MainActor in
            AppServices.warmDailyContentCache()
            RabiaQuranEmbeddingRetriever.shared.preloadSemanticIndex()
        }
    }
}
