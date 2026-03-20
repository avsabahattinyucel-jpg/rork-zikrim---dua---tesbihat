import CoreLocation
import Foundation

struct PrayerNotificationContext: Sendable {
    let coordinate: CLLocationCoordinate2D
    let locationName: String?
    let administrativeArea: String?
    let country: String?
    let timezone: TimeZone
}

protocol PrayerTimesProviding: Sendable {
    func currentContext() async -> PrayerNotificationContext?
    func prayerTimes(for date: Date, context: PrayerNotificationContext) async -> PrayerTimes?
}

struct LivePrayerTimesProvider: PrayerTimesProviding {
    private let prayerSettings: PrayerSettings
    private let service: PrayerTimesServing

    init(
        prayerSettings: PrayerSettings = PrayerSettings(),
        service: PrayerTimesServing = RegionalPrayerTimesService()
    ) {
        self.prayerSettings = prayerSettings
        self.service = service
    }

    func currentContext() async -> PrayerNotificationContext? {
        if prayerSettings.locationMode == .manual, let manual = prayerSettings.manualLocation {
            return PrayerNotificationContext(
                coordinate: manual.coordinate,
                locationName: manual.name,
                administrativeArea: manual.adminArea,
                country: manual.country,
                timezone: .autoupdatingCurrent
            )
        }

        guard let coordinate = prayerSettings.lastKnownCoordinate else {
            return nil
        }

        return PrayerNotificationContext(
            coordinate: coordinate,
            locationName: prayerSettings.lastLocationName,
            administrativeArea: prayerSettings.lastAdministrativeArea,
            country: prayerSettings.lastCountry,
            timezone: .autoupdatingCurrent
        )
    }

    func prayerTimes(for date: Date, context: PrayerNotificationContext) async -> PrayerTimes? {
        await service.prayerTimes(
            for: context.coordinate,
            date: date,
            settings: prayerSettings,
            locationName: context.locationName,
            administrativeArea: context.administrativeArea,
            country: context.country
        )
    }
}

struct MockPrayerTimesProvider: PrayerTimesProviding {
    let timezone: TimeZone
    let locationName: String

    init(
        timezone: TimeZone = .autoupdatingCurrent,
        locationName: String = "Istanbul"
    ) {
        self.timezone = timezone
        self.locationName = locationName
    }

    func currentContext() async -> PrayerNotificationContext? {
        PrayerNotificationContext(
            coordinate: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            locationName: locationName,
            administrativeArea: "Istanbul",
            country: "TR",
            timezone: timezone
        )
    }

    func prayerTimes(for date: Date, context: PrayerNotificationContext) async -> PrayerTimes? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let day = calendar.startOfDay(for: date)

        func make(_ hour: Int, _ minute: Int) -> Date {
            calendar.date(byAdding: .minute, value: hour * 60 + minute, to: day) ?? day
        }

        return PrayerTimes(
            fajr: make(5, 28),
            sunrise: make(6, 47),
            dhuhr: make(12, 58),
            asr: make(16, 19),
            maghrib: make(19, 1),
            isha: make(20, 19),
            date: day,
            timeZone: timezone,
            locationName: context.locationName,
            sourceName: "Mock"
        )
    }
}
