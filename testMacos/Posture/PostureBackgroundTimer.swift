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
    runSilentPostureCheck()
}

func stopPostureBackgroundTimer() {
    postureBackgroundTimer?.invalidate()
    postureBackgroundTimer = nil
}

private func runSilentPostureCheck() {
    let coordinator = PostureCheckCoordinator.shared
    guard !coordinator.cameraManager.session.isRunning else { return }

    coordinator.cameraManager.startSession()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        coordinator.runCheck { _ in
            coordinator.cameraManager.stopSession()
        }
    }
}
