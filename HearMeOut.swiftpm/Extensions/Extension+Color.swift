//  Created by Sam on 09/08/2026.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        
        let r: Double
        let g: Double
        let b: Double
        
        switch hex.count {
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            
        default:
            r = 0
            g = 0
            b = 0
        }
        
        self.init(red: r, green: g, blue: b)
    }
}
