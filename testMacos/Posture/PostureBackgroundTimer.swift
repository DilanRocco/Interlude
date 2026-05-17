import Foundation
import AVFoundation

var postureBackgroundTimer: Timer?

func startPostureBackgroundTimer() {
    guard AppSettingsStore.shared.currentSettings().autoPostureCheckEnabled else { return }
    guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
    guard postureBackgroundTimer == nil else { return }

    postureBackgroundTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { _ in
        runSilentPostureCheck()
    }
}

func stopPostureBackgroundTimer() {
    postureBackgroundTimer?.invalidate()
    postureBackgroundTimer = nil
}

private var sessionObserver: NSObjectProtocol?

private func runSilentPostureCheck() {
    let coordinator = PostureCheckCoordinator.shared
    guard !coordinator.cameraManager.session.isRunning else { return }

    sessionObserver = NotificationCenter.default.addObserver(
        forName: .AVCaptureSessionDidStartRunning,
        object: coordinator.cameraManager.session,
        queue: .main
    ) { _ in
        if let observer = sessionObserver {
            NotificationCenter.default.removeObserver(observer)
            sessionObserver = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        coordinator.runCheck { result in
            coordinator.cameraManager.stopSession()
            switch result {
            case .success(let posture):
                print("[PostureBackground] ✅ score: \(posture.score), confidence: \(String(format: "%.2f", posture.confidence))")
            case .failure(let error):
                print("[PostureBackground] ❌ failed: \(error.localizedDescription)")
            }
        }
        }
    }

    coordinator.cameraManager.startSession()
}
