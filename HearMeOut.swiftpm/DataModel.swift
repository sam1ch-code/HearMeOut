///*
//See the License.txt file for this sample’s licensing information.
//*/
//
//import AVFoundation
//import SwiftUI
//import os.log
//
//@MainActor
//final class DataModel: ObservableObject {
//    let camera = Camera()
//
//    @Published var viewfinderImage: Image?
//    @Published var thumbnailImage: Image?
//    
//    var isPhotosLoaded = false
//    
//    init() {
//        Task {
//            await handleCameraPreviews()
//        }
//    }
//    
//    func handleCameraPreviews() async {
//        let imageStream = camera.previewStream
//            .map { $0.image }
//
//        for await image in imageStream {
//            Task { @MainActor in
//                viewfinderImage = image
//            }
//        }
//    }
//}
//
//fileprivate extension CIImage {
//    var image: Image? {
//        let ciContext = CIContext()
//        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
//        return Image(decorative: cgImage, scale: 1, orientation: .up)
//    }
//}
//
//fileprivate extension Image.Orientation {
//
//    init(_ cgImageOrientation: CGImagePropertyOrientation) {
//        switch cgImageOrientation {
//        case .up: self = .up
//        case .upMirrored: self = .upMirrored
//        case .down: self = .down
//        case .downMirrored: self = .downMirrored
//        case .left: self = .left
//        case .leftMirrored: self = .leftMirrored
//        case .right: self = .right
//        case .rightMirrored: self = .rightMirrored
//        }
//    }
//}
//
//fileprivate let logger = Logger(subsystem: "com.apple.swiftplaygroundscontent.capturingphotos", category: "DataModel")

import SwiftUI
import UIKit
import AVFoundation
import Vision
import Speech

// MARK: - APP ENTRY POINT

//@main
//struct MyPlaygroundApp: App {
//
//    var body: some Scene {
//        WindowGroup {
//            UIKitApp()
//                .ignoresSafeArea()
//        }
//    }
//}


// MARK: - CONNECT SWIFTUI WITH UIKIT

struct UIKitApp: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UINavigationController {
        let startingVC = StartViewController()
        let navigationController = UINavigationController(rootViewController: startingVC)
        navigationController.navigationBar.prefersLargeTitles = true

        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController,
                                context: Context) {
    }
}


// MARK: - COLORS

extension UIColor {

    static let appPurple = UIColor(
        red: 205 / 255.0,
        green: 193 / 255.0,
        blue: 255 / 255.0,
        alpha: 1.0
    )

    static let appLightPurple = UIColor(
        red: 245 / 255.0,
        green: 239 / 255.0,
        blue: 255 / 255.0,
        alpha: 1.0
    )
}


// MARK: - START VIEW CONTROLLER

class StartViewController: UIViewController {

    private let speechCheckButton = UIButton(type: .system)
    private let visualSpeechButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Visual Speech"
        view.backgroundColor = .white

        setupUI()
    }

    private func setupUI() {

        let titleLabel = UILabel()
        titleLabel.text = "Improve Your\nPublic Speaking"
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.monospacedSystemFont(
            ofSize: 30,
            weight: .bold
        )

        let descriptionLabel = UILabel()
        descriptionLabel.text =
        "Practice your speech accuracy and eye contact."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .darkGray
        descriptionLabel.font = UIFont.systemFont(
            ofSize: 17
        )

        configureButton(
            speechCheckButton,
            title: "Speech Check",
            imageName: "waveform"
        )

        configureButton(
            visualSpeechButton,
            title: "Visual Speech",
            imageName: "eye"
        )

        speechCheckButton.addTarget(
            self,
            action: #selector(openSpeechCheck),
            for: .touchUpInside
        )

        visualSpeechButton.addTarget(
            self,
            action: #selector(openVisualSpeech),
            for: .touchUpInside
        )

        let stackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                descriptionLabel,
                speechCheckButton,
                visualSpeechButton
            ]
        )

        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([

            stackView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: -40
            ),

            stackView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 30
            ),

            stackView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -30
            ),

            speechCheckButton.heightAnchor.constraint(
                equalToConstant: 120
            ),

            visualSpeechButton.heightAnchor.constraint(
                equalToConstant: 120
            )
        ])
    }

    private func configureButton(
        _ button: UIButton,
        title: String,
        imageName: String
    ) {

        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)

        button.titleLabel?.font =
        UIFont.monospacedSystemFont(
            ofSize: 20,
            weight: .regular
        )

        button.backgroundColor = .appLightPurple

        button.layer.cornerRadius = 25
        button.clipsToBounds = true

        let image = UIImage(
            systemName: imageName
        )

        button.setImage(image, for: .normal)
        button.tintColor = .black

        button.imageView?.contentMode = .scaleAspectFit
    }

    @objc private func openSpeechCheck() {

        let vc = ModeIntroductionViewController(
            mode: .speechCheck
        )

        navigationController?.pushViewController(
            vc,
            animated: true
        )
    }

    @objc private func openVisualSpeech() {

        let vc = ModeIntroductionViewController(
            mode: .visualSpeech
        )

        navigationController?.pushViewController(
            vc,
            animated: true
        )
    }
}


// MARK: - MODE

enum ExerciseMode {

    case speechCheck
    case visualSpeech

    var title: String {

        switch self {
        case .speechCheck:
            return "Speech Check"

        case .visualSpeech:
            return "Visual Speech"
        }
    }

    var description: String {

        switch self {

        case .speechCheck:
            return """
            Read the text aloud while it scrolls on the screen.

            Your spoken words will be compared with the original text.

            When you are finished, press STOP to see your result.
            """

        case .visualSpeech:
            return """
            Speak while keeping your eyes focused toward the camera.

            Looking away for too long will count as a mistake.

            Every mistake reduces your final score.
            """
        }
    }
}


// MARK: - INTRODUCTION SCREEN

class ModeIntroductionViewController: UIViewController {

    private let mode: ExerciseMode

    init(mode: ExerciseMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = mode.title
        view.backgroundColor = .white

        setupUI()
    }

    private func setupUI() {

        let titleLabel = UILabel()
        titleLabel.text = mode.title
        titleLabel.font = UIFont.monospacedSystemFont(
            ofSize: 30,
            weight: .bold
        )
        titleLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.text = mode.description
        descriptionLabel.font = UIFont.systemFont(
            ofSize: 18
        )
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        let startButton = UIButton(type: .system)

        startButton.setTitle(
            "START EXERCISE",
            for: .normal
        )

        startButton.setTitleColor(
            .white,
            for: .normal
        )

        startButton.titleLabel?.font =
        UIFont.monospacedSystemFont(
            ofSize: 18,
            weight: .bold
        )

        startButton.backgroundColor = .appPurple
        startButton.layer.cornerRadius = 20

        startButton.addTarget(
            self,
            action: #selector(startExercise),
            for: .touchUpInside
        )

        let stackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                descriptionLabel,
                startButton
            ]
        )

        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([

            stackView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            stackView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 30
            ),

            stackView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -30
            ),

            startButton.heightAnchor.constraint(
                equalToConstant: 60
            )
        ])
    }

    @objc private func startExercise() {

        switch mode {

        case .speechCheck:

            navigationController?.pushViewController(
                SpeechCheckViewController(),
                animated: true
            )

        case .visualSpeech:

            navigationController?.pushViewController(
                VisualSpeechViewController(),
                animated: true
            )
        }
    }
}


// MARK: - SPEECH CHECK

class SpeechCheckViewController: UIViewController {

    private let beginButton = UIButton(type: .system)

    private let labelSample = UILabel()
    private let labelSampleContainer = UIView()

    private var viewResults = UIView()
    private let resultLabel = UILabel()
    private let transcriptLabel = UILabel()
    private let continueButton = UIButton(type: .system)

    private var matchingWords = 0

    private var isStarted = false

    private var fullTranscript = ""

    private let preMadeSpeech =
    """
    Occasional movements during sleep can be normal. This is a sample text that is long enough to scroll up slowly. Speaking clearly and confidently can help you become a better public speaker.
    """

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer =
    SFSpeechRecognizer()

    private var request =
    SFSpeechAudioBufferRecognitionRequest()

    private var task: SFSpeechRecognitionTask?


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Speech Check"
        view.backgroundColor = .white

        setupSample()
        setupButton()
        setupResults()
    }


    private func setupSample() {

        labelSampleContainer.translatesAutoresizingMaskIntoConstraints = false

        labelSampleContainer.clipsToBounds = true

        view.addSubview(labelSampleContainer)

        NSLayoutConstraint.activate([

            labelSampleContainer.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 40
            ),

            labelSampleContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 30
            ),

            labelSampleContainer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -30
            ),

            labelSampleContainer.heightAnchor.constraint(
                equalToConstant: 220
            )
        ])

        labelSample.text = preMadeSpeech
        labelSample.font =
        UIFont.monospacedSystemFont(
            ofSize: 22,
            weight: .regular
        )

        labelSample.numberOfLines = 0
        labelSample.textAlignment = .center

        labelSample.frame = CGRect(
            x: 0,
            y: 220,
            width: view.bounds.width - 60,
            height: 500
        )

        labelSampleContainer.addSubview(labelSample)
    }


    private func setupButton() {

        beginButton.setTitle(
            "START",
            for: .normal
        )

        beginButton.setTitleColor(
            .white,
            for: .normal
        )

        beginButton.titleLabel?.font =
        UIFont.monospacedSystemFont(
            ofSize: 20,
            weight: .bold
        )

        beginButton.backgroundColor = .appPurple
        beginButton.layer.cornerRadius = 20

        beginButton.translatesAutoresizingMaskIntoConstraints = false

        beginButton.addTarget(
            self,
            action: #selector(beginAction),
            for: .touchUpInside
        )

        view.addSubview(beginButton)

        NSLayoutConstraint.activate([

            beginButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            beginButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -40
            ),

            beginButton.widthAnchor.constraint(
                equalToConstant: 200
            ),

            beginButton.heightAnchor.constraint(
                equalToConstant: 60
            )
        ])
    }


    private func setupResults() {

        viewResults.backgroundColor = .appLightPurple
        viewResults.layer.cornerRadius = 25

        viewResults.translatesAutoresizingMaskIntoConstraints = false
        viewResults.isHidden = true

        resultLabel.font =
        UIFont.monospacedSystemFont(
            ofSize: 26,
            weight: .bold
        )

        resultLabel.textAlignment = .center

        transcriptLabel.numberOfLines = 0
        transcriptLabel.font =
        UIFont.systemFont(ofSize: 16)

        transcriptLabel.textAlignment = .center

        continueButton.setTitle(
            "CONTINUE",
            for: .normal
        )

        continueButton.setTitleColor(
            .white,
            for: .normal
        )

        continueButton.backgroundColor = .appPurple
        continueButton.layer.cornerRadius = 15

        continueButton.addTarget(
            self,
            action: #selector(returnHome),
            for: .touchUpInside
        )

        let stack = UIStackView(
            arrangedSubviews: [
                resultLabel,
                transcriptLabel,
                continueButton
            ]
        )

        stack.axis = .vertical
        stack.spacing = 20

        stack.translatesAutoresizingMaskIntoConstraints = false

        viewResults.addSubview(stack)
        view.addSubview(viewResults)

        NSLayoutConstraint.activate([

            viewResults.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            viewResults.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            viewResults.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 25
            ),

            viewResults.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -25
            ),

            stack.topAnchor.constraint(
                equalTo: viewResults.topAnchor,
                constant: 30
            ),

            stack.bottomAnchor.constraint(
                equalTo: viewResults.bottomAnchor,
                constant: -30
            ),

            stack.leadingAnchor.constraint(
                equalTo: viewResults.leadingAnchor,
                constant: 20
            ),

            stack.trailingAnchor.constraint(
                equalTo: viewResults.trailingAnchor,
                constant: -20
            ),

            continueButton.heightAnchor.constraint(
                equalToConstant: 50
            )
        ])
    }


    @objc private func beginAction() {

        isStarted.toggle()

        if isStarted {

            startSpeechRecognition()

            beginButton.setTitle(
                "STOP",
                for: .normal
            )

            animateSample()

        } else {

            stopSpeechRecognition()

            beginButton.isHidden = true

            showResults()
        }
    }


    private func animateSample() {

        let textHeight =
        labelSample.sizeThatFits(
            CGSize(
                width: labelSampleContainer.bounds.width,
                height: .greatestFiniteMagnitude
            )
        ).height

        labelSample.frame.size.height = textHeight

        UIView.animate(
            withDuration: 20,
            delay: 0,
            options: [.curveLinear],
            animations: {

                self.labelSample.frame.origin.y =
                -textHeight

            }
        )
    }


    private func cleanWords(
        from text: String
    ) -> [String] {

        let cleaned = text.lowercased().filter {
            $0.isLetter ||
            $0.isNumber ||
            $0.isWhitespace
        }

        return cleaned
            .components(
                separatedBy: .whitespacesAndNewlines
            )
            .filter { !$0.isEmpty }
    }


    private func compareWords() {

        let sampleWords =
        cleanWords(from: preMadeSpeech)

        let speechWords =
        cleanWords(from: fullTranscript)

        var sampleIndex = 0
        var count = 0

        for spokenWord in speechWords {

            while sampleIndex < sampleWords.count {

                if spokenWord ==
                    sampleWords[sampleIndex] {

                    count += 1
                    sampleIndex += 1

                    break

                } else {

                    sampleIndex += 1
                }
            }
        }

        matchingWords = count
    }


    private func showResults() {

        compareWords()

        let sampleWords =
        cleanWords(from: preMadeSpeech)

        let totalWords = sampleWords.count

        let percentage: Int

        if totalWords > 0 {

            percentage = Int(
                (Double(matchingWords) /
                 Double(totalWords)) * 100
            )

        } else {

            percentage = 0
        }

        resultLabel.text =
        """
        Your Result: \(percentage)%

        Matching Words:
        \(matchingWords) / \(totalWords)
        """

        transcriptLabel.text =
        """
        Your Speech:

        \(fullTranscript)
        """

        viewResults.isHidden = false
    }


    private func startSpeechRecognition() {

        request =
        SFSpeechAudioBufferRecognitionRequest()

        let node = audioEngine.inputNode

        let recordingFormat =
        node.outputFormat(forBus: 0)

        node.removeTap(onBus: 0)

        node.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { buffer, _ in

            self.request.append(buffer)
        }

        audioEngine.prepare()

        do {

            try audioEngine.start()

        } catch {

            print(error.localizedDescription)
        }

        task =
        speechRecognizer?.recognitionTask(
            with: request
        ) { response, error in

            if let response = response {

                self.fullTranscript =
                response.bestTranscription.formattedString
            }

            if let error = error {

                print(error.localizedDescription)
            }
        }
    }


    private func stopSpeechRecognition() {

        request.endAudio()

        task?.finish()
        task?.cancel()
        task = nil

        audioEngine.stop()

        audioEngine.inputNode.removeTap(onBus: 0)
    }


    @objc private func returnHome() {

        navigationController?.popToRootViewController(
            animated: true
        )
    }
}


// MARK: - VISUAL SPEECH

class VisualSpeechViewController:
    UIViewController,
    @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {


    private let beginButton = UIButton(type: .system)

    private var viewResults = UIView()
    private let resultLabel = UILabel()
    private let continueButton = UIButton(type: .system)

    private var isStarted = false

    private var userMistake = 0

    // Starts at 100.
    private var resultOverall = 100

    private var wasMistake = false


    private let captureSession =
    AVCaptureSession()

    private var previewLayer:
    AVCaptureVideoPreviewLayer!

    private let sequenceHandler =
    VNSequenceRequestHandler()


    private var strokeOverlay: UIView!


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Visual Speech"
        view.backgroundColor = .black

        setupCamera()
        setupStrokeOverlay()
        setupButton()
        setupResults()
    }


    private func setupButton() {

        beginButton.setTitle(
            "START",
            for: .normal
        )

        beginButton.setTitleColor(
            .white,
            for: .normal
        )

        beginButton.titleLabel?.font =
        UIFont.monospacedSystemFont(
            ofSize: 20,
            weight: .bold
        )

        beginButton.backgroundColor = .appPurple
        beginButton.layer.cornerRadius = 20

        beginButton.translatesAutoresizingMaskIntoConstraints = false

        beginButton.addTarget(
            self,
            action: #selector(beginAction),
            for: .touchUpInside
        )

        view.addSubview(beginButton)

        NSLayoutConstraint.activate([

            beginButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            beginButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -30
            ),

            beginButton.widthAnchor.constraint(
                equalToConstant: 200
            ),

            beginButton.heightAnchor.constraint(
                equalToConstant: 60
            )
        ])
    }


    @objc private func beginAction() {

        isStarted.toggle()

        if isStarted {

            userMistake = 0
            resultOverall = 100

            beginButton.setTitle(
                "STOP",
                for: .normal
            )

        } else {

            beginButton.isHidden = true

            showResults()
        }
    }


    // MARK: CAMERA

    private func setupCamera() {

        captureSession.sessionPreset = .high

        guard let camera =
                AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .front
                )
        else {
            return
        }

        do {

            let input =
            try AVCaptureDeviceInput(
                device: camera
            )

            if captureSession.canAddInput(input) {

                captureSession.addInput(input)
            }

            let output =
            AVCaptureVideoDataOutput()

            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey
                as String:
                    kCVPixelFormatType_32BGRA
            ]

            output.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(
                    label: "videoQueue"
                )
            )

            if captureSession.canAddOutput(output) {

                captureSession.addOutput(output)
            }

            previewLayer =
            AVCaptureVideoPreviewLayer(
                session: captureSession
            )

            previewLayer.frame =
            view.bounds

            previewLayer.videoGravity =
            .resizeAspectFill

            view.layer.insertSublayer(
                previewLayer,
                at: 0
            )

            captureSession.startRunning()

        } catch {

            print(error.localizedDescription)
        }
    }


    private func setupStrokeOverlay() {

        strokeOverlay = UIView(
            frame: view.bounds
        )

        strokeOverlay.backgroundColor =
        .clear

        strokeOverlay.layer.borderWidth = 5

        strokeOverlay.layer.borderColor =
        UIColor.green.cgColor

        strokeOverlay.layer.cornerRadius = 30

        strokeOverlay.layer.masksToBounds = true

        strokeOverlay.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        strokeOverlay.isUserInteractionEnabled =
        false

        view.addSubview(strokeOverlay)
    }


    // MARK: VISION

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard isStarted else {
            return
        }

        guard let pixelBuffer =
                CMSampleBufferGetImageBuffer(
                    sampleBuffer
                )
        else {
            return
        }

        let request =
        VNDetectFaceLandmarksRequest {
            [weak self] request, error in

            guard let self = self else {
                return
            }

            guard
                let faces =
                    request.results
                    as? [VNFaceObservation],
                let face =
                    faces.first,
                let landmarks =
                    face.landmarks
            else {
                return
            }

            guard
                let leftPupil =
                    landmarks.leftPupil,
                let leftEye =
                    landmarks.leftEye
            else {
                return
            }

            self.processEye(
                pupil: leftPupil,
                eye: leftEye
            )
        }

        do {

            try sequenceHandler.perform(
                [request],
                on: pixelBuffer,
                orientation: .right
            )

        } catch {

            print(error.localizedDescription)
        }
    }


    private func processEye(
        pupil: VNFaceLandmarkRegion2D,
        eye: VNFaceLandmarkRegion2D
    ) {

        guard
            let pupilPoint =
                pupil.normalizedPoints.first
        else {
            return
        }

        let eyePoints =
        eye.normalizedPoints

        guard !eyePoints.isEmpty else {
            return
        }

        let minX =
        eyePoints.map { $0.x }.min() ?? 0

        let maxX =
        eyePoints.map { $0.x }.max() ?? 1

        let minY =
        eyePoints.map { $0.y }.min() ?? 0

        let maxY =
        eyePoints.map { $0.y }.max() ?? 1

        let relativeX =
        (pupilPoint.x - minX) /
        (maxX - minX)

        let relativeY =
        (pupilPoint.y - minY) /
        (maxY - minY)


        let centeredX =
        relativeX > 0.25 &&
        relativeX < 0.75

        let centeredY =
        relativeY > 0.25 &&
        relativeY < 0.75

        let isCentered =
        centeredX && centeredY


        DispatchQueue.main.async {

            if !self.isStarted {
                return
            }

            if !isCentered {

                if !self.wasMistake {

                    self.wasMistake = true

                    self.userMistake += 1

                    // Every mistake removes 3.
                    self.resultOverall =
                    max(
                        0,
                        self.resultOverall - 3
                    )

                    self.flashRedStroke()
                }

            } else {

                self.wasMistake = false

                self.strokeOverlay.layer.borderColor =
                UIColor.green.cgColor
            }
        }
    }


    private func flashRedStroke() {

        strokeOverlay.layer.borderColor =
        UIColor.red.cgColor

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.5
        ) {

            if self.isStarted {

                self.strokeOverlay.layer.borderColor =
                UIColor.green.cgColor
            }
        }
    }


    private func setupResults() {

        viewResults.backgroundColor =
        .appLightPurple

        viewResults.layer.cornerRadius = 25

        viewResults.translatesAutoresizingMaskIntoConstraints =
        false

        viewResults.isHidden = true


        resultLabel.font =
        UIFont.monospacedSystemFont(
            ofSize: 25,
            weight: .bold
        )

        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center


        continueButton.setTitle(
            "CONTINUE",
            for: .normal
        )

        continueButton.setTitleColor(
            .white,
            for: .normal
        )

        continueButton.backgroundColor =
        .appPurple

        continueButton.layer.cornerRadius = 15

        continueButton.addTarget(
            self,
            action: #selector(returnHome),
            for: .touchUpInside
        )


        let stack =
        UIStackView(
            arrangedSubviews: [
                resultLabel,
                continueButton
            ]
        )

        stack.axis = .vertical
        stack.spacing = 25

        stack.translatesAutoresizingMaskIntoConstraints =
        false


        viewResults.addSubview(stack)
        view.addSubview(viewResults)


        NSLayoutConstraint.activate([

            viewResults.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            viewResults.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            viewResults.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 30
            ),

            viewResults.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -30
            ),

            stack.topAnchor.constraint(
                equalTo: viewResults.topAnchor,
                constant: 30
            ),

            stack.bottomAnchor.constraint(
                equalTo: viewResults.bottomAnchor,
                constant: -30
            ),

            stack.leadingAnchor.constraint(
                equalTo: viewResults.leadingAnchor,
                constant: 20
            ),

            stack.trailingAnchor.constraint(
                equalTo: viewResults.trailingAnchor,
                constant: -20
            ),

            continueButton.heightAnchor.constraint(
                equalToConstant: 50
            )
        ])
    }


    private func showResults() {

        resultLabel.text =
        """
        Eye Contact Result

        Mistakes: \(userMistake)

        Overall Score:
        \(resultOverall)%
        """

        viewResults.isHidden = false
    }


    @objc private func returnHome() {

        captureSession.stopRunning()

        navigationController?.popToRootViewController(
            animated: true
        )
    }
}
