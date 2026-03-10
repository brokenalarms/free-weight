import AVFoundation
import UIKit

@Observable
final class CameraManager: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var continuation: CheckedContinuation<Data, Error>?

    var isAuthorized = false
    var cameraPosition: AVCaptureDevice.Position = .back

    func requestAccess() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
    }

    func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Remove existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: cameraPosition
        ),
        let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }
        if !session.outputs.contains(photoOutput), session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
    }

    func start() {
        Task.detached { [session] in
            session.startRunning()
        }
    }

    func stop() {
        session.stopRunning()
    }

    func flipCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        configure()
    }

    /// Async photo capture — returns JPEG data.
    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            continuation?.resume(throwing: error)
        } else if let data = photo.fileDataRepresentation() {
            continuation?.resume(returning: data)
        }
        continuation = nil
    }
}
