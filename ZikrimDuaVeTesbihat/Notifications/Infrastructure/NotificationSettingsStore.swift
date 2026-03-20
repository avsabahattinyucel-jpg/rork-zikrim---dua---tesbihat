import Foundation
import Observation

@Observable
@MainActor
final class NotificationSettingsStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "zikrim.notification.settings.v2"

    private(set) var settings: NotificationSettings

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: storageKey),
           let decoded = try? decoder.decode(NotificationSettings.self, from: data) {
            self.settings = Self.normalize(decoded)
            if self.settings != decoded {
                persist()
            }
        } else {
            self.settings = Self.migrateLegacySettings(from: defaults) ?? .default
            persist()
        }
    }

    func reload() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode(NotificationSettings.self, from: data) else {
            settings = Self.migrateLegacySettings(from: defaults) ?? .default
            persist()
            return
        }
        let normalized = Self.normalize(decoded)
        settings = normalized
        if normalized != decoded {
            persist()
        }
    }

    func save(_ newSettings: NotificationSettings) {
        settings = newSettings
        persist()
    }

    func update(_ mutation: (inout NotificationSettings) -> Void) {
        var updated = settings
        mutation(&updated)
        save(updated)
    }

    @discardableResult
    func synchronizeRuntimeContext(
        languageCode: String,
        timezoneIdentifier: String,
        location: NotificationLocationSnapshot? = nil,
        premiumEnabled: Bool
    ) -> Bool {
        let updated = settings.withRuntimeContext(
            languageCode: languageCode,
            timezoneIdentifier: timezoneIdentifier,
            location: location,
            premiumEnabled: premiumEnabled
        )
        guard updated != settings else { return false }
        save(updated)
        return true
    }

    private func persist() {
        if let encoded = try? encoder.encode(settings) {
            defaults.set(encoded, forKey: storageKey)
        }
        NotificationCenter.default.post(name: .notificationSettingsDidChange, object: settings)
    }

    private static func normalize(_ settings: NotificationSettings) -> NotificationSettings {
        var normalized = settings
        normalized.soundSelection.preset = normalized.soundSelection.preset.normalizedForCurrentCatalog
        if normalized.soundSelection.preset != .custom {
            normalized.soundSelection.customSoundName = nil
        }
        normalized.clampPremiumFeatures()
        return normalized
    }

    private static func legacyClockTime(forKey key: String, in defaults: UserDefaults) -> ClockTime? {
        guard let date = defaults.object(forKey: key) as? Date else {
            return nil
        }

        let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: date)
        return ClockTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    private static func migrateLegacySettings(from defaults: UserDefaults) -> NotificationSettings? {
        var migrated = NotificationSettings.default
        var didMigrate = false

        if defaults.object(forKey: "prayer_notifications_enabled") != nil {
            migrated.prayerNotificationsEnabled = defaults.bool(forKey: "prayer_notifications_enabled")
            didMigrate = true
        }

        if defaults.object(forKey: "prayer_reminder_offset") != nil {
            let offset = defaults.integer(forKey: "prayer_reminder_offset")
            switch offset {
            case 30...:
                migrated.reminderTimingMode = .thirtyMinutesBefore
            case 15:
                migrated.reminderTimingMode = .fifteenMinutesBefore
            default:
                migrated.reminderTimingMode = .atTime
            }
            didMigrate = true
        }

        if defaults.object(forKey: "daily_dua_enabled") != nil {
            migrated.dailyDuaEnabled = defaults.bool(forKey: "daily_dua_enabled")
            didMigrate = true
        }

        if let dailyDuaTime = legacyClockTime(forKey: "daily_dua_time", in: defaults) {
            migrated.dailyDuaTime = dailyDuaTime
            didMigrate = true
        }

        if defaults.object(forKey: "morning_reminder_enabled") != nil {
            migrated.morningReminderEnabled = defaults.bool(forKey: "morning_reminder_enabled")
            didMigrate = true
        }

        if let morningTime = legacyClockTime(forKey: "morning_reminder_time", in: defaults) {
            migrated.morningReminderTime = morningTime
            didMigrate = true
        }

        if defaults.object(forKey: "evening_reminder_enabled") != nil {
            migrated.eveningReminderEnabled = defaults.bool(forKey: "evening_reminder_enabled")
            didMigrate = true
        }

        if let eveningTime = legacyClockTime(forKey: "evening_reminder_time", in: defaults) {
            migrated.eveningReminderTime = eveningTime
            didMigrate = true
        }

        if defaults.object(forKey: "smart_notifications_enabled") != nil {
            migrated.smartRemindersEnabled = defaults.bool(forKey: "smart_notifications_enabled")
            didMigrate = true
        }

        if defaults.object(forKey: "notification_vibration_only") != nil {
            migrated.vibrationOnly = defaults.bool(forKey: "notification_vibration_only")
            didMigrate = true
        }

        let hasQuietHoursStart = defaults.object(forKey: "quiet_hours_start") != nil
        let hasQuietHoursEnd = defaults.object(forKey: "quiet_hours_end") != nil
        if hasQuietHoursStart || hasQuietHoursEnd {
            let startHour = hasQuietHoursStart ? defaults.integer(forKey: "quiet_hours_start") : migrated.quietHours.start.hour
            let endHour = hasQuietHoursEnd ? defaults.integer(forKey: "quiet_hours_end") : migrated.quietHours.end.hour
            migrated.quietHours = QuietHoursConfiguration(
                isEnabled: true,
                start: ClockTime(hour: startHour, minute: 0),
                end: ClockTime(hour: endHour, minute: 0)
            )
            didMigrate = true
        }

        return didMigrate ? normalize(migrated) : nil
    }
}
