import Foundation
import Combine

final class PostureMenuViewModel: ObservableObject {
    enum FlowStep {
        case ready
        case analyzing
        case result(PostureCheckResult)
        case error(String)
    }

    @Published private(set) var step: FlowStep = .ready
    @Published var isPresented: Bool = false

    private let postureCoordinator: PostureCheckCoordinator

    init(postureCoordinator: PostureCheckCoordinator = .shared) {
        self.postureCoordinator = postureCoordinator
    }

    var cameraManager: PostureCameraManager {
        postureCoordinator.cameraManager
    }

    func startPostureFlow() {
        step = .ready
        isPresented = true
        postureCoordinator.cameraManager.startSession()
    }

    func closeFlow() {
        postureCoordinator.cameraManager.stopSession()
        isPresented = false
    }

    func retryAfterError() {
        postureCoordinator.cameraManager.startSession()
        step = .ready
    }

    func startCheck() {
        step = .analyzing
        Task {
            do {
                let result = try await postureCoordinator.runCheckAsync()
                await MainActor.run {
                    self.postureCoordinator.cameraManager.stopSession()
                    self.step = .result(result)
                }
            } catch {
                await MainActor.run {
                    self.postureCoordinator.cameraManager.stopSession()
                    self.step = .error(postureErrorText(error))
                }
            }
        }
    }
}
