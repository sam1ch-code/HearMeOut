//  Created by Sukhrob on 25/08/26.
//

import UIKit
import AVFoundation
import SwiftUI

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false
    
    private let captureSession = AVCaptureSession()
    // TODO: Add qos
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    /// Detector
    nonisolated(unsafe) private var videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private let gazeDetector = GazeDetector()
    private var boundaryEvaluator: GazeBoundaryEvaluator?
    private let calibrationCoordinator = CalibrationCoordinator()
    private var calibrationTargetView: CalibrationTargetView?
    private var isCalibrating = false

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
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

    @MainActor
    func setUpCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        previewLayer.connection?.videoRotationAngle = 0
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoRotationAngle = 0
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.previewLayer.frame = self.view.bounds
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
            case .withinBounds(let point):
                print("🔥 within bounds — point: \(point), confidence: \(reading.confidence)")
            case .exceeded(let point, let direction):
                print("❌ exceeded (\(direction)) — point: \(point), confidence: \(reading.confidence)")
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
            guard let calibration, let self else { return }

            let evaluator = GazeBoundaryEvaluator(calibration: calibration)
            self.boundaryEvaluator = evaluator

            let centerEstimate = calibration.estimatedScreenPoint(horizontalAngle: 0, verticalAngle: 0)
            let actualCenter = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
            print("Calibration center estimate: \(centerEstimate), actual center: \(actualCenter)")
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
