import Foundation
@preconcurrency import MapKit
import CoreLocation

nonisolated enum POISource: String, Codable, Sendable {
    case mapKit
    case osm
    case merged

    nonisolated var qualityRank: Int {
        switch self {
        case .merged:
            return 3
        case .mapKit:
            return 2
        case .osm:
            return 1
        }
    }
}

nonisolated enum POICategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case mosques
    case shrines
    case historicalPlaces
    case halalFood

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .mosques:
            return L10n.string(.placeCategoryCamiler)
        case .shrines:
            return L10n.string(.placeCategoryTurbeler)
        case .historicalPlaces:
            return L10n.string(.placeCategoryTarihiYerler)
        case .halalFood:
            return L10n.string(.placeCategoryHelalYemek)
        }
    }

    nonisolated var icon: String {
        switch self {
        case .mosques:
            return "building.columns.fill"
        case .shrines:
            return "sparkles"
        case .historicalPlaces:
            return "building.columns.circle.fill"
        case .halalFood:
            return "fork.knife"
        }
    }

    nonisolated func mapKitQueries(for language: AppLanguage = .current) -> [String] {
        switch self {
        case .mosques:
            switch language {
            case .tr:
                return ["cami", "mescit", "mosque"]
            case .en:
                return ["mosque", "masjid", "islamic center"]
            default:
                return ["mosque", "masjid", "cami"]
            }
        case .shrines:
            switch language {
            case .tr:
                return ["türbe", "turbe", "islamic shrine", "tomb", "mausoleum"]
            case .en:
                return ["islamic shrine", "tomb", "mausoleum", "shrine"]
            default:
                return ["islamic shrine", "tomb", "turbe", "shrine"]
            }
        case .historicalPlaces:
            switch language {
            case .tr:
                return ["tarihi yer", "tarihi eser", "tarihi mekan", "müze", "saray", "kule", "historic site", "historical landmark"]
            case .en:
                return ["historic site", "historical landmark", "heritage", "monument", "memorial", "museum", "palace", "tower"]
            default:
                return ["historic site", "historical place", "landmark", "monument", "museum", "palace", "tower"]
            }
        case .halalFood:
            switch language {
            case .tr:
                return ["helal yemek", "helal restoran", "helal kafe", "halal restaurant", "halal cafe"]
            case .en:
                return ["halal restaurant", "halal food", "halal cafe", "halal fast food"]
            default:
                return ["halal restaurant", "halal food", "halal cafe", "helal"]
            }
        }
    }

    nonisolated static var defaultSelection: POICategory { .mosques }
}

nonisolated struct POIMetadata: Hashable, Sendable {
    let osmTags: [String: String]
    let rawSourceID: String?
    let rawDisplayName: String?

    init(
        osmTags: [String: String] = [:],
        rawSourceID: String? = nil,
        rawDisplayName: String? = nil
    ) {
        self.osmTags = osmTags
        self.rawSourceID = rawSourceID
        self.rawDisplayName = rawDisplayName
    }

    func merged(with other: POIMetadata) -> POIMetadata {
        POIMetadata(
            osmTags: osmTags.merging(other.osmTags) { current, _ in current },
            rawSourceID: [rawSourceID, other.rawSourceID]
                .compactMap { $0?.nilIfEmpty }
                .uniquedJoined(separator: "|"),
            rawDisplayName: rawDisplayName?.nilIfEmpty ?? other.rawDisplayName?.nilIfEmpty
        )
    }
}

struct POIItem: Identifiable, Hashable, @unchecked Sendable {
    let id: String
    let source: POISource
    let category: POICategory
    let name: String
    let localizedName: String?
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let distanceMeters: CLLocationDistance?
    let subtitle: String?
    let confidence: Double
    let metadata: POIMetadata
    let mapItem: MKMapItem?

    init(
        id: String,
        source: POISource,
        category: POICategory,
        name: String,
        localizedName: String? = nil,
        coordinate: CLLocationCoordinate2D,
        address: String? = nil,
        distanceMeters: CLLocationDistance? = nil,
        subtitle: String? = nil,
        confidence: Double,
        metadata: POIMetadata = POIMetadata(),
        mapItem: MKMapItem? = nil
    ) {
        self.id = id
        self.source = source
        self.category = category
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.localizedName = localizedName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.coordinate = coordinate
        self.address = address?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.distanceMeters = distanceMeters
        self.subtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.metadata = metadata
        self.mapItem = mapItem
    }

    static func == (lhs: POIItem, rhs: POIItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var displayName: String {
        localizedName?.nilIfEmpty ?? name
    }

    var canonicalName: String {
        displayName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var addressComparable: String {
        (address ?? "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func withDistance(from location: CLLocation?) -> POIItem {
        guard let location else { return self }
        let resolvedDistance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: location)

        return POIItem(
            id: id,
            source: source,
            category: category,
            name: name,
            localizedName: localizedName,
            coordinate: coordinate,
            address: address,
            distanceMeters: resolvedDistance,
            subtitle: subtitle,
            confidence: confidence,
            metadata: metadata,
            mapItem: mapItem
        )
    }

    func withConfidence(_ newConfidence: Double) -> POIItem {
        POIItem(
            id: id,
            source: source,
            category: category,
            name: name,
            localizedName: localizedName,
            coordinate: coordinate,
            address: address,
            distanceMeters: distanceMeters,
            subtitle: subtitle,
            confidence: newConfidence,
            metadata: metadata,
            mapItem: mapItem
        )
    }

    func merged(with other: POIItem, userLocation: CLLocation?) -> POIItem {
        let preferred = confidence >= other.confidence ? self : other
        let secondary = preferred.id == id ? other : self
        let mergedSource: POISource = source == other.source ? source : .merged
        let mergedName = preferred.name.count >= secondary.name.count ? preferred.name : secondary.name
        let mergedLocalizedName = preferred.localizedName?.nilIfEmpty ?? secondary.localizedName?.nilIfEmpty

        return POIItem(
            id: source == other.source ? preferred.id : "merged-\(preferred.id)-\(secondary.id)",
            source: mergedSource,
            category: preferred.category,
            name: mergedName,
            localizedName: mergedLocalizedName,
            coordinate: preferred.mapItem != nil ? preferred.coordinate : secondary.coordinate,
            address: preferred.address?.nilIfEmpty ?? secondary.address?.nilIfEmpty,
            distanceMeters: preferred.distanceMeters ?? secondary.distanceMeters,
            subtitle: preferred.subtitle?.nilIfEmpty ?? secondary.subtitle?.nilIfEmpty,
            confidence: min(max(preferred.confidence, secondary.confidence) + 0.06, 1.0),
            metadata: preferred.metadata.merged(with: secondary.metadata),
            mapItem: preferred.mapItem ?? secondary.mapItem
        )
        .withDistance(from: userLocation)
    }
}

extension POIItem {
    static func sort(lhs: POIItem, rhs: POIItem) -> Bool {
        if lhs.confidence != rhs.confidence {
            return lhs.confidence > rhs.confidence
        }

        switch (lhs.distanceMeters, rhs.distanceMeters) {
        case let (left?, right?) where left != right:
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            if lhs.metadataCompletenessScore != rhs.metadataCompletenessScore {
                return lhs.metadataCompletenessScore > rhs.metadataCompletenessScore
            }
            if lhs.source.qualityRank != rhs.source.qualityRank {
                return lhs.source.qualityRank > rhs.source.qualityRank
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    var metadataCompletenessScore: Double {
        var score = 0.0
        if !displayName.isEmpty { score += 0.34 }
        if address?.isEmpty == false { score += 0.20 }
        if subtitle?.isEmpty == false { score += 0.16 }
        if metadata.rawSourceID?.isEmpty == false { score += 0.12 }
        if !metadata.osmTags.isEmpty { score += min(0.18, Double(metadata.osmTags.count) * 0.015) }
        return min(score, 1.0)
    }
}

nonisolated struct POIViewportCacheKey: Hashable, Sendable {
    let category: POICategory
    let latitudeBucket: Int
    let longitudeBucket: Int
    let latitudeSpanBucket: Int
    let longitudeSpanBucket: Int

    nonisolated init(region: MKCoordinateRegion, category: POICategory) {
        self.category = category
        latitudeBucket = Int((region.center.latitude * 100).rounded())
        longitudeBucket = Int((region.center.longitude * 100).rounded())
        latitudeSpanBucket = Int((region.span.latitudeDelta * 100).rounded())
        longitudeSpanBucket = Int((region.span.longitudeDelta * 100).rounded())
    }
}

struct POIMapCluster: Identifiable {
    let items: [POIItem]

    var id: String {
        let seed = items.map(\.id).sorted().joined(separator: "-")
        return "cluster-\(seed)"
    }

    var count: Int { items.count }

    var dominantCategory: POICategory? {
        Dictionary(grouping: items, by: \.category)
            .max(by: { $0.value.count < $1.value.count })?
            .key
    }
}

nonisolated extension AppLanguage {
    static var current: AppLanguage {
        AppLanguage(code: RabiaAppLanguage.currentCode())
    }
}

nonisolated private extension String {
    nonisolated var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

nonisolated private extension Array where Element == String {
    nonisolated func uniquedJoined(separator: String) -> String? {
        let values = reduce(into: [String]()) { partial, value in
            guard !partial.contains(value) else { return }
            partial.append(value)
        }
        guard !values.isEmpty else { return nil }
        return values.joined(separator: separator)
    }
}
