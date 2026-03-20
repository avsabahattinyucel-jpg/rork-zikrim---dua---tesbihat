import Foundation

enum PremiumEntryL10n {
    static let cardUnlockTitleKey = L10n.Key("premium.card.unlock_title", fallback: "Unlock Premium")
    static let cardUnlockSubtitleKey = L10n.Key("premium.card.unlock_subtitle", fallback: "Access all premium features")
    static let cardActiveTitleKey = L10n.Key("premium.card.active_title", fallback: "Premium Active")
    static let cardActiveSubtitleKey = L10n.Key("premium.card.active_subtitle", fallback: "Enjoy all premium features")
    static let cardRenewal = L10n.Key("premium.card.renewal", fallback: "Renews %@")
    static let managementTitleKey = L10n.Key("premium.management.title", fallback: "Premium")
    static let managementPlanKey = L10n.Key("premium.management.plan", fallback: "Current Plan")
    static let managementStatusKey = L10n.Key("premium.management.status", fallback: "Status")
    static let managementRenewsKey = L10n.Key("premium.management.renews", fallback: "Renews")
    static let managementFeaturesKey = L10n.Key("premium.management.features", fallback: "Included Features")
    static let managementManageKey = L10n.Key("premium.management.manage", fallback: "Manage Subscription")
    static let managementRestoreKey = L10n.Key("premium.management.restore", fallback: "Restore Purchases")
    static let managementSupportKey = L10n.Key("premium.management.support", fallback: "Contact Support")

    static var cardUnlockTitle: String { L10n.string(cardUnlockTitleKey) }
    static var cardUnlockSubtitle: String { L10n.string(cardUnlockSubtitleKey) }
    static var cardActiveTitle: String { L10n.string(cardActiveTitleKey) }
    static var cardActiveSubtitle: String { L10n.string(cardActiveSubtitleKey) }
    static var managementTitle: String { L10n.string(managementTitleKey) }
    static var managementPlan: String { L10n.string(managementPlanKey) }
    static var managementStatus: String { L10n.string(managementStatusKey) }
    static var managementRenews: String { L10n.string(managementRenewsKey) }
    static var managementFeatures: String { L10n.string(managementFeaturesKey) }
    static var managementManage: String { L10n.string(managementManageKey) }
    static var managementRestore: String { L10n.string(managementRestoreKey) }
    static var managementSupport: String { L10n.string(managementSupportKey) }
}
