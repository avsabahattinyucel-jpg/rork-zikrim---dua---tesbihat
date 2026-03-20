import Foundation

protocol PrayerTimesServiceProtocol: Sendable {
    func fetch(request: PrayerTimesRequest) async -> PrayerTimesResponse
    func nextPrayer(
        from today: PrayerTimesSnapshot,
        tomorrow: PrayerTimesSnapshot?,
        now: Date
    ) -> PrayerTimeItem?
}

final class PrayerTimesService: PrayerTimesServiceProtocol {
    private let router: PrayerSourceRouting
    private let repository: PrayerTimesRepository
    private let logger: PrayerTimesLogger

    init(
        router: PrayerSourceRouting,
        repository: PrayerTimesRepository,
        logger: PrayerTimesLogger = PrayerTimesConsoleLogger()
    ) {
        self.router = router
        self.repository = repository
        self.logger = logger
    }

    func fetch(request: PrayerTimesRequest) async -> PrayerTimesResponse {
        do {
            let route = try await router.route(for: request)
            let response = await repository.load(request: request, route: route)
            return markPrayerFlags(snapshot: response.snapshot, state: response.loadState, route: response.routeReason)
        } catch let error as PrayerTimesDataError {
            return PrayerTimesResponse(
                snapshot: PrayerTimesSnapshot(
                    date: request.date,
                    hijriDateText: "",
                    gregorianDateText: "",
                    timezoneIdentifier: request.context.timezoneIdentifier ?? TimeZone.current.identifier,
                    cityName: request.context.city ?? "",
                    districtName: request.context.district,
                    countryCode: request.context.countryCode ?? "",
                    sourceType: .cache,
                    sourceDetail: "",
                    calculationMethod: request.methodLabel,
                    prayers: [],
                    fetchedAt: Date(),
                    isFallback: false,
                    isFromCache: false
                ),
                loadState: .failed(error),
                routeReason: .nonTurkey
            )
        } catch {
            return PrayerTimesResponse(
                snapshot: PrayerTimesSnapshot(
                    date: request.date,
                    hijriDateText: "",
                    gregorianDateText: "",
                    timezoneIdentifier: request.context.timezoneIdentifier ?? TimeZone.current.identifier,
                    cityName: request.context.city ?? "",
                    districtName: request.context.district,
                    countryCode: request.context.countryCode ?? "",
                    sourceType: .cache,
                    sourceDetail: "",
                    calculationMethod: request.methodLabel,
                    prayers: [],
                    fetchedAt: Date(),
                    isFallback: false,
                    isFromCache: false
                ),
                loadState: .failed(.networkFailure),
                routeReason: .nonTurkey
            )
        }
    }

    func nextPrayer(
        from today: PrayerTimesSnapshot,
        tomorrow: PrayerTimesSnapshot?,
        now: Date
    ) -> PrayerTimeItem? {
        let sorted = today.prayers.sorted { $0.time < $1.time }
        for prayer in sorted where prayer.kind != .sunrise {
            if prayer.time > now {
                logger.log(event: "next_prayer_calculation", metadata: ["next": prayer.kind.rawValue, "date": today.gregorianDateText])
                return prayer
            }
        }

        if let tomorrow {
            if let imsak = tomorrow.prayers.first(where: { $0.kind == .imsak }) {
                logger.log(event: "next_prayer_calculation", metadata: ["next": "next_day_imsak", "date": tomorrow.gregorianDateText])
                return imsak
            }
        }

        return nil
    }

    private func markPrayerFlags(
        snapshot: PrayerTimesSnapshot,
        state: PrayerTimesLoadState,
        route: PrayerRouteReason
    ) -> PrayerTimesResponse {
        let now = Date()
        let nextID = snapshot.prayers
            .filter { $0.kind != .sunrise && $0.time > now }
            .sorted { $0.time < $1.time }
            .first?
            .kind

        let mapped = snapshot.prayers.map { item in
            item.withFlags(isNext: item.kind == nextID, isPassed: item.time < now)
        }

        let updated = PrayerTimesSnapshot(
            date: snapshot.date,
            hijriDateText: snapshot.hijriDateText,
            gregorianDateText: snapshot.gregorianDateText,
            timezoneIdentifier: snapshot.timezoneIdentifier,
            cityName: snapshot.cityName,
            districtName: snapshot.districtName,
            countryCode: snapshot.countryCode,
            sourceType: snapshot.sourceType,
            sourceDetail: snapshot.sourceDetail,
            calculationMethod: snapshot.calculationMethod,
            prayers: mapped,
            fetchedAt: snapshot.fetchedAt,
            isFallback: snapshot.isFallback,
            isFromCache: snapshot.isFromCache
        )

        return PrayerTimesResponse(snapshot: updated, loadState: state, routeReason: route)
    }
}

extension PrayerTimesService {
    static func live(
        logger: PrayerTimesLogger = PrayerTimesConsoleLogger()
    ) -> PrayerTimesService {
        let repository = DefaultPrayerTimesRepository(
            diyanetProvider: DiyanetPrayerTimesProvider(logger: logger),
            aladhanProvider: AlAdhanPrayerTimesProvider(logger: logger),
            cacheStore: PrayerTimesHybridCacheStore(),
            logger: logger
        )
        return PrayerTimesService(
            router: PrayerSourceRouter(logger: logger),
            repository: repository,
            logger: logger
        )
    }
}
