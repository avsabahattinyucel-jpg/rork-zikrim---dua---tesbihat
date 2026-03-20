import Foundation
import CoreLocation

@Observable
@MainActor
final class QiblaService: NSObject, CLLocationManagerDelegate {
    private static let requestTimeout: TimeInterval = 10
    private static let resourceTimeout: TimeInterval = 12

    private let manager = CLLocationManager()
    private let session: URLSession

    var userLocation: CLLocation?
    var heading: CLLocationDirection = 0
    var qiblaBearing: Double = 0
    var qiblaDirection: Double = 0
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isHeadingAvailable: Bool = false
    var errorMessage: String?
    var distanceToKaabaKM: Double = 0
    var isSyncingRemoteBearing: Bool = false

    private static let kaabaLatitude: Double = 21.4225
    private static let kaabaLongitude: Double = 39.8262

    private let remoteRefreshDistanceThreshold: CLLocationDistance = 250
    private var qiblaLookupTask: Task<Void, Never>?
    private var lastRemoteLookupLocation: CLLocation?

    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "Zikrim/1.0 iOS Qibla"
        ]
        configuration.timeoutIntervalForRequest = Self.requestTimeout
        configuration.timeoutIntervalForResource = Self.resourceTimeout
        session = URLSession(configuration: configuration)

        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
        authorizationStatus = manager.authorizationStatus
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
        qiblaLookupTask?.cancel()
    }

    private func calculateLocalQiblaBearing(from location: CLLocation) -> Double {
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

    private func fetchRemoteQiblaBearingIfNeeded(for location: CLLocation) {
        guard shouldRefreshRemoteBearing(for: location) else { return }

        lastRemoteLookupLocation = location
        isSyncingRemoteBearing = true
        qiblaLookupTask?.cancel()

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        qiblaLookupTask = Task { [weak self] in
            guard let self else { return }
            let remoteBearing = await self.fetchRemoteQiblaBearing(latitude: latitude, longitude: longitude)
            guard !Task.isCancelled else { return }

            if let remoteBearing {
                self.qiblaBearing = self.normalizedBearing(remoteBearing)
                self.errorMessage = nil
                self.updateQiblaDirection()
            } else {
                self.lastRemoteLookupLocation = nil
            }

            self.isSyncingRemoteBearing = false
        }
    }

    private func shouldRefreshRemoteBearing(for location: CLLocation) -> Bool {
        guard let previousLocation = lastRemoteLookupLocation else { return true }
        return location.distance(from: previousLocation) >= remoteRefreshDistanceThreshold
    }

    private func fetchRemoteQiblaBearing(latitude: Double, longitude: Double) async -> Double? {
        guard let url = URL(string: "https://api.aladhan.com/v1/qibla/\(latitude)/\(longitude)") else {
            return nil
        }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(QiblaEnvelope.self, from: data)
            return response.data.direction
        } catch {
            return nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.userLocation = location
            self.qiblaBearing = self.calculateLocalQiblaBearing(from: location)
            self.distanceToKaabaKM = self.calculateDistanceToKaaba(from: location)
            self.updateQiblaDirection()
            self.fetchRemoteQiblaBearingIfNeeded(for: location)
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
                self.errorMessage = L10n.string(.errorQiblaPermissionRequired)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = L10n.format(.errorLocationUnavailable, error.localizedDescription)
        }
    }

    private func updateQiblaDirection() {
        qiblaDirection = normalizedBearing(qiblaBearing - heading)
    }

    private func calculateDistanceToKaaba(from location: CLLocation) -> Double {
        let kaabaLocation = CLLocation(latitude: Self.kaabaLatitude, longitude: Self.kaabaLongitude)
        return location.distance(from: kaabaLocation) / 1000.0
    }

    private func normalizedBearing(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }
}

private struct QiblaEnvelope: Decodable {
    let data: QiblaData

    struct QiblaData: Decodable {
        let direction: Double
    }
}
