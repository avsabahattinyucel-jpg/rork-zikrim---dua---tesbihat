import Foundation
import SwiftUI

nonisolated enum AppName {
    private static let fullNameKey = "app_full_name"
    private static let shortNameKey = "app_short_name"

    static var full: String {
        NSLocalizedString(fullNameKey, comment: "Localized full application name")
    }

    static var short: String {
        NSLocalizedString(shortNameKey, comment: "Localized short application name")
    }

    static var fullTextKey: LocalizedStringKey {
        LocalizedStringKey(fullNameKey)
    }

    static var shortTextKey: LocalizedStringKey {
        LocalizedStringKey(shortNameKey)
    }
}

nonisolated enum ShareCardBranding {
    static var storeSubtitle: String {
        String(localized: "share_card_brand_store_subtitle", defaultValue: "App Store'da mevcuttur")
    }
}
