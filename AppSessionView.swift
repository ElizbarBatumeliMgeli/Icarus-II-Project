//
//  AppSessionView.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 29/05/2026.
//

import SwiftUI

/// The master router for the application.
/// It checks the user's authentication state and decides whether to show the login screen or the main app.
struct AppSessionView: View {
    @State private var authManager = AppleAuthManager()

    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                ProgressView("Loading…")

            case .signedIn:
                if authManager.currentUserProfile != nil {
                    AppRootView()
                }

            case .signedOut:
                SignInView()
            }
        }
        // Inject the auth manager so any deep view (like the Profile screen) can log out.
        .environment(authManager)
    }
}

#Preview {
    AppSessionView()
}
