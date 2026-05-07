import Foundation

enum PostureMetricEngine {
    static let defaultCameraToScreenOffset: Double = 12.0
    static let minConfidence: Double = 0.55

    static func evaluate(input: PostureMetricInput) -> PostureCheckResult {
        guard input.sample.confidence >= minConfidence else {
            return PostureCheckResult(
                classification: .inconclusive,
                distanceBand: .unknown,
                correctedAngleDegrees: nil,
                confidence: input.sample.confidence,
                recommendation: "Low confidence. Ensure your face is fully visible and retry.",
                calibrationState: input.calibration == nil ? .uncalibrated : .calibrated
            )
        }

        let offset = input.calibration?.cameraToScreenOffsetDegrees ?? defaultCameraToScreenOffset
        let correctedAngle = input.sample.downwardPitchDegrees + offset
        let distanceBand = classifyDistance(faceScale: input.sample.faceScale, calibration: input.calibration)
        let calibrationState: PostureCalibrationState = input.calibration == nil ? .uncalibrated : .calibrated

        let angleInIdealBand = correctedAngle >= 10 && correctedAngle <= 20
        if angleInIdealBand && (distanceBand == .preferred || distanceBand == .comfortPreferred) {
            return PostureCheckResult(
                classification: .good,
                distanceBand: distanceBand,
                correctedAngleDegrees: correctedAngle,
                confidence: input.sample.confidence,
                recommendation: "Great posture. Keep screen center about 10-20 degrees below your eye line.",
                calibrationState: calibrationState
            )
        }

        var recommendation = "Adjust monitor height and seating distance."
        if correctedAngle < 7 {
            recommendation = "Lower monitor center or relax head position. Your gaze appears too level with camera."
        } else if correctedAngle > 25 {
            recommendation = "Raise monitor center slightly or sit taller. Gaze appears too far downward."
        }
        switch distanceBand {
        case .nearWarning:
            recommendation = "Sit a bit farther from the screen (target roughly 50-90 cm)."
        case .farWarning:
            recommendation = "Move closer to the screen (target roughly 50-90 cm)."
        default:
            break
        }
        if calibrationState == .uncalibrated {
            recommendation += " Interlude will refresh calibration automatically to improve accuracy."
        }

        return PostureCheckResult(
            classification: .adjust,
            distanceBand: distanceBand,
            correctedAngleDegrees: correctedAngle,
            confidence: input.sample.confidence,
            recommendation: recommendation,
            calibrationState: calibrationState
        )
    }

    static func classifyDistance(faceScale: Double, calibration: PostureCalibrationSnapshot?) -> PostureDistanceBand {
        guard faceScale > 0 else { return .unknown }
        if let calibration {
            let ratio = faceScale / max(calibration.baselineFaceScale, 0.0001)
            if ratio > 1.45 { return .nearWarning }
            if ratio >= 1.1 { return .preferred }
            if ratio >= 0.78 { return .comfortPreferred }
            if ratio < 0.55 { return .farWarning }
            return .preferred
        }

        // Fallback bins before calibration. Values are normalized bbox area in the camera frame.
        if faceScale > 0.22 { return .nearWarning }
        if faceScale >= 0.13 { return .preferred }
        if faceScale >= 0.08 { return .comfortPreferred }
        return .farWarning
    }
}
