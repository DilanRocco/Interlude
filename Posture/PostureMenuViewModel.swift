import Foundation
import Combine

final class PostureMenuViewModel: ObservableObject {
    enum FlowStep {
        case intro
        case calibrating(PostureCalibrationReason)
        case cameraReady
        case analyzing
        case result(PostureCheckResult)
        case error(String)
    }

    @Published private(set) var step: FlowStep = .intro
    @Published var isPresented: Bool = false

    private let postureCoordinator: PostureCheckCoordinator
    private let store: PostureStore
    private let minimumAnalyzeDurationNs: UInt64 = 3_200_000_000
    private var calibrationDecision = PostureCalibrationDecision(needsCalibration: false, reason: nil)

    init(
        postureCoordinator: PostureCheckCoordinator = .shared,
        store: PostureStore = .shared
    ) {
        self.postureCoordinator = postureCoordinator
        self.store = store
    }

    func startPostureFlow() {
        calibrationDecision = store.calibrationDecision()
        step = .intro
        isPresented = true
    }

    func closeFlow() {
        isPresented = false
    }

    func continueFromIntro() {
        if calibrationDecision.needsCalibration, let reason = calibrationDecision.reason {
            runCalibration(reason: reason)
            return
        }
        step = .cameraReady
    }

    func startAnalysis() {
        step = .analyzing
        Task {
            do {
                let start = DispatchTime.now().uptimeNanoseconds
                let score = try await postureCoordinator.runCheckAsync()
                let elapsed = DispatchTime.now().uptimeNanoseconds - start
                if elapsed < minimumAnalyzeDurationNs {
                    try await Task.sleep(nanoseconds: minimumAnalyzeDurationNs - elapsed)
                }
                await MainActor.run {
                    self.step = .result(score)
                }
            } catch {
                await MainActor.run {
                    self.step = .error(postureErrorText(error))
                }
            }
        }
    }

    func retryAfterError() {
        calibrationDecision = store.calibrationDecision()
        step = .intro
    }

    private func runCalibration(reason: PostureCalibrationReason) {
        step = .calibrating(reason)
        Task {
            do {
                _ = try await postureCoordinator.runCalibrationAsync()
                await MainActor.run {
                    self.calibrationDecision = PostureCalibrationDecision(needsCalibration: false, reason: nil)
                    self.step = .cameraReady
                }
            } catch {
                await MainActor.run {
                    self.step = .error(postureErrorText(error))
                }
            }
        }
    }
}
