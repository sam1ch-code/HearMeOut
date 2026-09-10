//  Created by Sam on 31/08/2026.
//

import UIKit

final class CalibrationTargetView: UIView {
    private let dot = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        dot.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        dot.backgroundColor = .systemBlue
        dot.layer.cornerRadius = 12
        addSubview(dot)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func move(to point: CGPoint, animated: Bool) {
        let apply = { self.dot.center = point }
        animated ? UIView.animate(withDuration: 0.3, animations: apply) : apply()
    }

    /// Visual cue that a sample is actively being recorded — gives the
    /// user a reason to hold still right at the moment it matters.
    func setCollecting(_ collecting: Bool) {
        if collecting {
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.0
            pulse.toValue = 1.4
            pulse.duration = 0.5
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            dot.layer.add(pulse, forKey: "pulse")
        } else {
            dot.layer.removeAnimation(forKey: "pulse")
        }
    }
}
