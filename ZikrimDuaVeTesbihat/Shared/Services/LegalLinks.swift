import Foundation

enum LegalLinks {
    static let marketingURL = URL(string: "https://melsalegal.com")!
    static let kvkkURL = URL(string: "https://melsalegal.com/kvkk")!
    static let privacyPolicyURL = URL(string: "https://melsalegal.com/privacy")!
    static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let supportURL = URL(string: "https://melsalegal.com/support")!
    static let supportEmail = "sabahattinaliyucel@melsalegal.com"
    static let standardEULATitle = "Apple Standard EULA"
    static let standardEULAShortTitle = "Apple EULA"

    static var supportEmailURL: URL? {
        URL(string: "mailto:\(supportEmail)")
    }
}
