import Foundation
import UIKit
import UserNotifications

private nonisolated func L(_ key: L10n.Key) -> String {
    L10n.string(key)
}

nonisolated enum SmartNotificationType: String, CaseIterable, Codable, Sendable {
    case dailyGentle
    case streakEncouragement
    case personalizedDhikr
    case prayerFollowup
    case completionCelebration
    case inactiveReturn
    case eveningCalm
    case weeklySummary

    var title: String {
        switch self {
        case .dailyGentle: return L(.smartTypeDailyGentleTitle)
        case .streakEncouragement: return L(.smartTypeStreakEncouragementTitle)
        case .personalizedDhikr: return L(.smartTypePersonalizedDhikrTitle)
        case .prayerFollowup: return L(.smartTypePrayerFollowupTitle)
        case .completionCelebration: return L(.smartTypeCompletionCelebrationTitle)
        case .inactiveReturn: return L(.smartTypeInactiveReturnTitle)
        case .eveningCalm: return L(.smartTypeEveningCalmTitle)
        case .weeklySummary: return L(.smartTypeWeeklySummaryTitle)
        }
    }

    var calmBody: String {
        switch self {
        case .dailyGentle: return L(.smartBodyDailyGentlePrimary)
        case .streakEncouragement: return L(.smartBodyStreakEncouragementPrimary)
        case .personalizedDhikr: return L(.smartBodyPersonalizedDhikrPrimary)
        case .prayerFollowup: return L(.smartBodyPrayerFollowupPrimary)
        case .completionCelebration: return L(.smartBodyCompletionCelebrationPrimary)
        case .inactiveReturn: return L(.smartBodyInactiveReturnPrimary)
        case .eveningCalm: return L(.smartBodyEveningCalmPrimary)
        case .weeklySummary: return L(.smartBodyWeeklySummaryPrimary)
        }
    }

    var alternativeBodies: [String] {
        switch self {
        case .dailyGentle:
            return [
                L(.smartBodyDailyGentleAlt1),
                L(.smartBodyDailyGentleAlt2),
                L(.smartBodyDailyGentleAlt3)
            ]
        case .streakEncouragement:
            return [
                L(.smartBodyStreakEncouragementAlt1),
                L(.smartBodyStreakEncouragementAlt2),
                L(.smartBodyStreakEncouragementAlt3)
            ]
        case .personalizedDhikr:
            return [
                L(.smartBodyPersonalizedDhikrAlt1),
                L(.smartBodyPersonalizedDhikrAlt2),
                L(.smartBodyPersonalizedDhikrAlt3)
            ]
        case .prayerFollowup:
            return [
                L(.smartBodyPrayerFollowupAlt1),
                L(.smartBodyPrayerFollowupAlt2),
                L(.smartBodyPrayerFollowupAlt3)
            ]
        case .completionCelebration:
            return [
                L(.smartBodyCompletionCelebrationAlt1),
                L(.smartBodyCompletionCelebrationAlt2),
                L(.smartBodyCompletionCelebrationAlt3)
            ]
        case .inactiveReturn:
            return [
                L(.smartBodyInactiveReturnAlt1),
                L(.smartBodyInactiveReturnAlt2),
                L(.smartBodyInactiveReturnAlt3)
            ]
        case .eveningCalm:
            return [
                L(.smartBodyEveningCalmAlt1),
                L(.smartBodyEveningCalmAlt2),
                L(.smartBodyEveningCalmAlt3)
            ]
        case .weeklySummary:
            return [
                L(.smartBodyWeeklySummaryAlt1),
                L(.smartBodyWeeklySummaryAlt2),
                L(.smartBodyWeeklySummaryAlt3)
            ]
        }
    }
}

nonisolated enum PrayerReminderOffset: Int, CaseIterable, Sendable {
    case atTime = 0
    case fifteenMin = 15
    case thirtyMin = 30
    case fortyFiveMin = 45

    var displayName: String {
        switch self {
        case .atTime: return L10n.string(.prayerOffsetAtTime)
        case .fifteenMin: return L10n.string(.prayerOffsetFifteenMin)
        case .thirtyMin: return L10n.string(.prayerOffsetThirtyMin)
        case .fortyFiveMin: return L10n.string(.prayerOffsetFortyFiveMin)
        }
    }

    var shortName: String {
        switch self {
        case .atTime: return L10n.string(.prayerOffsetShortAtTime)
        case .fifteenMin: return L10n.string(.prayerOffsetShortFifteenMin)
        case .thirtyMin: return L10n.string(.prayerOffsetShortThirtyMin)
        case .fortyFiveMin: return L10n.string(.prayerOffsetShortFortyFiveMin)
        }
    }
}

@Observable
@MainActor
class NotificationService {
    var isAuthorized: Bool = false

    var morningReminderEnabled: Bool {
        get {
            access(keyPath: \.morningReminderEnabled)
            return UserDefaults.standard.bool(forKey: "morning_reminder_enabled")
        }
        set {
            withMutation(keyPath: \.morningReminderEnabled) {
                UserDefaults.standard.set(newValue, forKey: "morning_reminder_enabled")
            }
        }
    }

    var eveningReminderEnabled: Bool {
        get {
            access(keyPath: \.eveningReminderEnabled)
            return UserDefaults.standard.bool(forKey: "evening_reminder_enabled")
        }
        set {
            withMutation(keyPath: \.eveningReminderEnabled) {
                UserDefaults.standard.set(newValue, forKey: "evening_reminder_enabled")
            }
        }
    }

    var prayerNotificationsEnabled: Bool {
        get {
            access(keyPath: \.prayerNotificationsEnabled)
            return UserDefaults.standard.bool(forKey: "prayer_notifications_enabled")
        }
        set {
            withMutation(keyPath: \.prayerNotificationsEnabled) {
                UserDefaults.standard.set(newValue, forKey: "prayer_notifications_enabled")
            }
        }
    }

    var prayerReminderOffset: PrayerReminderOffset {
        get {
            access(keyPath: \.prayerReminderOffset)
            let raw = UserDefaults.standard.integer(forKey: "prayer_reminder_offset")
            return PrayerReminderOffset(rawValue: raw) ?? .atTime
        }
        set {
            withMutation(keyPath: \.prayerReminderOffset) {
                UserDefaults.standard.set(newValue.rawValue, forKey: "prayer_reminder_offset")
            }
        }
    }

    var dailyDuaEnabled: Bool {
        get {
            access(keyPath: \.dailyDuaEnabled)
            return UserDefaults.standard.bool(forKey: "daily_dua_enabled")
        }
        set {
            withMutation(keyPath: \.dailyDuaEnabled) {
                UserDefaults.standard.set(newValue, forKey: "daily_dua_enabled")
            }
        }
    }

    var dailyDuaTime: Date {
        get {
            access(keyPath: \.dailyDuaTime)
            if let date = UserDefaults.standard.object(forKey: "daily_dua_time") as? Date {
                return date
            }
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            withMutation(keyPath: \.dailyDuaTime) {
                UserDefaults.standard.set(newValue, forKey: "daily_dua_time")
            }
        }
    }


    var vibrationOnlyMode: Bool {
        get {
            access(keyPath: \.vibrationOnlyMode)
            return UserDefaults.standard.bool(forKey: "notification_vibration_only")
        }
        set {
            withMutation(keyPath: \.vibrationOnlyMode) {
                UserDefaults.standard.set(newValue, forKey: "notification_vibration_only")
            }
        }
    }

    var playEvenInSilentMode: Bool {
        get {
            access(keyPath: \.playEvenInSilentMode)
            return UserDefaults.standard.bool(forKey: "notification_play_in_silent")
        }
        set {
            withMutation(keyPath: \.playEvenInSilentMode) {
                UserDefaults.standard.set(newValue, forKey: "notification_play_in_silent")
            }
        }
    }

    var smartNotificationsEnabled: Bool {
        get {
            access(keyPath: \.smartNotificationsEnabled)
            return UserDefaults.standard.bool(forKey: "smart_notifications_enabled")
        }
        set {
            withMutation(keyPath: \.smartNotificationsEnabled) {
                UserDefaults.standard.set(newValue, forKey: "smart_notifications_enabled")
            }
        }
    }

    var maxSmartNotificationsPerDay: Int { 2 }

    var quietHoursStart: Int {
        get {
            access(keyPath: \.quietHoursStart)
            let value = UserDefaults.standard.integer(forKey: "quiet_hours_start")
            return value == 0 ? 22 : value
        }
        set {
            withMutation(keyPath: \.quietHoursStart) {
                UserDefaults.standard.set(newValue, forKey: "quiet_hours_start")
            }
        }
    }

    var quietHoursEnd: Int {
        get {
            access(keyPath: \.quietHoursEnd)
            let value = UserDefaults.standard.integer(forKey: "quiet_hours_end")
            return value == 0 ? 8 : value
        }
        set {
            withMutation(keyPath: \.quietHoursEnd) {
                UserDefaults.standard.set(newValue, forKey: "quiet_hours_end")
            }
        }
    }

    var preferredActiveHour: Int {
        get {
            access(keyPath: \.preferredActiveHour)
            let value = UserDefaults.standard.integer(forKey: "preferred_active_hour")
            return value == 0 ? 20 : value
        }
        set {
            withMutation(keyPath: \.preferredActiveHour) {
                UserDefaults.standard.set(newValue, forKey: "preferred_active_hour")
            }
        }
    }

    var enabledSmartTypes: Set<SmartNotificationType> {
        get {
            access(keyPath: \.enabledSmartTypes)
            let raw = UserDefaults.standard.array(forKey: "enabled_smart_types") as? [String] ?? SmartNotificationType.allCases.map(\.rawValue)
            return Set(raw.compactMap { SmartNotificationType(rawValue: $0) })
        }
        set {
            withMutation(keyPath: \.enabledSmartTypes) {
                UserDefaults.standard.set(newValue.map(\.rawValue), forKey: "enabled_smart_types")
            }
        }
    }

    var morningTime: Date {
        get {
            access(keyPath: \.morningTime)
            if let date = UserDefaults.standard.object(forKey: "morning_reminder_time") as? Date {
                return date
            }
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            withMutation(keyPath: \.morningTime) {
                UserDefaults.standard.set(newValue, forKey: "morning_reminder_time")
            }
        }
    }

    var eveningTime: Date {
        get {
            access(keyPath: \.eveningTime)
            if let date = UserDefaults.standard.object(forKey: "evening_reminder_time") as? Date {
                return date
            }
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            withMutation(keyPath: \.eveningTime) {
                UserDefaults.standard.set(newValue, forKey: "evening_reminder_time")
            }
        }
    }

    init() {
        Task {
            await checkAuthorization()
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
                rescheduleAll()
            }
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func markUserActivityNow() {
        let hour = Calendar.current.component(.hour, from: Date())
        preferredActiveHour = hour
    }

    func toggleSmartType(_ type: SmartNotificationType) {
        var current = enabledSmartTypes
        if current.contains(type) {
            current.remove(type)
        } else {
            current.insert(type)
        }
        enabledSmartTypes = current
    }

    func scheduleMorningReminder() {
        guard isAuthorized else { return }
        guard morningReminderEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morning_reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = L10n.string(.morningReminderTitle)
        content.body = L10n.string(.morningReminderBody)
        content.sound = notificationSound(isPrayer: false)

        let components = Calendar.current.dateComponents([.hour, .minute], from: morningTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleEveningReminder() {
        guard isAuthorized else { return }
        guard eveningReminderEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["evening_reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = L10n.string(.eveningReminderTitle)
        content.body = L10n.string(.eveningReminderBody)
        content.sound = notificationSound(isPrayer: false)

        let components = Calendar.current.dateComponents([.hour, .minute], from: eveningTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailyDuaNotifications() {
        let existingIds = (0..<14).map { "daily_dua_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: existingIds)

        guard isAuthorized, dailyDuaEnabled else { return }

        let entries = ZikirRehberiData.entries
        guard !entries.isEmpty else { return }

        let duaComponents = Calendar.current.dateComponents([.hour, .minute], from: dailyDuaTime)
        let hour = duaComponents.hour ?? 9
        let minute = duaComponents.minute ?? 0

        for dayOffset in 0..<14 {
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            let entry = entries[dayOffset % entries.count]

            let content = UNMutableNotificationContent()
            let titleFormat = L10n.string(.dailyDuaNotificationTitleFormat)
            content.title = String.localizedStringWithFormat(titleFormat, entry.title)
            content.body = "\(entry.transliteration) — \(entry.meaning)"
            content.sound = notificationSound(isPrayer: false)
            content.userInfo = ["open_screen": "rehber", "entry_id": entry.id]

            var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
            components.hour = hour
            components.minute = minute
            components.second = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "daily_dua_\(dayOffset)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func scheduleSmartNotifications() {
        let ids = (0..<5).map { "smart_day_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

        guard smartNotificationsEnabled, isAuthorized else { return }

        let enabled = SmartNotificationType.allCases.filter { enabledSmartTypes.contains($0) }
        guard !enabled.isEmpty else { return }

        let planDates = smartPlanDates(limit: 5)
        for (index, date) in planDates.enumerated() {
            let type = enabled[index % enabled.count]
            let content = UNMutableNotificationContent()
            let bodyOptions = [type.calmBody] + type.alternativeBodies
            let body = bodyOptions[index % bodyOptions.count]

            content.title = smartTitle(for: type, on: date)
            content.body = body
            content.sound = notificationSound(isPrayer: false)
            content.userInfo = ["open_screen": smartDestination(for: type), "smart_type": type.rawValue]

            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "smart_day_\(index)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func smartPlanDates(limit: Int) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var dates: [Date] = []

        for dayOffset in 0..<(limit + 2) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let date = smartNotificationDate(for: day, index: dates.count)
            if date > now.addingTimeInterval(60 * 20) {
                dates.append(date)
            }
            if dates.count == limit { break }
        }

        return dates
    }

    private func smartNotificationDate(for day: Date, index: Int) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: day)
        let baseHour = suggestedHour(for: index, weekday: weekday)
        let minutePattern = [12, 28, 42, 18, 35]
        let minute = minutePattern[index % minutePattern.count]

        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = normalizedHourAvoidingQuiet(baseHour)
        components.minute = minute
        components.second = 0

        return calendar.date(from: components) ?? day
    }

    private func suggestedHour(for index: Int, weekday: Int) -> Int {
        let weekend = weekday == 1 || weekday == 7
        let offsets = weekend ? [1, 4, -2, 3, 0] : [0, 3, -1, 4, 2]
        return preferredActiveHour + offsets[index % offsets.count]
    }

    private func normalizedHourAvoidingQuiet(_ rawHour: Int) -> Int {
        var hour = ((rawHour % 24) + 24) % 24
        if isInQuietHours(hour) {
            hour = quietHoursEnd + 1
        }
        if isInQuietHours(hour) {
            hour = 12
        }
        return min(max(hour, 8), 21)
    }

    private func smartTitle(for type: SmartNotificationType, on date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch type {
        case .dailyGentle:
            return weekday == 6 ? L(.smartTitleFridayShortDhikr) : L(.smartTitleShortSpiritualBreak)
        case .streakEncouragement:
            return L(.smartTitleKeepConsistency)
        case .personalizedDhikr:
            return L(.smartTitlePersonalDhikrMoment)
        case .prayerFollowup:
            return L(.smartTitlePostPrayerReminder)
        case .completionCelebration:
            return L(.smartTitleTodayGratitude)
        case .inactiveReturn:
            return L(.smartTitleContinueProgress)
        case .eveningCalm:
            return L(.smartTitleCalmEvening)
        case .weeklySummary:
            return L(.smartTitleWeeklyGlance)
        }
    }

    private func smartDestination(for type: SmartNotificationType) -> String {
        switch type {
        case .personalizedDhikr, .completionCelebration:
            return "counter"
        case .prayerFollowup:
            return "prayer"
        case .weeklySummary:
            return "daily"
        default:
            return "rehber"
        }
    }

    func recordCompletionCelebrationNotification() {
        guard smartNotificationsEnabled, isAuthorized, enabledSmartTypes.contains(.completionCelebration) else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.string(.completionNotificationTitle)
        content.body = L10n.string(.completionNotificationBody)
        content.sound = notificationSound(isPrayer: false)
        content.userInfo = ["open_screen": "counter", "smart_type": SmartNotificationType.completionCelebration.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 90, repeats: false)
        let request = UNNotificationRequest(identifier: "smart_completion_celebration", content: content, trigger: trigger)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["smart_completion_celebration"])
        UNUserNotificationCenter.current().add(request)
    }

    func rescheduleAll() {
        scheduleMorningReminder()
        scheduleEveningReminder()
        scheduleDailyDuaNotifications()
        if smartNotificationsEnabled {
            scheduleSmartNotifications()
        }
    }

    private func isInQuietHours(_ hour: Int) -> Bool {
        if quietHoursStart > quietHoursEnd {
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
        return hour >= quietHoursStart && hour < quietHoursEnd
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        morningReminderEnabled = false
        eveningReminderEnabled = false
        smartNotificationsEnabled = false
        dailyDuaEnabled = false
    }

    func notificationSound(isPrayer: Bool = false) -> UNNotificationSound? {
        guard !vibrationOnlyMode else { return nil }
        if isPrayer {
            return NotificationSoundCatalog.sound(for: .default, isPrayer: true)
        }
        return NotificationSoundCatalog.sound(for: .init(preset: .nur, customSoundName: nil), isPrayer: false)
    }
}
