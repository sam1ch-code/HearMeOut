//  Created by Sukhrob on 10/09/26.
//

import SwiftUI

protocol ActionType: Hashable {}

struct ButtonModel: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let backgroundColor: Color
    let iconSystemName: String
}
