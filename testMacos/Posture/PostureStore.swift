import Foundation

extension Notification.Name {
    static let interludePostureDidChange = Notification.Name("interludePostureDidChange")
}

final class PostureStore {
    static let shared = PostureStore()

    private let defaults = UserDefaults.standard
    private let recordsKey = "interlude.posture.records.v2"

    private init() {}

    func appendRecord(_ result: PostureCheckResult, at date: Date = Date()) {
        var records = loadRecords()
        records.append(
            PostureCheckRecord(
                timestamp: date,
                score: result.score,
                headForwardAngleDegrees: result.metrics.headForwardAngleDegrees,
                headTiltDegrees: result.metrics.headTiltDegrees,
                shoulderSymmetryDelta: result.metrics.shoulderSymmetryDelta,
                shoulderRoundingOffset: result.metrics.shoulderRoundingOffset,
                confidence: result.confidence,
                recommendation: result.recommendations.joined(separator: " "),
                limitedVisibility: result.limitedVisibility
            )
        )
        saveRecords(records)
        NotificationCenter.default.post(name: .interludePostureDidChange, object: nil)
    }

    func records(from start: Date, to end: Date) -> [PostureCheckRecord] {
        loadRecords().filter { $0.timestamp >= start && $0.timestamp < end }
    }

    func summary(from start: Date, to end: Date) -> PostureDailySummary? {
        let filtered = records(from: start, to: end)
        guard !filtered.isEmpty else { return nil }

        let scoreTotal = filtered.reduce(0) { $0 + $1.score }
        let goodCount = filtered.filter { $0.score >= 70 }.count
        let confidenceTotal = filtered.reduce(0.0) { $0 + $1.confidence }

        return PostureDailySummary(
            checkCount: filtered.count,
            averageScore: Double(scoreTotal) / Double(filtered.count),
            goodRate: Double(goodCount) / Double(filtered.count),
            averageConfidence: confidenceTotal / Double(filtered.count)
        )
    }

    func dailySummary(reference: Date = Date()) -> PostureDailySummary? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: reference)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }

        let sameDay = loadRecords().filter { record in
            record.timestamp >= dayStart && record.timestamp < dayEnd
        }
        guard !sameDay.isEmpty else { return nil }

        let scoreTotal = sameDay.reduce(0) { $0 + $1.score }
        let goodCount = sameDay.filter { $0.score >= 70 }.count
        let confidenceTotal = sameDay.reduce(0.0) { $0 + $1.confidence }

        return PostureDailySummary(
            checkCount: sameDay.count,
            averageScore: Double(scoreTotal) / Double(sameDay.count),
            goodRate: Double(goodCount) / Double(sameDay.count),
            averageConfidence: confidenceTotal / Double(sameDay.count)
        )
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
