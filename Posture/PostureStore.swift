import Foundation

final class PostureStore {
    static let shared = PostureStore()

    private let defaults = UserDefaults.standard
    private let recordsKey = "interlude.posture.records.v1"
    private let calibrationKey = "interlude.posture.calibration.v1"

    private init() {}

    func calibration() -> PostureCalibrationSnapshot? {
        guard let data = defaults.data(forKey: calibrationKey),
              let calibration = try? JSONDecoder().decode(PostureCalibrationSnapshot.self, from: data) else {
            return nil
        }
        return calibration
    }

    func saveCalibration(_ calibration: PostureCalibrationSnapshot) {
        guard let data = try? JSONEncoder().encode(calibration) else { return }
        defaults.set(data, forKey: calibrationKey)
    }

    func appendRecord(_ result: PostureCheckResult, at date: Date = Date()) {
        var records = loadRecords()
        records.append(
            PostureCheckRecord(
                timestamp: date,
                classification: result.classification,
                distanceBand: result.distanceBand,
                correctedAngleDegrees: result.correctedAngleDegrees,
                confidence: result.confidence,
                recommendation: result.recommendation,
                calibrationState: result.calibrationState
            )
        )
        saveRecords(records)
    }

    func dailySummary(reference: Date = Date()) -> PostureDailySummary? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: reference)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }

        let sameDay = loadRecords().filter { record in
            record.timestamp >= dayStart && record.timestamp < dayEnd
        }
        guard !sameDay.isEmpty else { return nil }

        let goodCount = sameDay.reduce(0) { partial, record in
            partial + (record.classification == .good ? 1 : 0)
        }
        let confidenceTotal = sameDay.reduce(0.0) { $0 + $1.confidence }
        return PostureDailySummary(
            checkCount: sameDay.count,
            goodRate: Double(goodCount) / Double(sameDay.count),
            averageConfidence: confidenceTotal / Double(sameDay.count)
        )
    }

    func calibrationDecision(now: Date = Date()) -> PostureCalibrationDecision {
        guard let calibration = calibration() else {
            return PostureCalibrationDecision(needsCalibration: true, reason: .missingBaseline)
        }

        if let staleCutoff = Calendar.current.date(byAdding: .day, value: -7, to: now),
           calibration.createdAt < staleCutoff {
            return PostureCalibrationDecision(needsCalibration: true, reason: .staleBaseline)
        }

        let recent = Array(loadRecords().suffix(5))
        if recent.count >= 3 {
            let lowConfidenceCount = recent.filter { $0.confidence < 0.58 }.count
            let inconclusiveCount = recent.filter { $0.classification == .inconclusive }.count
            if lowConfidenceCount >= 2 || inconclusiveCount >= 2 {
                return PostureCalibrationDecision(needsCalibration: true, reason: .recentLowConfidence)
            }
        }

        return PostureCalibrationDecision(needsCalibration: false, reason: nil)
    }

    private func loadRecords() -> [PostureCheckRecord] {
        guard let data = defaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([PostureCheckRecord].self, from: data) else {
            return []
        }
        return records
    }

    private func saveRecords(_ records: [PostureCheckRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: recordsKey)
    }
}
