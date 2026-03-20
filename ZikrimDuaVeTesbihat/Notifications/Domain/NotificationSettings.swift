import Foundation

extension Notification.Name {
    static let notificationSettingsDidChange = Notification.Name("notificationSettingsDidChange")
    static let notificationRebuildRequested = Notification.Name("notificationRebuildRequested")
}

enum PrayerReminderTimingMode: String, CaseIterable, Codable, Sendable {
    case atTime
    case fifteenMinutesBefore
    case thirtyMinutesBefore
    case bothBeforeAndAtTime

    var offsetsInMinutes: [Int] {
        switch self {
        case .atTime:
            return [0]
        case .fifteenMinutesBefore:
            return [15]
        case .thirtyMinutesBefore:
            return [30]
        case .bothBeforeAndAtTime:
            return [15, 0]
        }
    }
}

enum SmartReminderIntensity: String, CaseIterable, Codable, Sendable {
    case light
    case balanced
    case frequent

    var dailyCap: Int {
        switch self {
        case .light:
            return 1
        case .balanced:
            return 2
        case .frequent:
            return 3
        }
    }
}

enum NotificationSoundPreset: String, CaseIterable, Codable, Sendable {
    case system
    case nur
    case safa
    case merve
    case huzur
    case adhan
    case gentle
    case custom

    var normalizedForCurrentCatalog: NotificationSoundPreset {
        switch self {
        case .system, .nur, .safa, .merve, .huzur:
            return self
        case .adhan, .gentle, .custom:
            return .nur
        }
    }
}

struct NotificationSoundSelection: Codable, Equatable, Sendable {
    var preset: NotificationSoundPreset
    var customSoundName: String?

    static let `default` = NotificationSoundSelection(preset: .system, customSoundName: nil)
}

struct ClockTime: Codable, Hashable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        self.hour = max(0, min(hour, 23))
        self.minute = max(0, min(minute, 59))
    }

    var minutesSinceMidnight: Int {
        hour * 60 + minute
    }

    func dateComponents(calendar: Calendar = .autoupdatingCurrent) -> DateComponents {
        var components = calendar.dateComponents([.calendar, .timeZone], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return components
    }

    func displayString(locale: Locale = .autoupdatingCurrent) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: calendar.date(from: dateComponents(calendar: calendar)) ?? Date())
    }
}

struct QuietHoursConfiguration: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var start: ClockTime
    var end: ClockTime

    static let `default` = QuietHoursConfiguration(
        isEnabled: true,
        start: ClockTime(hour: 23, minute: 30),
        end: ClockTime(hour: 7, minute: 30)
    )
}

struct PrayerNotificationPreferences: Codable, Equatable, Sendable {
    var fajr: Bool
    var dhuhr: Bool
    var asr: Bool
    var maghrib: Bool
    var isha: Bool

    static let `default` = PrayerNotificationPreferences(
        fajr: true,
        dhuhr: true,
        asr: true,
        maghrib: true,
        isha: true
    )

    subscript(prayer: PrayerName) -> Bool {
        get {
            switch prayer {
            case .fajr:
                return fajr
            case .sunrise:
                return false
            case .dhuhr:
                return dhuhr
            case .asr:
                return asr
            case .maghrib:
                return maghrib
            case .isha:
                return isha
            }
        }
        set {
            switch prayer {
            case .fajr:
                fajr = newValue
            case .sunrise:
                break
            case .dhuhr:
                dhuhr = newValue
            case .asr:
                asr = newValue
            case .maghrib:
                maghrib = newValue
            case .isha:
                isha = newValue
            }
        }
    }

    var enabledPrayers: [PrayerName] {
        PrayerName.allCases.filter { $0 != .sunrise && self[$0] }
    }
}

struct NotificationLocationSnapshot: Codable, Equatable, Sendable {
    var identifier: String?
    var cityName: String?
    var administrativeArea: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?
    var timezoneIdentifier: String?
}

struct NotificationSettings: Codable, Equatable, Sendable {
    var prayerNotificationsEnabled: Bool
    var prayerPreferences: PrayerNotificationPreferences
    var reminderTimingMode: PrayerReminderTimingMode
    var dailyDuaEnabled: Bool
    var dailyDuaTime: ClockTime
    var morningReminderEnabled: Bool
    var morningReminderTime: ClockTime
    var eveningReminderEnabled: Bool
    var eveningReminderTime: ClockTime
    var sleepReminderEnabled: Bool
    var sleepReminderTime: ClockTime
    var smartRemindersEnabled: Bool
    var smartReminderIntensity: SmartReminderIntensity
    var fridayReminderEnabled: Bool
    var fridayReminderTime: ClockTime
    var specialIslamicDaysEnabled: Bool
    var specialIslamicDayReminderTime: ClockTime
    var vibrationOnly: Bool
    var soundSelection: NotificationSoundSelection
    var quietHours: QuietHoursConfiguration
    var currentLanguageCode: String
    var currentTimezoneIdentifier: String
    var currentLocation: NotificationLocationSnapshot
    var premiumEnabled: Bool
    var lastRebuiltAt: Date?
    var lastActiveDayStamp: String?

    static let `default` = NotificationSettings(
        prayerNotificationsEnabled: true,
        prayerPreferences: .default,
        reminderTimingMode: .fifteenMinutesBefore,
        dailyDuaEnabled: true,
        dailyDuaTime: ClockTime(hour: 8, minute: 40),
        morningReminderEnabled: true,
        morningReminderTime: ClockTime(hour: 7, minute: 15),
        eveningReminderEnabled: true,
        eveningReminderTime: ClockTime(hour: 20, minute: 30),
        sleepReminderEnabled: false,
        sleepReminderTime: ClockTime(hour: 22, minute: 15),
        smartRemindersEnabled: false,
        smartReminderIntensity: .balanced,
        fridayReminderEnabled: false,
        fridayReminderTime: ClockTime(hour: 11, minute: 40),
        specialIslamicDaysEnabled: false,
        specialIslamicDayReminderTime: ClockTime(hour: 19, minute: 30),
        vibrationOnly: false,
        soundSelection: .default,
        quietHours: .default,
        currentLanguageCode: RabiaAppLanguage.currentCode(),
        currentTimezoneIdentifier: TimeZone.autoupdatingCurrent.identifier,
        currentLocation: NotificationLocationSnapshot(
            identifier: nil,
            cityName: nil,
            administrativeArea: nil,
            country: nil,
            latitude: nil,
            longitude: nil,
            timezoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        ),
        premiumEnabled: false,
        lastRebuiltAt: nil,
        lastActiveDayStamp: nil
    )

    var effectiveLanguage: AppLanguage {
        AppLanguage(code: currentLanguageCode)
    }

    func withRuntimeContext(
        languageCode: String,
        timezoneIdentifier: String,
        location: NotificationLocationSnapshot? = nil,
        premiumEnabled: Bool
    ) -> NotificationSettings {
        var copy = self
        copy.currentLanguageCode = RabiaAppLanguage.normalizedCode(for: languageCode)
        copy.currentTimezoneIdentifier = timezoneIdentifier
        if let location {
            copy.currentLocation = location
        } else {
            copy.currentLocation.timezoneIdentifier = timezoneIdentifier
        }
        copy.premiumEnabled = premiumEnabled
        copy.clampPremiumFeatures()
        return copy
    }

    mutating func clampPremiumFeatures() {
        guard !premiumEnabled else { return }
        sleepReminderEnabled = false
        smartRemindersEnabled = false
        fridayReminderEnabled = false
        specialIslamicDaysEnabled = false
    }
}
