import SwiftUI

import SwiftUI

struct AppRootView: View {
    @State private var viewModel = DeckViewModel()
    @State private var path = NavigationPath()
    
    // Controls the custom left-to-right profile transition
    @State private var showProfile = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Base Feed Layer
                MainFeedView(
                    viewModel: viewModel,
                    openProfile: {
                        // Slide the profile in from the left
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showProfile = true
                        }
                    },
                    openMatches: {
                        path.append(AppRoute.matches)
                    }
                )

                // Left-to-Right Profile Overlay
                if showProfile {
                    ProfileDeckView(
                        viewModel: viewModel,
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showProfile = false
                            }
                        },
                        openConnections: {
                            path.append(AppRoute.connections)
                        }
                    )
                    .transition(.move(edge: .leading))
                    .zIndex(1) // Ensures it slides over the feed
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .matches:
                    MatchesView(viewModel: viewModel)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden()
                case .connections:
                    ConnectionsView()
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden()
                }
            }
        }
    }
}

enum AppRoute: Hashable {
    case matches
    case connections
}
