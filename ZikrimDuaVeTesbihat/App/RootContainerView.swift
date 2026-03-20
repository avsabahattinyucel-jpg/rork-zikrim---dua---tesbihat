import SwiftUI

struct RootContainerView: View {
    let bootstrapper: AppBootstrapper

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var prayerViewModel = PrayerTimesViewModel.shared
    private let notificationCoordinator = ServiceContainer.shared.notificationLifecycleCoordinator

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundView
                .ignoresSafeArea()

            destinationView
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.985)),
                        removal: .opacity
                    )
                )
        }
        .tint(themeManager.currentTheme.accent)
        .animation(.easeInOut(duration: 0.28), value: bootstrapper.startupState.transitionKey)
        .animation(.easeInOut(duration: 0.18), value: themeManager.currentTheme.runtimeSignature)
        .task {
            await bootstrapper.bootstrapIfNeeded()
        }
        .onAppear {
            syncThemeAppearance()
            prayerViewModel.refresh()
            Task { await prayerViewModel.rescheduleNotificationsIfPossible() }
            Task { await notificationCoordinator.handleSceneDidBecomeActive(premiumEnabled: bootstrapper.subscriptionStore.isPremium) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncThemeAppearance()
                prayerViewModel.refresh()
                Task { await prayerViewModel.rescheduleNotificationsIfPossible() }
                Task {
                    await bootstrapper.subscriptionStore.refresh(force: false)
                    await notificationCoordinator.handleSceneDidBecomeActive(premiumEnabled: bootstrapper.subscriptionStore.isPremium)
                }
            }
        }
        .onChange(of: systemColorScheme) { _, newValue in
            themeManager.syncAppearance(using: newValue)
        }
        .onChange(of: bootstrapper.subscriptionStore.accessLevel) { _, _ in
            syncThemeAppearance()
            Task { await notificationCoordinator.updatePremiumState(isPremium: bootstrapper.subscriptionStore.isPremium) }
        }
        .onChange(of: bootstrapper.services.authService.currentUser?.id) { _, _ in
            Task { await bootstrapper.handleSessionMutation() }
        }
        .onChange(of: bootstrapper.services.authService.isPremium) { _, _ in
            syncThemeAppearance()
            bootstrapper.handleSubscriptionMutation()
            Task { await notificationCoordinator.updatePremiumState(isPremium: bootstrapper.services.authService.isPremium) }
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch bootstrapper.startupState {
        case .launching:
            SplashView()
        case .onboarding:
            OnboardingView(authService: bootstrapper.services.authService) {
                Task { await bootstrapper.completeOnboarding() }
            }
        case .unauthenticated:
            AuthView(
                authService: bootstrapper.services.authService,
                closeAction: .continueAsGuest
            )
        case .authenticatedFree:
            MainTabShell(
                authService: bootstrapper.services.authService,
                subscriptionAccess: .free,
                subscriptionStore: bootstrapper.subscriptionStore
            )
        case .authenticatedPremium:
            MainTabShell(
                authService: bootstrapper.services.authService,
                subscriptionAccess: .premium,
                subscriptionStore: bootstrapper.subscriptionStore
            )
        case .failedRecoverably(let context):
            ErrorRecoveryView(context: context) {
                Task { await bootstrapper.retry() }
            }
        }
    }

    private func syncThemeAppearance() {
        themeManager.syncAppearance(using: systemColorScheme)

        switch bootstrapper.subscriptionStore.accessLevel {
        case .premium:
            themeManager.enforceSubscriptionAccess(isPremiumUnlocked: true)
        case .free:
            themeManager.enforceSubscriptionAccess(isPremiumUnlocked: false)
        case .loading:
            switch bootstrapper.sessionStore.state {
            case .guest, .unauthenticated:
                themeManager.enforceSubscriptionAccess(isPremiumUnlocked: false)
            case .authenticated, .restoring:
                break
            }
        }
    }
}
