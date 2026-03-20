import Foundation
import Testing
@testable import ZikrimDuaVeTesbihat

struct NotificationDomainTests {
    @Test
    func quietHoursEvaluatorHandlesOvernightWindow() {
        let evaluator = QuietHoursEvaluator(calendar: fixedCalendar)
        let configuration = QuietHoursConfiguration(
            isEnabled: true,
            start: ClockTime(hour: 23, minute: 30),
            end: ClockTime(hour: 7, minute: 30)
        )

        #expect(evaluator.isDateWithinQuietHours(makeDate(hour: 0, minute: 15), configuration: configuration))
        #expect(evaluator.isDateWithinQuietHours(makeDate(hour: 23, minute: 45), configuration: configuration))
        #expect(!evaluator.isDateWithinQuietHours(makeDate(hour: 12, minute: 0), configuration: configuration))
    }

    @Test
    func smartReminderSelectorAvoidsBlockedPrayerTimes() {
        let selector = SmartReminderSlotSelector(
            calendar: fixedCalendar,
            quietHoursEvaluator: QuietHoursEvaluator(calendar: fixedCalendar),
            minimumGapMinutes: 75
        )

        let start = makeDate(day: 1, hour: 0, minute: 0)
        let blocked = [
            makeDate(day: 1, hour: 10, minute: 30),
            makeDate(day: 1, hour: 15, minute: 0)
        ]

        let slots = selector.selectSlots(
            startDate: start,
            days: 1,
            capPerDay: 2,
            quietHours: .default,
            occupiedDates: blocked
        )

        #expect(slots.count <= 2)
        #expect(slots.allSatisfy { slot in
            blocked.allSatisfy { abs($0.timeIntervalSince(slot)) >= 75 * 60 }
        })
    }

    @Test
    func summaryBuilderIncludesPrimarySettings() {
        var settings = NotificationSettings.default
        settings.currentLanguageCode = "en"
        settings.smartRemindersEnabled = true
        settings.premiumEnabled = true
        settings.quietHours = QuietHoursConfiguration(
            isEnabled: true,
            start: ClockTime(hour: 23, minute: 30),
            end: ClockTime(hour: 7, minute: 30)
        )

        let summary = NotificationSettingsSummaryBuilder().summary(settings: settings)

        #expect(summary.contains("Prayer"))
        #expect(summary.contains("Morning"))
        #expect(summary.contains("Quiet"))
    }

    @Test
    func identifiersStayStableForPrayerRequests() {
        let date = makeDate(day: 1, hour: 5, minute: 30)
        let identifier = NotificationRequestIdentifier.prayer(.fajr, date: date, offsetMinutes: 15, calendar: fixedCalendar)
        #expect(identifier == "zikrim.notification.prayer.fajr.2026-03-01.15")
    }

    @Test
    func deliverySettingsFlagQuietSystemDelivery() {
        let provisional = AppNotificationDeliverySettings(
            authorizationState: .provisional,
            alertEnabled: true,
            soundEnabled: true,
            notificationCenterEnabled: true,
            lockScreenEnabled: true
        )
        let mutedAuthorized = AppNotificationDeliverySettings(
            authorizationState: .authorized,
            alertEnabled: true,
            soundEnabled: false,
            notificationCenterEnabled: true,
            lockScreenEnabled: true
        )
        let fullyEnabled = AppNotificationDeliverySettings(
            authorizationState: .authorized,
            alertEnabled: true,
            soundEnabled: true,
            notificationCenterEnabled: true,
            lockScreenEnabled: true
        )

        #expect(provisional.needsSystemSettingsAttention)
        #expect(provisional.attentionReasons == [.provisionalAuthorization])
        #expect(mutedAuthorized.needsSystemSettingsAttention)
        #expect(mutedAuthorized.attentionReasons == [.soundDisabled])
        #expect(!fullyEnabled.needsSystemSettingsAttention)
        #expect(fullyEnabled.attentionReasons.isEmpty)
    }

    @Test
    func deliverySettingsDifferentiateBannerAndCombinedIssues() {
        let bannerOnly = AppNotificationDeliverySettings(
            authorizationState: .authorized,
            alertEnabled: false,
            soundEnabled: true,
            notificationCenterEnabled: true,
            lockScreenEnabled: true
        )
        let soundAndBanner = AppNotificationDeliverySettings(
            authorizationState: .authorized,
            alertEnabled: false,
            soundEnabled: false,
            notificationCenterEnabled: true,
            lockScreenEnabled: true
        )

        #expect(bannerOnly.attentionReasons == [.alertsDisabled])
        #expect(soundAndBanner.attentionReasons == [.soundDisabled, .alertsDisabled])
    }

    @Test
    func dailyReminderPlanAlwaysIncludesDailyAyah() {
        var settings = NotificationSettings.default
        settings.dailyDuaEnabled = false
        settings.morningReminderEnabled = false
        settings.eveningReminderEnabled = false
        settings.sleepReminderEnabled = false

        let engine = DailyReminderNotificationEngine(
            contentFactory: NotificationContentFactory(),
            quietHoursEvaluator: QuietHoursEvaluator(calendar: fixedCalendar),
            calendar: fixedCalendar
        )

        let plan = engine.buildPlan(settings: settings)

        #expect(plan.requests.count == 1)
        #expect(plan.requests.first?.category == .dailyAyah)
        #expect(plan.requests.first?.content.route == .dailyAyah)
    }

    @Test
    func prayerContentUsesTimeSensitiveLayoutAndLocationAwareTitle() {
        var settings = NotificationSettings.default
        settings.currentLanguageCode = "tr"
        settings.currentTimezoneIdentifier = "Europe/Istanbul"
        settings.currentLocation = NotificationLocationSnapshot(
            identifier: "Kadikoy",
            cityName: "Kadikoy",
            administrativeArea: "Istanbul",
            country: "TR",
            latitude: nil,
            longitude: nil,
            timezoneIdentifier: "Europe/Istanbul"
        )

        let content = NotificationContentFactory().makeContent(
            category: .prayerTimeNow,
            context: NotificationContentContext(
                settings: settings,
                scheduledDate: makeDate(hour: 5, minute: 38),
                requestKey: "debug",
                prayer: .fajr,
                offsetMinutes: 0,
                specialDayTitle: nil
            )
        )

        #expect(content.title.contains("Sabah"))
        #expect(content.title.contains("05:38"))
        #expect(content.title.contains("Kadikoy"))
        #expect(content.interruptionLevel == .timeSensitive)
    }

    @Test
    func prayerContentUsesPrayerSpecificTurkishTextPool() {
        var settings = NotificationSettings.default
        settings.currentLanguageCode = "tr"
        settings.currentTimezoneIdentifier = "Europe/Istanbul"

        let content = NotificationContentFactory().makeContent(
            category: .prayerReminder,
            context: NotificationContentContext(
                settings: settings,
                scheduledDate: makeDate(hour: 18, minute: 45),
                requestKey: "debug-maghrib",
                prayer: .maghrib,
                offsetMinutes: 15,
                specialDayTitle: nil
            )
        )

        let variants = PrayerNotificationTextCatalog.variants(for: .maghrib, language: .tr).map(\.text)

        #expect(content.body.contains("15 dakika sonra"))
        #expect(content.body.contains("Akşam"))
        #expect(variants.contains { content.body.contains($0) })
    }

    @Test
    func prayerContentCatalogLoadsLocalizedJsonVariants() {
        let englishVariants = PrayerNotificationTextCatalog.variants(for: .fajr, language: .en)
        let turkishVariants = PrayerNotificationTextCatalog.variants(for: .isha, language: .tr)

        #expect(englishVariants.count == 50)
        #expect(turkishVariants.count == 50)
        #expect(englishVariants.first?.text.contains("Allah") == true || englishVariants.first?.text.contains("Lord") == true)
        #expect(turkishVariants.first?.text.isEmpty == false)
    }

    @MainActor
    @Test
    func settingsStoreMigratesLegacyNotificationPreferences() {
        let suiteName = "NotificationDomainTests.LegacyMigration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set(true, forKey: "prayer_notifications_enabled")
        defaults.set(30, forKey: "prayer_reminder_offset")
        defaults.set(false, forKey: "daily_dua_enabled")
        defaults.set(true, forKey: "morning_reminder_enabled")
        defaults.set(true, forKey: "evening_reminder_enabled")
        defaults.set(true, forKey: "notification_vibration_only")
        defaults.set(22, forKey: "quiet_hours_start")
        defaults.set(6, forKey: "quiet_hours_end")

        let calendar = fixedCalendar
        defaults.set(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 6, minute: 50)), forKey: "morning_reminder_time")
        defaults.set(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 20, minute: 45)), forKey: "evening_reminder_time")

        let store = NotificationSettingsStore(defaults: defaults)
        let settings = store.settings

        #expect(settings.prayerNotificationsEnabled)
        #expect(settings.reminderTimingMode == .thirtyMinutesBefore)
        #expect(!settings.dailyDuaEnabled)
        #expect(settings.morningReminderEnabled)
        #expect(settings.morningReminderTime == ClockTime(hour: 6, minute: 50))
        #expect(settings.eveningReminderEnabled)
        #expect(settings.eveningReminderTime == ClockTime(hour: 20, minute: 45))
        #expect(settings.vibrationOnly)
        #expect(settings.quietHours.start == ClockTime(hour: 22, minute: 0))
        #expect(settings.quietHours.end == ClockTime(hour: 6, minute: 0))
    }

    @MainActor
    @Test
    func duaAndAyahRoutesOpenExpectedTabs() {
        let appState = AppState()

        appState.handleNotificationRoute(.dailyDua)
        #expect(appState.selectedTab == .guide)
        #expect(appState.presentedNotificationDestination == nil)

        appState.handleNotificationRoute(.dailyAyah)
        #expect(appState.selectedTab == .quran)
        #expect(appState.presentedNotificationDestination == nil)
    }

    private var fixedCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .gmt
        return calendar
    }

    private func makeDate(day: Int = 1, hour: Int, minute: Int) -> Date {
        fixedCalendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour, minute: minute)) ?? Date()
    }
}
