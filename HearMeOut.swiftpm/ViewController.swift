//  Created by Sukhrob on 25/08/26.
//

import UIKit
import AVFoundation
import SwiftUI

class ViewController: UIViewController, @MainActor AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false
    
    private let captureSession = AVCaptureSession()
    // TODO: Add qos
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil
    
    /// Detector
    nonisolated(unsafe) private var videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private let gazeDetector = GazeDetector()
    nonisolated(unsafe) private var boundaryEvaluator: GazeBoundaryEvaluator?
    nonisolated(unsafe) private let calibrationCoordinator = CalibrationCoordinator()
    nonisolated(unsafe) private var calibrationTargetView: CalibrationTargetView?
    nonisolated(unsafe) private var isCalibrating = false
    
    private var hasAppeared = false
    private var isSessionRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gazeDetector.onObservation = { [weak self] observation in
            self?.handleGazeObservation(observation)
        }
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setUpCaptureSession()
            self.captureSession.startRunning()
            
            // Signal readiness back on main — same hop already used
            // below for adding the preview layer.
            DispatchQueue.main.async { [weak self] in
                self?.cameraSessionDidStart()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
        attemptStartCalibrationIfReady()
    }

    private func cameraSessionDidStart() {
        isSessionRunning = true
        attemptStartCalibrationIfReady()
    }

    private func attemptStartCalibrationIfReady() {
        guard hasAppeared, isSessionRunning, !isCalibrating, boundaryEvaluator == nil else { return }
        startCalibration()
    }
    
    nonisolated func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    nonisolated func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func setUpCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        previewLayer.connection?.videoRotationAngle = 0
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoRotationAngle = 0
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.view.layer.addSublayer(self.previewLayer)
        }
    }
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        gazeDetector.handle(pixelBuffer)
    }
    
    private func handleGazeObservation(_ observation: GazeObservation) {
        switch observation {
        case .detected(let reading):
            if isCalibrating {
                calibrationCoordinator.handle(reading, timestamp: reading.timestamp)
                return
            }
            
            guard let evaluator = boundaryEvaluator else { return }  // calibration not run yet
            
            switch evaluator.evaluate(reading, viewBounds: view.bounds) {
            case .withinBounds:
                print("🚀 Face Found and eye contact enabled")
            case .exceeded(_, let direction):
                print("No Eye Contact")
            }
        case .noFace:
            print("No Face")
        }
    }
}
    
private extension ViewController {
    func startCalibration() {
        let inset: CGFloat = 60
        let bounds = view.bounds.insetBy(dx: inset, dy: inset)
        // Four corners for the actual fit, plus a center point held back
        // purely to sanity-check accuracy afterward.
        let targets = [
            CGPoint(x: bounds.minX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.minY),
            CGPoint(x: bounds.minX, y: bounds.maxY),
            CGPoint(x: bounds.maxX, y: bounds.maxY),
            CGPoint(x: bounds.midX, y: bounds.midY)
        ]

        let targetView = CalibrationTargetView(frame: view.bounds)
        view.addSubview(targetView)
        calibrationTargetView = targetView

        calibrationCoordinator.onTargetChanged = { [weak self] point in
            self?.calibrationTargetView?.move(to: point, animated: true)
        }
        calibrationCoordinator.onCollectingChanged = { [weak self] collecting in
            self?.calibrationTargetView?.setCollecting(collecting)
        }
        calibrationCoordinator.onFinished = { [weak self] calibration in
            self?.calibrationTargetView?.removeFromSuperview()
            self?.calibrationTargetView = nil
            self?.isCalibrating = false
            guard let calibration else {
                // surface a retry option to the user here
                return
            }
            self?.boundaryEvaluator = GazeBoundaryEvaluator(calibration: calibration)
        }

        isCalibrating = true
        calibrationCoordinator.begin(targets: targets)
    }
}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}
