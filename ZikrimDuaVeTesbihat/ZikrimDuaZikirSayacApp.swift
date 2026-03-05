import SwiftUI
import FirebaseCore
import FirebaseMessaging
import RevenueCat
import UserNotifications

@main
struct ZikrimDuaZikirSayacApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var authService: AuthService
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        if FirebaseApp.app() == nil, Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        RevenueCatService.shared.configure()
        AdService.shared.configure()
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView(authService: authService)
                } else {
                    OnboardingFlowView(authService: authService) {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .fontDesign(.rounded)
            .onOpenURL { url in
                handleOpenURL(url)
            }
        }
    }

    private func handleOpenURL(_ url: URL) {
        _ = GoogleSignInURLHandler.handle(url)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    nonisolated func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } catch {}
            } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        return true
    }

    nonisolated func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("GCM_TOKEN_HERE APNs token: \(tokenString)")
        Messaging.messaging().apnsToken = deviceToken
    }

    nonisolated func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error.localizedDescription)")
    }

    nonisolated func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("GCM_TOKEN_HERE: Token is nil")
            return
        }
        print("GCM_TOKEN_HERE: \(token)")
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": token]
        )
    }
}
