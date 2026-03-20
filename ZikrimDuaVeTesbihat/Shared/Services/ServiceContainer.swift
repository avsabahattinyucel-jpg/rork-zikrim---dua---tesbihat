import Foundation

@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()

    let authService: AuthService
    let notificationPermissionManager: NotificationPermissionManager
    let notificationSettingsStore: NotificationSettingsStore
    let notificationScheduler: NotificationSchedulerImpl
    let notificationNavigationHandler: NotificationNavigationHandler
    let notificationLifecycleCoordinator: NotificationLifecycleCoordinator
    let notificationDebugTools: NotificationDebugTools

    init() {
        self.authService = AuthService()
        self.notificationPermissionManager = NotificationPermissionManager()

        let settingsStore = NotificationSettingsStore()
        self.notificationSettingsStore = settingsStore

        let contentFactory = NotificationContentFactory()
        let prayerProvider = LivePrayerTimesProvider()
        let prayerEngine = PrayerNotificationEngine(provider: prayerProvider, contentFactory: contentFactory)
        let dailyEngine = DailyReminderNotificationEngine(contentFactory: contentFactory)
        let smartEngine = SmartReminderNotificationEngine(contentFactory: contentFactory)
        let fridayEngine = FridayNotificationEngine(contentFactory: contentFactory)
        let specialDaysEngine = SpecialDaysNotificationEngine(contentFactory: contentFactory)

        let scheduler = NotificationSchedulerImpl(
            permissionManager: notificationPermissionManager,
            prayerEngine: prayerEngine,
            dailyEngine: dailyEngine,
            smartEngine: smartEngine,
            fridayEngine: fridayEngine,
            specialDaysEngine: specialDaysEngine
        )

        self.notificationScheduler = scheduler
        self.notificationNavigationHandler = NotificationNavigationHandler()
        self.notificationLifecycleCoordinator = NotificationLifecycleCoordinator(
            permissionManager: notificationPermissionManager,
            settingsStore: settingsStore,
            scheduler: scheduler,
            prayerSettings: PrayerSettings(),
            analytics: NotificationNoopAnalyticsTracker()
        )
        self.notificationDebugTools = NotificationDebugTools(scheduler: scheduler)
    }
}
