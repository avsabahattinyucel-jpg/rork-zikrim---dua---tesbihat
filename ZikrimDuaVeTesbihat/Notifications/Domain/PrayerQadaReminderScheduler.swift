import Foundation
import UserNotifications

struct PrayerQadaReminderScheduler {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center
        self.calendar = calendar
    }

    func rescheduleReminder(
        for date: Date,
        missedPrayers: [PrayerName],
        nextMorningDate: Date?
    ) async {
        let identifier = NotificationRequestIdentifier.daily("qada.\(NotificationRequestIdentifier.dayStamp(for: date, calendar: calendar))")

        guard let nextMorningDate,
              nextMorningDate > date,
              !missedPrayers.isEmpty else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let names = missedPrayerNames(missedPrayers)
        let content = UNMutableNotificationContent()
        content.title = "Dünün eksik vakitleri"
        content.body = "Dün \(names) işaretlenmedi. Kaza namazlarının ayrı vakti yoktur; sabahın sükunetinde planlayıp Prayer ekranındaki kaza merkezinden kaydedebilirsin."
        content.sound = UNNotificationSound.default
        content.userInfo = NotificationRoute.prayerDetail(.fajr).userInfo

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextMorningDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        try? await center.add(request)
    }

    private func missedPrayerNames(_ prayers: [PrayerName]) -> String {
        let names = prayers.map(\.qadaDisplayName)

        switch names.count {
        case 0:
            return ""
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) ve \(names[1])"
        default:
            let prefix = names.dropLast().joined(separator: ", ")
            return "\(prefix) ve \(names[names.count - 1])"
        }
    }
}
