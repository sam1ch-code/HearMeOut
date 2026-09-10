//  Created by Sukhrob on 10/09/26.
//

import SwiftUI

extension View {
    func withRouter() -> some View {
        modifier(RouterViewModfier())
    }
}
