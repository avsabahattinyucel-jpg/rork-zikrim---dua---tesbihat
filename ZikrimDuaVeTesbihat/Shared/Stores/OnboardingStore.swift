import Foundation
import Observation

@Observable
@MainActor
final class OnboardingStore {
    nonisolated static let storageKey = "hasCompletedOnboarding"

    private let defaults: UserDefaults
    private(set) var hasCompletedOnboarding: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Self.storageKey)
    }

    func sync(with snapshot: LocalBootstrapSnapshot? = nil) {
        if let snapshot {
            hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        } else {
            hasCompletedOnboarding = defaults.bool(forKey: Self.storageKey)
        }
    }

    func complete() {
        defaults.set(true, forKey: Self.storageKey)
        hasCompletedOnboarding = true
    }
}
