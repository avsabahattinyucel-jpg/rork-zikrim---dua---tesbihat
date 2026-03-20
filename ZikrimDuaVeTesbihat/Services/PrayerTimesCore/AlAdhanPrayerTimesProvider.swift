import Foundation
import CoreLocation

final class AlAdhanPrayerTimesProvider: PrayerTimesProvider {
    let sourceType: PrayerSourceType = .aladhan

    private let client: PrayerHTTPClient
    private let logger: PrayerTimesLogger

    init(
        client: PrayerHTTPClient = URLSessionPrayerHTTPClient(),
        logger: PrayerTimesLogger = PrayerTimesConsoleLogger()
    ) {
        self.client = client
        self.logger = logger
    }

    func fetch(
        request: PrayerTimesRequest,
        resolvedCountryCode: String,
        routeReason: PrayerRouteReason
    ) async throws -> PrayerTimesSnapshot {
        let endpoint = try resolveEndpoint(for: request)
        let (data, http) = try await client.get(
            url: endpoint,
            headers: ["Accept": "application/json", "User-Agent": "Zikrim/1.0 iOS PrayerTimes"]
        )

        if http.statusCode == 429 {
            throw PrayerTimesDataError.rateLimitExceeded
        }
        guard (200...299).contains(http.statusCode) else {
            throw PrayerTimesDataError.aladhanRequestFailed(statusCode: http.statusCode)
        }

        let decoded: AlAdhanTimingsEnvelope
        do {
            decoded = try JSONDecoder().decode(AlAdhanTimingsEnvelope.self, from: data)
        } catch {
            throw PrayerTimesDataError.invalidResponse
        }

        if decoded.code == 429 {
            throw PrayerTimesDataError.rateLimitExceeded
        }

        guard let timezone = TimeZone(identifier: decoded.data.meta.timezone) else {
            throw PrayerTimesDataError.invalidResponse
        }

        guard let baseDate = Date.aladhanDateFormatter.date(from: decoded.data.date.gregorian.date) else {
            throw PrayerTimesDataError.invalidResponse
        }

        guard let imsak = baseDate.combiningPrayerTime(decoded.data.timings.fajr, timeZone: timezone),
              let sunrise = baseDate.combiningPrayerTime(decoded.data.timings.sunrise, timeZone: timezone),
              let dhuhr = baseDate.combiningPrayerTime(decoded.data.timings.dhuhr, timeZone: timezone),
              let asr = baseDate.combiningPrayerTime(decoded.data.timings.asr, timeZone: timezone),
              let maghrib = baseDate.combiningPrayerTime(decoded.data.timings.maghrib, timeZone: timezone),
              let isha = baseDate.combiningPrayerTime(decoded.data.timings.isha, timeZone: timezone) else {
            throw PrayerTimesDataError.emptyTimings
        }

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = timezone
        formatter.dateFormat = "d MMMM yyyy"

        let city = request.context.city ?? "Unknown"
        let district = request.context.district
        logger.log(
            event: "parse_success",
            metadata: [
                "source": "aladhan",
                "city": city,
                "district": district ?? "-",
                "method": String(request.calculationMethodID)
            ]
        )

        return PrayerTimesSnapshot(
            date: baseDate,
            hijriDateText: decoded.data.date.hijri.date,
            gregorianDateText: formatter.string(from: baseDate),
            timezoneIdentifier: timezone.identifier,
            cityName: city,
            districtName: district,
            countryCode: resolvedCountryCode,
            sourceType: .aladhan,
            sourceDetail: "AlAdhan",
            calculationMethod: request.methodLabel,
            prayers: [
                .init(kind: .imsak, title: "Imsak", time: imsak, isNext: false, isPassed: false),
                .init(kind: .sunrise, title: "Sunrise", time: sunrise, isNext: false, isPassed: false),
                .init(kind: .dhuhr, title: "Dhuhr", time: dhuhr, isNext: false, isPassed: false),
                .init(kind: .asr, title: "Asr", time: asr, isNext: false, isPassed: false),
                .init(kind: .maghrib, title: "Maghrib", time: maghrib, isNext: false, isPassed: false),
                .init(kind: .isha, title: "Isha", time: isha, isNext: false, isPassed: false)
            ],
            fetchedAt: Date(),
            isFallback: false,
            isFromCache: false
        )
    }

    private func resolveEndpoint(for request: PrayerTimesRequest) throws -> URL {
        let dateSegment = Date.aladhanQueryFormatter.string(from: request.date)
        var components = URLComponents(string: "https://api.aladhan.com/v1/timings/\(dateSegment)")

        if let coordinate = request.context.coordinate {
            components?.queryItems = [
                URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
                URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
                URLQueryItem(name: "method", value: String(request.calculationMethodID)),
                URLQueryItem(name: "school", value: String(request.madhabSchool))
            ]
        } else if let city = request.context.city, !city.isEmpty {
            var query: [URLQueryItem] = [
                URLQueryItem(name: "city", value: city),
                URLQueryItem(name: "method", value: String(request.calculationMethodID)),
                URLQueryItem(name: "school", value: String(request.madhabSchool))
            ]
            if let country = request.context.countryCode {
                query.append(URLQueryItem(name: "country", value: country))
            }
            components?.queryItems = query
        } else {
            throw PrayerTimesDataError.locationUnavailable
        }

        guard let url = components?.url else {
            throw PrayerTimesDataError.invalidResponse
        }
        return url
    }
}

private extension Date {
    static let aladhanQueryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    static let aladhanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

}
