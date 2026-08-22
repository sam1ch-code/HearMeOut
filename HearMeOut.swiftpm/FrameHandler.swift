//  Created by Sam on 17/08/2026.
//

import AVFoundation
import Combine
import CoreImage
import os.log

final class FrameHandler: NSObject, ObservableObject, @unchecked Sendable {
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue", qos: .userInitiated)
    private var permissionGranted = false
    private let context = CIContext()

    @Published @MainActor var frame: CGImage?

    override init() {
        super.init()
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.checkPermission()
            self.setUpCaptureSession()
            self.captureSession.startRunning()
        }
    }

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            // Blocks this (background) queue until the user responds,
            // so permissionGranted is set before setUpCaptureSession runs.
            let semaphore = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.permissionGranted = granted
                semaphore.signal()
            }
            semaphore.wait()
        default:
            permissionGranted = false
        }
    }

    private func setUpCaptureSession() {
        guard permissionGranted else { return }

        captureSession.sessionPreset = .medium // was .high/.photo — plenty for preview + tracking

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
        else { return }

        // Throttle to ~15fps — cuts the per-frame CIContext render + SwiftUI
        // update workload roughly in half vs. the camera's native 30fps.
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 15)
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 15)
            videoDevice.unlockForConfiguration()
        } catch {
            logger.error("Could not lock device for frame rate configuration: \(error.localizedDescription)")
        }

        captureSession.addInput(videoDeviceInput)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "SampleBufferQueue", qos: .userInitiated))
        captureSession.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 0
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }

        Task { @MainActor [weak self] in
            self?.frame = cgImage
        }
    }

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

fileprivate let logger = Logger(subsystem: "com.example.hearmeout", category: "FrameHandler")
