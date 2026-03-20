import Combine
import Foundation
import SwiftUI

struct NotificationSettingsSummaryBuilder {
    func summary(settings: NotificationSettings) -> String {
        let languageCode = settings.currentLanguageCode
        let separator = NotificationLocalization.text(.summarySeparator, languageCode: languageCode)
        var parts: [String] = []

        let prayerLabel = NotificationLocalization.text(.summaryPrayer, languageCode: languageCode)
        let timingLabel: String
        switch settings.reminderTimingMode {
        case .atTime:
            timingLabel = NotificationLocalization.text(.prayerAtTime, languageCode: languageCode)
        case .fifteenMinutesBefore:
            timingLabel = NotificationLocalization.text(.prayer15Before, languageCode: languageCode)
        case .thirtyMinutesBefore:
            timingLabel = NotificationLocalization.text(.prayer30Before, languageCode: languageCode)
        case .bothBeforeAndAtTime:
            timingLabel = NotificationLocalization.text(.prayerBoth, languageCode: languageCode)
        }
        parts.append("\(prayerLabel): \(settings.prayerNotificationsEnabled ? timingLabel : NotificationLocalization.text(.summaryOff, languageCode: languageCode))")

        if settings.dailyDuaEnabled {
            parts.append("\(NotificationLocalization.text(.dailyDua, languageCode: languageCode)): \(settings.dailyDuaTime.displayString())")
        }
        if settings.morningReminderEnabled {
            parts.append("\(NotificationLocalization.text(.summaryMorning, languageCode: languageCode)): \(settings.morningReminderTime.displayString())")
        }
        if settings.eveningReminderEnabled {
            parts.append("\(NotificationLocalization.text(.summaryEvening, languageCode: languageCode)): \(settings.eveningReminderTime.displayString())")
        }
        if settings.premiumEnabled && settings.sleepReminderEnabled {
            parts.append("\(NotificationLocalization.text(.summarySleep, languageCode: languageCode)): \(settings.sleepReminderTime.displayString())")
        }
        if settings.premiumEnabled && settings.smartRemindersEnabled {
            let intensity: String
            switch settings.smartReminderIntensity {
            case .light:
                intensity = NotificationLocalization.text(.intensityLight, languageCode: languageCode)
            case .balanced:
                intensity = NotificationLocalization.text(.intensityBalanced, languageCode: languageCode)
            case .frequent:
                intensity = NotificationLocalization.text(.intensityFrequent, languageCode: languageCode)
            }
            parts.append("\(NotificationLocalization.text(.summarySmart, languageCode: languageCode)): \(intensity)")
        }
        if settings.quietHours.isEnabled {
            parts.append(
                "\(NotificationLocalization.text(.summaryQuietHours, languageCode: languageCode)): \(settings.quietHours.start.displayString())-\(settings.quietHours.end.displayString())"
            )
        }

        return parts.joined(separator: separator)
    }
}

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    @Published var settings: NotificationSettings
    @Published var permissionState: AppNotificationPermissionState = .notDetermined
    @Published var deliverySettings: AppNotificationDeliverySettings = .empty
    @Published var isRebuilding: Bool = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    @Published var showSoftAsk: Bool = false

    private let settingsStore: NotificationSettingsStore
    private let permissionManager: NotificationPermissionManager
    private let lifecycleCoordinator: NotificationLifecycleCoordinator
    private let scheduler: NotificationScheduler
    private let debugTools: NotificationDebugTools
    private let summaryBuilder = NotificationSettingsSummaryBuilder()

    init(
        settingsStore: NotificationSettingsStore,
        permissionManager: NotificationPermissionManager,
        lifecycleCoordinator: NotificationLifecycleCoordinator,
        scheduler: NotificationScheduler,
        debugTools: NotificationDebugTools
    ) {
        self.settingsStore = settingsStore
        self.permissionManager = permissionManager
        self.lifecycleCoordinator = lifecycleCoordinator
        self.scheduler = scheduler
        self.debugTools = debugTools
        self.settings = settingsStore.settings
    }

    convenience init() {
        self.init(container: ServiceContainer.shared)
    }

    convenience init(container: ServiceContainer) {
        self.init(
            settingsStore: container.notificationSettingsStore,
            permissionManager: container.notificationPermissionManager,
            lifecycleCoordinator: container.notificationLifecycleCoordinator,
            scheduler: container.notificationScheduler,
            debugTools: container.notificationDebugTools
        )
    }

    var summaryText: String {
        summaryBuilder.summary(settings: settings)
    }

    var languageCode: String {
        settings.currentLanguageCode
    }

    var shouldShowPermissionAction: Bool {
        switch permissionState {
        case .notDetermined, .denied:
            return true
        case .authorized, .ephemeral, .provisional:
            return deliverySettings.needsSystemSettingsAttention
        }
    }

    var shouldShowQuietDeliveryWarning: Bool {
        permissionWarningMessage != nil
    }

    var permissionWarningMessage: String? {
        let attentionReasons = deliverySettings.attentionReasons
        guard !attentionReasons.isEmpty else { return nil }

        if attentionReasons.contains(.provisionalAuthorization) {
            return text(.permissionProvisionalMessage)
        }

        let hasSoundIssue = attentionReasons.contains(.soundDisabled)
        let hasBannerIssue = attentionReasons.contains(.alertsDisabled)
            || attentionReasons.contains(.notificationCenterDisabled)

        switch (hasSoundIssue, hasBannerIssue) {
        case (true, true):
            return text(.permissionSoundAndBannerDisabledMessage)
        case (true, false):
            return text(.permissionSoundDisabledMessage)
        case (false, true):
            return text(.permissionBannerDisabledMessage)
        case (false, false):
            return nil
        }
    }

    func text(_ key: NotificationUIKey) -> String {
        NotificationLocalization.text(key, languageCode: languageCode)
    }

    func refresh() async {
        settingsStore.reload()
        settings = settingsStore.settings
        deliverySettings = await permissionManager.refreshDeliverySettings()
        permissionState = deliverySettings.authorizationState
    }

    func binding<Value>(
        get: @escaping (NotificationSettings) -> Value,
        set: @escaping (inout NotificationSettings, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(self.settings) },
            set: { newValue in
                self.applyChange { settings in
                    set(&settings, newValue)
                }
            }
        )
    }

    func requestPermission() async {
        if permissionState == .notDetermined {
            showSoftAsk = true
            return
        }

        if permissionState == .provisional {
            _ = await permissionManager.requestAuthorization()
            deliverySettings = await permissionManager.refreshDeliverySettings()
            permissionState = deliverySettings.authorizationState

            if permissionState == .authorized || permissionState == .ephemeral {
                await lifecycleCoordinator.reconcile(reason: .settingsChanged)
            } else {
                permissionManager.openSystemSettings()
            }
            return
        }

        if permissionState == .denied || deliverySettings.needsSystemSettingsAttention {
            permissionManager.openSystemSettings()
            return
        }

        deliverySettings = await permissionManager.refreshDeliverySettings()
        permissionState = deliverySettings.authorizationState
    }

    func requestPermissionAfterSoftAsk() async {
        showSoftAsk = false
        let granted = await lifecycleCoordinator.requestPermissionAfterSoftAsk()
        deliverySettings = await permissionManager.refreshDeliverySettings()
        permissionState = deliverySettings.authorizationState
        if granted {
            toastMessage = text(.rebuildCompleted)
        }
    }

    func openSystemSettings() {
        permissionManager.openSystemSettings()
    }

    func rebuildNow() async {
        await performTask { [self] in
            await self.lifecycleCoordinator.applyUserSettings(self.settings)
            self.toastMessage = self.text(.rebuildCompleted)
        }
    }

    func sendTestNotification() async {
        deliverySettings = await permissionManager.refreshDeliverySettings()
        permissionState = deliverySettings.authorizationState

        if permissionState == .notDetermined {
            showSoftAsk = true
            return
        }

        if permissionState == .denied {
            permissionManager.openSystemSettings()
            return
        }

        await performTask { [self] in
            try await self.scheduler.sendDebugNotification(settings: self.settings)
            self.toastMessage = self.text(.testSent)
        }
    }

    func clearAll() async {
        await performTask { [self] in
            await self.scheduler.cancelAllAppNotifications()
        }
    }

    func printPending() async {
        await debugTools.printPendingRequests()
    }

    private func applyChange(_ mutation: (inout NotificationSettings) -> Void) {
        var updated = settings
        mutation(&updated)
        updated.clampPremiumFeatures()
        settings = updated

        Task { [self] in
            await self.lifecycleCoordinator.applyUserSettings(updated)
            await self.refresh()
        }
    }

    private func performTask(_ operation: @escaping () async throws -> Void) async {
        isRebuilding = true
        defer { isRebuilding = false }

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
