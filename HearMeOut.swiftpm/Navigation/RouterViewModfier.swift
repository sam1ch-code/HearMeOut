//  Created by Sukhrob on 10/09/26.
//

import SwiftUI

struct RouterViewModfier: ViewModifier {
    @State private var router = Router()

    private func routeView(for route: AppRoute) -> some View {
        Group {
            switch route {
            case .home:
                VStack{}
            case .tutorial(let type):
                TutorialView(type: type)
            case .interviewMode:
                ContentView()
            case .readingMode:
                VStack{}
            case .result(let string):
                VStack{}
            }
        }
        .environment(router)
    }

    func body(content: Content) -> some View {
        NavigationStack(path: $router.path) {
            content
                .environment(router)
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(for: route)
                }
        }
    }
}
