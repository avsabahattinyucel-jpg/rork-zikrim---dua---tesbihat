import Foundation
@preconcurrency import MapKit
import CoreLocation

struct POISearchService: Sendable {
    private let repository: POIRepository
    private let cache: POIViewportCache

    init(
        mapKitProvider: MapKitPOIProvider = MapKitPOIProvider(),
        osmProvider: OSMPOIProvider = OSMPOIProvider(),
        cache: POIViewportCache = POIViewportCache(),
        deduplicationService: POIDeduplicationService = POIDeduplicationService(),
        rankingService: POIRankingService = POIRankingService()
    ) {
        self.repository = POIRepository(
            mapKitProvider: mapKitProvider,
            osmProvider: osmProvider,
            deduplicationService: deduplicationService,
            rankingService: rankingService
        )
        self.cache = cache
    }

    func search(categories: Set<POICategory>, in region: MKCoordinateRegion, userLocation: CLLocation?) async throws -> [POIItem] {
        let sortedCategories = categories.sorted { $0.rawValue < $1.rawValue }

        let outcomes = await withTaskGroup(of: CategorySearchOutcome.self) { group in
            for category in sortedCategories {
                group.addTask {
                    do {
                        let items = try await search(category: category, in: region, userLocation: userLocation)
                        return CategorySearchOutcome(items: items, didFail: false)
                    } catch {
                        return CategorySearchOutcome(items: [], didFail: true)
                    }
                }
            }

            var collected: [CategorySearchOutcome] = []
            for await outcome in group {
                collected.append(outcome)
            }
            return collected
        }

        let mergedItems = outcomes.flatMap(\.items)
        if !mergedItems.isEmpty {
            return mergedItems.sorted { POIItem.sort(lhs: $0, rhs: $1) }
        }

        if outcomes.contains(where: { !$0.didFail }) {
            return []
        }

        throw URLError(.cannotLoadFromNetwork)
    }

    private func search(category: POICategory, in region: MKCoordinateRegion, userLocation: CLLocation?) async throws -> [POIItem] {
        let key = POIViewportCacheKey(region: region, category: category)
        if let cached = await cache.value(for: key) {
            debugLog("category=\(category.rawValue) provider=cache result_count=\(cached.count)")
            return cached
        }

        let result = try await repository.fetch(category: category, in: region, userLocation: userLocation)
        if !result.items.isEmpty {
            await cache.set(result.items, for: key)
        }

        debugLog("category=\(category.rawValue) primary=\(result.primaryProvider.rawValue) fallback=\(result.fallbackProvider?.rawValue ?? "none") fallback_attempted=\(result.fallbackAttempted) fallback_used=\(result.usedFallback) fallback_count=\(result.fallbackCount) raw_count=\(result.rawCount) normalized_count=\(result.normalizedCount) deduped_count=\(result.dedupedCount) displayed_count=\(result.items.count)")
        return result.items
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[ExploreFetch] \(message)")
        #endif
    }
}

private struct CategorySearchOutcome: Sendable {
    let items: [POIItem]
    let didFail: Bool
}

struct POIRepository: Sendable {
    private let mapKitProvider: MapKitPOIProvider
    private let osmProvider: OSMPOIProvider
    private let deduplicationService: POIDeduplicationService
    private let rankingService: POIRankingService

    init(
        mapKitProvider: MapKitPOIProvider,
        osmProvider: OSMPOIProvider,
        deduplicationService: POIDeduplicationService,
        rankingService: POIRankingService
    ) {
        self.mapKitProvider = mapKitProvider
        self.osmProvider = osmProvider
        self.deduplicationService = deduplicationService
        self.rankingService = rankingService
    }

    func fetch(category: POICategory, in region: MKCoordinateRegion, userLocation: CLLocation?) async throws -> POIRepositoryResult {
        let strategy = POISourceStrategy.forCategory(category)
        var primaryItems: [POIItem] = []
        var primaryError: Error?
        do {
            primaryItems = try await fetchItems(from: strategy.primary, category: category, in: region, userLocation: userLocation)
        } catch {
            primaryError = error
        }

        let primaryPreparedItems = rankingService.rank(
            deduplicationService.merge(primaryItems, userLocation: userLocation),
            category: category,
            in: region,
            userLocation: userLocation
        )

        var fallbackAttempted = false
        var fallbackItems: [POIItem] = []
        var fallbackError: Error?
        let shouldAttemptFallback = (primaryError != nil) || (primaryPreparedItems.count < strategy.fallbackThreshold)
        if let fallback = strategy.fallback, shouldAttemptFallback {
            fallbackAttempted = true
            do {
                fallbackItems = try await fetchItems(from: fallback, category: category, in: region, userLocation: userLocation)
            } catch {
                fallbackError = error
            }
        }

        if primaryItems.isEmpty, fallbackItems.isEmpty, let primaryError {
            throw fallbackError ?? primaryError
        }

        let rawCount = primaryItems.count + fallbackItems.count
        let normalizedItems = primaryItems + fallbackItems
        let dedupedItems = deduplicationService.merge(normalizedItems, userLocation: userLocation)
        let rankedItems = rankingService.rank(
            dedupedItems,
            category: category,
            in: region,
            userLocation: userLocation
        )

        return POIRepositoryResult(
            items: rankedItems,
            primaryProvider: strategy.primary,
            fallbackProvider: strategy.fallback,
            fallbackAttempted: fallbackAttempted,
            usedFallback: !fallbackItems.isEmpty,
            fallbackCount: fallbackItems.count,
            rawCount: rawCount,
            normalizedCount: normalizedItems.count,
            dedupedCount: dedupedItems.count
        )
    }

    private func fetchItems(
        from source: POISource,
        category: POICategory,
        in region: MKCoordinateRegion,
        userLocation: CLLocation?
    ) async throws -> [POIItem] {
        switch source {
        case .mapKit:
            return try await mapKitProvider.search(category: category, in: region, userLocation: userLocation)
        case .osm:
            return try await osmProvider.search(category: category, in: region, userLocation: userLocation)
        case .merged:
            return []
        }
    }
}

struct POIRepositoryResult: Sendable {
    let items: [POIItem]
    let primaryProvider: POISource
    let fallbackProvider: POISource?
    let fallbackAttempted: Bool
    let usedFallback: Bool
    let fallbackCount: Int
    let rawCount: Int
    let normalizedCount: Int
    let dedupedCount: Int
}

private struct POISourceStrategy {
    let primary: POISource
    let fallback: POISource?
    let fallbackThreshold: Int

    static func forCategory(_ category: POICategory) -> POISourceStrategy {
        switch category {
        case .mosques:
            return POISourceStrategy(primary: .osm, fallback: .mapKit, fallbackThreshold: 8)
        case .shrines:
            return POISourceStrategy(primary: .osm, fallback: .mapKit, fallbackThreshold: 4)
        case .historicalPlaces:
            return POISourceStrategy(primary: .osm, fallback: .mapKit, fallbackThreshold: 16)
        case .halalFood:
            return POISourceStrategy(primary: .mapKit, fallback: .osm, fallbackThreshold: 10)
        }
    }
}

actor POIViewportCache {
    private struct Entry: Sendable {
        let items: [POIItem]
        let expiry: Date
    }

    private var storage: [POIViewportCacheKey: Entry] = [:]
    private let ttl: TimeInterval = 15 * 60

    func value(for key: POIViewportCacheKey) -> [POIItem]? {
        guard let entry = storage[key] else { return nil }
        guard entry.expiry > Date() else {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.items
    }

    func set(_ items: [POIItem], for key: POIViewportCacheKey) {
        storage[key] = Entry(items: items, expiry: Date().addingTimeInterval(ttl))
    }
}

struct POIDeduplicationService: Sendable {
    func merge(_ items: [POIItem], userLocation: CLLocation?) -> [POIItem] {
        guard !items.isEmpty else { return [] }

        var merged: [POIItem] = []
        var consumed = Set<Int>()

        for (index, item) in items.enumerated() {
            guard !consumed.contains(index) else { continue }

            var candidate = item.withDistance(from: userLocation)
            consumed.insert(index)

            for (otherIndex, other) in items.enumerated() where otherIndex != index && !consumed.contains(otherIndex) {
                guard isDuplicate(candidate, other) else { continue }
                candidate = candidate.merged(with: other, userLocation: userLocation)
                consumed.insert(otherIndex)
            }

            merged.append(candidate.withDistance(from: userLocation))
        }

        return merged.sorted { POIItem.sort(lhs: $0, rhs: $1) }
    }

    private func isDuplicate(_ lhs: POIItem, _ rhs: POIItem) -> Bool {
        guard lhs.category == rhs.category else { return false }

        let coordinateDistance = lhs.coordinate.distance(to: rhs.coordinate)
        guard coordinateDistance <= 80 else { return false }

        let nameSimilarity = NameSimilarity.score(lhs.canonicalName, rhs.canonicalName)
        let addressSimilarity = NameSimilarity.score(lhs.addressComparable, rhs.addressComparable)

        if nameSimilarity >= 0.82 {
            return true
        }
        if nameSimilarity >= 0.72 && addressSimilarity >= 0.56 {
            return true
        }
        return addressSimilarity >= 0.90
    }
}

struct POIRankingService: Sendable {
    private let evaluator = POIConfidenceEvaluator()

    func rank(
        _ items: [POIItem],
        category: POICategory,
        in region: MKCoordinateRegion,
        userLocation: CLLocation?
    ) -> [POIItem] {
        items
            .map { item in
                item
                    .withDistance(from: userLocation)
                    .withConfidence(evaluator.evaluate(item, category: category, in: region))
            }
            .filter { shouldDisplay($0, category: category) }
            .sorted { POIItem.sort(lhs: $0, rhs: $1) }
    }

    private func shouldDisplay(_ item: POIItem, category: POICategory) -> Bool {
        switch category {
        case .mosques:
            return item.confidence >= 0.36
        case .shrines:
            return item.confidence >= 0.24
        case .historicalPlaces:
            return item.confidence >= 0.18
        case .halalFood:
            return item.confidence >= 0.24
        }
    }
}

private struct POIConfidenceEvaluator: Sendable {
    func evaluate(_ item: POIItem, category: POICategory, in region: MKCoordinateRegion) -> Double {
        var score = item.confidence
        let normalizedName = item.displayName.normalizedForMatching
        let normalizedContext = [
            item.subtitle?.normalizedForMatching,
            item.address?.normalizedForMatching
        ]
            .compactMap { $0 }
            .joined(separator: " ")
        let mergedText = "\(normalizedName) \(normalizedContext)"

        if item.displayName.count < 2 {
            score -= 0.30
        }
        if item.address?.isEmpty != false {
            score -= 0.03
        }
        if item.source == .merged {
            score += 0.06
        }

        if let queryID = item.metadata.osmTags["zikrim:query_id"] {
            if queryID.contains("name_hint") {
                score -= 0.16
            } else if queryID == "historical_curated" {
                score += 0.08
            } else if queryID == "historical_generic" {
                score -= 0.08
            }
        }

        let centerDistance = item.coordinate.distance(to: region.center)
        if centerDistance > max(2_500, region.approximateRadiusMeters * 1.6) {
            score -= 0.20
        }

        switch category {
        case .mosques:
            if mergedText.containsAny(of: mosqueTerms) {
                score += 0.08
            } else {
                score -= 0.35
            }
        case .shrines:
            if mergedText.containsAny(of: shrineTerms) {
                score += 0.05
            }
        case .historicalPlaces:
            if mergedText.containsAny(of: historicalTerms) {
                score += 0.04
            }
        case .halalFood:
            if mergedText.containsAny(of: halalTerms) {
                score += 0.07
            } else if item.source == .mapKit {
                score -= 0.12
            }
        }

        return min(max(score, 0.0), 0.99)
    }

    private let mosqueTerms = ["mosque", "cami", "camii", "masjid", "mescit", "mescid"]
    private let shrineTerms = ["turbe", "türbe", "tomb", "shrine", "mausoleum"]
    private let historicalTerms = [
        "historic", "historical", "heritage", "castle", "ruins", "monument", "memorial",
        "museum", "müze", "palace", "saray", "kale", "fort", "site", "ören",
        "tower", "kule", "sarnic", "sarnıç", "bazilika", "basilica"
    ]
    private let halalTerms = ["halal", "helal"]
}

private enum NameSimilarity {
    static func score(_ lhs: String, _ rhs: String) -> Double {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        if lhs == rhs { return 1 }

        let lhsBigrams = bigrams(for: lhs)
        let rhsBigrams = bigrams(for: rhs)
        guard !lhsBigrams.isEmpty, !rhsBigrams.isEmpty else { return 0 }

        let intersectionCount = lhsBigrams.intersection(rhsBigrams).count
        return (2.0 * Double(intersectionCount)) / Double(lhsBigrams.count + rhsBigrams.count)
    }

    private static func bigrams(for string: String) -> Set<String> {
        let characters = Array(string)
        guard characters.count > 1 else { return [string] }

        return Set((0..<(characters.count - 1)).map { index in
            String(characters[index...index + 1])
        })
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}

private extension MKCoordinateRegion {
    var approximateRadiusMeters: CLLocationDistance {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let northEdge = CLLocation(latitude: center.latitude + (span.latitudeDelta / 2), longitude: center.longitude)
        let eastEdge = CLLocation(latitude: center.latitude, longitude: center.longitude + (span.longitudeDelta / 2))
        return max(centerLocation.distance(from: northEdge), centerLocation.distance(from: eastEdge))
    }
}

private extension String {
    var normalizedForMatching: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    func containsAny(of terms: [String]) -> Bool {
        terms.contains { contains($0) }
    }
}
