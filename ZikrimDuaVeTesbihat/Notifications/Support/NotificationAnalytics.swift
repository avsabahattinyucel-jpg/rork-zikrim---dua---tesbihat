import Foundation

protocol NotificationAnalyticsTracking: Sendable {
    func track(event: String, metadata: [String: String])
}

struct NotificationNoopAnalyticsTracker: NotificationAnalyticsTracking {
    func track(event: String, metadata: [String: String]) {
        #if DEBUG
        let joined = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        print("[NotificationsAnalytics] \(event) \(joined)")
        #endif
    }
}
