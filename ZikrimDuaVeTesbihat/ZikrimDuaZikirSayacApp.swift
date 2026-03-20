import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications

private enum TestEnvironment {
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

private enum AppURLRelay {
    @MainActor static var handler: ((URL) -> Void)?
}

private nonisolated func appLog(_ message: @autoclosure () -> String) {
    fputs(message() + "\n", stderr)
}

@main
struct ZikrimDuaZikirSayacApp: App {
    @State private var bootstrapper: AppBootstrapper
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()

    init() {
        AppServices.configureCoreServicesIfNeeded(isRunningTests: TestEnvironment.isRunningTests)

        let serviceContainer = ServiceContainer.shared
        let bootstrapper = AppBootstrapper(
            services: serviceContainer,
            isRunningTests: TestEnvironment.isRunningTests
        )

        _bootstrapper = State(initialValue: bootstrapper)
    }

    var body: some Scene {
        WindowGroup {
            if TestEnvironment.isRunningTests {
                EmptyView()
            } else {
                RootContainerView(bootstrapper: bootstrapper)
                    .environmentObject(appState)
                    .environmentObject(themeManager)
                    .tint(themeManager.current.accent)
                    .preferredColorScheme(themeManager.preferredColorScheme)
                    .fontDesign(.rounded)
                    .onAppear {
                        AppURLRelay.handler = { url in
                            handleOpenURL(url)
                        }
                        NotificationRouteRelay.handler = { route in
                            appState.handleNotificationRoute(route)
                        }
                        if let bufferedRoute = NotificationRouteRelay.consumeBufferedRoute() {
                            appState.handleNotificationRoute(bufferedRoute)
                        }
                    }
                    .onOpenURL { url in
                        handleOpenURL(url)
                    }
            }
        }
    }

    private func handleOpenURL(_ url: URL) {
        if GoogleSignInURLHandler.handle(url) {
            return
        }

        if let deepLink = AppDeepLink(url: url) {
            appState.handleDeepLink(deepLink)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    override init() {
        super.init()

        if !TestEnvironment.isRunningTests, FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("[AppDelegate] Firebase configured during delegate initialization")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("[Push] AppDelegate didFinishLaunching called")
        if TestEnvironment.isRunningTests {
            return true
        }
        AppServices.configureCoreServicesIfNeeded()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        print("[Push] Delegates configured — Firebase app: \(FirebaseApp.app()?.name ?? "nil")")

        Task {
            await self.registerForRemoteNotificationsIfAuthorized()
        }

        return true
    }

    @MainActor
    private func registerForRemoteNotificationsIfAuthorized() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        print("[Push] Current authorization status: \(settings.authorizationStatus.rawValue)")

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            print("[Push] Already authorized — registering for remote notifications")
            UIApplication.shared.registerForRemoteNotifications()
        case .notDetermined:
            print("[Push] Permission not determined — onboarding/settings will request later")
        case .denied:
            print("[Push] Notifications denied by user")
        @unknown default:
            break
        }
    }

    nonisolated func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        appLog("[Push] APNs device token: \(tokenString)")
        if FirebaseApp.app() != nil {
            Messaging.messaging().apnsToken = deviceToken
        }
    }

    nonisolated func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Task { @MainActor in
            AppURLRelay.handler?(url)
        }
        return true
    }

    nonisolated func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        appLog("[Push] APNs registration failed: \(error.localizedDescription)")
    }

    nonisolated func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appLog("[Push] didReceiveRemoteNotification: \(userInfo)")
        if FirebaseApp.app() != nil {
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }
        completionHandler(.newData)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        appLog("[Push] Foreground notification received: \(userInfo)")
        if FirebaseApp.app() != nil {
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        appLog("[Push] Notification tapped: \(userInfo)")
        if FirebaseApp.app() != nil {
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }
        Task { @MainActor in
            ServiceContainer.shared.notificationNavigationHandler.handleNotificationResponse(response)
        }
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            appLog("[Push] FCM token is nil")
            return
        }
        appLog("[Push] FCM token: \(token)")

        Messaging.messaging().subscribe(toTopic: "all") { error in
            if let error = error {
                appLog("[Push] Topic subscription failed: \(error.localizedDescription)")
            } else {
                appLog("[Push] Subscribed to topic: all")
            }
        }

        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": token]
        )
    }
}
