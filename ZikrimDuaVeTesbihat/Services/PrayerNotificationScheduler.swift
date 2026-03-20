import Foundation
import UserNotifications
import CoreLocation

final class PrayerNotificationScheduler {
    private let prayerService: PrayerTimesServing
    private let settings: PrayerSettings
    private let notificationCenter: UNUserNotificationCenter
    private var permissionManager: NotificationPermissionManager?

    init(
        prayerService: PrayerTimesServing = RegionalPrayerTimesService(),
        settings: PrayerSettings = PrayerSettings(),
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.prayerService = prayerService
        self.settings = settings
        self.notificationCenter = notificationCenter
    }

    func clearOldPrayerNotifications() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let prayerIds = pending
            .map { $0.identifier }
            .filter { $0.contains("prayer_") }
        guard !prayerIds.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: prayerIds)
    }

    func scheduleNotificationsForToday(
        coordinates: CLLocationCoordinate2D,
        locationName: String?
    ) async {
        guard settings.prayerNotificationsEnabled else {
            await clearOldPrayerNotifications()
            return
        }

        let permissionManager = await getPermissionManager()
        let authorized = await permissionManager.requestAuthorizationIfNeeded()
        guard authorized else { return }

        let adminArea: String?
        let country: String?
        if settings.locationMode == .manual, let manual = settings.manualLocation {
            adminArea = manual.adminArea
            country = manual.country
        } else {
            adminArea = settings.lastAdministrativeArea
            country = settings.lastCountry
        }

        guard let times = await prayerService.prayerTimes(
            for: coordinates,
            date: Date(),
            settings: settings,
            locationName: locationName,
            administrativeArea: adminArea,
            country: country
        ) else {
            return
        }

        await clearOldPrayerNotifications()

        let now = Date()
        let calendar = Calendar.current
        let remindBefore = settings.remindBeforeMinutes

        for prayer in PrayerName.allCases {
            guard prayer != .sunrise else { continue }
            guard let prayerTime = times.allTimes[prayer] else { continue }

            let scheduleTime = remindBefore > 0
            ? calendar.date(byAdding: .minute, value: -remindBefore, to: prayerTime)
            : prayerTime

            guard let triggerDate = scheduleTime, triggerDate > now else { continue }

            let identifier = remindBefore > 0
            ? "\(prayer.notificationIdentifier)_before_\(remindBefore)"
            : prayer.notificationIdentifier

            let content = await notificationContent(for: prayer, remindBefore: remindBefore, scheduledDate: triggerDate)
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            do {
                try await notificationCenter.add(request)
            } catch {
                print("[PrayerNotificationScheduler] Failed to schedule \(identifier): \(error.localizedDescription)")
            }
        }
    }

    private func notificationContent(
        for prayer: PrayerName,
        remindBefore: Int,
        scheduledDate: Date
    ) async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let prayerName = prayer.localizedName
        let language = AppLanguage(code: RabiaAppLanguage.currentCode())
        let spiritualText = PrayerNotificationTextCatalog.rotatingVariant(
            for: prayer,
            language: language,
            date: scheduledDate
        )?.text

        if remindBefore > 0 {
            let titleFormat = L10n.string(.prayerNotificationApproachingTitleFormat)
            content.title = String.localizedStringWithFormat(titleFormat, prayerName)
            if let localizedBody = PrayerNotificationTextCatalog.localizedBody(
                prayerName: prayerName,
                language: language,
                offsetMinutes: remindBefore,
                spiritualText: spiritualText
            ) {
                content.body = localizedBody
            } else {
                let bodyFormat = L10n.string(.prayerNotificationApproachingBodyFormat)
                content.body = String.localizedStringWithFormat(bodyFormat, prayerName, remindBefore)
            }
        } else {
            let titleFormat = L10n.string(.prayerNotificationTimeTitleFormat)
            content.title = String.localizedStringWithFormat(titleFormat, prayerName)
            if let localizedBody = PrayerNotificationTextCatalog.localizedBody(
                prayerName: prayerName,
                language: language,
                offsetMinutes: nil,
                spiritualText: spiritualText
            ) {
                content.body = localizedBody
            } else {
                let bodyFormat = L10n.string(.prayerNotificationTimeBodyFormat)
                content.body = String.localizedStringWithFormat(bodyFormat, prayerName)
            }
        }

        content.userInfo = ["open_screen": "prayer", "prayer_name": prayer.rawValue]
        content.sound = await MainActor.run { NotificationService().notificationSound(isPrayer: true) }
        return content
    }

    private func getPermissionManager() async -> NotificationPermissionManager {
        if let existing = permissionManager {
            return existing
        }
        let created = await MainActor.run { NotificationPermissionManager() }
        permissionManager = created
        return created
    }
}
