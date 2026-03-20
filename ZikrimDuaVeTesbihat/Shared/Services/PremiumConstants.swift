import CoreGraphics
import Foundation

enum PremiumConstants {
    static let paywallMaxWidth: CGFloat = 720
    static let compactPaywallMaxWidth: CGFloat = 620
    static let fallbackMonthlyPrice: String = "79,90 ₺"
    static let fallbackYearlyPrice: String = "799,90 ₺"

    static func subscriptionTitle(isYearly: Bool) -> String {
        "\(L10n.string(.premiumPaywallEyebrow)) \(L10n.string(isYearly ? .premiumYearly : .premiumMonthly))"
    }

    static func subscriptionDuration(isYearly: Bool) -> String {
        "1 \(L10n.string(isYearly ? .premiumPeriodYear : .premiumPeriodMonth))"
    }

    static func fallbackPrice(isYearly: Bool) -> String {
        isYearly ? fallbackYearlyPrice : fallbackMonthlyPrice
    }

    static var complianceSectionTitle: String {
        L10n.string(.paywallComplianceSectionTitle)
    }

    static var compliancePlanLabel: String {
        L10n.string(.paywallCompliancePlanLabel)
    }

    static var complianceDurationLabel: String {
        L10n.string(.paywallComplianceDurationLabel)
    }

    static var compliancePriceLabel: String {
        L10n.string(.paywallCompliancePriceLabel)
    }

    static var complianceDisclosures: [String] {
        [
            L10n.string(.paywallComplianceDisclosureRenewal),
            L10n.string(.paywallComplianceDisclosurePayment),
            L10n.string(.paywallComplianceDisclosureRenewalCharge),
            L10n.string(.paywallComplianceDisclosureManage)
        ]
    }
}
