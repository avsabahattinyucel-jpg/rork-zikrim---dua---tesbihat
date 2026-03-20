import Foundation
import UserNotifications

struct FridayNotificationEngine {
    private let contentFactory: NotificationContentFactory

    init(contentFactory: NotificationContentFactory) {
        self.contentFactory = contentFactory
    }

    func buildPlan(settings: NotificationSettings) -> ScheduledNotificationPlan {
        guard settings.premiumEnabled, settings.fridayReminderEnabled else {
            return .empty
        }

        let identifier = NotificationRequestIdentifier.friday()
        let probeDate = Calendar.autoupdatingCurrent.date(from: settings.fridayReminderTime.dateComponents()) ?? Date()
        let content = contentFactory.makeContent(
            category: .fridayBlessing,
            context: NotificationContentContext(
                settings: settings,
                scheduledDate: probeDate,
                requestKey: identifier,
                prayer: nil,
                offsetMinutes: nil,
                specialDayTitle: nil
            )
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: settings.fridayReminderTime.hour, minute: settings.fridayReminderTime.minute, weekday: 6),
            repeats: true
        )

        let request = ScheduledLocalNotification(
            identifier: identifier,
            category: .fridayBlessing,
            content: content,
            trigger: trigger,
            scheduledDate: probeDate
        )
        return ScheduledNotificationPlan(requests: [request], occupiedDates: [probeDate])
    }
}
