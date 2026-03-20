import Foundation

struct OnboardingPage: Identifiable, Sendable {
    let id: String
    let imageName: String
    let titleKey: L10n.Key
    let subtitleKey: L10n.Key

    init(imageName: String, titleKey: L10n.Key, subtitleKey: L10n.Key) {
        self.id = imageName
        self.imageName = imageName
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
    }
}
