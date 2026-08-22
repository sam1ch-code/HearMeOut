//  Created by Sam on 17/08/2026.
//

import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("frame")

    var body: some View {
        if let image {
            GeometryReader { geometry in
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        } else {
            Color.black
        }
    }
}
