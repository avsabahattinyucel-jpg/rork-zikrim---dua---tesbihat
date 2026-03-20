import Foundation
import CoreLocation
import Adhan

final class LocalPrayerTimesService: PrayerTimesServing, @unchecked Sendable {
    func prayerTimes(
        for coordinates: CLLocationCoordinate2D,
        date: Date,
        settings: PrayerSettings,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) async -> PrayerTimes? {
        _ = administrativeArea
        _ = country

        let adhanCoordinates = Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let dateComponents = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        var params = settings.calculationMethod.adhanMethod.params
        params.madhab = settings.madhab.adhanMadhab

        guard let adhanTimes = Adhan.PrayerTimes(
            coordinates: adhanCoordinates,
            date: dateComponents,
            calculationParameters: params
        ) else {
            return nil
        }

        return PrayerTimes(
            fajr: adhanTimes.fajr,
            sunrise: adhanTimes.sunrise,
            dhuhr: adhanTimes.dhuhr,
            asr: adhanTimes.asr,
            maghrib: adhanTimes.maghrib,
            isha: adhanTimes.isha,
            date: date,
            timeZone: .current,
            locationName: locationName,
            sourceName: settings.calculationMethod.displayName
        )
    }
}

final class RegionalPrayerTimesService: PrayerTimesServing, @unchecked Sendable {
    private let diyanetService = DiyanetPrayerTimesService()
    private let remoteService = AladhanPrayerTimesService()
    private let localService = LocalPrayerTimesService()

    func prayerTimes(
        for coordinates: CLLocationCoordinate2D,
        date: Date,
        settings: PrayerSettings,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) async -> PrayerTimes? {
        let resolvedCountry = country ?? settings.manualLocation?.country ?? settings.lastCountry
        let shouldUseDiyanet = isTurkey(resolvedCountry) || PrayerCountryMatcher.isTurkey(coordinates: coordinates)
        if shouldUseDiyanet,
           let diyanetTimes = await diyanetService.prayerTimes(
                for: coordinates,
                date: date,
                settings: settings,
                locationName: locationName,
                administrativeArea: administrativeArea,
                country: resolvedCountry
           ) {
            return diyanetTimes
        }

        if let remoteTimes = await remoteService.prayerTimes(
            for: coordinates,
            date: date,
            settings: settings,
            locationName: locationName,
            administrativeArea: administrativeArea,
            country: country
        ) {
            return remoteTimes
        }

        return await localService.prayerTimes(
            for: coordinates,
            date: date,
            settings: settings,
            locationName: locationName,
            administrativeArea: administrativeArea,
            country: country
        )
    }

    private func isTurkey(_ country: String?) -> Bool {
        guard let country else { return false }
        return PrayerCountryMatcher.isTurkey(country)
    }
}

final class AladhanPrayerTimesService: PrayerTimesServing, @unchecked Sendable {
    private let api = AladhanPrayerTimesAPI.shared

    func prayerTimes(
        for coordinates: CLLocationCoordinate2D,
        date: Date,
        settings: PrayerSettings,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) async -> PrayerTimes? {
        let resolvedCountry = country ?? settings.manualLocation?.country ?? settings.lastCountry
        return await api.prayerTimes(
            coordinates: coordinates,
            date: date,
            methodID: resolvedMethodID(country: resolvedCountry, settings: settings),
            school: settings.madhab.aladhanSchool,
            locationName: locationName,
            administrativeArea: administrativeArea,
            country: resolvedCountry
        )
    }

    private func resolvedMethodID(country: String?, settings: PrayerSettings) -> Int {
        guard let country, PrayerCountryMatcher.isTurkey(country) else {
            return settings.calculationMethod.aladhanMethodID
        }
        return 13
    }
}

private actor AladhanPrayerTimesAPI {
    static let shared = AladhanPrayerTimesAPI()
    private static let requestTimeout: TimeInterval = 12
    private static let resourceTimeout: TimeInterval = 15

    private struct APIEnvelope<T: Decodable>: Decodable {
        let code: Int
        let status: String
        let data: T
    }

    private struct TimingsResponse: Decodable {
        let timings: Timings
        let date: ResponseDate
        let meta: Meta

        struct Timings: Decodable {
            let fajr: String
            let sunrise: String
            let dhuhr: String
            let asr: String
            let maghrib: String
            let isha: String

            enum CodingKeys: String, CodingKey {
                case fajr = "Fajr"
                case sunrise = "Sunrise"
                case dhuhr = "Dhuhr"
                case asr = "Asr"
                case maghrib = "Maghrib"
                case isha = "Isha"
            }
        }

        struct ResponseDate: Decodable {
            let gregorian: Gregorian

            struct Gregorian: Decodable {
                let date: String
            }
        }

        struct Meta: Decodable {
            let timezone: String
            let method: MethodInfo

            struct MethodInfo: Decodable {
                let id: Int?
                let name: String
            }
        }
    }

    private let session: URLSession
    private let queryDateFormatter: DateFormatter
    private let responseDateFormatter: DateFormatter

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "Zikrim/1.0 iOS PrayerTimes"
        ]
        configuration.timeoutIntervalForRequest = Self.requestTimeout
        configuration.timeoutIntervalForResource = Self.resourceTimeout
        session = URLSession(configuration: configuration)

        let queryFormatter = DateFormatter()
        queryFormatter.calendar = Calendar(identifier: .gregorian)
        queryFormatter.locale = Locale(identifier: "en_US_POSIX")
        queryFormatter.dateFormat = "dd-MM-yyyy"
        queryDateFormatter = queryFormatter

        let responseFormatter = DateFormatter()
        responseFormatter.calendar = Calendar(identifier: .gregorian)
        responseFormatter.locale = Locale(identifier: "en_US_POSIX")
        responseFormatter.dateFormat = "dd-MM-yyyy"
        responseDateFormatter = responseFormatter
    }

    func prayerTimes(
        coordinates: CLLocationCoordinate2D,
        date: Date,
        methodID: Int,
        school: Int,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) async -> PrayerTimes? {
        let dateSegment = queryDateFormatter.string(from: date)
        guard var components = URLComponents(string: "https://api.aladhan.com/v1/timings/\(dateSegment)") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinates.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinates.longitude)),
            URLQueryItem(name: "method", value: String(methodID)),
            URLQueryItem(name: "school", value: String(school))
        ]

        guard let url = components.url,
              let response: TimingsResponse = try? await fetch(url: url),
              let timeZone = TimeZone(identifier: response.meta.timezone),
              let baseDate = responseDateFormatter.date(from: response.date.gregorian.date),
              let fajr = combined(date: baseDate, time: response.timings.fajr, timeZone: timeZone),
              let sunrise = combined(date: baseDate, time: response.timings.sunrise, timeZone: timeZone),
              let dhuhr = combined(date: baseDate, time: response.timings.dhuhr, timeZone: timeZone),
              let asr = combined(date: baseDate, time: response.timings.asr, timeZone: timeZone),
              let maghrib = combined(date: baseDate, time: response.timings.maghrib, timeZone: timeZone),
              let isha = combined(date: baseDate, time: response.timings.isha, timeZone: timeZone) else {
            return nil
        }

        return PrayerTimes(
            fajr: fajr,
            sunrise: sunrise,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            date: baseDate,
            timeZone: timeZone,
            locationName: resolvedLocationName(locationName: locationName, administrativeArea: administrativeArea, country: country),
            sourceName: response.meta.method.name
        )
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APIEnvelope<T>.self, from: data).data
    }

    private func combined(date: Date, time: String, timeZone: TimeZone) -> Date? {
        let cleanedTime = time
            .components(separatedBy: " ")
            .first?
            .replacingOccurrences(of: "[^0-9:]", with: "", options: .regularExpression) ?? time

        let parts = cleanedTime.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }

    private func resolvedLocationName(
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) -> String? {
        let rawParts: [String?] = [locationName, administrativeArea, country]
        var parts: [String] = []

        for rawPart in rawParts {
            guard let rawPart else { continue }
            let trimmed = rawPart.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                parts.append(trimmed)
            }
        }

        let uniqueParts = parts.reduce(into: [String]()) { partial, item in
            if !partial.contains(item) {
                partial.append(item)
            }
        }

        return uniqueParts.isEmpty ? nil : uniqueParts.joined(separator: ", ")
    }
}

final class DiyanetPrayerTimesService: PrayerTimesServing, @unchecked Sendable {
    private let api = DiyanetPrayerTimesAPI.shared

    func prayerTimes(
        for coordinates: CLLocationCoordinate2D,
        date: Date,
        settings: PrayerSettings,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) async -> PrayerTimes? {
        let isTurkey = PrayerCountryMatcher.isTurkey(country ?? "") || PrayerCountryMatcher.isTurkey(coordinates: coordinates)
        guard isTurkey else {
            return nil
        }

        let components = PrayerLocationResolver.components(
            locationName: locationName,
            administrativeArea: administrativeArea,
            country: country
        )
        let cityName = components.city ?? administrativeArea ?? locationName
        let districtName = components.district

        guard let cityName else { return nil }

        return await api.prayerTimes(
            date: date,
            cityName: cityName,
            districtName: districtName,
            locationName: locationName,
            administrativeArea: administrativeArea,
            country: country
        )
    }
}

private actor DiyanetPrayerTimesAPI {
    static let shared = DiyanetPrayerTimesAPI()
    private static let requestTimeout: TimeInterval = 12
    private static let resourceTimeout: TimeInterval = 15
    private static let dayCacheTTL: TimeInterval = 6 * 60 * 60

    private struct Country: Decodable {
        let UlkeAdi: String
        let UlkeAdiEn: String
        let UlkeID: String
    }

    private struct City: Decodable {
        let SehirAdi: String
        let SehirAdiEn: String
        let SehirID: String
    }

    private struct District: Decodable {
        let IlceAdi: String
        let IlceAdiEn: String
        let IlceID: String
    }

    private struct Day: Decodable {
        let HicriTarihUzun: String
        let MiladiTarihKisa: String
        let MiladiTarihKisaIso8601: String?
        let MiladiTarihUzun: String
        let MiladiTarihUzunIso8601: String
        let Imsak: String
        let Gunes: String
        let Ogle: String
        let Ikindi: String
        let Aksam: String
        let Yatsi: String
    }

    private struct CachedDays {
        let days: [Day]
        let fetchedAt: Date
    }

    private let session: URLSession
    private let isoDateFormatter = ISO8601DateFormatter()
    private let shortDateFormatter: DateFormatter
    private var cityCache: [String: String] = [:]
    private var districtCache: [String: String] = [:]
    private var dayCache: [String: CachedDays] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "Zikrim/1.0 iOS PrayerTimes"
        ]
        configuration.timeoutIntervalForRequest = Self.requestTimeout
        configuration.timeoutIntervalForResource = Self.resourceTimeout
        session = URLSession(configuration: configuration)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        formatter.dateFormat = "dd.MM.yyyy"
        shortDateFormatter = formatter
    }

    func prayerTimes(
        date: Date,
        cityName: String,
        districtName: String?,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) async -> PrayerTimes? {
        do {
            let cityID = try await resolveCityID(for: cityName)
            let districtID = try await resolveDistrictID(
                cityID: cityID,
                cityName: cityName,
                districtName: districtName,
                locationName: locationName
            )

            let days = try await fetchDays(for: districtID)
            guard let day = day(for: date, in: days),
                  let baseDate = baseDate(for: day),
                  let imsak = combined(date: baseDate, time: day.Imsak),
                  let sunrise = combined(date: baseDate, time: day.Gunes),
                  let dhuhr = combined(date: baseDate, time: day.Ogle),
                  let asr = combined(date: baseDate, time: day.Ikindi),
                  let maghrib = combined(date: baseDate, time: day.Aksam),
                  let isha = combined(date: baseDate, time: day.Yatsi) else {
                return nil
            }

            let tz = TimeZone(identifier: "Europe/Istanbul") ?? .current
            return PrayerTimes(
                fajr: imsak,
                sunrise: sunrise,
                dhuhr: dhuhr,
                asr: asr,
                maghrib: maghrib,
                isha: isha,
                date: baseDate,
                timeZone: tz,
                locationName: resolvedLocationName(
                    cityName: cityName,
                    districtName: districtName,
                    locationName: locationName,
                    administrativeArea: administrativeArea,
                    country: country
                ),
                sourceName: "Diyanet"
            )
        } catch {
            return nil
        }
    }

    private func resolveCityID(for cityName: String) async throws -> String {
        let normalizedCity = normalizeLookup(cityName)
        if let cached = cityCache[normalizedCity] {
            return cached
        }

        let countries: [Country] = try await fetch(path: "/ulkeler")
        guard let turkeyID = countries.first(where: {
            normalizeLookup($0.UlkeAdi) == "turkiye" ||
            normalizeLookup($0.UlkeAdiEn) == "turkey"
        })?.UlkeID else {
            throw URLError(.badServerResponse)
        }

        let cities: [City] = try await fetch(path: "/sehirler/\(turkeyID)")
        guard let matched = cities.first(where: {
            normalizeLookup($0.SehirAdi) == normalizedCity ||
            normalizeLookup($0.SehirAdiEn) == normalizedCity
        }) else {
            throw URLError(.resourceUnavailable)
        }

        cityCache[normalizedCity] = matched.SehirID
        return matched.SehirID
    }

    private func resolveDistrictID(
        cityID: String,
        cityName: String,
        districtName: String?,
        locationName: String?
    ) async throws -> String {
        let cacheKey = "\(cityID):\(normalizeLookup(districtName ?? locationName ?? cityName))"
        if let cached = districtCache[cacheKey] {
            return cached
        }

        let districts: [District] = try await fetch(path: "/ilceler/\(cityID)")
        let districtLookup = normalizeLookup(districtName)
        let locationLookup = normalizeLookup(locationName)
        let cityLookup = normalizeLookup(cityName)

        let matched =
            districts.first(where: {
                let value = normalizeLookup($0.IlceAdi)
                return !districtLookup.isEmpty && value == districtLookup
            }) ??
            districts.first(where: {
                let value = normalizeLookup($0.IlceAdi)
                return !locationLookup.isEmpty && value == locationLookup
            }) ??
            districts.first(where: {
                let value = normalizeLookup($0.IlceAdi)
                return value == cityLookup || value.contains(cityLookup) || cityLookup.contains(value)
            }) ??
            districts.first

        guard let matched else {
            throw URLError(.resourceUnavailable)
        }

        districtCache[cacheKey] = matched.IlceID
        return matched.IlceID
    }

    private func fetchDays(for districtID: String) async throws -> [Day] {
        if let cached = dayCache[districtID],
           Date().timeIntervalSince(cached.fetchedAt) < Self.dayCacheTTL {
            return cached.days
        }

        let days: [Day] = try await fetch(path: "/vakitler/\(districtID)")
        dayCache[districtID] = CachedDays(days: days, fetchedAt: Date())
        return days
    }

    private func fetch<T: Decodable>(path: String) async throws -> T {
        guard let url = URL(string: "https://ezanvakti.emushaf.net\(path)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func day(for requestedDate: Date, in days: [Day]) -> Day? {
        let calendar = Calendar(identifier: .gregorian)
        return days.first {
            guard let current = baseDate(for: $0) else {
                return false
            }
            return calendar.isDate(current, inSameDayAs: requestedDate)
        }
    }

    private func baseDate(for day: Day) -> Date? {
        if let date = shortDateFormatter.date(from: day.MiladiTarihKisaIso8601 ?? day.MiladiTarihKisa) {
            return date
        }
        return isoDateFormatter.date(from: day.MiladiTarihUzunIso8601)
    }

    private func combined(date: Date, time: String) -> Date? {
        let cleanedTime = time.replacingOccurrences(of: "[^0-9:]", with: "", options: .regularExpression)
        let parts = cleanedTime.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }

    private func resolvedLocationName(
        cityName: String,
        districtName: String?,
        locationName: String?,
        administrativeArea: String?,
        country: String?
    ) -> String {
        let parts = [
            districtName ?? locationName,
            administrativeArea ?? cityName,
            country
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func normalizeLookup(_ value: String?) -> String {
        (value ?? "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "[^\\p{L}\\p{N}]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum PrayerCountryMatcher {
    static func isTurkey(_ country: String) -> Bool {
        let normalized = normalizeLookup(country)
        return normalized == "turkiye" || normalized == "turkey"
    }

    static func isTurkey(coordinates: CLLocationCoordinate2D) -> Bool {
        (35.5...42.8).contains(coordinates.latitude) &&
        (25.5...45.0).contains(coordinates.longitude)
    }

    private static func normalizeLookup(_ value: String?) -> String {
        (value ?? "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "[^\\p{L}\\p{N}]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum PrayerLocationResolver {
    struct Components {
        let city: String?
        let district: String?
    }

    static func components(locationName: String?, administrativeArea: String?, country: String?) -> Components {
        let rawParts = (locationName ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let adminLookup = normalizeLookup(administrativeArea)
        let countryLookup = normalizeLookup(country)

        let filteredParts = rawParts.filter {
            let lookup = normalizeLookup($0)
            return lookup != adminLookup && lookup != countryLookup
        }

        let district = filteredParts.first
        let city = administrativeArea ?? filteredParts.dropFirst().first ?? rawParts.dropFirst().first ?? rawParts.first

        return Components(
            city: city,
            district: normalizedDistrict(
                district: district,
                city: city
            )
        )
    }

    static func normalizedDistrict(district: String?, city: String?) -> String? {
        guard let district else { return nil }
        let location = normalizeLookup(district)
        let cityLookup = normalizeLookup(city)
        guard !location.isEmpty, location != cityLookup else { return nil }
        return district
    }

    private static func normalizeLookup(_ value: String?) -> String {
        (value ?? "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "[^\\p{L}\\p{N}]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
