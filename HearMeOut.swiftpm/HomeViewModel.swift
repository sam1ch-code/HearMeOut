//  Created by Sukhrob on 10/09/26.
//

import Foundation
import Combine

protocol HomeViewModelProtocol: ObservableObject {
    var state: HomeState { get }

    func handleIntent(_ intent: HandleIntent)
}

final class HomeViewModel: HomeViewModelProtocol {
    @Published private(set) var state: HomeState

    init(state: HomeState) {
        self.state = state
    }

    func handleIntent(_ intent: HandleIntent) {
        switch intent {
        case .navigateToInterviewFlow:
            print("someThing 2")
        case .navigateToReadingFlow:
            print("someThing")
        }
    }
}

struct HomeState: Equatable {
    let buttons: [ButtonModel] = [
        ButtonModel(title: "Interview Mode", subtitle: "Rehearse your next conversation", backgroundColor: .green, iconSystemName: "person.2.fill"),
        ButtonModel(title: "Reading Mode", subtitle: "Read aloud at your own pace", backgroundColor: .yellow, iconSystemName: "book.closed.fill")
    ]
}

enum HandleIntent: Equatable {
    case navigateToInterviewFlow
    case navigateToReadingFlow
}
