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

struct RecentBreakStats {
    let sampleCount: Int
    let skipRate: Double
    let recentSkipStreak: Int
}

enum RecoveryTier: String {
    case optimal = "Optimal"
    case strong = "Strong"
    case steady = "Steady"
    case strained = "Strained"
    case depleted = "Depleted"
}

enum RecoveryViewState {
    case loading
    case empty
    case partial
    case ready
    case error
}

struct RecoveryScoreInput {
    let compliance: Int
    let skipRate: Double
    let recentSkipStreak: Int
    let streakDays: Int
    let meetingLoadRatio: Double?
}

struct RecoveryScoreSnapshot {
    let score: Int
    let tier: RecoveryTier
    let insightText: String
    let trendText: String
    let missingSignals: [String]

    var isPartial: Bool {
        !missingSignals.isEmpty
    }
}

enum RecoveryScoreComputation {
    static func score(from input: RecoveryScoreInput) -> Int {
        var value = Double(input.compliance)
        value -= input.skipRate * 22.0
        value -= Double(min(input.recentSkipStreak, 5)) * 3.0
        value += Double(min(input.streakDays, 7)) * 1.5
        if let meetingLoadRatio = input.meetingLoadRatio {
            value -= min(max(meetingLoadRatio, 0), 1) * 10.0
        }
        return min(max(Int(value.rounded()), 0), 100)
    }

    static func tier(for score: Int) -> RecoveryTier {
        switch score {
        case 85...100:
            return .optimal
        case 70...84:
            return .strong
        case 55...69:
            return .steady
        case 40...54:
            return .strained
        default:
            return .depleted
        }
    }

    static func trendText(current: Int, previous: Int?) -> String {
        guard let previous else { return "No prior-day baseline yet" }
        let delta = current - previous
        if delta >= 8 {
            return "Up \(delta) vs yesterday"
        }
        if delta <= -8 {
            return "Down \(abs(delta)) vs yesterday"
        }
        return "Stable vs yesterday"
    }

    static func insightText(input: RecoveryScoreInput, score: Int) -> String {
        if input.compliance < 50 {
            return "Low break compliance is dragging recovery down."
        }
        if input.recentSkipStreak >= 3 {
            return "Recent skipped-break streak is increasing strain."
        }
        if let meetingLoadRatio = input.meetingLoadRatio, meetingLoadRatio >= 0.6 {
            return "Heavy meeting load is reducing recovery headroom."
        }
        if input.streakDays >= 3 {
            return "Consistent break streak is supporting recovery."
        }
        if score >= 70 {
            return "Recovery is in a strong range today."
        }
        return "More consistent breaks can improve recovery quickly."
    }

    static func baselineScore(compliance: Int, skippedCount: Int) -> Int {
        let value = Double(compliance) - Double(min(skippedCount, 5) * 6)
        return min(max(Int(value.rounded()), 0), 100)
    }
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

    func recentBreakStats(sampleSize: Int = 20) -> RecentBreakStats? {
        let allEvents = loadEvents()
        guard !allEvents.isEmpty else { return nil }

        let boundedSampleSize = max(1, sampleSize)
        let window = Array(allEvents.suffix(boundedSampleSize))
        let skipCount = window.reduce(0) { total, event in
            total + (event.outcome == .skipped ? 1 : 0)
        }
        let streak = recentSkipStreak(from: allEvents)
        let skipRate = Double(skipCount) / Double(window.count)
        return RecentBreakStats(
            sampleCount: window.count,
            skipRate: skipRate,
            recentSkipStreak: streak
        )
    }

    func recoveryScoreSnapshot(now: Date = Date()) -> RecoveryScoreSnapshot? {
        let calendar = mondayFirstCalendar
        let todayRecord = dailyRecord(for: now, calendar: calendar)
        let totalToday = todayRecord.takenCount + todayRecord.skippedCount
        guard totalToday > 0 else { return nil }

        let complianceToday = StatsComputation.compliancePercentage(
            taken: todayRecord.takenCount,
            skipped: todayRecord.skippedCount
        ) ?? 0
        let recentStats = recentBreakStats(sampleSize: 20)
        let skipRate = recentStats?.skipRate ?? Double(todayRecord.skippedCount) / Double(max(totalToday, 1))
        let skipStreak = recentStats?.recentSkipStreak ?? 0
        let streakDays = currentStreakLength(now: now)
        let meetingLoadRatio = CalendarAvailabilityStore.shared.meetingLoadRatioForToday(reference: now)

        let input = RecoveryScoreInput(
            compliance: complianceToday,
            skipRate: skipRate,
            recentSkipStreak: skipStreak,
            streakDays: streakDays,
            meetingLoadRatio: meetingLoadRatio
        )

        let score = RecoveryScoreComputation.score(from: input)
        let tier = RecoveryScoreComputation.tier(for: score)
        let previousDayScore = previousDayBaselineScore(now: now, calendar: calendar)
        let trendText = RecoveryScoreComputation.trendText(current: score, previous: previousDayScore)
        let insight = RecoveryScoreComputation.insightText(input: input, score: score)

        var missingSignals: [String] = []
        if recentStats == nil {
            missingSignals.append("Recent behavior sample")
        }
        if meetingLoadRatio == nil {
            missingSignals.append("Calendar load")
        }

        return RecoveryScoreSnapshot(
            score: score,
            tier: tier,
            insightText: insight,
            trendText: trendText,
            missingSignals: missingSignals
        )
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

    private func recentSkipStreak(from events: [BreakEvent]) -> Int {
        var streak = 0
        for event in events.reversed() {
            if event.outcome == .skipped {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private func dailyRecord(for date: Date, calendar: Calendar) -> DailyStatsRecord {
        let key = StatsComputation.dayKey(for: date, calendar: calendar)
        return loadDailyRecords()[key] ?? DailyStatsRecord(takenCount: 0, skippedCount: 0)
    }

    private func previousDayBaselineScore(now: Date, calendar: Calendar) -> Int? {
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
        let previousRecord = dailyRecord(for: previousDate, calendar: calendar)
        let total = previousRecord.takenCount + previousRecord.skippedCount
        guard total > 0 else { return nil }

        let compliance = StatsComputation.compliancePercentage(
            taken: previousRecord.takenCount,
            skipped: previousRecord.skippedCount
        ) ?? 0
        return RecoveryScoreComputation.baselineScore(
            compliance: compliance,
            skippedCount: previousRecord.skippedCount
        )
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

    func exportStatsToDownloads(scope: StatsScope, format: StatsExportFormat) throws -> URL {
        let rows = dailyStats(for: scope)
        let payload: String

        switch format {
        case .csv:
            payload = StatsExportFormatter.buildCSV(rows: rows)
        case .text:
            payload = StatsExportFormatter.buildPlainText(rows: rows, scope: scope, streakDays: currentStreakLength(now: Date()))
        }

        let fileManager = FileManager.default
        let baseDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "interlude-stats-\(scope.rawValue)-\(timestamp).\(format.fileExtension)"
        let destinationURL = baseDirectory.appendingPathComponent(fileName)

        try payload.write(to: destinationURL, atomically: true, encoding: .utf8)
        return destinationURL
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
        @Published var selectedScope: StatsScope = .thisWeek {
            didSet { refresh() }
        }
        @Published var takenForScope: Int = 0
        @Published var skippedForScope: Int = 0
        @Published var complianceText: String = "N/A"
        @Published var streakDays: Int = 0
        @Published var chartData: [DailyStats] = []
        @Published var allTimeTotal: Int = 0
        @Published var recoveryScoreValue: Int = 0
        @Published var recoveryScoreText: String = "--"
        @Published var recoveryTierLabel: String = "No Data"
        @Published var recoveryInsightText: String = "Recovery score appears after recorded break activity."
        @Published var recoveryTrendText: String = ""
        @Published var recoveryStateMessage: String = ""
        @Published var recoveryViewState: RecoveryViewState = .loading

        private let statsStore = StatsStore.shared
        private var cancellables: Set<AnyCancellable> = []

        init() {
            bindNotifications()
            refresh()
        }

        func refresh() {
            recoveryViewState = .loading

            let snapshot = statsStore.snapshot(for: selectedScope)
            takenForScope = snapshot.takenCount
            skippedForScope = snapshot.skippedCount
            complianceText = snapshot.compliancePercentage.map { "\($0)%" } ?? "N/A"
            streakDays = snapshot.streakDays
            chartData = snapshot.chartPoints
            allTimeTotal = snapshot.allTimeTakenCount

            guard let recovery = statsStore.recoveryScoreSnapshot() else {
                recoveryScoreValue = 0
                recoveryScoreText = "--"
                recoveryTierLabel = "No Data"
                recoveryInsightText = "Complete a few break cycles to generate your daily recovery score."
                recoveryTrendText = "No baseline yet"
                recoveryStateMessage = "Insufficient history to calculate recovery."
                recoveryViewState = .empty
                return
            }

            recoveryScoreValue = recovery.score
            recoveryScoreText = "\(recovery.score)"
            recoveryTierLabel = recovery.tier.rawValue
            recoveryInsightText = recovery.insightText
            recoveryTrendText = recovery.trendText
            if recovery.isPartial {
                recoveryStateMessage = "Limited signals: \(recovery.missingSignals.joined(separator: ", "))."
                recoveryViewState = .partial
            } else {
                recoveryStateMessage = ""
                recoveryViewState = .ready
            }
        }

        func retryRecovery() {
            refresh()
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
