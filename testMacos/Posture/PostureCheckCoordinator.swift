import Foundation

final class PostureCheckCoordinator {
    static let shared = PostureCheckCoordinator()

    private let cameraCapture = CameraFrameBurstCapture()
    private let analyzer = PostureVisionAnalyzer()
    private let store = PostureStore.shared

    private init() {}

    func runCheck(completion: @escaping (Result<PostureCheckResult, Error>) -> Void) {
        cameraCapture.capture(frameCount: 12, timeout: 3.0) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let frames):
                do {
                    let sample = try self.analyzer.bestSample(from: frames)
                    let metricInput = PostureMetricInput(sample: sample, calibration: self.store.calibration())
                    let posture = PostureMetricEngine.evaluate(input: metricInput)
                    self.store.appendRecord(posture)
                    completion(.success(posture))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func runCheckAsync() async throws -> PostureCheckResult {
        try await withCheckedThrowingContinuation { continuation in
            runCheck { result in
                continuation.resume(with: result)
            }
        }
    }

    func runCalibration(completion: @escaping (Result<PostureCalibrationSnapshot, Error>) -> Void) {
        cameraCapture.capture(frameCount: 12, timeout: 3.0) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let frames):
                do {
                    let sample = try self.analyzer.bestSample(from: frames)
                    guard sample.confidence >= PostureMetricEngine.minConfidence else {
                        completion(.failure(PostureCheckError.lowConfidence))
                        return
                    }
                    let offset = 15.0 - sample.downwardPitchDegrees
                    let calibration = PostureCalibrationSnapshot(
                        cameraToScreenOffsetDegrees: offset,
                        baselineFaceScale: sample.faceScale,
                        createdAt: Date()
                    )
                    self.store.saveCalibration(calibration)
                    completion(.success(calibration))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func runCalibrationAsync() async throws -> PostureCalibrationSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            runCalibration { result in
                continuation.resume(with: result)
            }
        }
    }
}
