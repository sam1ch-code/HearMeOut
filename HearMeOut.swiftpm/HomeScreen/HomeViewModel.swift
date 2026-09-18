//  Created by Sukhrob on 10/09/26.
//

import Foundation
import Combine

protocol HomeViewModelProtocol: ObservableObject {
    var state: HomeState { get }
}

final class HomeViewModel: HomeViewModelProtocol {
    @Published private(set) var state: HomeState

    init(state: HomeState) {
        self.state = state
    }
}

struct HomeState: Equatable {
    enum HomeAction: ActionType, Equatable {
        case interview
        case reading
    }

    let buttons: [ActionButton<HomeAction>] = [
        ActionButton(
            model: ButtonModel(id: UUID().uuidString, title: "Interview Mode", subtitle: "Rehearse your next conversation", backgroundColor: .green, iconSystemName: "person.2.fill"),
            action: HomeAction.interview
        ),
        ActionButton(
            model: ButtonModel(id: UUID().uuidString, title: "Reading Mode", subtitle: "Read aloud at your own pace", backgroundColor: .yellow, iconSystemName: "book.closed.fill"),
            action: HomeAction.reading)
    ]
}
