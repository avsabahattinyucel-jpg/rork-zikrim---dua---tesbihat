import Foundation
@preconcurrency import MapKit
import CoreLocation

protocol OverpassQueryBuilding {
    func queries(for category: POICategory, bbox: String) -> [String]
}

struct OverpassQueryBuilder: OverpassQueryBuilding, Sendable {
    func queries(for category: POICategory, bbox: String) -> [String] {
        primaryPlans(for: category, bbox: bbox, region: nil).map(\.query)
    }

    fileprivate func primaryPlans(for category: POICategory, bbox: String, region: MKCoordinateRegion?) -> [OverpassQueryPlan] {
        let isWideRegion: Bool
        if let region {
            isWideRegion = region.span.latitudeDelta > 0.9 || region.span.longitudeDelta > 0.9
        } else {
            isWideRegion = false
        }
        switch category {
        case .mosques:
            var plans = [renderedPlan(.mosquesPrimary, bbox: bbox)]
            if !isWideRegion {
                plans.append(renderedPlan(.mosquesSecondaryNameHint, bbox: bbox))
            }
            return plans

        case .shrines:
            var plans = [
                renderedPlan(.shrinesPrimary, bbox: bbox),
                renderedPlan(.shrinesSecondaryBuildingShrine, bbox: bbox)
            ]
            if !isWideRegion {
                plans.append(renderedPlan(.shrinesNameHint, bbox: bbox))
            }
            return plans

        case .historicalPlaces:
            return [renderedPlan(.historicalCurated, bbox: bbox, resultLimit: 120)]

        case .halalFood:
            var plans = [
                renderedPlan(.halalFoodFallback, bbox: bbox),
                renderedPlan(.halalFoodSecondaryHalalTag, bbox: bbox)
            ]
            if !isWideRegion {
                plans.append(renderedPlan(.halalFoodNameHint, bbox: bbox))
            }
            return plans
        }
    }

    fileprivate func fallbackPlans(for category: POICategory, bbox: String) -> [OverpassQueryPlan] {
        switch category {
        case .historicalPlaces:
            return [renderedPlan(.historicalGeneric, bbox: bbox, resultLimit: 90)]
        default:
            return []
        }
    }

    private func renderedPlan(_ template: OverpassQueryTemplate, bbox: String, resultLimit: Int? = nil) -> OverpassQueryPlan {
        OverpassQueryPlan(
            id: template.id,
            category: template.category,
            query: template.query.replacingOccurrences(of: "{bbox}", with: bbox),
            matchQuality: template.matchQuality,
            resultLimit: resultLimit,
            requiresName: template.requiresName
        )
    }

}

private struct OverpassQueryPlan: Sendable {
    let id: String
    let category: POICategory
    let query: String
    let matchQuality: OverpassMatchQuality
    let resultLimit: Int?
    let requiresName: Bool
}

private enum OverpassMatchQuality: String, Sendable {
    case high
    case medium
    case low

    var baseScore: Double {
        switch self {
        case .high:
            return 0.76
        case .medium:
            return 0.58
        case .low:
            return 0.34
        }
    }
}

private enum OverpassQueryTemplate {
    case mosquesPrimary
    case mosquesSecondaryNameHint
    case shrinesPrimary
    case shrinesSecondaryBuildingShrine
    case shrinesNameHint
    case historicalCurated
    case historicalGeneric
    case halalFoodFallback
    case halalFoodSecondaryHalalTag
    case halalFoodNameHint

    var id: String {
        switch self {
        case .mosquesPrimary: return "mosques_primary"
        case .mosquesSecondaryNameHint: return "mosques_secondary_name_hint"
        case .shrinesPrimary: return "shrines_primary"
        case .shrinesSecondaryBuildingShrine: return "shrines_secondary_building_shrine"
        case .shrinesNameHint: return "shrines_name_hint"
        case .historicalCurated: return "historical_curated"
        case .historicalGeneric: return "historical_generic"
        case .halalFoodFallback: return "halal_food_fallback"
        case .halalFoodSecondaryHalalTag: return "halal_food_secondary_halal_tag"
        case .halalFoodNameHint: return "halal_food_name_hint"
        }
    }

    var category: POICategory {
        switch self {
        case .mosquesPrimary, .mosquesSecondaryNameHint:
            return .mosques
        case .shrinesPrimary, .shrinesSecondaryBuildingShrine, .shrinesNameHint:
            return .shrines
        case .historicalCurated, .historicalGeneric:
            return .historicalPlaces
        case .halalFoodFallback, .halalFoodSecondaryHalalTag, .halalFoodNameHint:
            return .halalFood
        }
    }

    var matchQuality: OverpassMatchQuality {
        switch self {
        case .mosquesPrimary, .shrinesPrimary, .historicalCurated, .halalFoodFallback:
            return .high
        case .shrinesSecondaryBuildingShrine, .historicalGeneric, .halalFoodSecondaryHalalTag:
            return .medium
        case .mosquesSecondaryNameHint, .shrinesNameHint, .halalFoodNameHint:
            return .low
        }
    }

    var requiresName: Bool {
        switch self {
        case .mosquesSecondaryNameHint, .shrinesNameHint, .halalFoodNameHint:
            return true
        default:
            return false
        }
    }

    var query: String {
        switch self {
        case .mosquesPrimary:
            return Self.makeQuery([
                Self.block(filters: #"[\"amenity\"=\"place_of_worship\"][\"religion\"=\"muslim\"]"#)
            ])
        case .mosquesSecondaryNameHint:
            return Self.makeQuery([
                Self.block(filters: #"[\"name\"~\"(?i)mosque|cami|camii|masjid|mesjid\"]"#)
            ])
        case .shrinesPrimary:
            return Self.makeQuery([
                Self.block(filters: #"[\"historic\"=\"tomb\"]"#)
            ])
        case .shrinesSecondaryBuildingShrine:
            return Self.makeQuery([
                Self.block(filters: #"[\"building\"=\"shrine\"]"#)
            ])
        case .shrinesNameHint:
            return Self.makeQuery([
                Self.block(filters: #"[\"name\"~\"(?i)türbe|turbe|shrine|tomb\"]"#)
            ])
        case .historicalCurated:
            return Self.makeQuery([
                Self.block(filters: #"[\"historic\"~\"^(monument|memorial|castle|archaeological_site|tomb|ruins)$\"]"#)
            ])
        case .historicalGeneric:
            return Self.makeQuery([
                Self.block(filters: #"[\"historic\"]"#)
            ])
        case .halalFoodFallback:
            return Self.makeQuery([
                Self.block(filters: #"[\"amenity\"=\"restaurant\"][\"diet:halal\"=\"yes\"]"#),
                Self.block(filters: #"[\"amenity\"=\"fast_food\"][\"diet:halal\"=\"yes\"]"#),
                Self.block(filters: #"[\"amenity\"=\"cafe\"][\"diet:halal\"=\"yes\"]"#)
            ])
        case .halalFoodSecondaryHalalTag:
            return Self.makeQuery([
                Self.block(filters: #"[\"amenity\"~\"^(restaurant|fast_food|cafe)$\"][\"halal\"=\"yes\"]"#),
                Self.block(filters: #"[\"amenity\"~\"^(restaurant|fast_food|cafe)$\"][\"diet:halal\"=\"only\"]"#)
            ])
        case .halalFoodNameHint:
            return Self.makeQuery([
                Self.block(filters: #"[\"amenity\"~\"^(restaurant|fast_food|cafe)$\"][\"name\"~\"(?i)halal|helal\"]"#)
            ])
        }
    }

    private static func makeQuery(_ blocks: [String]) -> String {
        """
        [out:json][timeout:25];
        (
        \(blocks.joined(separator: "\n"))
        );
        out center tags;
        """
    }

    private static func block(filters: String) -> String {
        """
          node\(filters)({bbox});
          way\(filters)({bbox});
          relation\(filters)({bbox});
        """
    }
}

struct OSMPOIProvider: POIDataProvider {
    let source: POISource = .osm

    private let session: URLSession
    private let endpoint = URL(string: "https://overpass-api.de/api/interpreter")!
    private let queryBuilder: OverpassQueryBuilder
    private let filtersUnnamedResults: Bool

    init(
        session: URLSession = .shared,
        queryBuilder: OverpassQueryBuilder = OverpassQueryBuilder(),
        filtersUnnamedResults: Bool = false
    ) {
        self.session = session
        self.queryBuilder = queryBuilder
        self.filtersUnnamedResults = filtersUnnamedResults
    }

    func search(category: POICategory, in region: MKCoordinateRegion, userLocation: CLLocation?) async throws -> [POIItem] {
        guard let bbox = boundingBox(for: region) else { return [] }

        var plans = queryBuilder.primaryPlans(for: category, bbox: bbox, region: region)
        var items = try await execute(plans: plans, userLocation: userLocation)

        if category == .historicalPlaces, items.count < 10 {
            let fallbackPlans = queryBuilder.fallbackPlans(for: category, bbox: bbox)
            plans = fallbackPlans
            let fallbackItems = try await execute(plans: plans, userLocation: userLocation)
            items = mergeOSMItems(items, fallbackItems, userLocation: userLocation)
        }

        return items
            .map { $0.withDistance(from: userLocation) }
            .sorted { POIItem.sort(lhs: $0, rhs: $1) }
    }

    private func execute(plans: [OverpassQueryPlan], userLocation: CLLocation?) async throws -> [POIItem] {
        guard !plans.isEmpty else { return [] }

        var deduped: [String: POIItem] = [:]
        for plan in plans {
            try Task.checkCancellation()
            let fetched = try await execute(plan: plan, userLocation: userLocation)
            for item in fetched {
                let key = item.metadata.rawSourceID ?? item.id
                if let existing = deduped[key] {
                    deduped[key] = existing.merged(with: item, userLocation: userLocation)
                } else {
                    deduped[key] = item
                }
            }
        }
        return Array(deduped.values)
    }

    private func execute(plan: OverpassQueryPlan, userLocation: CLLocation?) async throws -> [POIItem] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(plan.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? plan.query)".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
        let items = decoded.elements.compactMap { element in
            normalize(element: element, plan: plan, userLocation: userLocation)
        }

        let rankedItems = items.sorted { POIItem.sort(lhs: $0, rhs: $1) }
        return plan.resultLimit.map { Array(rankedItems.prefix($0)) } ?? rankedItems
    }

    private func validate(response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse, 200..<300 ~= response.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    private func boundingBox(for region: MKCoordinateRegion) -> String? {
        guard region.span.latitudeDelta <= 6, region.span.longitudeDelta <= 6 else {
            return nil
        }

        let south = max(-90, region.center.latitude - (region.span.latitudeDelta / 2))
        let north = min(90, region.center.latitude + (region.span.latitudeDelta / 2))
        let west = max(-180, region.center.longitude - (region.span.longitudeDelta / 2))
        let east = min(180, region.center.longitude + (region.span.longitudeDelta / 2))
        return String(format: "%.6f,%.6f,%.6f,%.6f", south, west, north, east)
    }

    private func normalize(element: OverpassElement, plan: OverpassQueryPlan, userLocation: CLLocation?) -> POIItem? {
        guard let coordinate = element.coordinate else {
            if element.type != "node" {
                debugLog("skip missing center for \(element.type)#\(element.id) query=\(plan.id)")
            }
            return nil
        }

        var tags = element.tags ?? [:]
        let appLanguage = AppLanguage.current
        let localizedName = localizedName(from: tags, language: appLanguage)
        let fallbackName = tags["name"]?.trimmedNilIfEmpty ??
        tags["official_name"]?.trimmedNilIfEmpty ??
        tags["name:en"]?.trimmedNilIfEmpty ??
        tags["name:tr"]?.trimmedNilIfEmpty ??
        tags["alt_name"]?.trimmedNilIfEmpty

        if filtersUnnamedResults && fallbackName == nil { return nil }
        if plan.requiresName && fallbackName == nil && localizedName == nil { return nil }

        tags["zikrim:query_id"] = plan.id
        tags["zikrim:match_quality"] = plan.matchQuality.rawValue

        let title = fallbackName ?? localizedName ?? plan.category.title
        let subtitle = subtitle(from: tags, category: plan.category)

        return POIItem(
            id: "osm-\(element.type)-\(element.id)",
            source: .osm,
            category: plan.category,
            name: title,
            localizedName: localizedName == title ? nil : localizedName,
            coordinate: coordinate,
            address: address(from: tags),
            distanceMeters: resolvedDistance(from: userLocation, to: coordinate),
            subtitle: subtitle,
            confidence: confidenceScore(for: plan, tags: tags),
            metadata: POIMetadata(
                osmTags: tags,
                rawSourceID: "\(element.type)-\(element.id)",
                rawDisplayName: tags["name"]?.trimmedNilIfEmpty
            ),
            mapItem: nil
        )
    }

    private func localizedName(from tags: [String: String], language: AppLanguage) -> String? {
        switch language {
        case .tr:
            return tags["name:tr"]?.trimmedNilIfEmpty ?? tags["name"]?.trimmedNilIfEmpty
        case .en:
            return tags["name:en"]?.trimmedNilIfEmpty ?? tags["name"]?.trimmedNilIfEmpty
        default:
            return tags["name"]?.trimmedNilIfEmpty ?? tags["name:en"]?.trimmedNilIfEmpty
        }
    }

    private func address(from tags: [String: String]) -> String? {
        [
            tags["addr:street"],
            tags["addr:suburb"],
            tags["addr:city"],
            tags["addr:country"]
        ]
        .compactMap { $0?.trimmedNilIfEmpty }
        .joined(separator: ", ")
        .trimmedNilIfEmpty
    }

    private func subtitle(from tags: [String: String], category: POICategory) -> String? {
        tags["amenity"]?.trimmedNilIfEmpty ??
        tags["shop"]?.trimmedNilIfEmpty ??
        tags["historic"]?.trimmedNilIfEmpty ??
        tags["building"]?.trimmedNilIfEmpty ??
        tags["tourism"]?.trimmedNilIfEmpty ??
        category.title
    }

    private func confidenceScore(for plan: OverpassQueryPlan, tags: [String: String]) -> Double {
        var score = plan.matchQuality.baseScore

        if tags["name"]?.trimmedNilIfEmpty != nil {
            score += 0.10
        } else {
            score -= 0.08
        }
        if tags["addr:city"]?.trimmedNilIfEmpty != nil || tags["addr:street"]?.trimmedNilIfEmpty != nil {
            score += 0.05
        }
        if tags["website"]?.trimmedNilIfEmpty != nil || tags["phone"]?.trimmedNilIfEmpty != nil {
            score += 0.04
        }

        switch plan.category {
        case .mosques:
            if tags["amenity"] == "place_of_worship" && tags["religion"] == "muslim" {
                score += 0.10
            }
        case .shrines:
            if tags["historic"] == "tomb" {
                score += 0.08
            } else if tags["building"] == "shrine" {
                score += 0.04
            }
        case .historicalPlaces:
            if plan.id == "historical_curated" {
                score += 0.08
            } else {
                score -= 0.06
            }
        case .halalFood:
            if tags["diet:halal"] == "yes" {
                score += 0.08
            }
        }

        return min(max(score, 0.10), 0.97)
    }

    private func mergeOSMItems(_ base: [POIItem], _ incoming: [POIItem], userLocation: CLLocation?) -> [POIItem] {
        var deduped: [String: POIItem] = Dictionary(uniqueKeysWithValues: base.map { (($0.metadata.rawSourceID ?? $0.id), $0) })
        for item in incoming {
            let key = item.metadata.rawSourceID ?? item.id
            if let existing = deduped[key] {
                deduped[key] = existing.merged(with: item, userLocation: userLocation)
            } else {
                deduped[key] = item
            }
        }
        return Array(deduped.values)
    }

    private func resolvedDistance(from userLocation: CLLocation?, to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let userLocation else { return nil }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: userLocation)
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[OSMProvider] \(message)")
        #endif
    }
}

private struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Decodable {
    let id: Int64
    let type: String
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?

    var coordinate: CLLocationCoordinate2D? {
        if let lat, let lon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let center {
            return CLLocationCoordinate2D(latitude: center.lat, longitude: center.lon)
        }
        return nil
    }
}

private struct OverpassCenter: Decodable {
    let lat: Double
    let lon: Double
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
