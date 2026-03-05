import Foundation
import MapKit
import CoreLocation

@Observable
@MainActor
class ManeviRehberViewModel: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    var places: [ManeviPlace] = []
    var selectedCategories: Set<PlaceCategory> = [.mosque]
    var selectedPlace: ManeviPlace?
    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var heading: CLLocationDirection = 0
    var qiblaBearing: Double = 0
    var isLoading: Bool = false
    var isHeadingAvailable: Bool = false

    private var searchRegion: MKCoordinateRegion?
    private var lastSearchCategories: Set<PlaceCategory> = []

    static let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 1
        isHeadingAvailable = CLLocationManager.headingAvailable()
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdates() {
        locationManager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }

    func stopUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    func toggleCategory(_ category: PlaceCategory) {
        if selectedCategories.contains(category) {
            if selectedCategories.count > 1 {
                selectedCategories.remove(category)
            }
        } else {
            selectedCategories.insert(category)
        }
        Task { await searchNearby() }
    }

    func searchNearby() async {
        guard let location = userLocation else { return }

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        isLoading = true
        var allPlaces: [ManeviPlace] = []

        for category in selectedCategories {
            for query in category.searchQueries {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = region

                let search = MKLocalSearch(request: request)
                do {
                    let response = try await search.start()
                    let newPlaces = response.mapItems.map { ManeviPlace(mapItem: $0, category: category) }
                    allPlaces.append(contentsOf: newPlaces)
                } catch {}
            }
        }

        var seen = Set<String>()
        places = allPlaces.filter { place in
            let key = "\(String(format: "%.4f", place.coordinate.latitude))-\(String(format: "%.4f", place.coordinate.longitude))"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        isLoading = false
    }

    func openDirections(to place: ManeviPlace) {
        place.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    var qiblaLineCoordinates: [CLLocationCoordinate2D] {
        guard let location = userLocation else { return [] }
        return generateGeodesicPath(
            from: location.coordinate,
            to: Self.kaabaCoordinate,
            segments: 100
        )
    }

    private func generateGeodesicPath(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, segments: Int) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []

        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180

        let d = 2 * asin(sqrt(
            pow(sin((lat1 - lat2) / 2), 2) +
            cos(lat1) * cos(lat2) * pow(sin((lon1 - lon2) / 2), 2)
        ))

        for i in 0...segments {
            let f = Double(i) / Double(segments)
            let A = sin((1 - f) * d) / sin(d)
            let B = sin(f * d) / sin(d)
            let x = A * cos(lat1) * cos(lon1) + B * cos(lat2) * cos(lon2)
            let y = A * cos(lat1) * sin(lon1) + B * cos(lat2) * sin(lon2)
            let z = A * sin(lat1) + B * sin(lat2)

            let lat = atan2(z, sqrt(x * x + y * y)) * 180 / .pi
            let lon = atan2(y, x) * 180 / .pi
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        return coordinates
    }

    private func calculateQiblaBearing(from location: CLLocation) -> Double {
        let lat1 = location.coordinate.latitude * .pi / 180
        let lon1 = location.coordinate.longitude * .pi / 180
        let lat2 = Self.kaabaCoordinate.latitude * .pi / 180
        let lon2 = Self.kaabaCoordinate.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }

    var isPointingToQibla: Bool {
        let diff = ((qiblaBearing - heading).truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return diff < 3 || diff > 357
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            let isFirst = self.userLocation == nil
            self.userLocation = location
            self.qiblaBearing = self.calculateQiblaBearing(from: location)
            if isFirst {
                await self.searchNearby()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            if newHeading.headingAccuracy >= 0 {
                self.heading = newHeading.trueHeading
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdates()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
