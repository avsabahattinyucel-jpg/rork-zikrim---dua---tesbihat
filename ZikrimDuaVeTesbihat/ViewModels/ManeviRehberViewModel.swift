import Foundation
@preconcurrency import MapKit
import CoreLocation
import UIKit

@Observable
@MainActor
final class ExploreMapViewModel: NSObject, CLLocationManagerDelegate {
    private enum FetchTrigger: Equatable {
        case initial
        case category
        case region
    }

    private let locationManager = CLLocationManager()
    private let searchService: POISearchService
    private let telemetry = ExploreTelemetry()
    private let summaryStore = ExploreSummaryStore.shared
    private let categoryHaptic = UISelectionFeedbackGenerator()
    private let selectionHaptic = UIImpactFeedbackGenerator(style: .light)
    private let directionsHaptic = UIImpactFeedbackGenerator(style: .medium)

    var items: [POIItem] = []
    var selectedCategory: POICategory = .mosques
    var selectedItem: POIItem?
    var categoryResultCounts: [POICategory: Int] = Dictionary(
        uniqueKeysWithValues: POICategory.allCases.map { ($0, 0) }
    )
    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLoading = false
    var visibleRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var lastFetchedRegion: MKCoordinateRegion?
    private var hasCompletedInitialFetch = false
    private var hasUserInteractedWithMap = false
    private var hasUserSelectedPOI = false

    init(searchService: POISearchService) {
        self.searchService = searchService
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
        categoryHaptic.prepare()
        selectionHaptic.prepare()
        directionsHaptic.prepare()
    }

    override convenience init() {
        self.init(searchService: POISearchService())
    }

    var featuredItem: POIItem? {
        selectedItem ?? items.first
    }

    var statusText: String {
        if let errorMessage, items.isEmpty {
            return errorMessage
        }
        if hasCompletedInitialFetch, items.isEmpty {
            return emptyStateMessage(for: selectedCategory)
        }
        return L10n.format(.guidePlacesFoundFormat, Int64(items.count))
    }

    var emptyStateTitle: String? {
        guard hasCompletedInitialFetch, items.isEmpty, errorMessage == nil else { return nil }
        return emptyStateMessage(for: selectedCategory)
    }

    var shouldShowZoomHelper: Bool {
        guard hasCompletedInitialFetch, items.isEmpty, errorMessage == nil else { return false }
        return isWideRegion(visibleRegion)
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdates() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdates() {
        locationManager.stopUpdatingLocation()
        cancelAllTasks()
    }

    func selectCategory(_ category: POICategory) {
        guard selectedCategory != category else { return }
        categoryHaptic.selectionChanged()
        categoryHaptic.prepare()
        telemetry.track(
            .categorySelected,
            payload: [
                "category": category.rawValue,
                "previous_category": selectedCategory.rawValue
            ]
        )
        selectedCategory = category
        items = []
        selectedItem = nil
        hasUserSelectedPOI = false
        errorMessage = nil
        cancelAllTasks()
        fetchPOIs(for: category, trigger: .category)
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion, userInitiated: Bool = true) {
        visibleRegion = region
        if userInitiated && hasCompletedInitialFetch {
            hasUserInteractedWithMap = true
        }
        scheduleRegionDebouncedFetch()
    }

    func setSelectedItem(_ item: POIItem?, userInitiated: Bool = false) {
        let previousSelectedID = selectedItem?.id
        if userInitiated {
            hasUserSelectedPOI = item != nil
        }
        selectedItem = item
        if userInitiated, let item, previousSelectedID != item.id {
            selectionHaptic.impactOccurred(intensity: 0.72)
            selectionHaptic.prepare()
        }
        guard userInitiated, let item else { return }
        telemetry.track(
            .resultSelected,
            payload: [
                "category": item.category.rawValue,
                "source": item.source.rawValue,
                "confidence": String(format: "%.3f", item.confidence)
            ]
        )
    }

    func openDirections(to item: POIItem) {
        directionsHaptic.impactOccurred(intensity: 0.88)
        directionsHaptic.prepare()
        telemetry.track(
            .directionsTapped,
            payload: [
                "category": item.category.rawValue,
                "source": item.source.rawValue
            ]
        )
        let destination = item.mapItem ?? MKMapItem(placemark: MKPlacemark(coordinate: item.coordinate))
        destination.name = item.displayName
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    func region(focusing item: POIItem) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: item.coordinate,
            latitudinalMeters: 1_800,
            longitudinalMeters: 1_800
        )
    }

    private func cancelAllTasks() {
        debounceTask?.cancel()
        searchTask?.cancel()
    }

    private func scheduleRegionDebouncedFetch() {
        debounceTask?.cancel()
        let regionSnapshot = visibleRegion
        let categorySnapshot = selectedCategory

        debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            guard !self.isLoading else { return }

            guard self.shouldFetch(for: regionSnapshot, trigger: .region) else { return }
            self.fetchPOIs(for: categorySnapshot, trigger: .region)
        }
    }

    private func fetchPOIs(for category: POICategory, trigger: FetchTrigger) {
        switch category {
        case .mosques, .shrines, .historicalPlaces, .halalFood:
            break
        }

        searchTask?.cancel()
        let regionSnapshot = visibleRegion
        searchTask = Task { [weak self] in
            guard let self else { return }
            guard self.selectedCategory == category else { return }
            guard self.shouldFetch(for: regionSnapshot, trigger: trigger) else { return }
            await self.runFetch(category: category, region: regionSnapshot, trigger: trigger)
        }
    }

    private func runFetch(category: POICategory, region: MKCoordinateRegion, trigger: FetchTrigger) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let results = try await searchService.search(
                categories: [category],
                in: region,
                userLocation: userLocation
            )
            guard !Task.isCancelled else { return }
            guard selectedCategory == category else { return }

            let limited = Array(results.prefix(annotationLimit(for: region)))
            let shouldKeepExistingItems = trigger == .region &&
                limited.isEmpty &&
                !items.isEmpty &&
                selectedCategory == category

            if shouldKeepExistingItems {
                hasCompletedInitialFetch = true
                lastFetchedRegion = region
                categoryResultCounts[category] = items.count
                errorMessage = nil
                telemetry.track(
                    .resultsLoaded,
                    payload: [
                        "category": category.rawValue,
                        "result_count": "\(items.count)",
                        "kept_previous": "true"
                    ]
                )
                return
            }

            items = limited
            categoryResultCounts[category] = limited.count
            summaryStore.update(category: category, count: limited.count)
            hasCompletedInitialFetch = true
            lastFetchedRegion = region
            telemetry.track(
                .resultsLoaded,
                payload: [
                    "category": category.rawValue,
                    "result_count": "\(limited.count)"
                ]
            )

            if limited.isEmpty {
                errorMessage = emptyStateMessage(for: category)
                selectedItem = nil
                hasUserSelectedPOI = false
            } else {
                errorMessage = nil
                if hasUserSelectedPOI, let selectedItem, let refreshed = limited.first(where: { $0.id == selectedItem.id }) {
                    self.selectedItem = refreshed
                } else {
                    self.selectedItem = limited.first
                    hasUserSelectedPOI = false
                }
            }

            if trigger == .category,
               !hasUserInteractedWithMap,
               let fittedRegion = fittedRegion(for: limited) {
                visibleRegion = fittedRegion
            }
        } catch is CancellationError {
            return
        } catch {
            guard selectedCategory == category else { return }
            categoryResultCounts[category] = 0
            if trigger == .category {
                items = []
                selectedItem = nil
            }
            hasCompletedInitialFetch = true
            errorMessage = L10n.string(.guideSearchError)
        }
    }

    private func shouldFetch(for region: MKCoordinateRegion, trigger: FetchTrigger) -> Bool {
        if trigger == .initial || trigger == .category {
            return true
        }
        guard let lastFetchedRegion else { return true }

        let currentCenter = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let lastCenter = CLLocation(latitude: lastFetchedRegion.center.latitude, longitude: lastFetchedRegion.center.longitude)
        let centerDistance = currentCenter.distance(from: lastCenter)

        let latitudeSpanDelta = abs(region.span.latitudeDelta - lastFetchedRegion.span.latitudeDelta)
        let longitudeSpanDelta = abs(region.span.longitudeDelta - lastFetchedRegion.span.longitudeDelta)
        let spanBaseline = max(lastFetchedRegion.span.latitudeDelta, lastFetchedRegion.span.longitudeDelta, 0.01)
        let spanThreshold = spanBaseline * 0.18

        return centerDistance > 250 || latitudeSpanDelta > spanThreshold || longitudeSpanDelta > spanThreshold
    }

    private func annotationLimit(for region: MKCoordinateRegion) -> Int {
        if !hasCompletedInitialFetch {
            return 30
        }

        let zoom = max(region.span.latitudeDelta, region.span.longitudeDelta)
        switch zoom {
        case ..<0.03:
            return 90
        case ..<0.07:
            return 60
        case ..<0.14:
            return 45
        default:
            return 30
        }
    }

    private func fittedRegion(for results: [POIItem]) -> MKCoordinateRegion? {
        guard !results.isEmpty else { return nil }
        if results.count == 1, let first = results.first {
            return MKCoordinateRegion(
                center: first.coordinate,
                latitudinalMeters: 1_800,
                longitudinalMeters: 1_800
            )
        }

        let latitudes = results.map { $0.coordinate.latitude }
        let longitudes = results.map { $0.coordinate.longitude }
        guard
            let minLat = latitudes.min(),
            let maxLat = latitudes.max(),
            let minLon = longitudes.min(),
            let maxLon = longitudes.max()
        else {
            return nil
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.35, 0.02),
            longitudeDelta: max((maxLon - minLon) * 1.35, 0.02)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    private func emptyStateMessage(for category: POICategory) -> String {
        switch category {
        case .mosques:
            return L10n.string(.guideEmptyMosques)
        case .shrines:
            return L10n.string(.guideEmptyShrines)
        case .historicalPlaces:
            return L10n.string(.guideEmptyHistoricalPlaces)
        case .halalFood:
            return L10n.string(.guideEmptyHalalFood)
        }
    }

    private func isWideRegion(_ region: MKCoordinateRegion) -> Bool {
        region.span.latitudeDelta > 0.9 || region.span.longitudeDelta > 0.9
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self, let location = locations.last else { return }
            let isFirstUpdate = self.userLocation == nil
            self.userLocation = location

            if isFirstUpdate {
                self.visibleRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 7_500,
                    longitudinalMeters: 7_500
                )
                self.cancelAllTasks()
                self.fetchPOIs(for: self.selectedCategory, trigger: .initial)
            } else {
                self.items = self.items
                    .map { $0.withDistance(from: location) }
                    .sorted { POIItem.sort(lhs: $0, rhs: $1) }
                if let selectedItem, let refreshed = self.items.first(where: { $0.id == selectedItem.id }) {
                    self.selectedItem = refreshed
                }
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdates()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}

typealias ManeviRehberViewModel = ExploreMapViewModel

@Observable
final class ExploreSummaryStore {
    static let shared = ExploreSummaryStore()

    var mosquesCount: Int
    var shrinesCount: Int
    var historicalPlacesCount: Int
    var hasLoadedSnapshot: Bool

    var totalTrackedCount: Int {
        mosquesCount + shrinesCount + historicalPlacesCount
    }

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        mosquesCount = defaults.integer(forKey: ExploreSummaryStore.keys.mosquesCount)
        shrinesCount = defaults.integer(forKey: ExploreSummaryStore.keys.shrinesCount)
        historicalPlacesCount = defaults.integer(forKey: ExploreSummaryStore.keys.historicalPlacesCount)
        hasLoadedSnapshot = defaults.bool(forKey: ExploreSummaryStore.keys.hasLoadedSnapshot)
    }

    func update(category: POICategory, count: Int) {
        let normalizedCount = max(count, 0)
        switch category {
        case .mosques:
            mosquesCount = normalizedCount
            defaults.set(normalizedCount, forKey: Self.keys.mosquesCount)
        case .shrines:
            shrinesCount = normalizedCount
            defaults.set(normalizedCount, forKey: Self.keys.shrinesCount)
        case .historicalPlaces:
            historicalPlacesCount = normalizedCount
            defaults.set(normalizedCount, forKey: Self.keys.historicalPlacesCount)
        case .halalFood:
            break
        }

        if category == .mosques || category == .shrines || category == .historicalPlaces {
            hasLoadedSnapshot = true
            defaults.set(true, forKey: Self.keys.hasLoadedSnapshot)
        }
    }

    private enum keys {
        static let mosquesCount = "explore_summary_mosques_count_v1"
        static let shrinesCount = "explore_summary_shrines_count_v1"
        static let historicalPlacesCount = "explore_summary_historical_count_v1"
        static let hasLoadedSnapshot = "explore_summary_has_loaded_v1"
    }
}

private struct ExploreTelemetry {
    enum Event: String {
        case categorySelected = "explore_category_selected"
        case resultsLoaded = "explore_results_loaded"
        case resultSelected = "explore_result_selected"
        case directionsTapped = "explore_directions_tapped"
    }

    func track(_ event: Event, payload: [String: String]) {
        #if DEBUG
        let payloadText = payload
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        print("[ExploreTelemetry] event=\(event.rawValue) \(payloadText)")
        #endif
    }
}
