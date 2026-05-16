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

    func testPostureMetricEngineScoresHighForGoodPosture() {
        let observation = BodyPoseObservation(
            nose: CGPoint(x: 0.5, y: 0.7),
            leftEar: CGPoint(x: 0.45, y: 0.65),
            rightEar: CGPoint(x: 0.55, y: 0.65),
            leftShoulder: CGPoint(x: 0.4, y: 0.5),
            rightShoulder: CGPoint(x: 0.6, y: 0.5),
            neck: CGPoint(x: 0.5, y: 0.55),
            noseConfidence: 0.9,
            leftEarConfidence: 0.9,
            rightEarConfidence: 0.9,
            leftShoulderConfidence: 0.9,
            rightShoulderConfidence: 0.9,
            neckConfidence: 0.9
        )

        let result = PostureMetricEngine.evaluate(observation: observation, confidence: 0.9)

        XCTAssertGreaterThanOrEqual(result.score, 70)
        XCTAssertFalse(result.limitedVisibility)
    }

    func testPostureMetricEngineDegradeGracefullyWithoutShoulders() {
        let observation = BodyPoseObservation(
            nose: CGPoint(x: 0.5, y: 0.7),
            leftEar: CGPoint(x: 0.45, y: 0.65),
            rightEar: CGPoint(x: 0.55, y: 0.65),
            leftShoulder: nil,
            rightShoulder: nil,
            neck: nil,
            noseConfidence: 0.9,
            leftEarConfidence: 0.9,
            rightEarConfidence: 0.9,
            leftShoulderConfidence: 0,
            rightShoulderConfidence: 0,
            neckConfidence: 0
        )

        let result = PostureMetricEngine.evaluate(observation: observation, confidence: 0.8)

        XCTAssertTrue(result.limitedVisibility)
        XCTAssertGreaterThan(result.score, 0)
        XCTAssertFalse(result.recommendations.isEmpty)
    }

    func testPostureGaussianScoringHasNoCliffDrops() {
        let metrics1 = PostureMetrics(
            headForwardAngleDegrees: 9,
            headTiltDegrees: 2,
            shoulderSymmetryDelta: 0.01,
            shoulderRoundingOffset: 0.01,
            availableFactors: [.headForward, .headTilt, .shoulderSymmetry, .shoulderRounding]
        )
        let metrics2 = PostureMetrics(
            headForwardAngleDegrees: 11,
            headTiltDegrees: 2,
            shoulderSymmetryDelta: 0.01,
            shoulderRoundingOffset: 0.01,
            availableFactors: [.headForward, .headTilt, .shoulderSymmetry, .shoulderRounding]
        )

        let score1 = PostureMetricEngine.score(metrics: metrics1)
        let score2 = PostureMetricEngine.score(metrics: metrics2)
        let diff = abs(score1 - score2)

        XCTAssertLessThan(diff, 0.1, "Scores for similar postures should not cliff-drop")
    }

    func testPostureRecordRoundTripsWithCodable() throws {
        let record = PostureCheckRecord(
            timestamp: Date(timeIntervalSince1970: 123),
            score: 78,
            headForwardAngleDegrees: 8.5,
            headTiltDegrees: 3.0,
            shoulderSymmetryDelta: 0.02,
            shoulderRoundingOffset: 0.03,
            confidence: 0.88,
            recommendation: "Your posture looks great.",
            limitedVisibility: false
        )

        let encoded = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(PostureCheckRecord.self, from: encoded)

        XCTAssertEqual(decoded.score, 78)
        XCTAssertEqual(decoded.headForwardAngleDegrees, 8.5)
        XCTAssertEqual(decoded.confidence, 0.88)
        XCTAssertEqual(decoded.recommendation, "Your posture looks great.")
        XCTAssertFalse(decoded.limitedVisibility)
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
