import Foundation

@MainActor
final class NotificationDebugTools {
    private let scheduler: NotificationScheduler

    init(scheduler: NotificationScheduler) {
        self.scheduler = scheduler
    }

    func printPendingRequests() async {
        let pending = await scheduler.debugPendingRequests()
        #if DEBUG
        print("[NotificationDebug] Pending count: \(pending.count)")
        for item in pending {
            print("[NotificationDebug] \(item.id) | \(item.dateDescription) | \(item.title)")
        }
        #endif
    }
}
