///*
//See the License.txt file for this sample’s licensing information.
//*/
//
//import AVFoundation
//import CoreImage
//import UIKit
//import os.log
//
//final class Camera: NSObject {
//    private let captureSession = AVCaptureSession()
//    private var isCaptureSessionConfigured = false
//    private var deviceInput: AVCaptureDeviceInput?
//    private var videoOutput: AVCaptureVideoDataOutput?
//    private var sessionQueue: DispatchQueue!
//
//    private var frontCaptureDevice: AVCaptureDevice? {
//        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
//    }
//
//    var isRunning: Bool {
//        captureSession.isRunning
//    }
//
//    private var addToPreviewStream: ((CIImage) -> Void)?
//
//    var isPreviewPaused = false
//
//    lazy var previewStream: AsyncStream<CIImage> = {
//        AsyncStream { continuation in
//            addToPreviewStream = { ciImage in
//                if !self.isPreviewPaused {
//                    continuation.yield(ciImage)
//                }
//            }
//        }
//    }()
//
//    override init() {
//        super.init()
//        initialize()
//    }
//
//    private func initialize() {
//        sessionQueue = DispatchQueue(label: "session queue")
//
//        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//        NotificationCenter.default.addObserver(self, selector: #selector(updateForDeviceOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
//    }
//
//    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
//
//        var success = false
//
//        self.captureSession.beginConfiguration()
//
//        defer {
//            self.captureSession.commitConfiguration()
//            completionHandler(success)
//        }
//
//        guard
//            let captureDevice = frontCaptureDevice,
//            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
//        else {
//            logger.error("Failed to obtain front camera video input.")
//            return
//        }
//
//        captureSession.sessionPreset = AVCaptureSession.Preset.high
//
//        let videoOutput = AVCaptureVideoDataOutput()
//        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))
//
//        guard captureSession.canAddInput(deviceInput) else {
//            logger.error("Unable to add device input to capture session.")
//            return
//        }
//        guard captureSession.canAddOutput(videoOutput) else {
//            logger.error("Unable to add video output to capture session.")
//            return
//        }
//
//        captureSession.addInput(deviceInput)
//        captureSession.addOutput(videoOutput)
//
//        self.deviceInput = deviceInput
//        self.videoOutput = videoOutput
//
//        updateVideoOutputConnection()
//
//        isCaptureSessionConfigured = true
//
//        success = true
//    }
//
//    private func checkAuthorization() async -> Bool {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized:
//            logger.debug("Camera access authorized.")
//            return true
//        case .notDetermined:
//            logger.debug("Camera access not determined.")
//            sessionQueue.suspend()
//            let status = await AVCaptureDevice.requestAccess(for: .video)
//            sessionQueue.resume()
//            return status
//        case .denied:
//            logger.debug("Camera access denied.")
//            return false
//        case .restricted:
//            logger.debug("Camera library access restricted.")
//            return false
//        @unknown default:
//            return false
//        }
//    }
//
//    private func updateVideoOutputConnection() {
//        if let videoOutput = videoOutput, let videoOutputConnection = videoOutput.connection(with: .video) {
//            if videoOutputConnection.isVideoMirroringSupported {
//                videoOutputConnection.isVideoMirrored = true
//            }
//        }
//    }
//
//    func start() async {
//        let authorized = await checkAuthorization()
//        guard authorized else {
//            logger.error("Camera access was not authorized.")
//            return
//        }
//
//        if isCaptureSessionConfigured {
//            if !captureSession.isRunning {
//                sessionQueue.async { [self] in
//                    self.captureSession.startRunning()
//                }
//            }
//            return
//        }
//
//        sessionQueue.async { [unowned self] in
//            self.configureCaptureSession { success in
//                guard success else { return }
//                self.captureSession.startRunning()
//            }
//        }
//    }
//
//    func stop() {
//        guard isCaptureSessionConfigured else { return }
//
//        if captureSession.isRunning {
//            sessionQueue.async {
//                self.captureSession.stopRunning()
//            }
//        }
//    }
//
//    private var deviceOrientation: UIDeviceOrientation {
//        var orientation = UIDevice.current.orientation
//        if orientation == UIDeviceOrientation.unknown {
//            orientation = UIScreen.main.orientation
//        }
//        return orientation
//    }
//
//    @objc
//    func updateForDeviceOrientation() {
//        //TODO: Figure out if we need this for anything.
//    }
//
//    private func videoOrientationFor(_ deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
//        switch deviceOrientation {
//        case .portrait: return AVCaptureVideoOrientation.portrait
//        case .portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
//        case .landscapeLeft: return AVCaptureVideoOrientation.landscapeRight
//        case .landscapeRight: return AVCaptureVideoOrientation.landscapeLeft
//        default: return nil
//        }
//    }
//}
//
//extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
//
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
//
//        if connection.isVideoOrientationSupported,
//           let videoOrientation = videoOrientationFor(deviceOrientation) {
//            connection.videoOrientation = videoOrientation
//        }
//
//        addToPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
//    }
//}
//
//fileprivate extension UIScreen {
//
//    var orientation: UIDeviceOrientation {
//        let point = coordinateSpace.convert(CGPoint.zero, to: fixedCoordinateSpace)
//        if point == CGPoint.zero {
//            return .portrait
//        } else if point.x != 0 && point.y != 0 {
//            return .portraitUpsideDown
//        } else if point.x == 0 && point.y != 0 {
//            return .landscapeRight //.landscapeLeft
//        } else if point.x != 0 && point.y == 0 {
//            return .landscapeLeft //.landscapeRight
//        } else {
//            return .unknown
//        }
//    }
//}
//
//fileprivate let logger = Logger(subsystem: "com.example.eyecontact", category: "Camera")
