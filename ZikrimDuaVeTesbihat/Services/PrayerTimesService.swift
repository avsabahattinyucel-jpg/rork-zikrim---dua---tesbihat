import Foundation
import CoreLocation

struct PrayerTimes: Sendable {
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let date: Date
    let timeZone: TimeZone
    let locationName: String?
    let sourceName: String?

    var allTimes: [PrayerName: Date] {
        [
            .fajr: fajr,
            .sunrise: sunrise,
            .dhuhr: dhuhr,
            .asr: asr,
            .maghrib: maghrib,
            .isha: isha
        ]
    }
}

enum PrayerName: String, CaseIterable, Codable, Sendable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    nonisolated var notificationIdentifier: String {
        "prayer_\(rawValue)"
    }

    nonisolated var systemImage: String {
        switch self {
        case .fajr: return "prayer_icon_fajr"
        case .sunrise: return "prayer_icon_sunrise"
        case .dhuhr: return "prayer_icon_dhuhr"
        case .asr: return "prayer_icon_asr"
        case .maghrib: return "prayer_icon_maghrib"
        case .isha: return "prayer_icon_isha"
        }
    }

    nonisolated var localizedKey: L10n.Key {
        switch self {
        case .fajr: return .prayerFajr
        case .sunrise: return .prayerSunrise
        case .dhuhr: return .prayerDhuhr
        case .asr: return .prayerAsr
        case .maghrib: return .prayerMaghrib
        case .isha: return .prayerIsha
        }
    }

    nonisolated var localizedName: String {
        L10n.string(localizedKey)
    }
}

protocol PrayerTimesServing: Sendable {
    func prayerTimes(
        for coordinates: CLLocationCoordinate2D,
        date: Date,
        settings: PrayerSettings,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) async -> PrayerTimes?
}
