import Foundation
import AVFoundation
import Vision
import CoreImage

final class PostureVisionAnalyzer {
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

    func bestObservation(from cgImages: [CGImage]) throws -> (observation: BodyPoseObservation, confidence: Double) {
        var best: BodyPoseObservation?
        var bestConfidence: Float = 0
        var detectedCount = 0

        for image in cgImages {
            if let obs = try analyze(cgImage: image) {
                detectedCount += 1
                let avgConf = averageConfidence(obs)
                if avgConf > bestConfidence {
                    bestConfidence = avgConf
                    best = obs
                }
            }
        }

        guard let best else { throw PostureCheckError.noBodyDetected }

        let detectionRate = Double(detectedCount) / Double(max(1, cgImages.count))
        let blendedConfidence = min(Double(bestConfidence) * 0.4 + detectionRate * 0.6, 1.0)
        return (best, blendedConfidence)
    }

    private func analyze(cgImage: CGImage) throws -> BodyPoseObservation? {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([bodyPoseRequest])

        guard let result = bodyPoseRequest.results?.first else { return nil }

        func point(for joint: VNHumanBodyPoseObservation.JointName) -> (CGPoint?, Float) {
            guard let recognized = try? result.recognizedPoint(joint),
                  recognized.confidence > 0.1 else {
                return (nil, 0)
            }
            return (recognized.location, recognized.confidence)
        }

        let (nose, noseConf) = point(for: .nose)
        let (leftEar, leftEarConf) = point(for: .leftEar)
        let (rightEar, rightEarConf) = point(for: .rightEar)
        let (leftShoulder, leftShoulderConf) = point(for: .leftShoulder)
        let (rightShoulder, rightShoulderConf) = point(for: .rightShoulder)
        let (neck, neckConf) = point(for: .neck)

        let hasAnyData = nose != nil || leftEar != nil || rightEar != nil
        guard hasAnyData else { return nil }

        return BodyPoseObservation(
            nose: nose,
            leftEar: leftEar,
            rightEar: rightEar,
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            neck: neck,
            noseConfidence: noseConf,
            leftEarConfidence: leftEarConf,
            rightEarConfidence: rightEarConf,
            leftShoulderConfidence: leftShoulderConf,
            rightShoulderConfidence: rightShoulderConf,
            neckConfidence: neckConf
        )
    }

    private func averageConfidence(_ obs: BodyPoseObservation) -> Float {
        let values = [
            obs.noseConfidence, obs.leftEarConfidence, obs.rightEarConfidence,
            obs.leftShoulderConfidence, obs.rightShoulderConfidence, obs.neckConfidence,
        ]
        let nonZero = values.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0, +) / Float(nonZero.count)
    }
}

final class PostureCameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let outputQueue = DispatchQueue(label: "interlude.posture.camera")
    private let ciContext = CIContext()

    private var isCapturing = false
    private var capturedImages: [CGImage] = []
    private var targetFrameCount = 0
    private var captureCompletion: ((Result<[CGImage], Error>) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    private var isSessionConfigured = false

    func startSession() {
        guard !session.isRunning else { return }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.configureAndStart() }
                }
            }
        default:
            break
        }
    }

    func stopSession() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        isCapturing = false
        captureCompletion = nil
        if session.isRunning {
            session.stopRunning()
        }
    }

    func captureFrames(count: Int = 8, timeout: TimeInterval = 4.0, completion: @escaping (Result<[CGImage], Error>) -> Void) {
        guard session.isRunning else {
            completion(.failure(PostureCheckError.cameraUnavailable))
            return
        }

        capturedImages = []
        targetFrameCount = max(1, count)
        captureCompletion = completion
        isCapturing = true

        let workItem = DispatchWorkItem { [weak self] in
            self?.finishCapture()
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }

    private func configureAndStart() {
        guard !isSessionConfigured else {
            if !session.isRunning { session.startRunning() }
            return
        }

        guard let camera = AVCaptureDevice.default(for: .video) else { return }

        session.beginConfiguration()
        session.sessionPreset = .medium

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            session.commitConfiguration()
            return
        }

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: outputQueue)
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()

        isSessionConfigured = true
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isCapturing, capturedImages.count < targetFrameCount,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(image, from: image.extent) else { return }
        capturedImages.append(cgImage)

        if capturedImages.count >= targetFrameCount {
            finishCapture()
        }
    }

    private func finishCapture() {
        guard let completion = captureCompletion else { return }
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        captureCompletion = nil
        isCapturing = false

        let images = capturedImages
        capturedImages = []

        DispatchQueue.main.async {
            if images.isEmpty {
                completion(.failure(PostureCheckError.frameCaptureFailed))
            } else {
                completion(.success(images))
            }
        }
    }
}
