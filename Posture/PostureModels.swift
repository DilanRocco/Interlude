import Foundation

enum PostureDistanceBand: String, Codable {
    case nearWarning
    case preferred
    case comfortPreferred
    case farWarning
    case unknown

    var label: String {
        switch self {
        case .nearWarning: return "too near"
        case .preferred: return "preferred"
        case .comfortPreferred: return "comfort"
        case .farWarning: return "too far"
        case .unknown: return "unknown"
        }
    }
}

enum PostureClassification: String, Codable {
    case good
    case adjust
    case inconclusive
}

enum PostureCalibrationState: String, Codable {
    case calibrated
    case uncalibrated
}

enum PostureCalibrationReason: String {
    case missingBaseline
    case staleBaseline
    case recentLowConfidence

    var title: String {
        switch self {
        case .missingBaseline:
            return "Preparing first-time baseline"
        case .staleBaseline:
            return "Refreshing baseline for accuracy"
        case .recentLowConfidence:
            return "Improving accuracy"
        }
    }

    var subtitle: String {
        switch self {
        case .missingBaseline:
            return "Hold your natural posture while Interlude captures your reference."
        case .staleBaseline:
            return "Your previous baseline is old. Interlude is refreshing it before scoring."
        case .recentLowConfidence:
            return "Recent checks were less confident. Interlude is re-calibrating automatically."
        }
    }
}

struct PostureCalibrationDecision {
    let needsCalibration: Bool
    let reason: PostureCalibrationReason?
}

struct PostureCalibrationSnapshot: Codable {
    let cameraToScreenOffsetDegrees: Double
    let baselineFaceScale: Double
    let createdAt: Date
}

struct PostureCheckRecord: Codable {
    let timestamp: Date
    let classification: PostureClassification
    let distanceBand: PostureDistanceBand
    let correctedAngleDegrees: Double?
    let confidence: Double
    let recommendation: String
    let calibrationState: PostureCalibrationState
}

struct PostureCheckResult {
    let classification: PostureClassification
    let distanceBand: PostureDistanceBand
    let correctedAngleDegrees: Double?
    let confidence: Double
    let recommendation: String
    let calibrationState: PostureCalibrationState
}

struct PostureDailySummary {
    let checkCount: Int
    let goodRate: Double
    let averageConfidence: Double
}

struct PostureFrameSample {
    let faceScale: Double
    let downwardPitchDegrees: Double
    let confidence: Double
}

enum PostureCheckError: Error {
    case permissionDenied
    case cameraUnavailable
    case frameCaptureFailed
    case noFaceDetected
    case lowConfidence
}

struct PostureMetricInput {
    let sample: PostureFrameSample
    let calibration: PostureCalibrationSnapshot?
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
    case .noFaceDetected:
        return "No face detected. Center your face and retry."
    case .lowConfidence:
        return "Low confidence calibration. Improve lighting and retry."
    }
}
