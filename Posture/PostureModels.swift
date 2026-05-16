import Foundation

enum PostureFactor: String, Codable {
    case headForward
    case headTilt
    case shoulderSymmetry
    case shoulderRounding
}

struct BodyPoseObservation {
    let nose: CGPoint?
    let leftEar: CGPoint?
    let rightEar: CGPoint?
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let neck: CGPoint?

    let noseConfidence: Float
    let leftEarConfidence: Float
    let rightEarConfidence: Float
    let leftShoulderConfidence: Float
    let rightShoulderConfidence: Float
    let neckConfidence: Float

    var hasSufficientShoulderData: Bool {
        leftShoulderConfidence > 0.3 && rightShoulderConfidence > 0.3
            && leftShoulder != nil && rightShoulder != nil
    }

    var hasEarData: Bool {
        (leftEarConfidence > 0.3 || rightEarConfidence > 0.3)
            && (leftEar != nil || rightEar != nil)
    }
}

struct PostureMetrics {
    let headForwardAngleDegrees: Double?
    let headTiltDegrees: Double?
    let shoulderSymmetryDelta: Double?
    let shoulderRoundingOffset: Double?
    let availableFactors: Set<PostureFactor>
}

struct PostureCheckResult {
    let score: Int
    let metrics: PostureMetrics
    let recommendations: [String]
    let confidence: Double
    let limitedVisibility: Bool
}

struct PostureCheckRecord: Codable {
    let timestamp: Date
    let score: Int
    let headForwardAngleDegrees: Double?
    let headTiltDegrees: Double?
    let shoulderSymmetryDelta: Double?
    let shoulderRoundingOffset: Double?
    let confidence: Double
    let recommendation: String
    let limitedVisibility: Bool
}

struct PostureDailySummary {
    let checkCount: Int
    let averageScore: Double
    let goodRate: Double
    let averageConfidence: Double
}

enum PostureCheckError: Error {
    case permissionDenied
    case cameraUnavailable
    case frameCaptureFailed
    case noBodyDetected
    case lowConfidence
}

func postureErrorText(_ error: Error) -> String {
    guard let postureError = error as? PostureCheckError else {
        return "Posture check failed. Please try again."
    }
    switch postureError {
    case .permissionDenied:
        return "Camera permission denied. Enable camera access in System Settings."
    case .cameraUnavailable:
        return "No camera available for posture check."
    case .frameCaptureFailed:
        return "Unable to capture camera frames. Try again."
    case .noBodyDetected:
        return "No body detected. Make sure you're visible in the camera and try again."
    case .lowConfidence:
        return "Low confidence result. Improve lighting and try again."
    }
}
