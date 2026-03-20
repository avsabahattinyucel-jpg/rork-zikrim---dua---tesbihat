import Foundation

enum AppStartupState: Equatable, Sendable {
    case launching
    case onboarding
    case unauthenticated
    case authenticatedFree
    case authenticatedPremium
    case failedRecoverably(BootstrapFailureContext)

    init(route: AppRoute) {
        switch route {
        case .onboarding:
            self = .onboarding
        case .unauthenticated:
            self = .unauthenticated
        case .authenticatedFree:
            self = .authenticatedFree
        case .authenticatedPremium:
            self = .authenticatedPremium
        }
    }

    var transitionKey: String {
        switch self {
        case .launching:
            return "launching"
        case .onboarding:
            return "onboarding"
        case .unauthenticated:
            return "unauthenticated"
        case .authenticatedFree:
            return "authenticatedFree"
        case .authenticatedPremium:
            return "authenticatedPremium"
        case .failedRecoverably:
            return "failedRecoverably"
        }
    }
}
