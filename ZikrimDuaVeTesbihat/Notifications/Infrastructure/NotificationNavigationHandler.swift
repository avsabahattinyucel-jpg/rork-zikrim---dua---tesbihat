import Foundation
import UserNotifications

@MainActor
enum NotificationRouteRelay {
    static var handler: ((NotificationRoute) -> Void)?
    private static var bufferedRoute: NotificationRoute?

    static func dispatch(_ route: NotificationRoute) {
        if let handler {
            handler(route)
        } else {
            bufferedRoute = route
        }
    }

    static func consumeBufferedRoute() -> NotificationRoute? {
        defer { bufferedRoute = nil }
        return bufferedRoute
    }
}

final class NotificationNavigationHandler {
    func route(from userInfo: [AnyHashable: Any]) -> NotificationRoute? {
        NotificationRoute(userInfo: userInfo)
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        guard let route = route(from: response.notification.request.content.userInfo) else { return }
        Task { @MainActor in
            NotificationRouteRelay.dispatch(route)
        }
    }
}
