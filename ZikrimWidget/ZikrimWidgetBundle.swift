import WidgetKit
import SwiftUI

@main
struct ZikrimWidgetBundle: WidgetBundle {
    var body: some Widget {
        SignatureWidget()
        PrayerFocusWidget()
        DhikrProgressWidget()
        PrayerTimelineWidget()
        PrayerDhikrWidget()
        SpiritualDashboardWidget()
        NoorSpotlightWidget()
        AuraFlowWidget()
        MajlisGlowWidget()
        DailyVerseWidget()
        DailyHadithWidget()
    }
}
