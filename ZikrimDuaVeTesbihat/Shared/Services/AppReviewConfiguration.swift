import Foundation

enum AppReviewConfiguration {
    static let privacyPolicyURL = LegalLinks.privacyPolicyURL
    static let termsOfUseURL = LegalLinks.termsOfUseURL
    static let supportURL = LegalLinks.supportURL
    static let supportEmail = LegalLinks.supportEmail

    static var supportEmailURL: URL? {
        LegalLinks.supportEmailURL
    }
}
