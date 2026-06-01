import SwiftUI

struct AppRootView: View {
    @State private var viewModel = DeckViewModel()
    @State private var userViewModel = UserViewModel()
    @State private var path = NavigationPath()
    @Environment(AppleAuthManager.self) var authManager

    var body: some View {
        NavigationStack(path: $path) {
            // OLA: Consider calling viewModel.fetchCards() from a .task modifier here to load from cloud on launch.
            MainFeedView(
                viewModel: viewModel,
                openProfile: {
                    path.append(AppRoute.profile)
                },
                openMatches: {
                    path.append(AppRoute.matches)
                }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .profile:
                    ProfileDeckView(viewModel: viewModel)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden()

                case .matches:
                    MatchesView(viewModel: viewModel)
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
    case profile
    case matches
}
