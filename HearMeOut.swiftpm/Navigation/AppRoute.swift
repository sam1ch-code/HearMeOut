import SwiftUI
import Observation

enum AppRoute: Hashable {
    case home
    case tutorial(TutorialType)
    case interviewMode
    case readingMode
    case result(String)
}

@Observable
final class Router {
    var path = NavigationPath()

    func navigateToTutorial(_ type: TutorialType) {
        path.append(AppRoute.tutorial(type))
    }

    func navigateToInterviewMode() {
        path.append(AppRoute.interviewMode)
    }

    func navigateToReadingMode() {
        path.append(AppRoute.readingMode)
    }

    func completeTutorial(_ type: TutorialType) {
        switch type {
        case .readingTutorial:
            path.append(AppRoute.readingMode)
        case .interviewTutorial:
            path.append(AppRoute.interviewMode)
        }
    }

    func navigateToResult(score: String) {
        path.append(AppRoute.result(score))
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum TutorialType: Hashable {
    case readingTutorial
    case interviewTutorial
}
