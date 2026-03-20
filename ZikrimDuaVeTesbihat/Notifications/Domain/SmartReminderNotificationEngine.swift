import Foundation
import UserNotifications

struct SmartReminderSlotSelector {
    private let calendar: Calendar
    private let quietHoursEvaluator: QuietHoursEvaluator
    private let minimumGapMinutes: Int

    init(
        calendar: Calendar = .autoupdatingCurrent,
        quietHoursEvaluator: QuietHoursEvaluator = QuietHoursEvaluator(),
        minimumGapMinutes: Int = 90
    ) {
        self.calendar = calendar
        self.quietHoursEvaluator = quietHoursEvaluator
        self.minimumGapMinutes = minimumGapMinutes
    }

    func selectSlots(
        startDate: Date,
        days: Int,
        capPerDay: Int,
        quietHours: QuietHoursConfiguration,
        occupiedDates: [Date]
    ) -> [Date] {
        guard capPerDay > 0 else { return [] }

        let windows = [
            ClosedRange(uncheckedBounds: (8 * 60 + 20, 9 * 60 + 40)),
            ClosedRange(uncheckedBounds: (12 * 60 + 20, 13 * 60 + 50)),
            ClosedRange(uncheckedBounds: (20 * 60 + 10, 21 * 60 + 40))
        ]

        let blocked = occupiedDates.sorted()
        var selected: [Date] = []

        for dayOffset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: startDate)) else {
                continue
            }

            let daySeed = abs(NotificationRequestIdentifier.dayStamp(for: day, calendar: calendar).hashValue)
            var daySlots: [Date] = []

            for (index, window) in windows.enumerated() {
                let rangeCount = max(window.upperBound - window.lowerBound, 1)
                let primaryMinute = window.lowerBound + ((daySeed + index * 37) % rangeCount)
                let secondaryMinute = window.lowerBound + ((daySeed + index * 61 + 17) % rangeCount)

                for minuteOfDay in [primaryMinute, secondaryMinute] {
                    guard let candidate = calendar.date(byAdding: .minute, value: minuteOfDay, to: day) else { continue }
                    guard !quietHoursEvaluator.shouldSuppressNonCriticalReminder(at: candidate, configuration: quietHours) else { continue }
                    guard isFarEnough(candidate, from: blocked + daySlots + selected) else { continue }
                    daySlots.append(candidate)
                    if daySlots.count == capPerDay { break }
                }

                if daySlots.count == capPerDay { break }
            }

            selected.append(contentsOf: daySlots.sorted())
        }

        return selected.sorted()
    }

    private func isFarEnough(_ candidate: Date, from dates: [Date]) -> Bool {
        dates.allSatisfy { abs($0.timeIntervalSince(candidate)) >= TimeInterval(minimumGapMinutes * 60) }
    }
}

struct SmartReminderNotificationEngine {
    private let contentFactory: NotificationContentFactory
    private let selector: SmartReminderSlotSelector
    private let calendar: Calendar

    init(
        contentFactory: NotificationContentFactory,
        selector: SmartReminderSlotSelector = SmartReminderSlotSelector(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.contentFactory = contentFactory
        self.selector = selector
        self.calendar = calendar
    }

    func buildPlan(settings: NotificationSettings, occupiedDates: [Date]) -> ScheduledNotificationPlan {
        guard settings.premiumEnabled, settings.smartRemindersEnabled else {
            return .empty
        }

        let selectedSlots = selector.selectSlots(
            startDate: Date(),
            days: 3,
            capPerDay: settings.smartReminderIntensity.dailyCap,
            quietHours: settings.quietHours,
            occupiedDates: occupiedDates
        )

        let requests = selectedSlots.enumerated().map { index, date in
            let identifier = NotificationRequestIdentifier.smart(slotIndex: index, date: date, calendar: calendar)
            let content = contentFactory.makeContent(
                category: .smartDhikrNudge,
                context: NotificationContentContext(
                    settings: settings,
                    scheduledDate: date,
                    requestKey: identifier,
                    prayer: nil,
                    offsetMinutes: nil,
                    specialDayTitle: nil
                )
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                repeats: false
            )
            return ScheduledLocalNotification(
                identifier: identifier,
                category: .smartDhikrNudge,
                content: content,
                trigger: trigger,
                scheduledDate: date
            )
        }

        return ScheduledNotificationPlan(requests: requests, occupiedDates: selectedSlots)
    }
}
