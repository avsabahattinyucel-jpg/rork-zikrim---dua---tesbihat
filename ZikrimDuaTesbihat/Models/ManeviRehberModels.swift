import Foundation
import MapKit

nonisolated enum PlaceCategory: String, CaseIterable, Identifiable, Sendable {
    case mosque = "mosque"
    case halalFood = "halalFood"
    case islamicBooks = "islamicBooks"
    case historicalSites = "historicalSites"

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .mosque: return "Camiler"
        case .halalFood: return "Helal Yemek"
        case .islamicBooks: return "Kitapçılar"
        case .historicalSites: return "Tarihi Yerler"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .mosque: return "building.columns.fill"
        case .halalFood: return "fork.knife"
        case .islamicBooks: return "book.closed.fill"
        case .historicalSites: return "star.and.crescent"
        }
    }

    nonisolated var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .mosque: return (0.13, 0.55, 0.35)
        case .halalFood: return (0.85, 0.50, 0.10)
        case .islamicBooks: return (0.30, 0.45, 0.75)
        case .historicalSites: return (0.72, 0.58, 0.10)
        }
    }

    nonisolated var searchQueries: [String] {
        switch self {
        case .mosque: return ["Mosque", "Cami"]
        case .halalFood: return ["Halal Restaurant", "Alkolsüz Restoran"]
        case .islamicBooks: return ["Islamic Bookstore", "Dini Kitapçı"]
        case .historicalSites: return ["Tomb", "Tekke", "Historical Mosque"]
        }
    }
}

struct ManeviPlace: Identifiable {
    let id: String
    let name: String
    let category: PlaceCategory
    let coordinate: CLLocationCoordinate2D
    let address: String
    let mapItem: MKMapItem

    init(mapItem: MKMapItem, category: PlaceCategory) {
        self.id = "\(mapItem.placemark.coordinate.latitude)-\(mapItem.placemark.coordinate.longitude)-\(mapItem.name ?? "")"
        self.name = mapItem.name ?? "Bilinmiyor"
        self.category = category
        self.coordinate = mapItem.placemark.coordinate
        self.address = [mapItem.placemark.thoroughfare, mapItem.placemark.locality]
            .compactMap { $0 }
            .joined(separator: ", ")
        self.mapItem = mapItem
    }
}
