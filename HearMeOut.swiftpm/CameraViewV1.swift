import SwiftUI

import AVFoundation
import UIKit

class CameraManager: NSObject, ObservableObject {
    // AVFoundation Components
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func startSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else { return }

        // Session Configuration Pattern
        session.beginConfiguration()
        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
        session.startRunning()
    }

    // Lifecycle Management
    func stopSession() {
        session.stopRunning()

        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        session.commitConfiguration()

        previewLayer = nil
    }

    // Preview Layer Management
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let layer = previewLayer {
            return layer
        } else {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
            return layer
        }
    }
}


struct CameraPreview: UIViewRepresentable {
    let sessionLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        sessionLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(sessionLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            sessionLayer.frame = uiView.bounds
        }
    }
}

struct CameraViewV1: View {
    @ObservedObject var cameraManager: CameraManager
    @Environment(\.presentationMode) var presentationMode

    @State private var showPreview = false
    @State private var capturedPhoto: UIImage?

    var body: some View {
        ZStack {
            GeometryReader { _ in
                CameraPreview(sessionLayer: cameraManager.getPreviewLayer())
                    .ignoresSafeArea()
            }
        }
        .onAppear { cameraManager.startSession() }
        .onDisappear { cameraManager.stopSession() }
    }
}
