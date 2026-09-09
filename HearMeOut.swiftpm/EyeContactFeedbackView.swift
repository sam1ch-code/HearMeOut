import UIKit

/// A lightweight, camera-safe overlay used to make gaze feedback visible
/// without mixing presentation concerns into the detector or evaluator.
final class EyeContactFeedbackView: UIView {
    enum State {
        case readyToCalibrate
        case calibrating
        case eyeContact
        case lookingAway
        case lowConfidence
        case noFace
        case calibrationFailed(String)
    }

    private let outlineLayer = CAShapeLayer()
    private let statusLabel = UILabel()
    private let recalibrateButton = UIButton(type: .system)
    var onRecalibrateTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true

        outlineLayer.fillColor = UIColor.clear.cgColor
        outlineLayer.lineWidth = 7
        outlineLayer.lineJoin = .round
        layer.addSublayer(outlineLayer)

        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        statusLabel.layer.cornerRadius = 12
        statusLabel.layer.masksToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)

        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Recalibrate"
        configuration.image = UIImage(systemName: "arrow.clockwise")
        configuration.imagePadding = 6
        recalibrateButton.configuration = configuration
        recalibrateButton.isHidden = true
        recalibrateButton.translatesAutoresizingMaskIntoConstraints = false
        recalibrateButton.addTarget(self, action: #selector(recalibrateTapped), for: .touchUpInside)
        addSubview(recalibrateButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            recalibrateButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            recalibrateButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        setState(.readyToCalibrate)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        outlineLayer.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), cornerRadius: 18).cgPath
        outlineLayer.frame = bounds
    }

    func setState(_ state: State) {
        let details: (text: String, color: UIColor, showsRecalibrate: Bool)

        switch state {
        case .readyToCalibrate:
            details = ("Calibration required", .systemBlue, false)
        case .calibrating:
            details = ("Calibration in progress", .systemBlue, false)
        case .eyeContact:
            details = ("Eye contact detected", .systemGreen, true)
        case .lookingAway:
            details = ("Looking away", .systemRed, true)
        case .lowConfidence:
            details = ("Hold still and face the camera", .systemOrange, true)
        case .noFace:
            details = ("No face found\nMove into the camera frame", .systemOrange, true)
        case .calibrationFailed(let reason):
            details = (reason, .systemRed, false)
        }

        statusLabel.text = details.text
        outlineLayer.strokeColor = details.color.cgColor
        recalibrateButton.isHidden = !details.showsRecalibrate
    }

    @objc private func recalibrateTapped() {
        onRecalibrateTapped?()
    }
}
