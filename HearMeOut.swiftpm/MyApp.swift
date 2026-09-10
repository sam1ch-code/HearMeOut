import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView<HomeViewModel>(viewModel: HomeViewModel(state: HomeState()))
                .withRouter()
        }
    }
}
