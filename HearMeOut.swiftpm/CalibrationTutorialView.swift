import UIKit

/// Introduces calibration before the camera starts collecting samples. The
/// user remains in control: calibration begins only after tapping the button.
final class CalibrationTutorialView: UIView {
    var onStartTapped: (() -> Void)?

    private let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.25)

        card.layer.cornerRadius = 24
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        let title = UILabel()
        title.text = "Calibrate eye contact"
        title.font = .preferredFont(forTextStyle: .title2)
        title.textColor = .white

        let instructions = UILabel()
        instructions.text = "Keep your face in frame. A dot will move to five positions. Look at each dot and hold your gaze until it moves again."
        instructions.font = .preferredFont(forTextStyle: .body)
        instructions.textColor = .white
        instructions.numberOfLines = 0
        instructions.textAlignment = .center

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Start calibration"
        configuration.image = UIImage(systemName: "eye")
        configuration.imagePadding = 8
        let startButton = UIButton(configuration: configuration)
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, instructions, startButton])
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            card.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -28),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 420)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func startTapped() {
        onStartTapped?()
    }
}
