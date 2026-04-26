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
