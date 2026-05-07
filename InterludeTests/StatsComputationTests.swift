import XCTest
@testable import Interlude

final class StatsComputationTests: XCTestCase {
    func testWeekRangeStartsOnMonday() {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let calendar = StatsComputation.mondayFirstCalendar(timeZone: timeZone)
        let now = makeDate(year: 2026, month: 4, day: 26, hour: 15, minute: 0, calendar: calendar)

        let range = StatsComputation.dateRange(for: .thisWeek, now: now, calendar: calendar)

        XCTAssertEqual(dateString(range.start, calendar: calendar), "2026-04-20")
        XCTAssertEqual(dateString(range.endExclusive, calendar: calendar), "2026-04-27")
    }

    func testMonthRangeUsesCalendarBoundaries() {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let calendar = StatsComputation.mondayFirstCalendar(timeZone: timeZone)
        let now = makeDate(year: 2026, month: 2, day: 15, hour: 8, minute: 0, calendar: calendar)

        let range = StatsComputation.dateRange(for: .thisMonth, now: now, calendar: calendar)

        XCTAssertEqual(dateString(range.start, calendar: calendar), "2026-02-01")
        XCTAssertEqual(dateString(range.endExclusive, calendar: calendar), "2026-03-01")
    }

    func testComplianceHandlesZeroTotalAndNormalCase() {
        XCTAssertNil(StatsComputation.compliancePercentage(taken: 0, skipped: 0))
        XCTAssertEqual(StatsComputation.compliancePercentage(taken: 3, skipped: 1), 75)
    }

    func testStreakResetsWhenDayContainsSkip() {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let calendar = StatsComputation.mondayFirstCalendar(timeZone: timeZone)
        let now = makeDate(year: 2026, month: 4, day: 26, hour: 12, minute: 0, calendar: calendar)

        let day0 = StatsComputation.dayKey(for: now, calendar: calendar)
        let day1 = StatsComputation.dayKey(for: calendar.date(byAdding: .day, value: -1, to: now)!, calendar: calendar)
        let day2 = StatsComputation.dayKey(for: calendar.date(byAdding: .day, value: -2, to: now)!, calendar: calendar)

        let streak = StatsComputation.streakLength(
            daily: [
                day0: (taken: 2, skipped: 0),
                day1: (taken: 3, skipped: 0),
                day2: (taken: 1, skipped: 1)
            ],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(streak, 2)
    }

    func testRecoveryScoreHighComplianceLowSkipsProducesHighScore() {
        let input = RecoveryScoreInput(
            compliance: 92,
            skipRate: 0.05,
            recentSkipStreak: 0,
            streakDays: 4,
            meetingLoadRatio: 0.2
        )

        let score = RecoveryScoreComputation.score(from: input)
        XCTAssertGreaterThanOrEqual(score, 80)
        XCTAssertEqual(RecoveryScoreComputation.tier(for: score), .optimal)
    }

    func testRecoveryScoreLowComplianceHighSkipsProducesLowScore() {
        let input = RecoveryScoreInput(
            compliance: 34,
            skipRate: 0.8,
            recentSkipStreak: 4,
            streakDays: 0,
            meetingLoadRatio: 0.7
        )

        let score = RecoveryScoreComputation.score(from: input)
        XCTAssertLessThanOrEqual(score, 30)
        XCTAssertEqual(RecoveryScoreComputation.tier(for: score), .depleted)
    }

    func testRecoveryScoreIsClampedToRange() {
        let highInput = RecoveryScoreInput(
            compliance: 150,
            skipRate: 0,
            recentSkipStreak: 0,
            streakDays: 20,
            meetingLoadRatio: nil
        )
        let lowInput = RecoveryScoreInput(
            compliance: 0,
            skipRate: 2.0,
            recentSkipStreak: 20,
            streakDays: 0,
            meetingLoadRatio: 1.0
        )

        XCTAssertEqual(RecoveryScoreComputation.score(from: highInput), 100)
        XCTAssertEqual(RecoveryScoreComputation.score(from: lowInput), 0)
    }

    func testRecoveryTierBoundariesAreDeterministic() {
        XCTAssertEqual(RecoveryScoreComputation.tier(for: 85), .optimal)
        XCTAssertEqual(RecoveryScoreComputation.tier(for: 70), .strong)
        XCTAssertEqual(RecoveryScoreComputation.tier(for: 55), .steady)
        XCTAssertEqual(RecoveryScoreComputation.tier(for: 40), .strained)
        XCTAssertEqual(RecoveryScoreComputation.tier(for: 39), .depleted)
    }

    func testPostureMetricEngineReturnsGoodForIdealAngleAndPreferredDistance() {
        let sample = PostureFrameSample(
            faceScale: 0.15,
            downwardPitchDegrees: 3,
            confidence: 0.9
        )
        let calibration = PostureCalibrationSnapshot(
            cameraToScreenOffsetDegrees: 10,
            baselineFaceScale: 0.12,
            createdAt: Date()
        )
        let input = PostureMetricInput(sample: sample, calibration: calibration)

        let result = PostureMetricEngine.evaluate(input: input)

        XCTAssertEqual(result.classification, .good)
        XCTAssertEqual(result.distanceBand, .preferred)
        XCTAssertEqual(result.calibrationState, .calibrated)
        XCTAssertEqual(result.correctedAngleDegrees?.rounded(), 13)
    }

    func testPostureMetricEngineReturnsInconclusiveWhenConfidenceIsLow() {
        let sample = PostureFrameSample(
            faceScale: 0.15,
            downwardPitchDegrees: 0,
            confidence: 0.2
        )
        let input = PostureMetricInput(sample: sample, calibration: nil)

        let result = PostureMetricEngine.evaluate(input: input)

        XCTAssertEqual(result.classification, .inconclusive)
        XCTAssertEqual(result.distanceBand, .unknown)
        XCTAssertNil(result.correctedAngleDegrees)
    }

    func testPostureDistanceClassificationHandlesNearPreferredAndFarBands() {
        let calibration = PostureCalibrationSnapshot(
            cameraToScreenOffsetDegrees: 12,
            baselineFaceScale: 0.1,
            createdAt: Date()
        )

        XCTAssertEqual(
            PostureMetricEngine.classifyDistance(faceScale: 0.16, calibration: calibration),
            .nearWarning
        )
        XCTAssertEqual(
            PostureMetricEngine.classifyDistance(faceScale: 0.115, calibration: calibration),
            .preferred
        )
        XCTAssertEqual(
            PostureMetricEngine.classifyDistance(faceScale: 0.05, calibration: calibration),
            .farWarning
        )
    }

    func testPostureRecordRoundTripsWithCodable() throws {
        let record = PostureCheckRecord(
            timestamp: Date(timeIntervalSince1970: 123),
            classification: .adjust,
            distanceBand: .comfortPreferred,
            correctedAngleDegrees: 18.5,
            confidence: 0.88,
            recommendation: "Sit slightly farther back.",
            calibrationState: .calibrated
        )

        let encoded = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(PostureCheckRecord.self, from: encoded)

        XCTAssertEqual(decoded.classification, .adjust)
        XCTAssertEqual(decoded.distanceBand, .comfortPreferred)
        XCTAssertEqual(decoded.correctedAngleDegrees, 18.5)
        XCTAssertEqual(decoded.confidence, 0.88)
        XCTAssertEqual(decoded.recommendation, "Sit slightly farther back.")
        XCTAssertEqual(decoded.calibrationState, .calibrated)
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components)!
    }

    private func dateString(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
