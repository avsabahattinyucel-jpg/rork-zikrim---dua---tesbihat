import Foundation
import CoreLocation

protocol CountryCodeResolving: Sendable {
    func resolveCountryCode(for coordinate: CLLocationCoordinate2D) async throws -> String
}

struct ReverseGeocodingCountryResolver: CountryCodeResolving {
    func resolveCountryCode(for coordinate: CLLocationCoordinate2D) async throws -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let code = placemarks.first?.isoCountryCode?.uppercased() else {
            throw PrayerTimesDataError.reverseGeocodingFailed
        }
        return code
    }
}

struct PrayerRouteDecision: Sendable, Equatable {
    let primarySource: PrayerSourceType
    let resolvedCountryCode: String
    let routeReason: PrayerRouteReason

    var isTurkey: Bool { resolvedCountryCode == "TR" }
}

protocol PrayerSourceRouting: Sendable {
    func route(for request: PrayerTimesRequest) async throws -> PrayerRouteDecision
}

struct PrayerSourceRouter: PrayerSourceRouting {
    private let countryResolver: CountryCodeResolving
    private let logger: PrayerTimesLogger

    init(
        countryResolver: CountryCodeResolving = ReverseGeocodingCountryResolver(),
        logger: PrayerTimesLogger = PrayerTimesConsoleLogger()
    ) {
        self.countryResolver = countryResolver
        self.logger = logger
    }

    func route(for request: PrayerTimesRequest) async throws -> PrayerRouteDecision {
        let code: String

        if let explicitCode = request.context.countryCode?.uppercased(), !explicitCode.isEmpty {
            code = explicitCode
        } else if request.context.selection == .manualCity {
            throw PrayerTimesDataError.locationUnavailable
        } else if let coordinate = request.context.coordinate {
            code = try await countryResolver.resolveCountryCode(for: coordinate)
        } else {
            throw PrayerTimesDataError.locationUnavailable
        }

        let reason: PrayerRouteReason = code == "TR" ? .turkey : .nonTurkey
        let source: PrayerSourceType = code == "TR" ? .diyanet : .aladhan

        logger.log(
            event: "source_routing",
            metadata: [
                "selected_source": source.rawValue,
                "route_reason": reason.rawValue,
                "country_code": code,
                "selection": request.context.selection == .manualCity ? "manual" : "automatic"
            ]
        )

        return PrayerRouteDecision(primarySource: source, resolvedCountryCode: code, routeReason: reason)
    }
}
