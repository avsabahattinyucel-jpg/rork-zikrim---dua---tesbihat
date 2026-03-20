import Foundation

final class DiyanetPrayerTimesProvider: PrayerTimesProvider {
    let sourceType: PrayerSourceType = .diyanet

    private let client: PrayerHTTPClient
    private let parser: DiyanetResponseParsing
    private let endpointResolver: DiyanetEndpointResolving
    private let logger: PrayerTimesLogger

    init(
        client: PrayerHTTPClient = URLSessionPrayerHTTPClient(),
        parser: DiyanetResponseParsing = DiyanetHTMLParser(),
        endpointResolver: DiyanetEndpointResolving = DiyanetEndpointResolver(),
        logger: PrayerTimesLogger = PrayerTimesConsoleLogger()
    ) {
        self.client = client
        self.parser = parser
        self.endpointResolver = endpointResolver
        self.logger = logger
    }

    func fetch(
        request: PrayerTimesRequest,
        resolvedCountryCode: String,
        routeReason: PrayerRouteReason
    ) async throws -> PrayerTimesSnapshot {
        guard resolvedCountryCode == "TR" else {
            throw PrayerTimesDataError.noPrayerTimesForSelectedLocation
        }

        guard let city = request.context.city, !city.isEmpty else {
            throw PrayerTimesDataError.diyanetDistrictMappingFailed(city: "", district: request.context.district)
        }

        let district = request.context.district
        let urls = endpointResolver.candidateURLs(city: city, district: district)
        logger.log(event: "city_resolution_result", metadata: ["city": city, "district": district ?? "-"])

        for url in urls {
            do {
                let (data, http) = try await client.get(
                    url: url,
                    headers: ["Accept": "text/html", "User-Agent": "Zikrim/1.0 iOS PrayerTimes"]
                )
                guard (200...299).contains(http.statusCode) else {
                    continue
                }
                guard let html = String(data: data, encoding: .utf8) else {
                    continue
                }

                let day = try parser.parse(html: html, date: request.date)
                logger.log(event: "parse_success", metadata: ["source": "diyanet", "url": url.absoluteString])
                return try Self.normalize(
                    day: day,
                    countryCode: resolvedCountryCode,
                    sourceType: .diyanet,
                    sourceDetail: "Diyanet",
                    methodLabel: "Diyanet Official"
                )
            } catch let error as PrayerTimesDataError {
                logger.log(event: "parse_failure", metadata: ["source": "diyanet", "reason": error.localizedDescription])
            } catch {
                logger.log(event: "parse_failure", metadata: ["source": "diyanet", "reason": "unknown"]) 
            }
        }

        throw PrayerTimesDataError.diyanetPageStructureChanged
    }

    private static func normalize(
        day: DiyanetNormalizedDay,
        countryCode: String,
        sourceType: PrayerSourceType,
        sourceDetail: String,
        methodLabel: String
    ) throws -> PrayerTimesSnapshot {
        let tz = TimeZone(identifier: day.timezoneIdentifier) ?? .init(identifier: "Europe/Istanbul") ?? .current

        guard let imsak = day.gregorianDate.combiningPrayerTime(day.imsak, timeZone: tz),
              let sunrise = day.gregorianDate.combiningPrayerTime(day.sunrise, timeZone: tz),
              let dhuhr = day.gregorianDate.combiningPrayerTime(day.dhuhr, timeZone: tz),
              let asr = day.gregorianDate.combiningPrayerTime(day.asr, timeZone: tz),
              let maghrib = day.gregorianDate.combiningPrayerTime(day.maghrib, timeZone: tz),
              let isha = day.gregorianDate.combiningPrayerTime(day.isha, timeZone: tz) else {
            throw PrayerTimesDataError.invalidResponse
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        dateFormatter.timeZone = tz
        dateFormatter.dateFormat = "d MMMM yyyy"

        let items: [PrayerTimeItem] = [
            .init(kind: .imsak, title: "İmsak", time: imsak, isNext: false, isPassed: false),
            .init(kind: .sunrise, title: "Güneş", time: sunrise, isNext: false, isPassed: false),
            .init(kind: .dhuhr, title: "Öğle", time: dhuhr, isNext: false, isPassed: false),
            .init(kind: .asr, title: "İkindi", time: asr, isNext: false, isPassed: false),
            .init(kind: .maghrib, title: "Akşam", time: maghrib, isNext: false, isPassed: false),
            .init(kind: .isha, title: "Yatsı", time: isha, isNext: false, isPassed: false)
        ]

        return PrayerTimesSnapshot(
            date: day.gregorianDate,
            hijriDateText: day.hijriDateText,
            gregorianDateText: dateFormatter.string(from: day.gregorianDate),
            timezoneIdentifier: tz.identifier,
            cityName: day.cityDisplayName.isEmpty ? "Türkiye" : day.cityDisplayName,
            districtName: day.districtDisplayName,
            countryCode: countryCode,
            sourceType: sourceType,
            sourceDetail: sourceDetail,
            calculationMethod: methodLabel,
            prayers: items,
            fetchedAt: Date(),
            isFallback: false,
            isFromCache: false
        )
    }
}
