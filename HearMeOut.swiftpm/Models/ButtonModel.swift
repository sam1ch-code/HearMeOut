//  Created by Sukhrob on 10/09/26.
//

import SwiftUI

struct ButtonModel: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let backgroundColor: Color
    let iconSystemName: String

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        backgroundColor: Color,
        iconSystemName: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
        self.iconSystemName = iconSystemName
    }
}
