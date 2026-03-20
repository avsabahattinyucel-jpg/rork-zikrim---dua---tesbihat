import SwiftUI

struct MainTabShell: View {
    let authService: AuthService
    let subscriptionAccess: SubscriptionStore.AccessLevel
    let subscriptionStore: SubscriptionStore

    var body: some View {
        RootTabContainer(
            authService: authService,
            subscriptionAccess: subscriptionAccess,
            subscriptionStore: subscriptionStore
        )
    }
}
