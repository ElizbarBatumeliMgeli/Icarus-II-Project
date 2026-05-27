import SwiftUI

struct AppRootView: View {
    @State private var viewModel = DeckViewModel()
    @State private var path = NavigationPath()

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
        }
    }
}

enum AppRoute: Hashable {
    case profile
    case matches
}
