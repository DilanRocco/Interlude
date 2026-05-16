import Foundation

final class PostureCheckCoordinator {
    static let shared = PostureCheckCoordinator()

    let cameraManager = PostureCameraManager()
    private let analyzer = PostureVisionAnalyzer()
    private let store = PostureStore.shared

    private init() {}

    func runCheck(completion: @escaping (Result<PostureCheckResult, Error>) -> Void) {
        cameraManager.captureFrames(count: 8, timeout: 4.0) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let frames):
                do {
                    let (observation, confidence) = try self.analyzer.bestObservation(from: frames)
                    let posture = PostureMetricEngine.evaluate(observation: observation, confidence: confidence)
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
}
