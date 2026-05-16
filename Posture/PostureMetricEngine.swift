import Foundation

enum PostureMetricEngine {
    // Sigma values calibrated to clinical thresholds:
    // Head forward: 0-15° good, 15-30° caution, >30° poor (AS-1990, ANSI/HFES-2002)
    // Head tilt: <5° normal, 5-15° mild, >15° significant
    // Shoulder symmetry: normalized coord delta
    // Shoulder rounding: normalized coord offset
    private static let headForwardSigma: Double = 22.0
    private static let headTiltSigma: Double = 8.0
    private static let symmetrySigma: Double = 0.04
    private static let roundingSigma: Double = 0.06

    private static let headForwardWeight: Double = 0.40
    private static let headTiltWeight: Double = 0.15
    private static let symmetryWeight: Double = 0.15
    private static let roundingWeight: Double = 0.30

    static func evaluate(observation: BodyPoseObservation, confidence: Double) -> PostureCheckResult {
        let metrics = computeMetrics(from: observation)
        let rawScore = score(metrics: metrics)
        let finalScore = min(100, max(0, Int((rawScore * 100).rounded())))
        let recommendations = generateRecommendations(metrics: metrics, score: rawScore)
        let limited = !observation.hasSufficientShoulderData

        return PostureCheckResult(
            score: finalScore,
            metrics: metrics,
            recommendations: recommendations,
            confidence: confidence,
            limitedVisibility: limited
        )
    }

    static func computeMetrics(from observation: BodyPoseObservation) -> PostureMetrics {
        var headForward: Double?
        var headTilt: Double?
        var symmetryDelta: Double?
        var roundingOffset: Double?
        var factors = Set<PostureFactor>()

        let earMid = midpoint(observation.leftEar, observation.rightEar)

        // Head tilt: angle of ear-to-ear line from horizontal
        if let le = observation.leftEar, let re = observation.rightEar,
           observation.leftEarConfidence > 0.3, observation.rightEarConfidence > 0.3 {
            let dy = Double(le.y - re.y)
            let dx = Double(le.x - re.x)
            let tiltRad = atan2(dy, dx)
            headTilt = abs(tiltRad * 180.0 / .pi)
            factors.insert(.headTilt)
        }

        if observation.hasSufficientShoulderData,
           let shoulderMid = midpoint(observation.leftShoulder, observation.rightShoulder),
           let earMid {
            // Head forward angle: how far ears are in front of shoulders.
            // Vision coords: origin bottom-left, y-up.
            let dx = earMid.x - shoulderMid.x
            let dy = earMid.y - shoulderMid.y
            let angleRad = atan2(abs(dx), dy)
            headForward = angleRad * 180.0 / .pi
            factors.insert(.headForward)

            // Shoulder symmetry: y-difference between left and right shoulder.
            if let ls = observation.leftShoulder, let rs = observation.rightShoulder {
                symmetryDelta = abs(Double(ls.y - rs.y))
                factors.insert(.shoulderSymmetry)
            }

            // Shoulder rounding: forward offset of shoulders relative to ears.
            roundingOffset = abs(Double(shoulderMid.x - earMid.x))
            factors.insert(.shoulderRounding)
        } else if let earMid, let nose = observation.nose {
            // Head-only: use ear-to-nose vertical alignment as proxy.
            let dx = nose.x - earMid.x
            let dy = nose.y - earMid.y
            let angleRad = atan2(abs(dx), abs(dy))
            headForward = angleRad * 180.0 / .pi
            factors.insert(.headForward)
        }

        return PostureMetrics(
            headForwardAngleDegrees: headForward,
            headTiltDegrees: headTilt,
            shoulderSymmetryDelta: symmetryDelta,
            shoulderRoundingOffset: roundingOffset,
            availableFactors: factors
        )
    }

    static func score(metrics: PostureMetrics) -> Double {
        var totalWeight: Double = 0
        var weightedSum: Double = 0

        if let angle = metrics.headForwardAngleDegrees, metrics.availableFactors.contains(.headForward) {
            let w = metrics.availableFactors.subtracting([.headTilt]).count == 1 ? 1.0 : headForwardWeight
            weightedSum += gaussian(value: angle, ideal: 0, sigma: headForwardSigma) * w
            totalWeight += w
        }

        if let tilt = metrics.headTiltDegrees, metrics.availableFactors.contains(.headTilt) {
            weightedSum += gaussian(value: tilt, ideal: 0, sigma: headTiltSigma) * headTiltWeight
            totalWeight += headTiltWeight
        }

        if let delta = metrics.shoulderSymmetryDelta, metrics.availableFactors.contains(.shoulderSymmetry) {
            weightedSum += gaussian(value: delta, ideal: 0, sigma: symmetrySigma) * symmetryWeight
            totalWeight += symmetryWeight
        }

        if let offset = metrics.shoulderRoundingOffset, metrics.availableFactors.contains(.shoulderRounding) {
            weightedSum += gaussian(value: offset, ideal: 0, sigma: roundingSigma) * roundingWeight
            totalWeight += roundingWeight
        }

        guard totalWeight > 0 else { return 0.5 }
        return weightedSum / totalWeight
    }

    static func generateRecommendations(metrics: PostureMetrics, score: Double) -> [String] {
        if score >= 0.85 {
            return ["Your posture looks great — head balanced over shoulders, neutral alignment."]
        }

        var recs: [String] = []

        if let angle = metrics.headForwardAngleDegrees,
           metrics.availableFactors.contains(.headForward) {
            let s = gaussian(value: angle, ideal: 0, sigma: headForwardSigma)
            if s < 0.6 {
                if angle > 30 {
                    recs.append(String(format: "Your head is ~%.0f° forward — your monitor is likely too low or too far away. Raise it so the top of the screen is at eye level.", angle))
                } else {
                    recs.append(String(format: "Your head is tilting ~%.0f° forward. Try aligning your ears over your shoulders — your monitor may need to be raised slightly.", angle))
                }
            }
        }

        if let tilt = metrics.headTiltDegrees,
           metrics.availableFactors.contains(.headTilt) {
            let s = gaussian(value: tilt, ideal: 0, sigma: headTiltSigma)
            if s < 0.6 {
                recs.append("Your head is tilting to one side. Your screen or documents may be off-center — position them directly in front of you.")
            }
        }

        if let delta = metrics.shoulderSymmetryDelta,
           metrics.availableFactors.contains(.shoulderSymmetry) {
            let s = gaussian(value: delta, ideal: 0, sigma: symmetrySigma)
            if s < 0.6 {
                recs.append("Your shoulders are uneven. Check that your armrests are level and you're not leaning to one side.")
            }
        }

        if let offset = metrics.shoulderRoundingOffset,
           metrics.availableFactors.contains(.shoulderRounding) {
            let s = gaussian(value: offset, ideal: 0, sigma: roundingSigma)
            if s < 0.6 {
                recs.append("Your shoulders are rolling forward — a sign of upper back rounding. Gently pull your shoulder blades back and make sure your chair supports your back.")
            }
        }

        if recs.isEmpty {
            recs.append("Your posture is decent but has room to improve. Keep your head balanced over your spine and shoulders relaxed.")
        }

        return Array(recs.prefix(2))
    }

    private static func gaussian(value: Double, ideal: Double, sigma: Double) -> Double {
        let diff = value - ideal
        return exp(-0.5 * (diff * diff) / (sigma * sigma))
    }

    private static func midpoint(_ a: CGPoint?, _ b: CGPoint?) -> CGPoint? {
        if let a, let b {
            return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        }
        return a ?? b
    }
}
