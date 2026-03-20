import Foundation
import Observation

extension AuthUser: Equatable {
    static func == (lhs: AuthUser, rhs: AuthUser) -> Bool {
        lhs.id == rhs.id &&
        lhs.email == rhs.email &&
        lhs.displayName == rhs.displayName &&
        lhs.provider == rhs.provider &&
        lhs.createdAt == rhs.createdAt
    }
}

@Observable
@MainActor
final class SessionStore {
    enum State: Equatable, Sendable {
        case restoring
        case unauthenticated
        case guest(AuthUser)
        case authenticated(AuthUser)
    }

    private let authService: AuthService
    private(set) var state: State = .restoring

    init(authService: AuthService) {
        self.authService = authService
        syncFromAuthService()
    }

    func restoreSession() async -> State {
        syncFromAuthService()
    }

    @discardableResult
    func syncFromAuthService() -> State {
        if let user = authService.currentUser {
            state = user.provider == .anonymous ? .guest(user) : .authenticated(user)
        } else {
            state = .unauthenticated
        }

        return state
    }
}
