import SwiftUI

struct ManeviRehberView: View {
    let authService: AuthService

    var body: some View {
        ExploreMapView(authService: authService)
    }
}
