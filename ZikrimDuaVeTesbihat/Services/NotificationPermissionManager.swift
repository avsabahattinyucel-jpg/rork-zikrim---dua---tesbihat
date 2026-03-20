import Combine
import Foundation
import UIKit
import UserNotifications

enum AppNotificationDeliveryAttention: Equatable, Sendable {
    case provisionalAuthorization
    case soundDisabled
    case alertsDisabled
    case notificationCenterDisabled
}

struct AppNotificationDeliverySettings: Equatable, Sendable {
    var authorizationState: AppNotificationPermissionState
    var alertEnabled: Bool
    var soundEnabled: Bool
    var notificationCenterEnabled: Bool
    var lockScreenEnabled: Bool

    static let empty = AppNotificationDeliverySettings(
        authorizationState: .notDetermined,
        alertEnabled: false,
        soundEnabled: false,
        notificationCenterEnabled: false,
        lockScreenEnabled: false
    )

    var attentionReasons: [AppNotificationDeliveryAttention] {
        switch authorizationState {
        case .notDetermined, .denied:
            return []
        case .provisional:
            return [.provisionalAuthorization]
        case .authorized, .ephemeral:
            var reasons: [AppNotificationDeliveryAttention] = []
            if !soundEnabled {
                reasons.append(.soundDisabled)
            }
            if !alertEnabled {
                reasons.append(.alertsDisabled)
            }
            if !notificationCenterEnabled {
                reasons.append(.notificationCenterDisabled)
            }
            return reasons
        }
    }

    var needsSystemSettingsAttention: Bool {
        !attentionReasons.isEmpty
    }
}

enum AppNotificationPermissionState: String, Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    var isGranted: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        }
    }
}

@MainActor
final class NotificationPermissionManager: ObservableObject {
    @Published private(set) var state: AppNotificationPermissionState = .notDetermined
    @Published private(set) var deliverySettings: AppNotificationDeliverySettings = .empty

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        apply(settings)
        return settings.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let permissionState = await refreshStatus()
        guard permissionState == .notDetermined || permissionState == .provisional else {
            return permissionState.isGranted
        }
        return await requestAuthorization()
    }

    @discardableResult
    func refreshStatus() async -> AppNotificationPermissionState {
        let settings = await center.notificationSettings()
        apply(settings)
        return state
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            let refreshed = await refreshStatus()
            if granted || refreshed.isGranted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted || refreshed.isGranted
        } catch {
            state = .denied
            deliverySettings = .empty
            return false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }

    func refreshDeliverySettings() async -> AppNotificationDeliverySettings {
        let settings = await center.notificationSettings()
        apply(settings)
        return deliverySettings
    }

    private func apply(_ settings: UNNotificationSettings) {
        let mapped = Self.map(settings.authorizationStatus)
        state = mapped
        deliverySettings = AppNotificationDeliverySettings(
            authorizationState: mapped,
            alertEnabled: Self.isEnabled(settings.alertSetting),
            soundEnabled: Self.isEnabled(settings.soundSetting),
            notificationCenterEnabled: Self.isEnabled(settings.notificationCenterSetting),
            lockScreenEnabled: Self.isEnabled(settings.lockScreenSetting)
        )
    }

    private static func map(_ status: UNAuthorizationStatus) -> AppNotificationPermissionState {
        switch status {
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private static func isEnabled(_ setting: UNNotificationSetting) -> Bool {
        switch setting {
        case .enabled:
            return true
        case .disabled, .notSupported:
            return false
        @unknown default:
            return false
        }
    }
}
