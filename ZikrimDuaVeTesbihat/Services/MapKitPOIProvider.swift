import Foundation
@preconcurrency import MapKit
import CoreLocation

struct MapKitPOIProvider: POIDataProvider {
    let source: POISource = .mapKit

    func search(category: POICategory, in region: MKCoordinateRegion, userLocation: CLLocation?) async throws -> [POIItem] {
        var results: [POIItem] = []
        var seen = Set<String>()
        let appLanguage = AppLanguage.current

        for query in category.mapKitQueries(for: appLanguage) {
            try Task.checkCancellation()

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = region
            request.resultTypes = category == .halalFood ? [.pointOfInterest, .address] : .pointOfInterest

            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            for mapItem in response.mapItems {
                guard MapKitPOIQualityRules.isRelevant(mapItem, category: category, in: region) else { continue }

                let item = normalize(
                    mapItem: mapItem,
                    category: category,
                    in: region,
                    userLocation: userLocation
                )

                if seen.insert(dedupKey(for: item)).inserted {
                    results.append(item)
                }
            }
        }

        return results
            .map { $0.withDistance(from: userLocation) }
            .sorted { POIItem.sort(lhs: $0, rhs: $1) }
    }

    private func normalize(
        mapItem: MKMapItem,
        category: POICategory,
        in region: MKCoordinateRegion,
        userLocation: CLLocation?
    ) -> POIItem {
        let coordinate = mapItem.placemark.coordinate
        let addressParts = [
            mapItem.placemark.thoroughfare,
            mapItem.placemark.subLocality,
            mapItem.placemark.locality,
            mapItem.placemark.country
        ]
            .compactMap { $0?.trimmedNilIfEmpty }

        let title = mapItem.name?.trimmedNilIfEmpty ?? category.title
        let subtitle = mapItem.placemark.title?.trimmedNilIfEmpty ?? category.title
        let confidence = MapKitPOIQualityRules.confidenceScore(
            for: mapItem,
            category: category,
            in: region
        )

        return POIItem(
            id: "mapkit-\(coordinate.latitude)-\(coordinate.longitude)-\(title)",
            source: .mapKit,
            category: category,
            name: title,
            localizedName: title,
            coordinate: coordinate,
            address: addressParts.joined(separator: ", ").trimmedNilIfEmpty,
            distanceMeters: resolvedDistance(from: userLocation, to: coordinate),
            subtitle: subtitle,
            confidence: confidence,
            metadata: POIMetadata(
                osmTags: [:],
                rawSourceID: nil,
                rawDisplayName: mapItem.name?.trimmedNilIfEmpty
            ),
            mapItem: mapItem
        )
    }

    private func dedupKey(for item: POIItem) -> String {
        "\(item.canonicalName)-\(String(format: "%.4f", item.coordinate.latitude))-\(String(format: "%.4f", item.coordinate.longitude))"
    }

    private func resolvedDistance(from userLocation: CLLocation?, to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let userLocation else { return nil }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: userLocation)
    }
}

enum MapKitPOIQualityRules {
    static func isRelevant(_ mapItem: MKMapItem, category: POICategory, in region: MKCoordinateRegion) -> Bool {
        let title = mapItem.name?.normalizedForSearch ?? ""
        let placemarkText = [
            mapItem.placemark.title,
            mapItem.placemark.thoroughfare,
            mapItem.placemark.locality,
            mapItem.placemark.country
        ]
        .compactMap { $0?.normalizedForSearch }
        .joined(separator: " ")

        let combined = "\(title) \(placemarkText)"
        let regionRadius = region.approximateRadiusMeters
        let distanceToCenter = mapItem.placemark.coordinate.distance(
            to: region.center
        )

        guard distanceToCenter <= max(1_500, regionRadius * 2.2) else { return false }

        switch category {
        case .mosques:
            let mosqueSignal = combined.containsAny(of: mosqueKeywords)
            let likelyMismatch = isLikelyMismatchedMosque(
                nameText: title,
                contextText: placemarkText,
                distanceFromRegionCenter: distanceToCenter,
                regionRadiusMeters: regionRadius
            )
            return mosqueSignal && !likelyMismatch

        case .shrines:
            return combined.containsAny(of: shrineKeywords)

        case .historicalPlaces:
            return combined.containsAny(of: historicalKeywords)

        case .halalFood:
            let hasHalalSignal = combined.containsAny(of: halalKeywords)
            if hasHalalSignal {
                return true
            }
            return distanceToCenter <= max(1_000, regionRadius * 1.2)
        }
    }

    static func isLikelyMismatchedMosque(
        nameText: String,
        contextText: String,
        distanceFromRegionCenter: CLLocationDistance,
        regionRadiusMeters: CLLocationDistance
    ) -> Bool {
        let combined = "\(nameText) \(contextText)"
        let genericTourismSignal = combined.containsAny(of: touristicKeywords)
        let hasIslamicSignal = combined.containsAny(of: mosqueKeywords)
        let tooFarForSmallViewport = distanceFromRegionCenter > max(1_800, regionRadiusMeters * 1.1)
        return genericTourismSignal && !hasIslamicSignal && tooFarForSmallViewport
    }

    static func confidenceScore(for mapItem: MKMapItem, category: POICategory, in region: MKCoordinateRegion) -> Double {
        let title = mapItem.name?.normalizedForSearch ?? ""
        let placemarkText = [
            mapItem.placemark.title,
            mapItem.placemark.thoroughfare,
            mapItem.placemark.locality,
            mapItem.placemark.country
        ]
        .compactMap { $0?.normalizedForSearch }
        .joined(separator: " ")
        let combined = "\(title) \(placemarkText)"
        let distance = mapItem.placemark.coordinate.distance(to: region.center)
        let regionRadius = region.approximateRadiusMeters

        var score = 0.52
        if mapItem.name?.trimmedNilIfEmpty != nil {
            score += 0.20
        } else {
            score -= 0.22
        }
        if mapItem.placemark.title?.trimmedNilIfEmpty != nil {
            score += 0.10
        }
        if mapItem.pointOfInterestCategory != nil {
            score += 0.08
        }
        if mapItem.url != nil || mapItem.phoneNumber != nil {
            score += 0.05
        }

        switch category {
        case .mosques:
            if combined.containsAny(of: mosqueKeywords) {
                score += 0.14
            } else {
                score -= 0.30
            }
        case .shrines:
            if combined.containsAny(of: shrineKeywords) {
                score += 0.10
            }
        case .historicalPlaces:
            if combined.containsAny(of: historicalKeywords) {
                score += 0.08
            }
        case .halalFood:
            if combined.containsAny(of: halalKeywords) {
                score += 0.12
            } else {
                score -= 0.08
            }
        }

        if distance > max(2_400, regionRadius * 1.4) {
            score -= 0.22
        }

        return min(max(score, 0.05), 0.98)
    }

    private static let mosqueKeywords = [
        "mosque", "masjid", "cami", "camii", "mescid", "mescit", "jami", "musalla"
    ]

    private static let shrineKeywords = [
        "tomb", "turbe", "türbe", "shrine", "mausoleum"
    ]

    private static let historicalKeywords = [
        "historic", "historical", "heritage", "castle", "ruins", "monument", "memorial", "archaeological",
        "museum", "müze", "palace", "saray", "fort", "kale", "old town", "site", "ören",
        "tower", "kule", "sarnic", "sarnıç", "bazilika", "basilica"
    ]

    private static let halalKeywords = [
        "halal", "helal"
    ]

    private static let touristicKeywords = [
        "museum", "tour", "ticket", "bazaar", "market"
    ]
}

private extension MKCoordinateRegion {
    var approximateRadiusMeters: CLLocationDistance {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let northEdge = CLLocation(latitude: center.latitude + (span.latitudeDelta / 2), longitude: center.longitude)
        let eastEdge = CLLocation(latitude: center.latitude, longitude: center.longitude + (span.longitudeDelta / 2))
        return max(centerLocation.distance(from: northEdge), centerLocation.distance(from: eastEdge))
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var normalizedForSearch: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    func containsAny(of terms: [String]) -> Bool {
        terms.contains { contains($0) }
    }
}
