import Foundation
import CoreLocation

@Observable
@MainActor
class QiblaService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var userLocation: CLLocation?
    var heading: CLLocationDirection = 0
    var qiblaBearing: Double = 0
    var qiblaDirection: Double = 0
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isHeadingAvailable: Bool = false
    var errorMessage: String?
    var distanceToKaabaKM: Double = 0

    private static let kaabaLatitude: Double = 21.4225
    private static let kaabaLongitude: Double = 39.8262

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
        isHeadingAvailable = CLLocationManager.headingAvailable()
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdates() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    private func calculateQiblaBearing(from location: CLLocation) -> Double {
        let lat1 = location.coordinate.latitude * .pi / 180
        let lon1 = location.coordinate.longitude * .pi / 180
        let lat2 = Self.kaabaLatitude * .pi / 180
        let lon2 = Self.kaabaLongitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.userLocation = location
            self.qiblaBearing = self.calculateQiblaBearing(from: location)
            self.distanceToKaabaKM = self.calculateDistanceToKaaba(from: location)
            self.updateQiblaDirection()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            if newHeading.headingAccuracy >= 0 {
                self.heading = newHeading.magneticHeading
                self.updateQiblaDirection()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdates()
                self.errorMessage = nil
            } else if manager.authorizationStatus == .denied {
                self.errorMessage = "Konum izni gerekli. Ayarlardan konum iznini açın."
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Konum alınamadı: \(error.localizedDescription)"
        }
    }

    private func updateQiblaDirection() {
        qiblaDirection = qiblaBearing - heading
    }

    private func calculateDistanceToKaaba(from location: CLLocation) -> Double {
        let kaabaLocation = CLLocation(latitude: Self.kaabaLatitude, longitude: Self.kaabaLongitude)
        return location.distance(from: kaabaLocation) / 1000.0
    }
}
