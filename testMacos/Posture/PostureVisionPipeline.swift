import Foundation
import AVFoundation
import Vision
import CoreImage

final class PostureVisionAnalyzer {
    private let request = VNDetectFaceLandmarksRequest()

    func bestSample(from cgImages: [CGImage]) throws -> PostureFrameSample {
        var best: PostureFrameSample?
        for image in cgImages {
            guard let sample = try analyze(cgImage: image) else { continue }
            if let currentBest = best {
                if sample.confidence > currentBest.confidence {
                    best = sample
                }
            } else {
                best = sample
            }
        }
        guard let best else { throw PostureCheckError.noFaceDetected }
        return best
    }

    private func analyze(cgImage: CGImage) throws -> PostureFrameSample? {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let observation = request.results?.first as? VNFaceObservation else {
            return nil
        }

        let faceScale = Double(observation.boundingBox.width * observation.boundingBox.height)
        let rawPitchDegrees = observation.pitch.map { -($0.doubleValue * 180.0 / .pi) } ?? 0

        var confidence = Double(observation.confidence)
        if observation.landmarks == nil {
            confidence *= 0.6
        }

        return PostureFrameSample(
            faceScale: faceScale,
            downwardPitchDegrees: rawPitchDegrees,
            confidence: min(max(confidence, 0), 1)
        )
    }
}

final class CameraFrameBurstCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let outputQueue = DispatchQueue(label: "interlude.posture.camera")
    private let ciContext = CIContext()

    private var targetFrames = 0
    private var completion: ((Result<[CGImage], Error>) -> Void)?
    private var images: [CGImage] = []
    private var timeoutWorkItem: DispatchWorkItem?

    func capture(frameCount: Int = 12, timeout: TimeInterval = 3.0, completion: @escaping (Result<[CGImage], Error>) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            startCapture(frameCount: frameCount, timeout: timeout, completion: completion)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startCapture(frameCount: frameCount, timeout: timeout, completion: completion)
                    } else {
                        completion(.failure(PostureCheckError.permissionDenied))
                    }
                }
            }
        default:
            completion(.failure(PostureCheckError.permissionDenied))
        }
    }

    private func startCapture(frameCount: Int, timeout: TimeInterval, completion: @escaping (Result<[CGImage], Error>) -> Void) {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            completion(.failure(PostureCheckError.cameraUnavailable))
            return
        }

        self.completion = completion
        self.targetFrames = max(1, frameCount)
        self.images = []

        session.beginConfiguration()
        session.sessionPreset = .medium
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            session.commitConfiguration()
            completion(.failure(error))
            return
        }

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: outputQueue)
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()

        session.startRunning()

        let workItem = DispatchWorkItem { [weak self] in
            self?.finishCaptureIfNeeded()
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard images.count < targetFrames,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(image, from: image.extent) else { return }
        images.append(cgImage)

        if images.count >= targetFrames {
            finishCaptureIfNeeded()
        }
    }

    private func finishCaptureIfNeeded() {
        guard let completion else { return }
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        self.completion = nil
        output.setSampleBufferDelegate(nil, queue: nil)
        if session.isRunning {
            session.stopRunning()
        }

        guard !images.isEmpty else {
            completion(.failure(PostureCheckError.frameCaptureFailed))
            return
        }
        completion(.success(images))
    }
}
