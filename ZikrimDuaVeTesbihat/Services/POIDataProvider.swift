import Foundation
@preconcurrency import MapKit
import CoreLocation

protocol POIDataProvider: Sendable {
    var source: POISource { get }
    func search(category: POICategory, in region: MKCoordinateRegion, userLocation: CLLocation?) async throws -> [POIItem]
}
