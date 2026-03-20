import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class AppBootstrapper {
    let services: ServiceContainer
    let sessionStore: SessionStore
    let subscriptionStore: SubscriptionStore
    let onboardingStore: OnboardingStore

    private let isRunningTests: Bool
    private let minimumSplashDuration: Duration = .milliseconds(320)
    private let subscriptionTimeout: Duration = .seconds(2)
    private let launchWatchdogTimeout: Duration = .seconds(4)

    private(set) var startupState: AppStartupState = .launching
    private(set) var latestResult: BootstrapResult?

    private var bootstrapTask: Task<Void, Never>?
    private var launchWatchdogTask: Task<Void, Never>?
    private var hasCompletedInitialBootstrap = false
    private let clock = ContinuousClock()

    init(
        services: ServiceContainer,
        sessionStore: SessionStore? = nil,
        subscriptionStore: SubscriptionStore? = nil,
        onboardingStore: OnboardingStore? = nil,
        isRunningTests: Bool = false
    ) {
        self.services = services
        self.sessionStore = sessionStore ?? SessionStore(authService: services.authService)
        self.subscriptionStore = subscriptionStore ?? SubscriptionStore(authService: services.authService)
        self.onboardingStore = onboardingStore ?? OnboardingStore()
        self.isRunningTests = isRunningTests
    }

    func bootstrapIfNeeded() async {
        await runBootstrap(force: false)
    }

    func retry() async {
        await runBootstrap(force: true)
    }

    func completeOnboarding() async {
        onboardingStore.complete()
        await refreshRouteFromCurrentState(forcePremiumRefresh: false)
    }

    func handleSessionMutation() async {
        guard hasCompletedInitialBootstrap else { return }

        let sessionState = sessionStore.syncFromAuthService()

        switch sessionState {
        case .authenticated:
            apply(route: .authenticatedFree)
            _ = await preloadSubscriptionState(for: sessionState)
            apply(route: resolvedRoute(for: sessionState, accessLevel: subscriptionStore.accessLevel))
        case .guest:
            _ = await preloadSubscriptionState(for: sessionState)
            apply(route: resolvedRoute(for: sessionState, accessLevel: subscriptionStore.accessLevel))
        case .unauthenticated:
            subscriptionStore.syncFromCurrentServices(sessionState: sessionState)
            apply(route: onboardingStore.hasCompletedOnboarding ? .unauthenticated : .onboarding)
        case .restoring:
            break
        }
    }

    func handleSubscriptionMutation() {
        guard hasCompletedInitialBootstrap else { return }

        let sessionState = sessionStore.syncFromAuthService()
        _ = subscriptionStore.syncFromCurrentServices(sessionState: sessionState)

        guard onboardingStore.hasCompletedOnboarding else {
            apply(route: .onboarding)
            return
        }

        switch sessionState {
        case .authenticated, .guest:
            apply(route: resolvedRoute(for: sessionState, accessLevel: subscriptionStore.accessLevel))
        case .unauthenticated:
            apply(route: .unauthenticated)
        case .restoring:
            startupState = .launching
        }
    }

    private func runBootstrap(force: Bool) async {
        if !force, hasCompletedInitialBootstrap {
            return
        }

        if let bootstrapTask {
            await bootstrapTask.value
            return
        }

        startupState = .launching
        subscriptionStore.resetForLaunch()
        scheduleLaunchWatchdog()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performBootstrap()
        }

        bootstrapTask = task
        await task.value
        bootstrapTask = nil
    }

    private func performBootstrap() async {
        let startTime = clock.now

        do {
            try validateStartupConfiguration()
            AppServices.configureCoreServicesIfNeeded(isRunningTests: isRunningTests)

            async let localSettings = preloadLocalSettings()
            async let restoredSession = sessionStore.restoreSession()

            let (snapshot, sessionState) = await (localSettings, restoredSession)
            onboardingStore.sync(with: snapshot)

            AppServices.warmBackgroundCachesIfNeeded(isRunningTests: isRunningTests)

            let route: AppRoute
            var warnings: [String] = []

            if !onboardingStore.hasCompletedOnboarding {
                subscriptionStore.syncFromCurrentServices(sessionState: sessionState)
                route = .onboarding
            } else {
                switch sessionState {
                case .restoring, .unauthenticated:
                    subscriptionStore.syncFromCurrentServices(sessionState: .unauthenticated)
                    route = .unauthenticated
                case .guest:
                    let accessLevel = await preloadSubscriptionState(for: sessionState)
                    route = resolvedRoute(for: sessionState, accessLevel: accessLevel)
                case .authenticated:
                    let accessLevel = await preloadSubscriptionState(for: sessionState)
                    if accessLevel == .free {
                        warnings.append("subscription_fallback_free")
                    }
                    route = resolvedRoute(for: sessionState, accessLevel: accessLevel)
                }
            }

            await keepSplashVisible(from: startTime)

            latestResult = BootstrapResult(route: route, warnings: warnings)
            hasCompletedInitialBootstrap = true
            cancelLaunchWatchdog()
            apply(route: route)
        } catch is CancellationError {
            cancelLaunchWatchdog()
            return
        } catch {
            await keepSplashVisible(from: startTime)
            hasCompletedInitialBootstrap = false
            cancelLaunchWatchdog()
            applyFailure(BootstrapFailureContext.startup(debugMessage: error.localizedDescription))
        }
    }

    private func scheduleLaunchWatchdog() {
        cancelLaunchWatchdog()

        launchWatchdogTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: launchWatchdogTimeout)
            guard self.startupState == .launching else { return }
            self.forceResolveLaunchState()
        }
    }

    private func cancelLaunchWatchdog() {
        launchWatchdogTask?.cancel()
        launchWatchdogTask = nil
    }

    private func forceResolveLaunchState() {
        let sessionState = sessionStore.syncFromAuthService()
        let accessLevel = subscriptionStore.syncFromCurrentServices(sessionState: sessionState)

        let route: AppRoute
        if !onboardingStore.hasCompletedOnboarding {
            route = .onboarding
        } else {
            route = resolvedRoute(for: sessionState, accessLevel: accessLevel)
        }

        latestResult = BootstrapResult(
            route: route,
            warnings: (latestResult?.warnings ?? []) + ["launch_watchdog_fallback"]
        )
        hasCompletedInitialBootstrap = true

#if DEBUG
        print("[Bootstrap] launch_watchdog_fallback route=\(route.rawValue)")
#endif

        apply(route: route)
    }

    private func refreshRouteFromCurrentState(forcePremiumRefresh: Bool) async {
        guard hasCompletedInitialBootstrap else { return }

        let sessionState = sessionStore.syncFromAuthService()

        guard onboardingStore.hasCompletedOnboarding else {
            apply(route: .onboarding)
            return
        }

        switch sessionState {
        case .restoring:
            startupState = .launching
        case .unauthenticated:
            subscriptionStore.syncFromCurrentServices(sessionState: sessionState)
            apply(route: .unauthenticated)
        case .guest:
            if forcePremiumRefresh {
                let access = await preloadSubscriptionState(for: sessionState)
                apply(route: resolvedRoute(for: sessionState, accessLevel: access))
            } else {
                let access = subscriptionStore.syncFromCurrentServices(sessionState: sessionState)
                apply(route: resolvedRoute(for: sessionState, accessLevel: access))
            }
        case .authenticated:
            if forcePremiumRefresh {
                let access = await preloadSubscriptionState(for: sessionState)
                apply(route: resolvedRoute(for: sessionState, accessLevel: access))
            } else {
                let access = subscriptionStore.syncFromCurrentServices(sessionState: sessionState)
                apply(route: resolvedRoute(for: sessionState, accessLevel: access))
            }
        }
    }

    private func preloadLocalSettings() async -> LocalBootstrapSnapshot {
        AppServices.preloadLocalSettings()
    }

    private func preloadSubscriptionState(for sessionState: SessionStore.State) async -> SubscriptionStore.AccessLevel {
        let workTask = Task { @MainActor [weak self] in
            guard let self else { return SubscriptionStore.fallback(for: sessionState) }
            return await self.subscriptionStore.preload(for: sessionState)
        }

        let timeoutTask = Task {
            try? await Task.sleep(for: subscriptionTimeout)
            return SubscriptionStore.fallback(for: sessionState)
        }

        let accessLevel = await withTaskGroup(of: SubscriptionStore.AccessLevel.self) { group in
            group.addTask { await workTask.value }
            group.addTask { await timeoutTask.value }

            let first = await group.next() ?? .free
            group.cancelAll()
            workTask.cancel()
            timeoutTask.cancel()
            return first
        }

        subscriptionStore.syncFromCurrentServices(sessionState: sessionState)

        if accessLevel == .free && services.authService.isPremium {
            return .premium
        }

        return accessLevel
    }

    private func resolvedRoute(
        for sessionState: SessionStore.State,
        accessLevel: SubscriptionStore.AccessLevel
    ) -> AppRoute {
        switch sessionState {
        case .restoring, .unauthenticated:
            return .unauthenticated
        case .guest:
            return accessLevel == .premium ? .authenticatedPremium : .authenticatedFree
        case .authenticated:
            return accessLevel == .premium ? .authenticatedPremium : .authenticatedFree
        }
    }

    private func apply(route: AppRoute) {
        let nextState = AppStartupState(route: route)
        latestResult = BootstrapResult(route: route, warnings: latestResult?.warnings ?? [])

        guard startupState != nextState else { return }

        withAnimation(.easeInOut(duration: 0.28)) {
            startupState = nextState
        }
    }

    private func applyFailure(_ context: BootstrapFailureContext) {
        withAnimation(.easeInOut(duration: 0.28)) {
            startupState = .failedRecoverably(context)
        }
    }

    private func keepSplashVisible(from startTime: ContinuousClock.Instant) async {
        let elapsed = startTime.duration(to: clock.now)
        if elapsed < minimumSplashDuration {
            try? await Task.sleep(for: minimumSplashDuration - elapsed)
        }
    }

    private func validateStartupConfiguration() throws {
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        guard bundleName?.isEmpty == false else {
            throw NSError(
                domain: "AppBootstrapper",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "CFBundleName is missing from Info.plist."]
            )
        }
    }
}
