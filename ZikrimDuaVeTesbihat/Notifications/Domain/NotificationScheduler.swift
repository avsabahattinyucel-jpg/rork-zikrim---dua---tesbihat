import Foundation
import UserNotifications

struct ScheduledLocalNotification: Sendable {
    let identifier: String
    let category: NotificationContentCategory
    let content: AppNotificationContent
    let trigger: UNNotificationTrigger
    let scheduledDate: Date?
}

struct ScheduledNotificationPlan: Sendable {
    var requests: [ScheduledLocalNotification]
    var occupiedDates: [Date]

    static let empty = ScheduledNotificationPlan(requests: [], occupiedDates: [])
}

struct PendingNotificationDebugItem: Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let dateDescription: String
}

protocol NotificationScheduler {
    func rebuildAllNotifications(settings: NotificationSettings) async throws
    func cancelAllAppNotifications() async
    func cancel(category: NotificationContentCategory) async
    func debugPendingRequests() async -> [PendingNotificationDebugItem]
    func sendDebugNotification(settings: NotificationSettings) async throws
}

enum NotificationSchedulerReason: String, Sendable {
    case appLaunch
    case foregroundRefresh
    case settingsChanged
    case premiumChanged
    case languageChanged
    case locationChanged
    case timezoneChanged
    case newDay
    case prayerTimesChanged
    case manual
}

enum NotificationRequestIdentifier {
    static let prefix = "zikrim.notification"

    static func prayer(_ prayer: PrayerName, date: Date, offsetMinutes: Int, calendar: Calendar) -> String {
        "\(prefix).prayer.\(prayer.rawValue).\(dayStamp(for: date, calendar: calendar)).\(offsetMinutes)"
    }

    static func daily(_ name: String) -> String {
        "\(prefix).daily.\(name)"
    }

    static func friday() -> String {
        "\(prefix).friday.weekly"
    }

    static func specialDay(_ id: String, date: Date, calendar: Calendar) -> String {
        "\(prefix).special.\(id).\(dayStamp(for: date, calendar: calendar))"
    }

    static func smart(slotIndex: Int, date: Date, calendar: Calendar) -> String {
        "\(prefix).smart.\(dayStamp(for: date, calendar: calendar)).\(slotIndex)"
    }

    static func debugNow() -> String {
        "\(prefix).debug.now"
    }

    static func belongsToApp(_ identifier: String) -> Bool {
        identifier.hasPrefix(prefix)
    }

    static func dayStamp(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

final class NotificationSchedulerImpl: NotificationScheduler {
    private let center: UNUserNotificationCenter
    private let permissionManager: NotificationPermissionManager
    private let prayerEngine: PrayerNotificationEngine
    private let dailyEngine: DailyReminderNotificationEngine
    private let smartEngine: SmartReminderNotificationEngine
    private let fridayEngine: FridayNotificationEngine
    private let specialDaysEngine: SpecialDaysNotificationEngine
    private let analytics: NotificationAnalyticsTracking
    private let calendar: Calendar

    init(
        center: UNUserNotificationCenter = .current(),
        permissionManager: NotificationPermissionManager,
        prayerEngine: PrayerNotificationEngine,
        dailyEngine: DailyReminderNotificationEngine,
        smartEngine: SmartReminderNotificationEngine,
        fridayEngine: FridayNotificationEngine,
        specialDaysEngine: SpecialDaysNotificationEngine,
        analytics: NotificationAnalyticsTracking = NotificationNoopAnalyticsTracker(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center
        self.permissionManager = permissionManager
        self.prayerEngine = prayerEngine
        self.dailyEngine = dailyEngine
        self.smartEngine = smartEngine
        self.fridayEngine = fridayEngine
        self.specialDaysEngine = specialDaysEngine
        self.analytics = analytics
        self.calendar = calendar
    }

    func rebuildAllNotifications(settings: NotificationSettings) async throws {
        let permissionState = await permissionManager.refreshStatus()
        guard permissionState.isGranted else {
            await cancelAllAppNotifications()
            analytics.track(event: "notification_rebuild_skipped", metadata: ["reason": "permission_not_granted"])
            return
        }

        await cancelAllAppNotifications()

        var allRequests: [ScheduledLocalNotification] = []

        let prayerPlan = await prayerEngine.buildPlan(settings: settings)
        allRequests.append(contentsOf: prayerPlan.requests)

        let dailyPlan = dailyEngine.buildPlan(settings: settings)
        allRequests.append(contentsOf: dailyPlan.requests)

        let occupied = prayerPlan.occupiedDates + dailyPlan.occupiedDates
        let smartPlan = smartEngine.buildPlan(settings: settings, occupiedDates: occupied)
        allRequests.append(contentsOf: smartPlan.requests)

        let fridayPlan = fridayEngine.buildPlan(settings: settings)
        allRequests.append(contentsOf: fridayPlan.requests)

        let specialPlan = specialDaysEngine.buildPlan(settings: settings)
        allRequests.append(contentsOf: specialPlan.requests)

        for request in allRequests {
            try await center.add(
                UNNotificationRequest(
                    identifier: request.identifier,
                    content: prayerEngine.contentFactory.makeUNContent(from: request.content),
                    trigger: request.trigger
                )
            )
        }

        analytics.track(
            event: "notification_rebuild_completed",
            metadata: [
                "count": String(allRequests.count),
                "premium": String(settings.premiumEnabled)
            ]
        )
    }

    func cancelAllAppNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter(NotificationRequestIdentifier.belongsToApp(_:))

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancel(category: NotificationContentCategory) async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .filter { request in
                request.identifier.contains(".\(category.rawValue)")
                    || request.content.userInfo["zikrim.notification.route"] != nil
            }
            .map(\.identifier)
            .filter(NotificationRequestIdentifier.belongsToApp(_:))

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func debugPendingRequests() async -> [PendingNotificationDebugItem] {
        let pending = await center.pendingNotificationRequests()
        return pending
            .filter { NotificationRequestIdentifier.belongsToApp($0.identifier) }
            .map {
                PendingNotificationDebugItem(
                    id: $0.identifier,
                    title: $0.content.title,
                    body: $0.content.body,
                    dateDescription: describe(trigger: $0.trigger)
                )
            }
            .sorted { $0.dateDescription < $1.dateDescription }
    }

    func sendDebugNotification(settings: NotificationSettings) async throws {
        let content = await debugContent(settings: settings)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationRequestIdentifier.debugNow(),
            content: prayerEngine.contentFactory.makeUNContent(from: content),
            trigger: trigger
        )
        try await center.add(request)
    }

    private func describe(trigger: UNNotificationTrigger?) -> String {
        switch trigger {
        case let calendarTrigger as UNCalendarNotificationTrigger:
            let components = calendarTrigger.dateComponents
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            let weekday = components.weekday.map(String.init) ?? "-"
            return "weekday=\(weekday) \(String(format: "%02d:%02d", hour, minute)) repeats=\(calendarTrigger.repeats)"
        case let timeTrigger as UNTimeIntervalNotificationTrigger:
            return "in \(Int(timeTrigger.timeInterval))s"
        default:
            return "unknown"
        }
    }

    private func debugContent(settings: NotificationSettings) async -> AppNotificationContent {
        return AppNotificationContent(
            contentID: "debug_now",
            category: .dailyDua,
            title: L10n.string(.settingsTestNotificationTitle),
            subtitle: nil,
            body: L10n.string(.notificationTestBody),
            route: .notificationsSettings,
            sound: settings.vibrationOnly ? nil : NotificationSoundCatalog.sound(for: settings.soundSelection, isPrayer: false),
            interruptionLevel: .active,
            relevanceScore: nil
        )
    }
}
