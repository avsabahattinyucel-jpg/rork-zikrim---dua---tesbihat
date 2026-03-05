import Foundation
import UIKit
import UserNotifications

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
        case .dailyGentle: return "Günlük Hatırlatma"
        case .streakEncouragement: return "Seri Teşviki"
        case .personalizedDhikr: return "Kişisel Zikir Önerisi"
        case .prayerFollowup: return "Namaz Sonrası Öneri"
        case .completionCelebration: return "Tamamlama Tebriği"
        case .inactiveReturn: return "Geri Dönüş"
        case .eveningCalm: return "Akşam Sükuneti"
        case .weeklySummary: return "Haftalık Özet"
        }
    }

    var calmBody: String {
        switch self {
        case .dailyGentle: return "Bugün kalbinizi dinlendirecek kısa bir zikir için birkaç dakika ayırın."
        case .streakEncouragement: return "Güzel istikrarınızı koruyorsunuz. Bugünkü zikrinizle serinizi sürdürün."
        case .personalizedDhikr: return "Dün en çok okuduğunuz zikri bugün de devam ettirmek ister misiniz?"
        case .prayerFollowup: return "Namaz sonrası kısa bir tesbihat ile gününüze huzur katabilirsiniz."
        case .completionCelebration: return "Bugünkü hedefinizi tamamladınız. Allah kabul etsin."
        case .inactiveReturn: return "Sizi yeniden görmek güzel olur. Kısa bir zikirle tekrar başlayabilirsiniz."
        case .eveningCalm: return "Günü sakin bir dua ile kapatmak için uygun bir an."
        case .weeklySummary: return "Bu hafta gösterdiğiniz gayreti görmek için özetinize göz atın."
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
        case .atTime: return "Tam Vakitte"
        case .fifteenMin: return "15 Dakika Önce"
        case .thirtyMin: return "30 Dakika Önce"
        case .fortyFiveMin: return "45 Dakika Önce"
        }
    }

    var shortName: String {
        switch self {
        case .atTime: return "Tam"
        case .fifteenMin: return "15 dk"
        case .thirtyMin: return "30 dk"
        case .fortyFiveMin: return "45 dk"
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
        content.title = "Sabah Zikirleri"
        content.body = "Güne zikirle başlayın. Sabah zikirlerinizi okumayı unutmayın."
        content.sound = notificationSound()

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
        content.title = "Akşam Zikirleri"
        content.body = "Akşam zikirlerinizi okumayı unutmayın. Günü zikirle bitirin."
        content.sound = notificationSound()

        let components = Calendar.current.dateComponents([.hour, .minute], from: eveningTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func schedulePrayerNotification(prayerName: String, time: String, identifier: String) {
        guard isAuthorized else { return }
        guard prayerNotificationsEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let prayerDate = formatter.date(from: time) else { return }

        let offsetMinutes = prayerReminderOffset.rawValue
        let triggerDate = prayerDate.addingTimeInterval(TimeInterval(-offsetMinutes * 60))

        let content = UNMutableNotificationContent()
        if offsetMinutes > 0 {
            content.title = "\(prayerName) Vakti Yaklaşıyor"
            content.body = "\(prayerName) namazına \(offsetMinutes) dakika kaldı. Allah kabul etsin."
        } else {
            content.title = "\(prayerName) Vakti"
            content.body = "\(prayerName) namazı vakti girdi. Allah kabul etsin."
        }
        content.userInfo = ["open_screen": "prayer", "prayer_name": prayerName]

        content.sound = notificationSound()

        var triggerComponents = Calendar.current.dateComponents([.hour, .minute], from: triggerDate)
        triggerComponents.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
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
            content.title = "🤲 Günün Duası: \(entry.title)"
            content.body = "\(entry.transliteration) — \(entry.meaning)"
            content.sound = notificationSound()
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
        let ids = SmartNotificationType.allCases.map { "smart_\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

        guard smartNotificationsEnabled, isAuthorized else { return }

        let enabled = SmartNotificationType.allCases.filter { enabledSmartTypes.contains($0) }
        guard !enabled.isEmpty else { return }

        let picked = Array(enabled.prefix(maxSmartNotificationsPerDay))
        for (index, type) in picked.enumerated() {
            let targetHour = suggestedHour(for: index)
            var components = DateComponents()
            components.hour = targetHour
            components.minute = index == 0 ? 15 : 45

            let content = UNMutableNotificationContent()
            content.title = type.title
            content.body = type.calmBody
            content.sound = notificationSound()

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "smart_\(type.rawValue)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func rescheduleAll() {
        scheduleMorningReminder()
        scheduleEveningReminder()
        scheduleDailyDuaNotifications()
        if smartNotificationsEnabled {
            scheduleSmartNotifications()
        }
    }

    private func suggestedHour(for index: Int) -> Int {
        let base = index == 0 ? preferredActiveHour : preferredActiveHour + 3
        var hour = base % 24
        if isInQuietHours(hour) {
            hour = quietHoursEnd
        }
        if isInQuietHours(hour) {
            hour = 12
        }
        return hour
    }

    private func isInQuietHours(_ hour: Int) -> Bool {
        if quietHoursStart > quietHoursEnd {
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
        return hour >= quietHoursStart && hour < quietHoursEnd
    }

    func cancelPrayerNotifications() {
        let ids = ["prayer_fajr", "prayer_dhuhr", "prayer_asr", "prayer_maghrib", "prayer_isha"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        morningReminderEnabled = false
        eveningReminderEnabled = false
        smartNotificationsEnabled = false
        dailyDuaEnabled = false
    }

    private func notificationSound() -> UNNotificationSound? {
        guard !vibrationOnlyMode else { return nil }
        return UNNotificationSound(named: AdhanPlayerService.shared.notificationSoundName)
    }
}
