import Foundation
import UserNotifications

struct PrayerNotificationEngine {
    let provider: PrayerTimesProviding
    let contentFactory: NotificationContentFactory
    private let calendar: Calendar

    init(
        provider: PrayerTimesProviding,
        contentFactory: NotificationContentFactory,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.provider = provider
        self.contentFactory = contentFactory
        self.calendar = calendar
    }

    func buildPlan(settings: NotificationSettings) async -> ScheduledNotificationPlan {
        guard settings.prayerNotificationsEnabled,
              let context = await provider.currentContext() else {
            return .empty
        }

        let now = Date()
        var requests: [ScheduledLocalNotification] = []
        var occupiedDates: [Date] = []

        for dayOffset in 0..<2 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let prayerTimes = await provider.prayerTimes(for: day, context: context) else {
                continue
            }

            for prayer in settings.prayerPreferences.enabledPrayers {
                guard let prayerDate = prayerTimes.allTimes[prayer] else { continue }

                for offset in settings.reminderTimingMode.offsetsInMinutes {
                    let scheduledDate = offset > 0
                        ? calendar.date(byAdding: .minute, value: -offset, to: prayerDate)
                        : prayerDate

                    guard let scheduledDate, scheduledDate > now else { continue }

                    let identifier = NotificationRequestIdentifier.prayer(
                        prayer,
                        date: prayerDate,
                        offsetMinutes: offset,
                        calendar: calendar
                    )

                    let content = contentFactory.makeContent(
                        category: offset > 0 ? .prayerReminder : .prayerTimeNow,
                        context: NotificationContentContext(
                            settings: settings,
                            scheduledDate: scheduledDate,
                            requestKey: identifier,
                            prayer: prayer,
                            offsetMinutes: offset,
                            specialDayTitle: nil
                        )
                    )

                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate),
                        repeats: false
                    )

                    requests.append(
                        ScheduledLocalNotification(
                            identifier: identifier,
                            category: offset > 0 ? .prayerReminder : .prayerTimeNow,
                            content: content,
                            trigger: trigger,
                            scheduledDate: scheduledDate
                        )
                    )
                    occupiedDates.append(scheduledDate)
                }
            }
        }

        return ScheduledNotificationPlan(requests: requests, occupiedDates: occupiedDates)
    }
}
