import SwiftUI

struct AppRootView: View {
    @State private var viewModel = DeckViewModel()
    @State private var userViewModel = UserViewModel()
    @State private var path = NavigationPath()
    @Environment(AppleAuthManager.self) var authManager

    // Controls the custom left-to-right profile transition
    @State private var showProfile = false
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

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
            .fullScreenCover(isPresented: .init(
                        get: { !hasCompletedOnboarding },
                        set: { _ in }
                    )) {
                        OnboardingView()
                            .environment(viewModel)
                            .environment(userViewModel)
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
                }
            }
        }
        .onOpenURL { url in
            Task {
                await userViewModel.handleDeepLink(url)
            }
        }
        .alert("Connect Request", isPresented: Binding(
            get: { userViewModel.pendingConnectionUser != nil && userViewModel.user != nil },
            set: { if !$0 { userViewModel.pendingConnectionUser = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                userViewModel.pendingConnectionUser = nil
            }
            Button("Connect") {
                if let targetCode = userViewModel.pendingConnectionUser?.connectionCode {
                    Task {
                        await userViewModel.connect(usingCode: targetCode)
                    }
                }
            }
            .disabled(userViewModel.isLoading)
        } message: {
            if let targetUser = userViewModel.pendingConnectionUser {
                Text("Would you like to connect with \(targetUser.firstName) \(targetUser.lastName)?")
            }
        }
        .alert("Connection Failed", isPresented: Binding(
            get: { userViewModel.errorMessage != nil },
            set: { if !$0 { userViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(userViewModel.errorMessage ?? "")
        }
        .environment(userViewModel)
        .overlay {
            if userViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Loading...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }
}

enum AppRoute: Hashable {
    case matches
    case connections
}
