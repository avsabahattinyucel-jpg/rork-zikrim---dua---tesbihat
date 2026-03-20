import Foundation
import CoreLocation
import Adhan

extension Notification.Name {
    static let prayerSettingsChanged = Notification.Name("prayerSettingsChanged")
}

@Observable
final class PrayerSettings {
    private let calculationMethodKey = "prayer_calculation_method"
    private let madhabKey = "prayer_madhab"
    private let prayerNotificationsEnabledKey = "prayer_notifications_enabled"
    private let prayerReminderOffsetKey = "prayer_reminder_offset"
    private let lastLatitudeKey = "prayer_last_latitude"
    private let lastLongitudeKey = "prayer_last_longitude"
    private let lastLocationNameKey = "prayer_last_location_name"
    private let lastAdminAreaKey = "prayer_last_admin_area"
    private let lastCountryKey = "prayer_last_country"
    private let locationModeKey = "prayer_location_mode"
    private let manualCityNameKey = "prayer_manual_city_name"
    private let manualLatitudeKey = "prayer_manual_latitude"
    private let manualLongitudeKey = "prayer_manual_longitude"
    private let manualAdminKey = "prayer_manual_admin"
    private let manualCountryKey = "prayer_manual_country"
    private let recentLocationsKey = "prayer_recent_locations"

    var calculationMethod: PrayerCalculationMethod {
        get {
            access(keyPath: \.calculationMethod)
            if let raw = UserDefaults.standard.string(forKey: calculationMethodKey),
               let method = PrayerCalculationMethod(rawValue: raw) {
                return method
            }
            return .muslimWorldLeague
        }
        set {
            withMutation(keyPath: \.calculationMethod) {
                UserDefaults.standard.set(newValue.rawValue, forKey: calculationMethodKey)
            }
            NotificationCenter.default.post(name: .prayerSettingsChanged, object: nil)
        }
    }

    var madhab: PrayerMadhab {
        get {
            access(keyPath: \.madhab)
            if let raw = UserDefaults.standard.string(forKey: madhabKey),
               let value = PrayerMadhab(rawValue: raw) {
                return value
            }
            return .shafi
        }
        set {
            withMutation(keyPath: \.madhab) {
                UserDefaults.standard.set(newValue.rawValue, forKey: madhabKey)
            }
            NotificationCenter.default.post(name: .prayerSettingsChanged, object: nil)
        }
    }

    var prayerNotificationsEnabled: Bool {
        get {
            access(keyPath: \.prayerNotificationsEnabled)
            return UserDefaults.standard.bool(forKey: prayerNotificationsEnabledKey)
        }
        set {
            withMutation(keyPath: \.prayerNotificationsEnabled) {
                UserDefaults.standard.set(newValue, forKey: prayerNotificationsEnabledKey)
            }
            NotificationCenter.default.post(name: .prayerSettingsChanged, object: nil)
        }
    }

    var reminderOffset: PrayerReminderOffset {
        get {
            access(keyPath: \.reminderOffset)
            let raw = UserDefaults.standard.integer(forKey: prayerReminderOffsetKey)
            return PrayerReminderOffset(rawValue: raw) ?? .atTime
        }
        set {
            withMutation(keyPath: \.reminderOffset) {
                UserDefaults.standard.set(newValue.rawValue, forKey: prayerReminderOffsetKey)
            }
            NotificationCenter.default.post(name: .prayerSettingsChanged, object: nil)
        }
    }

    var remindBeforeMinutes: Int {
        reminderOffset.rawValue
    }

    var locationMode: PrayerLocationMode {
        get {
            access(keyPath: \.locationMode)
            if let raw = UserDefaults.standard.string(forKey: locationModeKey),
               let mode = PrayerLocationMode(rawValue: raw) {
                return mode
            }
            return .automatic
        }
        set {
            withMutation(keyPath: \.locationMode) {
                UserDefaults.standard.set(newValue.rawValue, forKey: locationModeKey)
            }
            NotificationCenter.default.post(name: .prayerSettingsChanged, object: nil)
        }
    }

    var manualLocation: ManualPrayerLocation? {
        get {
            access(keyPath: \.manualLocation)
            guard let name = UserDefaults.standard.string(forKey: manualCityNameKey) else { return nil }
            guard let lat = UserDefaults.standard.object(forKey: manualLatitudeKey) as? Double,
                  let lon = UserDefaults.standard.object(forKey: manualLongitudeKey) as? Double else { return nil }
            let admin = UserDefaults.standard.string(forKey: manualAdminKey)
            let country = UserDefaults.standard.string(forKey: manualCountryKey)
            return ManualPrayerLocation(name: name, latitude: lat, longitude: lon, adminArea: admin, country: country)
        }
        set {
            withMutation(keyPath: \.manualLocation) {
                if let value = newValue {
                    UserDefaults.standard.set(value.name, forKey: manualCityNameKey)
                    UserDefaults.standard.set(value.latitude, forKey: manualLatitudeKey)
                    UserDefaults.standard.set(value.longitude, forKey: manualLongitudeKey)
                    UserDefaults.standard.set(value.adminArea, forKey: manualAdminKey)
                    UserDefaults.standard.set(value.country, forKey: manualCountryKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: manualCityNameKey)
                    UserDefaults.standard.removeObject(forKey: manualLatitudeKey)
                    UserDefaults.standard.removeObject(forKey: manualLongitudeKey)
                    UserDefaults.standard.removeObject(forKey: manualAdminKey)
                    UserDefaults.standard.removeObject(forKey: manualCountryKey)
                }
            }
            NotificationCenter.default.post(name: .prayerSettingsChanged, object: nil)
        }
    }

    var lastKnownCoordinate: CLLocationCoordinate2D? {
        get {
            access(keyPath: \.lastKnownCoordinate)
            let lat = UserDefaults.standard.object(forKey: lastLatitudeKey) as? Double
            let lon = UserDefaults.standard.object(forKey: lastLongitudeKey) as? Double
            guard let latitude = lat, let longitude = lon else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            withMutation(keyPath: \.lastKnownCoordinate) {
                if let value = newValue {
                    UserDefaults.standard.set(value.latitude, forKey: lastLatitudeKey)
                    UserDefaults.standard.set(value.longitude, forKey: lastLongitudeKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: lastLatitudeKey)
                    UserDefaults.standard.removeObject(forKey: lastLongitudeKey)
                }
            }
        }
    }

    var lastLocationName: String? {
        get {
            access(keyPath: \.lastLocationName)
            return UserDefaults.standard.string(forKey: lastLocationNameKey)
        }
        set {
            withMutation(keyPath: \.lastLocationName) {
                UserDefaults.standard.set(newValue, forKey: lastLocationNameKey)
            }
        }
    }

    var lastAdministrativeArea: String? {
        get {
            access(keyPath: \.lastAdministrativeArea)
            return UserDefaults.standard.string(forKey: lastAdminAreaKey)
        }
        set {
            withMutation(keyPath: \.lastAdministrativeArea) {
                UserDefaults.standard.set(newValue, forKey: lastAdminAreaKey)
            }
        }
    }

    var lastCountry: String? {
        get {
            access(keyPath: \.lastCountry)
            return UserDefaults.standard.string(forKey: lastCountryKey)
        }
        set {
            withMutation(keyPath: \.lastCountry) {
                UserDefaults.standard.set(newValue, forKey: lastCountryKey)
            }
        }
    }

    var recentLocations: [PrayerLocation] {
        get {
            access(keyPath: \.recentLocations)
            guard let data = UserDefaults.standard.data(forKey: recentLocationsKey),
                  let decoded = try? JSONDecoder().decode([PrayerLocation].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            withMutation(keyPath: \.recentLocations) {
                if let data = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(data, forKey: recentLocationsKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: recentLocationsKey)
                }
            }
        }
    }
}

enum LocationSource: String, Codable, Sendable {
    case automatic
    case manual
}

struct PrayerLocation: Codable, Sendable, Hashable {
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let source: LocationSource

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum PrayerLocationMode: String, CaseIterable, Sendable {
    case automatic
    case manual
}

struct ManualPrayerLocation: Sendable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    let adminArea: String?
    let country: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var subtitle: String? {
        let parts = [adminArea, country].compactMap { $0 }.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    var asPrayerLocation: PrayerLocation {
        PrayerLocation(
            city: name,
            country: country ?? "",
            latitude: latitude,
            longitude: longitude,
            source: .manual
        )
    }
}

enum PrayerCalculationMethod: String, CaseIterable, Sendable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case ummAlQura
    case dubai
    case qatar
    case kuwait
    case moonsightingCommittee
    case northAmerica
    case other

    var adhanMethod: CalculationMethod {
        switch self {
        case .muslimWorldLeague: return .muslimWorldLeague
        case .egyptian: return .egyptian
        case .karachi: return .karachi
        case .ummAlQura: return .ummAlQura
        case .dubai: return .dubai
        case .qatar: return .qatar
        case .kuwait: return .kuwait
        case .moonsightingCommittee: return .moonsightingCommittee
        case .northAmerica: return .northAmerica
        case .other: return .other
        }
    }
}

enum PrayerMadhab: String, CaseIterable, Sendable {
    case shafi
    case hanafi

    var adhanMadhab: Madhab {
        switch self {
        case .shafi: return .shafi
        case .hanafi: return .hanafi
        }
    }
}

extension PrayerCalculationMethod {
    var aladhanMethodID: Int {
        switch self {
        case .muslimWorldLeague:
            return 3
        case .egyptian:
            return 5
        case .karachi:
            return 1
        case .ummAlQura:
            return 4
        case .dubai:
            return 16
        case .qatar:
            return 10
        case .kuwait:
            return 9
        case .moonsightingCommittee:
            return 15
        case .northAmerica:
            return 2
        case .other:
            return 3
        }
    }

    var displayName: String {
        switch self {
        case .muslimWorldLeague:
            return "Muslim World League"
        case .egyptian:
            return "Egyptian"
        case .karachi:
            return "Karachi"
        case .ummAlQura:
            return "Umm al-Qura"
        case .dubai:
            return "Dubai"
        case .qatar:
            return "Qatar"
        case .kuwait:
            return "Kuwait"
        case .moonsightingCommittee:
            return "Moonsighting Committee"
        case .northAmerica:
            return "North America"
        case .other:
            return "Other"
        }
    }
}

extension PrayerMadhab {
    var aladhanSchool: Int {
        switch self {
        case .shafi:
            return 0
        case .hanafi:
            return 1
        }
    }
}
