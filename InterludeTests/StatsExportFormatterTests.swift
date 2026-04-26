import XCTest
@testable import Interlude

final class StatsExportFormatterTests: XCTestCase {
    func testCSVExportIncludesExpectedColumnsAndRows() {
        let rows = [
            DailyStats(dayStart: makeDate("2026-04-25"), takenCount: 3, skippedCount: 1),
            DailyStats(dayStart: makeDate("2026-04-26"), takenCount: 0, skippedCount: 0)
        ]

        let csv = StatsExportFormatter.buildCSV(rows: rows)

        XCTAssertTrue(csv.contains("date,taken,skipped,compliance_percent,streak_eligible"))
        XCTAssertTrue(csv.contains("2026-04-25,3,1,75,false"))
        XCTAssertTrue(csv.contains("2026-04-26,0,0,N/A,false"))
    }

    func testPlainTextExportIncludesScopeAndStreak() {
        let rows = [
            DailyStats(dayStart: makeDate("2026-04-26"), takenCount: 2, skippedCount: 0)
        ]

        let text = StatsExportFormatter.buildPlainText(rows: rows, scope: .today, streakDays: 4)

        XCTAssertTrue(text.contains("Interlude Stats Export - Today"))
        XCTAssertTrue(text.contains("Current streak (days): 4"))
        XCTAssertTrue(text.contains("2026-04-26: taken 2, skipped 0, compliance 100%"))
    }

    private func makeDate(_ value: String) -> Date {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: parts[0],
            month: parts[1],
            day: parts[2],
            hour: 12,
            minute: 0
        )
        return calendar.date(from: components)!
    }
}
