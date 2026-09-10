//  Created by Sukhrob on 10/09/26.
//

import Foundation

struct ActionButton<Action: ActionType>: Identifiable, Equatable {
    let model: ButtonModel
    let action: Action

    var id: String { model.id }
}
