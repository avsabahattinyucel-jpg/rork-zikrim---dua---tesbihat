import Foundation
import CoreLocation
import Testing
@testable import ZikrimDuaVeTesbihat

struct PrayerTimesArchitectureTests {

    @Test func turkeyRoutesToDiyanet() async throws {
        let router = PrayerSourceRouter(countryResolver: MockCountryResolver(code: "TR"), logger: NoopLogger())
        let request = PrayerTimesRequest(
            context: PrayerLocationContext(selection: .automatic, city: "Istanbul", coordinate: CLLocationCoordinate2D(latitude: 41.01, longitude: 28.97)),
            calculationMethodID: 2,
            methodLabel: "Muslim World League",
            madhabSchool: 1
        )

        let route = try await router.route(for: request)
        #expect(route.primarySource == .diyanet)
        #expect(route.routeReason == .turkey)
        #expect(route.resolvedCountryCode == "TR")
    }

    @Test func nonTurkeyRoutesToAlAdhan() async throws {
        let router = PrayerSourceRouter(countryResolver: MockCountryResolver(code: "DE"), logger: NoopLogger())
        let request = PrayerTimesRequest(
            context: PrayerLocationContext(selection: .automatic, city: "Berlin", coordinate: CLLocationCoordinate2D(latitude: 52.5, longitude: 13.4)),
            calculationMethodID: 2,
            methodLabel: "MWL",
            madhabSchool: 1
        )

        let route = try await router.route(for: request)
        #expect(route.primarySource == .aladhan)
        #expect(route.routeReason == .nonTurkey)
    }

    @Test func turkeyFallsBackToAlAdhanWhenDiyanetFails() async throws {
        let repo = DefaultPrayerTimesRepository(
            diyanetProvider: MockProvider(source: .diyanet, result: .failure(.diyanetPageStructureChanged)),
            aladhanProvider: MockProvider(source: .aladhan, result: .success(Self.sampleSnapshot(source: .aladhan, city: "Istanbul", countryCode: "TR"))),
            cacheStore: PrayerTimesMemoryCacheStore(),
            logger: NoopLogger()
        )

        let response = await repo.load(
            request: Self.sampleRequest(country: "TR", city: "Istanbul"),
            route: PrayerRouteDecision(primarySource: .diyanet, resolvedCountryCode: "TR", routeReason: .turkey)
        )

        #expect(response.loadState == .fallback)
        #expect(response.snapshot.isFallback == true)
    }

    @Test func cacheReadWriteWorksUntilEndOfDay() async throws {
        let cache = PrayerTimesMemoryCacheStore()
        let now = Date()
        let key = PrayerTimesCacheKey(
            source: .aladhan,
            countryCode: "DE",
            city: "Berlin",
            district: nil,
            coordinate: CLLocationCoordinate2D(latitude: 52.5, longitude: 13.4),
            date: now,
            method: "MWL"
        )
        let snapshot = Self.sampleSnapshot(source: .aladhan, city: "Berlin", countryCode: "DE")

        await cache.write(snapshot: snapshot, key: key, now: now)
        let cached = await cache.read(key: key, now: now)
        #expect(cached != nil)
        #expect(cached?.isFromCache == true)
    }

    @Test func parserExtractsDiyanetFields() async throws {
        let parser = DiyanetHTMLParser()
        let html = """
        <div data-city-name="Istanbul" data-district-name="Fatih" data-timezone="Europe/Istanbul" data-hijri="10 Ramazan 1447"></div>
        <table>
          <tr data-gregorian="2026-03-16"><td>Pzt</td><td>05:42</td><td>07:06</td><td>13:10</td><td>16:32</td><td>19:04</td><td>20:23</td></tr>
        </table>
        """

        let day = try parser.parse(html: html, date: Date.diyanetDateFormatter.date(from: "2026-03-16") ?? Date())
        #expect(day.cityDisplayName == "Istanbul")
        #expect(day.districtDisplayName == "Fatih")
        #expect(day.imsak == "05:42")
        #expect(day.isha == "20:23")
    }

    @Test func nextPrayerCalculationUsesTomorrowImsakAfterIsha() async throws {
        let service = PrayerTimesService(
            router: MockRouter(),
            repository: MockRepository(response: PrayerTimesResponse(snapshot: Self.sampleSnapshot(source: .aladhan, city: "Berlin", countryCode: "DE"), loadState: .loaded, routeReason: .nonTurkey)),
            logger: NoopLogger()
        )

        let tz = TimeZone(identifier: "Europe/Istanbul")!
        let today = Self.snapshotForDay("2026-03-16", timezone: tz, source: .diyanet)
        let tomorrow = Self.snapshotForDay("2026-03-17", timezone: tz, source: .diyanet)
        let now = Date.diyanetDateFormatter.date(from: "2026-03-16")!.combined(time: "23:50", timeZone: tz)!

        let next = service.nextPrayer(from: today, tomorrow: tomorrow, now: now)
        #expect(next?.kind == .imsak)
    }

    @Test func timezoneIsRespectedForNextPrayer() async throws {
        let service = PrayerTimesService(
            router: MockRouter(),
            repository: MockRepository(response: PrayerTimesResponse(snapshot: Self.sampleSnapshot(source: .aladhan, city: "London", countryCode: "GB"), loadState: .loaded, routeReason: .nonTurkey)),
            logger: NoopLogger()
        )

        let tz = TimeZone(identifier: "Europe/London")!
        let snapshot = Self.snapshotForDay("2026-06-01", timezone: tz, source: .aladhan)
        let now = Date.diyanetDateFormatter.date(from: "2026-06-01")!.combined(time: "12:05", timeZone: tz)!

        let next = service.nextPrayer(from: snapshot, tomorrow: nil, now: now)
        #expect(next?.kind == .asr)
    }

    private static func sampleRequest(country: String, city: String) -> PrayerTimesRequest {
        PrayerTimesRequest(
            context: PrayerLocationContext(
                selection: .manualCity,
                city: city,
                district: nil,
                countryCode: country,
                coordinate: CLLocationCoordinate2D(latitude: 41.01, longitude: 28.97),
                timezoneIdentifier: "Europe/Istanbul"
            ),
            calculationMethodID: 2,
            methodLabel: "MWL",
            madhabSchool: 1
        )
    }

    private static func sampleSnapshot(source: PrayerSourceType, city: String, countryCode: String) -> PrayerTimesSnapshot {
        snapshotForDay("2026-03-16", timezone: .current, source: source, city: city, countryCode: countryCode)
    }

    private static func snapshotForDay(
        _ dateString: String,
        timezone: TimeZone,
        source: PrayerSourceType,
        city: String = "City",
        countryCode: String = "TR"
    ) -> PrayerTimesSnapshot {
        let date = Date.diyanetDateFormatter.date(from: dateString)!
        func time(_ hhmm: String) -> Date {
            date.combined(time: hhmm, timeZone: timezone)!
        }

        return PrayerTimesSnapshot(
            date: date,
            hijriDateText: "10 Ramazan",
            gregorianDateText: dateString,
            timezoneIdentifier: timezone.identifier,
            cityName: city,
            districtName: nil,
            countryCode: countryCode,
            sourceType: source,
            sourceDetail: source.rawValue,
            calculationMethod: "Method",
            prayers: [
                .init(kind: .imsak, title: "Imsak", time: time("05:20"), isNext: false, isPassed: false),
                .init(kind: .sunrise, title: "Sunrise", time: time("06:40"), isNext: false, isPassed: false),
                .init(kind: .dhuhr, title: "Dhuhr", time: time("12:30"), isNext: false, isPassed: false),
                .init(kind: .asr, title: "Asr", time: time("15:50"), isNext: false, isPassed: false),
                .init(kind: .maghrib, title: "Maghrib", time: time("18:20"), isNext: false, isPassed: false),
                .init(kind: .isha, title: "Isha", time: time("19:40"), isNext: false, isPassed: false)
            ],
            fetchedAt: Date(),
            isFallback: false,
            isFromCache: false
        )
    }
}

private struct MockCountryResolver: CountryCodeResolving {
    let code: String
    func resolveCountryCode(for coordinate: CLLocationCoordinate2D) async throws -> String { code }
}

private struct NoopLogger: PrayerTimesLogger {
    func log(event: String, metadata: [String : String]) {}
}

private final class MockProvider: PrayerTimesProvider {
    let sourceType: PrayerSourceType
    let result: Result<PrayerTimesSnapshot, PrayerTimesDataError>

    init(source: PrayerSourceType, result: Result<PrayerTimesSnapshot, PrayerTimesDataError>) {
        self.sourceType = source
        self.result = result
    }

    func fetch(request: PrayerTimesRequest, resolvedCountryCode: String, routeReason: PrayerRouteReason) async throws -> PrayerTimesSnapshot {
        switch result {
        case .success(let snapshot): return snapshot
        case .failure(let error): throw error
        }
    }
}

private struct MockRouter: PrayerSourceRouting {
    func route(for request: PrayerTimesRequest) async throws -> PrayerRouteDecision {
        PrayerRouteDecision(primarySource: .aladhan, resolvedCountryCode: request.context.countryCode ?? "DE", routeReason: .nonTurkey)
    }
}

private struct MockRepository: PrayerTimesRepository {
    let response: PrayerTimesResponse
    func load(request: PrayerTimesRequest, route: PrayerRouteDecision) async -> PrayerTimesResponse { response }
}

private extension Date {
    func combined(time: String, timeZone: TimeZone) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var dc = calendar.dateComponents([.year, .month, .day], from: self)
        dc.hour = hour
        dc.minute = minute
        return calendar.date(from: dc)
    }
}
