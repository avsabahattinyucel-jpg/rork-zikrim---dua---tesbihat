import Foundation
import UserNotifications

struct IslamicSpecialDay: Identifiable, Sendable {
    let id: String
    let hijriMonth: Int
    let hijriDay: Int
    let localizedTitles: [AppLanguage: String]
}

struct SpecialDaysNotificationEngine {
    private let contentFactory: NotificationContentFactory
    private let calendar: Calendar

    init(
        contentFactory: NotificationContentFactory,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.contentFactory = contentFactory
        self.calendar = calendar
    }

    func buildPlan(settings: NotificationSettings) -> ScheduledNotificationPlan {
        guard settings.premiumEnabled, settings.specialIslamicDaysEnabled else {
            return .empty
        }

        let now = Date()
        var requests: [ScheduledLocalNotification] = []

        for day in Self.days {
            guard let date = nextOccurrence(of: day, after: now) else { continue }

            let reminderDate = dateSetting(for: settings.specialIslamicDayReminderTime, on: date)
            guard reminderDate > now else { continue }

            let identifier = NotificationRequestIdentifier.specialDay(day.id, date: reminderDate, calendar: calendar)
            let title = day.localizedTitles[settings.effectiveLanguage] ?? day.localizedTitles[.en]
            let content = contentFactory.makeContent(
                category: .specialDayReminder,
                context: NotificationContentContext(
                    settings: settings,
                    scheduledDate: reminderDate,
                    requestKey: identifier,
                    prayer: nil,
                    offsetMinutes: nil,
                    specialDayTitle: title
                )
            )

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
                repeats: false
            )
            requests.append(
                ScheduledLocalNotification(
                    identifier: identifier,
                    category: .specialDayReminder,
                    content: content,
                    trigger: trigger,
                    scheduledDate: reminderDate
                )
            )
        }

        return ScheduledNotificationPlan(
            requests: requests.sorted { ($0.scheduledDate ?? .distantFuture) < ($1.scheduledDate ?? .distantFuture) },
            occupiedDates: requests.compactMap(\.scheduledDate)
        )
    }

    private func nextOccurrence(of day: IslamicSpecialDay, after referenceDate: Date) -> Date? {
        var hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        hijriCalendar.timeZone = calendar.timeZone

        let currentHijriYear = hijriCalendar.component(.year, from: referenceDate)
        let candidateYears = [currentHijriYear, currentHijriYear + 1]

        for year in candidateYears {
            var components = DateComponents()
            components.calendar = hijriCalendar
            components.year = year
            components.month = day.hijriMonth
            components.day = day.hijriDay
            if let date = hijriCalendar.date(from: components),
               date >= calendar.startOfDay(for: referenceDate) {
                return calendar.startOfDay(for: date)
            }
        }

        return nil
    }

    private func dateSetting(for time: ClockTime, on date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .minute, value: time.minutesSinceMidnight, to: startOfDay) ?? startOfDay
    }

    static let days: [IslamicSpecialDay] = [
        IslamicSpecialDay(id: "laylat_al_raghaib", hijriMonth: 7, hijriDay: 1, localizedTitles: [.en: "Laylat al-Raghaib", .tr: "Regaib Kandili"]),
        IslamicSpecialDay(id: "laylat_al_miraj", hijriMonth: 7, hijriDay: 27, localizedTitles: [.en: "Laylat al-Miraj", .tr: "Miraç Kandili"]),
        IslamicSpecialDay(id: "laylat_al_barat", hijriMonth: 8, hijriDay: 15, localizedTitles: [.en: "Laylat al-Baraat", .tr: "Berat Kandili"]),
        IslamicSpecialDay(id: "laylat_al_qadr", hijriMonth: 9, hijriDay: 27, localizedTitles: [.en: "Laylat al-Qadr", .tr: "Kadir Gecesi"]),
        IslamicSpecialDay(id: "eid_al_fitr", hijriMonth: 10, hijriDay: 1, localizedTitles: [.en: "Eid al-Fitr", .tr: "Ramazan Bayramı"]),
        IslamicSpecialDay(id: "eid_al_adha", hijriMonth: 12, hijriDay: 10, localizedTitles: [.en: "Eid al-Adha", .tr: "Kurban Bayramı"]),
        IslamicSpecialDay(id: "mawlid", hijriMonth: 3, hijriDay: 12, localizedTitles: [.en: "Mawlid", .tr: "Mevlid Kandili"])
    ]
}
