import SwiftUI

// Kept as a compatibility wrapper for older references.
struct OnboardingFlowView: View {
    let authService: AuthService
    let onFinish: () -> Void

    var body: some View {
        OnboardingView(authService: authService, onFinish: onFinish)
    }
}
