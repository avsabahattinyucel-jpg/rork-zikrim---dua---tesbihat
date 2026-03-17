import Foundation

enum LegalLinks {
    static let marketingURL = URL(string: "https://melsalegal.com")!
    static let privacyPolicyURL = URL(string: "https://melsalegal.com/privacy")!
    static let termsOfUseURL = URL(string: "https://melsalegal.com/terms")!
    static let supportURL = URL(string: "https://melsalegal.com/support")!
    static let supportEmail = "sabahattinaliyucel@melsalegal.com"

    static var supportEmailURL: URL? {
        URL(string: "mailto:\(supportEmail)")
    }
}
