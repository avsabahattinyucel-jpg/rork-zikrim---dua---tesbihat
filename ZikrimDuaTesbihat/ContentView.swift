import SwiftUI

struct ContentView: View {
    private let sourceHashRefreshMarker: String = "2026-03-02-reset-1"
    let authService: AuthService
    @State private var storage = StorageService()
    @State private var selectedTab: Int = 0
    @State private var showPrayerScreen: Bool = false
    @State private var notificationService = NotificationService()
    @State private var showAuthScreen: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Günlük", systemImage: "sun.max.fill", value: 0) {
                GunlukView(storage: storage, authService: authService, onOpenPrayer: { showPrayerScreen = true }, onNavigateToTab: { tab in selectedTab = tab })
            }
            Tab("Zikirlerim", systemImage: "circle.circle.fill", value: 1) {
                CounterView(storage: storage, onGoHome: { selectedTab = 0 })
            }
            Tab("Rehber", systemImage: "books.vertical.fill", value: 2) {
                ZikirRehberiView(storage: storage) {
                    selectedTab = 1
                }
            }
            Tab("Kur'an", systemImage: "book.closed.fill", value: 3) {
                KuranView(storage: storage)
            }
            Tab("Daha Fazla", systemImage: "ellipsis.circle.fill", value: 4) {
                MoreDashboardView(storage: storage, authService: authService)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ManeviAssistantOverlayView()
        }
        .sheet(isPresented: $showPrayerScreen) {
            NavigationStack {
                NamazVakitleriView()
            }
        }
        .fullScreenCover(isPresented: $showAuthScreen) {
            AuthView(authService: authService)
        }
        .onAppear {
            showAuthScreen = !authService.isLoggedIn
        }
        .onChange(of: authService.isLoggedIn) { _, isLoggedIn in
            showAuthScreen = !isLoggedIn
        }
        .task {
            await notificationService.checkAuthorization()
            let shouldScheduleSmartNotifications: Bool = notificationService.smartNotificationsEnabled && notificationService.isAuthorized
            notificationService.markUserActivityNow()
            if shouldScheduleSmartNotifications {
                notificationService.scheduleSmartNotifications()
            }
            if notificationService.morningReminderEnabled && notificationService.isAuthorized {
                notificationService.scheduleMorningReminder()
            }
            if notificationService.eveningReminderEnabled && notificationService.isAuthorized {
                notificationService.scheduleEveningReminder()
            }
        }
    }
}
