import Foundation
import GoogleSignIn

nonisolated enum GoogleSignInURLHandler {
    static func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
