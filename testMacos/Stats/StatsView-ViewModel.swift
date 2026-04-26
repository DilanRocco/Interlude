//
//  StatsView-ViewModel.swift
//  testMacos
//

import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

enum BreakOutcome: String, Codable {
    case taken
    case skipped
}

struct BreakEvent: Codable {
    let timestamp: Date
    let outcome: BreakOutcome
}

struct DailyStats: Identifiable {
    let dayStart: Date
    let takenCount: Int
    let skippedCount: Int

    var id: Date { dayStart }

    var totalCount: Int { takenCount + skippedCount }
    var compliancePercentage: Int? {
        guard totalCount > 0 else { return nil }
        return Int((Double(takenCount) / Double(totalCount) * 100.0).rounded())
    }
    var streakEligible: Bool {
        totalCount > 0 && skippedCount == 0
    }
}

enum StatsScope: String, CaseIterable, Identifiable {
    case today
    case thisWeek
    case thisMonth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        }
    }
}

struct ScopedStatsSnapshot {
    let takenCount: Int
    let skippedCount: Int
    let compliancePercentage: Int?
    let streakDays: Int
    let chartPoints: [DailyStats]
    let allTimeTakenCount: Int
}

struct StatsComputation {
    static func mondayFirstCalendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    static func dateRange(for scope: StatsScope, now: Date, calendar: Calendar) -> (start: Date, endExclusive: Date) {
        let dayStart = calendar.startOfDay(for: now)
        switch scope {
        case .today:
            let end = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now
            return (dayStart, end)
        case .thisWeek:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            let weekStart = calendar.date(from: components) ?? dayStart
            let end = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            return (weekStart, end)
        case .thisMonth:
            let monthInterval = calendar.dateInterval(of: .month, for: now)
            let start = monthInterval?.start ?? dayStart
            let end = monthInterval?.end ?? now
            return (start, end)
        }
    }

    static func compliancePercentage(taken: Int, skipped: Int) -> Int? {
        let total = taken + skipped
        guard total > 0 else { return nil }
        return Int((Double(taken) / Double(total) * 100.0).rounded())
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func streakLength(
        daily: [String: (taken: Int, skipped: Int)],
        now: Date,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var day = calendar.startOfDay(for: now)

        while true {
            let key = dayKey(for: day, calendar: calendar)
            guard let record = daily[key] else { break }
            let total = record.taken + record.skipped
            if total == 0 || record.skipped > 0 {
                break
            }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }
}

extension Notification.Name {
    static let interludeStatsDidChange = Notification.Name("interludeStatsDidChange")
}

final class StatsStore {
    static let shared = StatsStore()

    private struct DailyStatsRecord: Codable {
        var takenCount: Int
        var skippedCount: Int
    }

    private let defaults = UserDefaults.standard
    private let eventsKey = "interlude.stats.breakEvents.v1"
    private let dailyStatsKey = "interlude.stats.dailyStats.v1"
    private let migrationKey = "interlude.stats.migrated.v1"
    private let allTimeKey = "totalBreaksAllTime"

    private init() {
        migrateIfNeeded()
    }

    func recordTaken(at date: Date = Date()) {
        record(outcome: .taken, at: date)
    }

    func recordSkipped(at date: Date = Date()) {
        record(outcome: .skipped, at: date)
    }

    func snapshot(for scope: StatsScope, now: Date = Date()) -> ScopedStatsSnapshot {
        let scopedDaily = dailyStats(for: scope, now: now)
        let taken = scopedDaily.reduce(0) { $0 + $1.takenCount }
        let skipped = scopedDaily.reduce(0) { $0 + $1.skippedCount }
        let compliance = StatsComputation.compliancePercentage(taken: taken, skipped: skipped)

        return ScopedStatsSnapshot(
            takenCount: taken,
            skippedCount: skipped,
            compliancePercentage: compliance,
            streakDays: currentStreakLength(now: now),
            chartPoints: scopedDaily,
            allTimeTakenCount: defaults.integer(forKey: allTimeKey)
        )
    }

    func dailyStats(for scope: StatsScope, now: Date = Date()) -> [DailyStats] {
        let calendar = mondayFirstCalendar
        let range = StatsComputation.dateRange(for: scope, now: now, calendar: calendar)
        return chartSeries(from: range.start, toExclusive: range.endExclusive, calendar: calendar)
    }

    private func record(outcome: BreakOutcome, at date: Date) {
        var events = loadEvents()
        events.append(BreakEvent(timestamp: date, outcome: outcome))
        saveEvents(events)

        var daily = loadDailyRecords()
        let key = dayKey(for: date)
        var record = daily[key] ?? DailyStatsRecord(takenCount: 0, skippedCount: 0)
        switch outcome {
        case .taken:
            record.takenCount += 1
            defaults.set(defaults.integer(forKey: allTimeKey) + 1, forKey: allTimeKey)
        case .skipped:
            record.skippedCount += 1
        }
        daily[key] = record
        saveDailyRecords(daily)

        NotificationCenter.default.post(name: .interludeStatsDidChange, object: nil)
    }

    private var mondayFirstCalendar: Calendar {
        StatsComputation.mondayFirstCalendar()
    }

    private func chartSeries(from start: Date, toExclusive endExclusive: Date, calendar: Calendar) -> [DailyStats] {
        var series: [DailyStats] = []
        let allDaily = loadDailyRecords()
        var dayCursor = calendar.startOfDay(for: start)
        let finalDayStart = calendar.startOfDay(for: min(Date(), calendar.date(byAdding: .second, value: -1, to: endExclusive) ?? Date()))

        while dayCursor <= finalDayStart {
            let key = dayKey(for: dayCursor)
            let record = allDaily[key] ?? DailyStatsRecord(takenCount: 0, skippedCount: 0)
            series.append(DailyStats(dayStart: dayCursor, takenCount: record.takenCount, skippedCount: record.skippedCount))
            dayCursor = calendar.date(byAdding: .day, value: 1, to: dayCursor) ?? dayCursor
            if dayCursor == series.last?.dayStart {
                break
            }
        }

        return series
    }

    private func currentStreakLength(now: Date) -> Int {
        let calendar = mondayFirstCalendar
        let tuples = loadDailyRecords().mapValues { (taken: $0.takenCount, skipped: $0.skippedCount) }
        return StatsComputation.streakLength(daily: tuples, now: now, calendar: calendar)
    }

    private func dayKey(for date: Date) -> String {
        StatsComputation.dayKey(for: date, calendar: mondayFirstCalendar)
    }

    private func loadEvents() -> [BreakEvent] {
        guard let data = defaults.data(forKey: eventsKey),
              let events = try? JSONDecoder().decode([BreakEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func saveEvents(_ events: [BreakEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: eventsKey)
    }

    private func loadDailyRecords() -> [String: DailyStatsRecord] {
        guard let data = defaults.data(forKey: dailyStatsKey),
              let records = try? JSONDecoder().decode([String: DailyStatsRecord].self, from: data) else {
            return [:]
        }
        return records
    }

    private func saveDailyRecords(_ records: [String: DailyStatsRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: dailyStatsKey)
    }

    private func migrateIfNeeded() {
        guard !defaults.bool(forKey: migrationKey) else { return }
        if defaults.object(forKey: allTimeKey) == nil {
            defaults.set(0, forKey: allTimeKey)
        }
        defaults.set(true, forKey: migrationKey)
    }
}

enum StatsExportFormat {
    case csv
    case text

    var fileExtension: String {
        switch self {
        case .csv:
            return "csv"
        case .text:
            return "txt"
        }
    }

    var defaultFileName: String {
        switch self {
        case .csv:
            return "interlude-stats.csv"
        case .text:
            return "interlude-stats.txt"
        }
    }
}

struct StatsExportFormatter {
    static func buildCSV(rows: [DailyStats]) -> String {
        var lines = ["date,taken,skipped,compliance_percent,streak_eligible"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current

        for row in rows {
            let date = formatter.string(from: row.dayStart)
            let compliance = row.compliancePercentage.map(String.init) ?? "N/A"
            let streakEligible = row.streakEligible ? "true" : "false"
            lines.append("\(date),\(row.takenCount),\(row.skippedCount),\(compliance),\(streakEligible)")
        }

        return lines.joined(separator: "\n")
    }

    static func buildPlainText(rows: [DailyStats], scope: StatsScope, streakDays: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current

        var output: [String] = []
        output.append("Interlude Stats Export - \(scope.title)")
        output.append("Current streak (days): \(streakDays)")
        output.append("")

        for row in rows {
            let date = formatter.string(from: row.dayStart)
            let compliance = row.compliancePercentage.map { "\($0)%" } ?? "N/A"
            output.append("\(date): taken \(row.takenCount), skipped \(row.skippedCount), compliance \(compliance)")
        }

        return output.joined(separator: "\n")
    }
}

extension StatsView {
    @MainActor final class ViewModel: ObservableObject {
        @Published var selectedScope: StatsScope = .today {
            didSet { refresh() }
        }
        @Published var takenForScope: Int = 0
        @Published var skippedForScope: Int = 0
        @Published var complianceText: String = "N/A"
        @Published var streakDays: Int = 0
        @Published var chartData: [DailyStats] = []
        @Published var allTimeTotal: Int = 0

        private let statsStore = StatsStore.shared
        private var cancellables: Set<AnyCancellable> = []

        init() {
            bindNotifications()
            refresh()
        }

        func refresh() {
            let snapshot = statsStore.snapshot(for: selectedScope)
            takenForScope = snapshot.takenCount
            skippedForScope = snapshot.skippedCount
            complianceText = snapshot.compliancePercentage.map { "\($0)%" } ?? "N/A"
            streakDays = snapshot.streakDays
            chartData = snapshot.chartPoints
            allTimeTotal = snapshot.allTimeTakenCount
        }

        func exportAsCSV() {
            export(format: .csv)
        }

        func exportAsText() {
            export(format: .text)
        }

        private func bindNotifications() {
            NotificationCenter.default.publisher(for: .interludeStatsDidChange)
                .sink { [weak self] _ in self?.refresh() }
                .store(in: &cancellables)

            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
                .sink { [weak self] _ in self?.refresh() }
                .store(in: &cancellables)
        }

        private func export(format: StatsExportFormat) {
            let rows = statsStore.dailyStats(for: selectedScope)
            let payload: String

            switch format {
            case .csv:
                payload = StatsExportFormatter.buildCSV(rows: rows)
            case .text:
                payload = StatsExportFormatter.buildPlainText(rows: rows, scope: selectedScope, streakDays: streakDays)
            }

            let savePanel = NSSavePanel()
            if #available(macOS 12.0, *) {
                savePanel.allowedContentTypes = format == .csv ? [.commaSeparatedText] : [.plainText]
            } else {
                savePanel.allowedFileTypes = [format.fileExtension]
            }
            savePanel.nameFieldStringValue = format.defaultFileName
            savePanel.canCreateDirectories = true

            guard savePanel.runModal() == .OK,
                  let destinationURL = savePanel.url else { return }

            try? payload.write(to: destinationURL, atomically: true, encoding: .utf8)
        }
    }
}
