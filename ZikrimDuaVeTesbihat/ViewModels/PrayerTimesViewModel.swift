import Foundation
import CoreLocation
import WidgetKit
import MapKit

@Observable
final class PrayerTimesViewModel: NSObject, CLLocationManagerDelegate {
    static let shared = PrayerTimesViewModel()
    var prayerTimes: PrayerTimes?
    var tomorrowPrayerTimes: PrayerTimes?
    var isLoading: Bool = false
    var errorMessage: String?
    var locationName: String = ""
    var hijriDate: String = ""
    var gregorianWeekday: String = ""
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationMode: PrayerLocationMode = .automatic
    var manualLocation: ManualPrayerLocation?
    var searchResults: [CitySearchResult] = []
    var isSearching: Bool = false
    var refreshAnimationID: UUID = UUID()

    private let prayerService: PrayerTimesServing
    private let settings: PrayerSettings
    private let locationManager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var midnightTimer: Timer?
    private var isGeocoding: Bool = false
    private var prayerFetchTask: Task<Void, Never>?
    private var citySearchTask: Task<Void, Never>?
    private var latestSearchQuery: String = ""
    private var lastLocationRequestAt: Date?
    private let minLocationRequestInterval: TimeInterval = 30
    private let geocodeDistanceThreshold: CLLocationDistance = 300
    private let citySearchDebounceNanoseconds: UInt64 = 300_000_000
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    private let hijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM y"
        return formatter
    }()
    private static var sharedGeocodeCache: GeocodeCache?
    private static var sharedGeocodeInFlight: CLLocationCoordinate2D?

    private struct GeocodeCache {
        let coordinate: CLLocationCoordinate2D
        let name: String
        let administrativeArea: String?
        let country: String?
        let updatedAt: Date
    }

    init(
        prayerService: PrayerTimesServing = RegionalPrayerTimesService(),
        settings: PrayerSettings = PrayerSettings()
    ) {
        self.prayerService = prayerService
        self.settings = settings
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 500

        locationMode = settings.locationMode
        manualLocation = settings.manualLocation

        if locationMode == .manual, let manual = manualLocation {
            locationName = manual.name
            updatePrayerTimes(for: manual.coordinate, locationName: manual.name)
        } else if let coordinate = settings.lastKnownCoordinate {
            locationName = settings.lastLocationName ?? ""
            updatePrayerTimes(
                for: coordinate,
                locationName: settings.lastLocationName,
                administrativeArea: settings.lastAdministrativeArea,
                country: settings.lastCountry
            )
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePrayerSettingsChanged),
            name: .prayerSettingsChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimeZoneChanged),
            name: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil
        )

        scheduleMidnightRefresh()
    }

    deinit {
        citySearchTask?.cancel()
        prayerFetchTask?.cancel()
        locationManager.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    var locationDisplayName: String {
        switch locationMode {
        case .automatic:
            return locationName.isEmpty ? L10n.string(.currentLocation) : locationName
        case .manual:
            return manualLocation?.name ?? L10n.string(.manualCity)
        }
    }

    var locationModeBadge: String {
        switch locationMode {
        case .automatic:
            return L10n.string(.locationModeAutoShort)
        case .manual:
            return L10n.string(.locationModeManualShort)
        }
    }

    var recentLocations: [PrayerLocation] {
        settings.recentLocations
    }

    var locationChipText: String {
        locationDisplayName
    }

    func setLocationMode(_ mode: PrayerLocationMode) {
        guard mode != locationMode else { return }
        settings.locationMode = mode
        locationMode = mode
        if mode == .manual {
            manualLocation = settings.manualLocation
        }
        refresh()
        Task { await rescheduleNotificationsIfPossible() }
    }

    func useAutomaticLocation() {
        settings.locationMode = .automatic
        locationMode = .automatic
        if let coordinate = settings.lastKnownCoordinate {
            recordRecentLocation(
                PrayerLocation(
                    city: settings.lastLocationName ?? locationDisplayName,
                    country: settings.lastCountry ?? "",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    source: .automatic
                )
            )
        }
        refreshPrayerTimes()
    }

    func selectManualCity(_ result: CitySearchResult) {
        let manual = ManualPrayerLocation(
            name: result.name,
            latitude: result.coordinate.latitude,
            longitude: result.coordinate.longitude,
            adminArea: result.adminArea,
            country: result.country
        )
        settings.manualLocation = manual
        settings.locationMode = .manual
        manualLocation = manual
        locationMode = .manual
        locationName = manual.name
        recordRecentLocation(manual.asPrayerLocation)
        updatePrayerTimes(for: manual.coordinate, locationName: manual.name)
        Task { await rescheduleNotificationsIfPossible() }
    }

    func selectRecentLocation(_ location: PrayerLocation) {
        switch location.source {
        case .automatic:
            useAutomaticLocation()
        case .manual:
            let manual = ManualPrayerLocation(
                name: location.city,
                latitude: location.latitude,
                longitude: location.longitude,
                adminArea: nil,
                country: location.country.isEmpty ? nil : location.country
            )
            settings.manualLocation = manual
            settings.locationMode = .manual
            manualLocation = manual
            locationMode = .manual
            locationName = manual.name
            recordRecentLocation(manual.asPrayerLocation)
            updatePrayerTimes(for: manual.coordinate, locationName: manual.name)
            Task { await rescheduleNotificationsIfPossible() }
        }
    }

    func refreshPrayerTimes() {
        refresh()
    }

    func removeRecentLocation(_ location: PrayerLocation) {
        settings.recentLocations.removeAll { candidate in
            candidate == location
        }
    }

    func clearRecentLocations() {
        settings.recentLocations = []
    }

    func refresh() {
        isLoading = true
        errorMessage = nil
        switch locationMode {
        case .automatic:
            if let last = lastLocationRequestAt,
               Date().timeIntervalSince(last) < minLocationRequestInterval,
               let cached = settings.lastKnownCoordinate {
#if DEBUG
                print("[PrayerTimes] geocode_skip_duplicate reason=recent_request lat=\(cached.latitude) lon=\(cached.longitude)")
#endif
                updatePrayerTimes(
                    for: cached,
                    locationName: settings.lastLocationName,
                    administrativeArea: settings.lastAdministrativeArea,
                    country: settings.lastCountry
                )
                isLoading = false
                return
            }
            lastLocationRequestAt = Date()
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestLocation()
        case .manual:
            if let manual = manualLocation ?? settings.manualLocation {
                manualLocation = manual
                locationName = manual.name
                updatePrayerTimes(for: manual.coordinate, locationName: manual.name)
            } else {
                isLoading = false
                errorMessage = L10n.string(.locationUsingSavedCity)
            }
        }
    }

    func rescheduleNotificationsIfPossible() async {
        _ = activeCoordinate
        await ServiceContainer.shared.notificationLifecycleCoordinator.reconcile(reason: .prayerTimesChanged)
    }

    func nextPrayer() -> (name: PrayerName, time: Date, systemImage: String)? {
        nextPrayer(now: Date())
    }

    func nextPrayer(now: Date) -> (name: PrayerName, time: Date, systemImage: String)? {
        let times = prayerTimes
        let prayers = PrayerName.allCases
            .filter { $0 != .sunrise }
            .compactMap { name -> (PrayerName, Date)? in
                guard let time = times?.allTimes[name] else { return nil }
                return (name, time)
            }
            .sorted { $0.1 < $1.1 }

        for prayer in prayers {
            if prayer.1 > now {
                return (prayer.0, prayer.1, prayer.0.systemImage)
            }
        }

        if let nextDayTimes = tomorrowPrayerTimes {
            let fajr = nextDayTimes.fajr
            return (.fajr, fajr, PrayerName.fajr.systemImage)
        }
        return nil
    }

    func minutesUntilNextPrayer() -> Int? {
        minutesUntilNextPrayer(now: Date())
    }

    func minutesUntilNextPrayer(now: Date) -> Int? {
        guard let next = nextPrayer(now: now) else { return nil }
        let diff = Int(next.time.timeIntervalSince(now) / 60)
        return diff >= 0 ? diff : nil
    }

    func formattedTime(_ date: Date) -> String {
        timeFormatter.timeZone = prayerTimes?.timeZone ?? tomorrowPrayerTimes?.timeZone ?? TimeZone.current
        return timeFormatter.string(from: date)
    }

    func scheduleCitySearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        latestSearchQuery = trimmed
        citySearchTask?.cancel()

        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        let debounceNanoseconds = citySearchDebounceNanoseconds
        citySearchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard let self, !Task.isCancelled else { return }
            await self.searchCities(query: trimmed)
        }
    }

    func searchCities(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = .address
        do {
            let response = try await MKLocalSearch(request: request).start()
            let results = response.mapItems.compactMap { item -> CitySearchResult? in
                guard let coordinate = item.placemark.location?.coordinate else { return nil }
                let name = preferredPrayerPlaceName(from: item.placemark) ?? item.name ?? trimmed
                let admin = item.placemark.administrativeArea
                let country = item.placemark.country
                let subtitle = [admin, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                return CitySearchResult(
                    name: name,
                    subtitle: subtitle.isEmpty ? nil : subtitle,
                    coordinate: coordinate,
                    adminArea: admin,
                    country: country
                )
            }
            let deduplicatedMap = Dictionary(
                uniqueKeysWithValues: results.map { result in
                    let key = [
                        result.name.lowercased(),
                        (result.subtitle ?? "").lowercased()
                    ].joined(separator: "|")
                    return (key, result)
                }
            )
            let deduplicatedResults = deduplicatedMap.values.sorted { (lhs: CitySearchResult, rhs: CitySearchResult) in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }

            guard !Task.isCancelled, trimmed == latestSearchQuery else { return }
            searchResults = deduplicatedResults
        } catch {
            guard !Task.isCancelled, trimmed == latestSearchQuery else { return }
            searchResults = []
        }
        if trimmed == latestSearchQuery {
            isSearching = false
        }
    }

    private var activeCoordinate: CLLocationCoordinate2D? {
        switch locationMode {
        case .automatic:
            return settings.lastKnownCoordinate
        case .manual:
            return manualLocation?.coordinate
        }
    }

    private func updatePrayerTimes(
        for coordinate: CLLocationCoordinate2D,
        locationName: String?,
        administrativeArea: String? = nil,
        country: String? = nil
    ) {
        prayerFetchTask?.cancel()
        isLoading = true

        let isManualContext = locationMode == .manual || settings.locationMode == .manual
        let resolvedAdminArea: String?
        let resolvedCountry: String?

        if isManualContext {
            resolvedAdminArea = administrativeArea ?? settings.manualLocation?.adminArea
            resolvedCountry = country ?? settings.manualLocation?.country
        } else {
            resolvedAdminArea = administrativeArea ?? settings.lastAdministrativeArea
            resolvedCountry = country ?? settings.lastCountry
        }

        prayerFetchTask = Task { @MainActor in
            guard let times = await prayerService.prayerTimes(
                for: coordinate,
                date: Date(),
                settings: settings,
                locationName: locationName,
                administrativeArea: resolvedAdminArea,
                country: resolvedCountry
            ) else {
                if Task.isCancelled { return }
                errorMessage = L10n.string(.namazVakitleriYukleniyor)
                isLoading = false
                return
            }

            if Task.isCancelled { return }

            prayerTimes = times
            tomorrowPrayerTimes = await prayerService.prayerTimes(
                for: coordinate,
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                settings: settings,
                locationName: locationName,
                administrativeArea: resolvedAdminArea,
                country: resolvedCountry
            )

            if let resolvedLocationName = times.locationName, !resolvedLocationName.isEmpty {
                self.locationName = resolvedLocationName
                settings.lastLocationName = resolvedLocationName
            }

            updateDateLabels(for: Date())
            updateWidgetData(using: times)
            refreshAnimationID = UUID()
            isLoading = false
        }
    }

    private func updateDateLabels(for date: Date) {
        weekdayFormatter.locale = Locale.current
        gregorianWeekday = weekdayFormatter.string(from: date)

        hijriFormatter.locale = Locale.current
        hijriDate = hijriFormatter.string(from: date)
    }

    private func updateWidgetData(using times: PrayerTimes) {
        guard let next = nextPrayer() else { return }
        let allTimes = times.allTimes.mapValues { formattedTime($0) }
        SharedDefaults.updateWidgetData(
            nextPrayerName: next.name.rawValue,
            nextPrayerTime: formattedTime(next.time),
            nextPrayerDate: next.time,
            nextPrayerIcon: next.name.systemImage,
            city: times.locationName ?? locationName,
            allPrayerTimes: Dictionary(uniqueKeysWithValues: allTimes.map { ($0.key.rawValue, $0.value) }),
            prayerSchedule: Dictionary(uniqueKeysWithValues: times.allTimes.map { ($0.key.rawValue, $0.value) }),
            tomorrowFajr: tomorrowPrayerTimes?.fajr
        )
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()
        let calendar = Calendar.current
        let now = Date()
        if let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime) {
            let interval = nextMidnight.timeIntervalSince(now)
            midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.refresh()
                Task { await self.rescheduleNotificationsIfPossible() }
                self.scheduleMidnightRefresh()
            }
        }
    }

    @objc private func handlePrayerSettingsChanged() {
        locationMode = settings.locationMode
        manualLocation = settings.manualLocation
        if locationMode == .manual, let manual = manualLocation {
            locationName = manual.name
        } else {
            locationName = settings.lastLocationName ?? ""
        }
        refresh()
        Task { await rescheduleNotificationsIfPossible() }
    }

    @objc private func handleTimeZoneChanged() {
        refresh()
        Task { await rescheduleNotificationsIfPossible() }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                errorMessage = L10n.string(.locationPermissionDenied)
                isLoading = false
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            guard locationMode == .automatic else { return }
            settings.lastKnownCoordinate = location.coordinate
            isLoading = true
            let coordinate = location.coordinate

            if let cached = Self.sharedGeocodeCache,
               isSameLocation(cached.coordinate, coordinate) {
#if DEBUG
                print("[PrayerTimes] geocode_cache_hit lat=\(coordinate.latitude) lon=\(coordinate.longitude) name=\(cached.name)")
#endif
                if locationName != cached.name {
                    locationName = cached.name
                    settings.lastLocationName = cached.name
                }
                settings.lastAdministrativeArea = cached.administrativeArea
                settings.lastCountry = cached.country
                updatePrayerTimes(
                    for: coordinate,
                    locationName: cached.name,
                    administrativeArea: cached.administrativeArea,
                    country: cached.country
                )
                await rescheduleNotificationsIfPossible()
                return
            }

            if let inFlight = Self.sharedGeocodeInFlight,
               isSameLocation(inFlight, coordinate) {
#if DEBUG
                print("[PrayerTimes] geocode_skip_duplicate reason=in_flight lat=\(coordinate.latitude) lon=\(coordinate.longitude)")
#endif
                updatePrayerTimes(
                    for: coordinate,
                    locationName: settings.lastLocationName,
                    administrativeArea: settings.lastAdministrativeArea,
                    country: settings.lastCountry
                )
                isLoading = false
                return
            }

            if isGeocoding {
#if DEBUG
                print("[PrayerTimes] geocode_skip_duplicate reason=busy lat=\(coordinate.latitude) lon=\(coordinate.longitude)")
#endif
                updatePrayerTimes(
                    for: coordinate,
                    locationName: settings.lastLocationName,
                    administrativeArea: settings.lastAdministrativeArea,
                    country: settings.lastCountry
                )
                isLoading = false
                return
            }

            isGeocoding = true
            Self.sharedGeocodeInFlight = coordinate
#if DEBUG
            print("[PrayerTimes] geocode_start lat=\(coordinate.latitude) lon=\(coordinate.longitude)")
#endif
            let place = try? await geocoder.reverseGeocodeLocation(location).first
            isGeocoding = false
            Self.sharedGeocodeInFlight = nil
            let name = preferredPrayerPlaceName(from: place)
            let adminArea = place?.administrativeArea
            let country = place?.country
            let resolvedName = name ?? settings.lastLocationName ?? ""
            if !resolvedName.isEmpty {
                locationName = resolvedName
                settings.lastLocationName = resolvedName
                settings.lastAdministrativeArea = adminArea
                settings.lastCountry = country
                Self.sharedGeocodeCache = GeocodeCache(
                    coordinate: coordinate,
                    name: resolvedName,
                    administrativeArea: adminArea,
                    country: country,
                    updatedAt: Date()
                )
                recordRecentLocation(
                    PrayerLocation(
                        city: resolvedName,
                        country: country ?? "",
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        source: .automatic
                    )
                )
            }
            updatePrayerTimes(
                for: coordinate,
                locationName: resolvedName.isEmpty ? nil : resolvedName,
                administrativeArea: adminArea,
                country: country
            )
            await rescheduleNotificationsIfPossible()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = L10n.string(.konumAliniyor)
            isLoading = false
        }
    }

    private func isSameLocation(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> Bool {
        let left = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
        let right = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
        return left.distance(from: right) < geocodeDistanceThreshold
    }

    private func preferredPrayerPlaceName(from placemark: CLPlacemark?) -> String? {
        let candidates = [
            placemark?.subAdministrativeArea,
            placemark?.subLocality,
            placemark?.locality,
            placemark?.administrativeArea,
            placemark?.country
        ]

        for candidate in candidates {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    private func recordRecentLocation(_ location: PrayerLocation) {
        let trimmedCity = location.city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty else { return }

        let normalized = PrayerLocation(
            city: trimmedCity,
            country: location.country.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: location.latitude,
            longitude: location.longitude,
            source: location.source
        )

        var updated = settings.recentLocations.filter {
            $0.city.caseInsensitiveCompare(trimmedCity) != .orderedSame
        }
        updated.insert(normalized, at: 0)
        settings.recentLocations = Array(updated.prefix(5))
    }
}

struct CitySearchResult: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let adminArea: String?
    let country: String?
}
