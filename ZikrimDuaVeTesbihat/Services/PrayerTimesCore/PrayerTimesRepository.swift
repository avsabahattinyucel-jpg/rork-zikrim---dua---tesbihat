import Foundation

protocol PrayerTimesRepository: Sendable {
    func load(
        request: PrayerTimesRequest,
        route: PrayerRouteDecision
    ) async -> PrayerTimesResponse
}

final class DefaultPrayerTimesRepository: PrayerTimesRepository {
    private let diyanetProvider: PrayerTimesProvider
    private let aladhanProvider: PrayerTimesProvider
    private let cacheStore: PrayerTimesCacheStore
    private let logger: PrayerTimesLogger

    init(
        diyanetProvider: PrayerTimesProvider,
        aladhanProvider: PrayerTimesProvider,
        cacheStore: PrayerTimesCacheStore,
        logger: PrayerTimesLogger = PrayerTimesConsoleLogger()
    ) {
        self.diyanetProvider = diyanetProvider
        self.aladhanProvider = aladhanProvider
        self.cacheStore = cacheStore
        self.logger = logger
    }

    func load(
        request: PrayerTimesRequest,
        route: PrayerRouteDecision
    ) async -> PrayerTimesResponse {
        let primary = route.primarySource == .diyanet ? diyanetProvider : aladhanProvider

        switch route.primarySource {
        case .diyanet:
            return await loadForTurkey(request: request, route: route, provider: primary)
        case .aladhan:
            return await loadForNonTurkey(request: request, route: route, provider: primary)
        default:
            return await loadForNonTurkey(request: request, route: route, provider: aladhanProvider)
        }
    }

    private func loadForTurkey(
        request: PrayerTimesRequest,
        route: PrayerRouteDecision,
        provider: PrayerTimesProvider
    ) async -> PrayerTimesResponse {
        let diyanetKey = makeKey(request: request, source: .diyanet, countryCode: route.resolvedCountryCode)

        do {
            let live = try await provider.fetch(request: request, resolvedCountryCode: route.resolvedCountryCode, routeReason: route.routeReason)
            await cacheStore.write(snapshot: live, key: diyanetKey, now: Date())
            logger.log(event: "selected_source", metadata: ["selected_source": "diyanet", "route_reason": "turkey"]) 
            return PrayerTimesResponse(snapshot: live, loadState: .loaded, routeReason: .turkey)
        } catch {
            logger.log(event: "parse_failure", metadata: ["source": "diyanet", "reason": String(describing: error)])
        }

        if let diyanetCache = await cacheStore.read(key: diyanetKey, now: Date()) {
            logger.log(event: "cache_hit", metadata: ["source": "diyanet"])
            return PrayerTimesResponse(
                snapshot: diyanetCache.markCache(isFromCache: true, isFallback: true, sourceType: .cache),
                loadState: .stale,
                routeReason: .fallbackAfterFailure
            )
        }
        logger.log(event: "cache_miss", metadata: ["source": "diyanet"])

        let fallbackKey = makeKey(request: request, source: .fallback, countryCode: route.resolvedCountryCode)
        do {
            let fallback = try await aladhanProvider.fetch(
                request: request,
                resolvedCountryCode: route.resolvedCountryCode,
                routeReason: .fallbackAfterFailure
            )
            let marked = fallback.markCache(isFromCache: false, isFallback: true, sourceType: .fallback)
            await cacheStore.write(snapshot: marked, key: fallbackKey, now: Date())
            logger.log(event: "selected_source", metadata: ["selected_source": "fallback", "route_reason": "fallback_after_failure"])
            return PrayerTimesResponse(snapshot: marked, loadState: .fallback, routeReason: .fallbackAfterFailure)
        } catch {
            if let cachedFallback = await cacheStore.read(key: fallbackKey, now: Date()) {
                logger.log(event: "cache_hit", metadata: ["source": "fallback"]) 
                return PrayerTimesResponse(
                    snapshot: cachedFallback.markCache(isFromCache: true, isFallback: true, sourceType: .fallback),
                    loadState: .stale,
                    routeReason: .fallbackAfterFailure
                )
            }

            let fail = PrayerTimesDataError.noPrayerTimesForSelectedLocation
            return PrayerTimesResponse(
                snapshot: Self.emptySnapshot(request: request, countryCode: route.resolvedCountryCode),
                loadState: .failed(fail),
                routeReason: .fallbackAfterFailure
            )
        }
    }

    private func loadForNonTurkey(
        request: PrayerTimesRequest,
        route: PrayerRouteDecision,
        provider: PrayerTimesProvider
    ) async -> PrayerTimesResponse {
        let key = makeKey(request: request, source: .aladhan, countryCode: route.resolvedCountryCode)

        do {
            let live = try await provider.fetch(request: request, resolvedCountryCode: route.resolvedCountryCode, routeReason: route.routeReason)
            await cacheStore.write(snapshot: live, key: key, now: Date())
            logger.log(event: "selected_source", metadata: ["selected_source": "aladhan", "route_reason": "non_turkey"])
            return PrayerTimesResponse(snapshot: live, loadState: .loaded, routeReason: .nonTurkey)
        } catch {
            logger.log(event: "cache_miss", metadata: ["source": "aladhan", "reason": String(describing: error)])
            if let cached = await cacheStore.read(key: key, now: Date()) {
                logger.log(event: "cache_hit", metadata: ["source": "aladhan"])
                return PrayerTimesResponse(snapshot: cached, loadState: .stale, routeReason: .nonTurkey)
            }
            let fail = (error as? PrayerTimesDataError) ?? .networkFailure
            return PrayerTimesResponse(
                snapshot: Self.emptySnapshot(request: request, countryCode: route.resolvedCountryCode),
                loadState: .failed(fail),
                routeReason: .nonTurkey
            )
        }
    }

    private func makeKey(request: PrayerTimesRequest, source: PrayerSourceType, countryCode: String) -> PrayerTimesCacheKey {
        PrayerTimesCacheKey(
            source: source,
            countryCode: countryCode,
            city: request.context.city,
            district: request.context.district,
            coordinate: request.context.coordinate,
            date: request.date,
            method: request.methodLabel
        )
    }

    private static func emptySnapshot(request: PrayerTimesRequest, countryCode: String) -> PrayerTimesSnapshot {
        PrayerTimesSnapshot(
            date: request.date,
            hijriDateText: "",
            gregorianDateText: "",
            timezoneIdentifier: request.context.timezoneIdentifier ?? TimeZone.current.identifier,
            cityName: request.context.city ?? "",
            districtName: request.context.district,
            countryCode: countryCode,
            sourceType: .cache,
            sourceDetail: "",
            calculationMethod: request.methodLabel,
            prayers: [],
            fetchedAt: Date(),
            isFallback: false,
            isFromCache: false
        )
    }
}
