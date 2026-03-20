import Foundation
import UserNotifications

struct DailyReminderNotificationEngine {
    private let contentFactory: NotificationContentFactory
    private let quietHoursEvaluator: QuietHoursEvaluator
    private let calendar: Calendar

    init(
        contentFactory: NotificationContentFactory,
        quietHoursEvaluator: QuietHoursEvaluator = QuietHoursEvaluator(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.contentFactory = contentFactory
        self.quietHoursEvaluator = quietHoursEvaluator
        self.calendar = calendar
    }

    func buildPlan(settings: NotificationSettings) -> ScheduledNotificationPlan {
        var requests: [ScheduledLocalNotification] = []
        var occupiedDates: [Date] = []

        let kinds = allowedKinds(settings: settings)
        for kind in kinds {
            guard let request = buildRequest(kind: kind, settings: settings) else { continue }
            requests.append(request)
            if let scheduledDate = request.scheduledDate {
                occupiedDates.append(scheduledDate)
            }
        }

        return ScheduledNotificationPlan(requests: requests, occupiedDates: occupiedDates)
    }

    private func allowedKinds(settings: NotificationSettings) -> [DailyReminderKind] {
        var kinds: [DailyReminderKind] = [.dailyAyah]

        if settings.dailyDuaEnabled {
            kinds.append(.dailyDua)
        }

        if settings.premiumEnabled {
            if settings.morningReminderEnabled { kinds.append(.morning) }
            if settings.eveningReminderEnabled { kinds.append(.evening) }
            if settings.sleepReminderEnabled { kinds.append(.sleep) }
        } else {
            if settings.morningReminderEnabled { kinds.append(.morning) }
            if settings.eveningReminderEnabled { kinds.append(.evening) }
        }

        return kinds
    }

    private func buildRequest(kind: DailyReminderKind, settings: NotificationSettings) -> ScheduledLocalNotification? {
        let time = kind.clockTime(in: settings)
        let probeDate = calendar.date(from: time.dateComponents(calendar: calendar)) ?? Date()

        guard !quietHoursEvaluator.shouldSuppressNonCriticalReminder(at: probeDate, configuration: settings.quietHours) else {
            return nil
        }

        let identifier = NotificationRequestIdentifier.daily(kind.identifier)
        let category = kind.category
        let content = contentFactory.makeContent(
            category: category,
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
            dateMatching: DateComponents(hour: time.hour, minute: time.minute),
            repeats: true
        )

        return ScheduledLocalNotification(
            identifier: identifier,
            category: category,
            content: content,
            trigger: trigger,
            scheduledDate: probeDate
        )
    }
}

private enum DailyReminderKind {
    case dailyAyah
    case dailyDua
    case morning
    case evening
    case sleep

    var identifier: String {
        switch self {
        case .dailyAyah: return "ayah"
        case .dailyDua: return "dua"
        case .morning: return "morning"
        case .evening: return "evening"
        case .sleep: return "sleep"
        }
    }

    var category: NotificationContentCategory {
        switch self {
        case .dailyAyah:
            return .dailyAyah
        case .dailyDua:
            return .dailyDua
        case .morning:
            return .morningDua
        case .evening:
            return .eveningReminder
        case .sleep:
            return .sleepReminder
        }
    }

    func clockTime(in settings: NotificationSettings) -> ClockTime {
        switch self {
        case .dailyAyah:
            return ClockTime(hour: 12, minute: 15)
        case .dailyDua:
            return settings.dailyDuaTime
        case .morning:
            return settings.morningReminderTime
        case .evening:
            return settings.eveningReminderTime
        case .sleep:
            return settings.sleepReminderTime
        }
    }
}
