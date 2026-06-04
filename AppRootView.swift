import SwiftUI

struct AppRootView: View {
    @State private var viewModel = DeckViewModel()
    @State private var userViewModel = UserViewModel()
    @State private var path = NavigationPath()
    @Environment(AppleAuthManager.self) var authManager

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
            .task {
                if let id = authManager.currentUserProfile?.userID {
                    await userViewModel.load(id: id)
                    // Scope the deck/feed to the real signed-in user + their connections.
                    if let signedInUser = userViewModel.user {
                        viewModel.bind(to: signedInUser)
                        await viewModel.reloadFeed()
                    }
                }
            }
            // Re-bind when the profile/connections change (e.g. after connecting to someone)
            // so the feed refreshes with the new connections.
            .onChange(of: userViewModel.user) { _, newUser in
                if let newUser {
                    viewModel.bind(to: newUser)
                    Task { await viewModel.reloadFeed() }
                }
            }
        }
        .onOpenURL { url in
            userViewModel.handleDeepLink(url)
        }
        // TODO(EL): Observe `userViewModel.pendingConnectionCode`.
        // When it is not nil, show your custom Confirmation Popup or use .alert (you are the wizard here). 
        // 1. If they tap Cancel, set `userViewModel.pendingConnectionCode = nil` to close it.
        // 2. If they tap Connect, call `await userViewModel.connect(usingCode:)` (it will auto-close when done).
        // 3. Disable your Connect button while `userViewModel.isLoading` is true.
        // 4. Observe `userViewModel.errorMessage` for any connection failures.
        .environment(userViewModel)
    }
}

enum AppRoute: Hashable {
    case matches
    case connections
}
