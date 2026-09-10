import SwiftUI
import Observation

enum AppRoute: Hashable {
    case home
    case tutorial(String)
    case interviewMode
    case readingMode
    case result(String)
}

@Observable
final class Router {
    var path = NavigationPath()

    func navigateToTutorial(_ id: String) {
        path.append(AppRoute.tutorial(id))
    }

    func navigateToInterviewMode() {
        path.append(AppRoute.interviewMode)
    }

    func navigateToReadingMode() {
        path.append(AppRoute.readingMode)
    }

    func navigateToResult(score: String) {
        path.append(AppRoute.result(score))
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}


