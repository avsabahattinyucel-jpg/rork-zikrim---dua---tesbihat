import CoreLocation
import Foundation

@MainActor
final class NotificationLifecycleCoordinator {
    private let permissionManager: NotificationPermissionManager
    private let settingsStore: NotificationSettingsStore
    private let scheduler: NotificationScheduler
    private let analytics: NotificationAnalyticsTracking
    private let prayerSettings: PrayerSettings

    private var observers: [NSObjectProtocol] = []

    init(
        permissionManager: NotificationPermissionManager,
        settingsStore: NotificationSettingsStore,
        scheduler: NotificationScheduler,
        prayerSettings: PrayerSettings,
        analytics: NotificationAnalyticsTracking
    ) {
        self.permissionManager = permissionManager
        self.settingsStore = settingsStore
        self.scheduler = scheduler
        self.prayerSettings = prayerSettings
        self.analytics = analytics
        startObserving()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func requestPermissionAfterSoftAsk() async -> Bool {
        let granted = await permissionManager.requestAuthorization()
        if granted {
            await reconcile(reason: .settingsChanged)
        }
        return granted
    }

    func applyUserSettings(_ settings: NotificationSettings) async {
        settingsStore.save(settings)
        await reconcile(reason: .settingsChanged)
    }

    func handleSceneDidBecomeActive(premiumEnabled: Bool) async {
        _ = await permissionManager.refreshStatus()
        let contextChanged = settingsStore.synchronizeRuntimeContext(
            languageCode: RabiaAppLanguage.currentCode(),
            timezoneIdentifier: TimeZone.autoupdatingCurrent.identifier,
            location: currentLocationSnapshot(),
            premiumEnabled: premiumEnabled
        )

        let reason: NotificationSchedulerReason = didDayChange() ? .newDay : (contextChanged ? .foregroundRefresh : .foregroundRefresh)
        await reconcile(reason: reason)
    }

    func updatePremiumState(isPremium: Bool) async {
        let changed = settingsStore.synchronizeRuntimeContext(
            languageCode: RabiaAppLanguage.currentCode(),
            timezoneIdentifier: TimeZone.autoupdatingCurrent.identifier,
            location: currentLocationSnapshot(),
            premiumEnabled: isPremium
        )
        guard changed else { return }
        await reconcile(reason: .premiumChanged)
    }

    func reconcile(reason: NotificationSchedulerReason) async {
        var updated = settingsStore.settings
        updated.currentLanguageCode = RabiaAppLanguage.currentCode()
        updated.currentTimezoneIdentifier = TimeZone.autoupdatingCurrent.identifier
        updated.currentLocation = currentLocationSnapshot()
        updated.lastActiveDayStamp = NotificationRequestIdentifier.dayStamp(for: Date(), calendar: .autoupdatingCurrent)

        do {
            try await scheduler.rebuildAllNotifications(settings: updated)
            updated.lastRebuiltAt = Date()
            settingsStore.save(updated)
            analytics.track(event: "notification_reconcile", metadata: ["reason": reason.rawValue])
        } catch {
            analytics.track(event: "notification_reconcile_failed", metadata: ["reason": reason.rawValue])
            #if DEBUG
            print("[Notifications] rebuild failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func startObserving() {
        let center = NotificationCenter.default

        observers.append(
            center.addObserver(
                forName: .prayerSettingsChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    await self?.reconcile(reason: .locationChanged)
                }
            }
        )

        observers.append(
            center.addObserver(
                forName: NSNotification.Name.NSSystemTimeZoneDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    await self?.reconcile(reason: .timezoneChanged)
                }
            }
        )
    }

    private func didDayChange() -> Bool {
        let today = NotificationRequestIdentifier.dayStamp(for: Date(), calendar: .autoupdatingCurrent)
        return settingsStore.settings.lastActiveDayStamp != today
    }

    private func currentLocationSnapshot() -> NotificationLocationSnapshot {
        if prayerSettings.locationMode == .manual, let manual = prayerSettings.manualLocation {
            return NotificationLocationSnapshot(
                identifier: manual.name,
                cityName: manual.name,
                administrativeArea: manual.adminArea,
                country: manual.country,
                latitude: manual.latitude,
                longitude: manual.longitude,
                timezoneIdentifier: TimeZone.autoupdatingCurrent.identifier
            )
        }

        return NotificationLocationSnapshot(
            identifier: prayerSettings.lastLocationName,
            cityName: prayerSettings.lastLocationName,
            administrativeArea: prayerSettings.lastAdministrativeArea,
            country: prayerSettings.lastCountry,
            latitude: prayerSettings.lastKnownCoordinate?.latitude,
            longitude: prayerSettings.lastKnownCoordinate?.longitude,
            timezoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        )
    }
}
