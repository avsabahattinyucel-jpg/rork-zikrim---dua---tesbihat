import Foundation
import CoreLocation

enum PrayerSourceType: String, Codable, Sendable {
    case diyanet
    case aladhan
    case cache
    case fallback
}

enum PrayerRouteReason: String, Codable, Sendable {
    case turkey
    case nonTurkey
    case fallbackAfterFailure
}

enum PrayerTimeKind: String, CaseIterable, Codable, Sendable {
    case imsak
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha
}

struct PrayerTimeItem: Codable, Sendable, Hashable {
    let kind: PrayerTimeKind
    let title: String
    let time: Date
    let isNext: Bool
    let isPassed: Bool

    func withFlags(isNext: Bool, isPassed: Bool) -> PrayerTimeItem {
        PrayerTimeItem(kind: kind, title: title, time: time, isNext: isNext, isPassed: isPassed)
    }
}

struct PrayerTimesSnapshot: Codable, Sendable, Hashable {
    let date: Date
    let hijriDateText: String
    let gregorianDateText: String
    let timezoneIdentifier: String
    let cityName: String
    let districtName: String?
    let countryCode: String
    let sourceType: PrayerSourceType
    let sourceDetail: String
    let calculationMethod: String
    let prayers: [PrayerTimeItem]
    let fetchedAt: Date
    let isFallback: Bool
    let isFromCache: Bool

    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }

    func markCache(isFromCache: Bool, isFallback: Bool? = nil, sourceType: PrayerSourceType? = nil) -> PrayerTimesSnapshot {
        PrayerTimesSnapshot(
            date: date,
            hijriDateText: hijriDateText,
            gregorianDateText: gregorianDateText,
            timezoneIdentifier: timezoneIdentifier,
            cityName: cityName,
            districtName: districtName,
            countryCode: countryCode,
            sourceType: sourceType ?? self.sourceType,
            sourceDetail: sourceDetail,
            calculationMethod: calculationMethod,
            prayers: prayers,
            fetchedAt: fetchedAt,
            isFallback: isFallback ?? self.isFallback,
            isFromCache: isFromCache
        )
    }
}

enum PrayerTimesLoadState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case stale
    case fallback
    case failed(PrayerTimesDataError)
}

enum PrayerTimesDataError: Error, Sendable, Equatable, LocalizedError {
    case locationUnavailable
    case reverseGeocodingFailed
    case diyanetDistrictMappingFailed(city: String, district: String?)
    case diyanetPageStructureChanged
    case aladhanRequestFailed(statusCode: Int?)
    case networkFailure
    case invalidResponse
    case rateLimitExceeded
    case emptyTimings
    case timeout
    case noPrayerTimesForSelectedLocation

    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "location_unavailable"
        case .reverseGeocodingFailed:
            return "reverse_geocoding_failed"
        case .diyanetDistrictMappingFailed:
            return "diyanet_district_mapping_failed"
        case .diyanetPageStructureChanged:
            return "diyanet_page_structure_changed"
        case .aladhanRequestFailed:
            return "aladhan_request_failed"
        case .networkFailure:
            return "network_failure"
        case .invalidResponse:
            return "invalid_response"
        case .rateLimitExceeded:
            return "rate_limit_exceeded"
        case .emptyTimings:
            return "empty_timings"
        case .timeout:
            return "timeout"
        case .noPrayerTimesForSelectedLocation:
            return "no_prayer_times_for_selected_location"
        }
    }
}

enum PrayerLocationSelection: Sendable, Equatable {
    case automatic
    case manualCity
}

struct PrayerLocationContext: Sendable {
    let selection: PrayerLocationSelection
    let city: String?
    let district: String?
    let countryCode: String?
    let coordinate: CLLocationCoordinate2D?
    let timezoneIdentifier: String?

    init(
        selection: PrayerLocationSelection,
        city: String? = nil,
        district: String? = nil,
        countryCode: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        timezoneIdentifier: String? = nil
    ) {
        self.selection = selection
        self.city = city
        self.district = district
        self.countryCode = countryCode
        self.coordinate = coordinate
        self.timezoneIdentifier = timezoneIdentifier
    }
}

extension Date {
    func combiningPrayerTime(_ time: String, timeZone: TimeZone) -> Date? {
        let cleaned = time.normalizedAladhanTime
        let parts = cleaned.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var day = calendar.dateComponents([.year, .month, .day], from: self)
        day.hour = hour
        day.minute = minute
        day.second = 0
        return calendar.date(from: day)
    }
}

struct PrayerTimesRequest: Sendable {
    let date: Date
    let context: PrayerLocationContext
    let calculationMethodID: Int
    let methodLabel: String
    let madhabSchool: Int

    init(
        date: Date = Date(),
        context: PrayerLocationContext,
        calculationMethodID: Int,
        methodLabel: String,
        madhabSchool: Int
    ) {
        self.date = date
        self.context = context
        self.calculationMethodID = calculationMethodID
        self.methodLabel = methodLabel
        self.madhabSchool = madhabSchool
    }
}

struct PrayerTimesResponse: Sendable {
    let snapshot: PrayerTimesSnapshot
    let loadState: PrayerTimesLoadState
    let routeReason: PrayerRouteReason
}

protocol PrayerTimesProvider: Sendable {
    var sourceType: PrayerSourceType { get }

    func fetch(
        request: PrayerTimesRequest,
        resolvedCountryCode: String,
        routeReason: PrayerRouteReason
    ) async throws -> PrayerTimesSnapshot
}

protocol PrayerTimesLogger: Sendable {
    func log(event: String, metadata: [String: String])
}

struct PrayerTimesConsoleLogger: PrayerTimesLogger {
    func log(event: String, metadata: [String: String]) {
        #if DEBUG
        let details = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        print("[PrayerTimes] \(event) \(details)")
        #endif
    }
}

struct PrayerTimesLocalizedStrings {
    static func sourceLabel(for source: PrayerSourceType, locale: Locale = .current) -> String {
        switch source {
        case .diyanet:
            return locale.language.languageCode?.identifier == "tr" ? "Veri kaynağı: Diyanet" : "Source: Diyanet"
        case .aladhan:
            return locale.language.languageCode?.identifier == "tr" ? "Veri kaynağı: AlAdhan" : "Source: AlAdhan"
        case .cache:
            return locale.language.languageCode?.identifier == "tr" ? "Çevrimdışı gösterim" : "Offline preview"
        case .fallback:
            return locale.language.languageCode?.identifier == "tr" ? "Yedek veri kullanılıyor" : "Fallback data in use"
        }
    }

    static func updatedNow(locale: Locale = .current) -> String {
        locale.language.languageCode?.identifier == "tr" ? "Son güncelleme" : "Updated"
    }
}
