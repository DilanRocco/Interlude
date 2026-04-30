//
//  Notification.swift
//  Interlude
//
//  Created by Dilan Piscatello on 7/25/22.
//

import Foundation
import AppKit
import AppIntents
extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}
class Notifications{
    static var timer: Timer?
    static func openSettings(){
        let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
           NSWorkspace.shared.open(prefpaneUrl)
    }
}

@MainActor
enum IntentActionRouter {
    private static var focusBlockTimer: Timer?

    static func skipNextBreak() {
        AppDelegate.StopScreenTimer()
        AppDelegate.StartScreenTimer()
    }

    static func openStretches() {
        OpenStretchHomePage()
    }

    static func startFocusBlock(minutes: Int) {
        let durationMinutes = max(1, minutes)
        focusBlockTimer?.invalidate()
        AppDelegate.StopScreenTimer()
        focusBlockTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(durationMinutes * 60), repeats: false) { _ in
            Task { @MainActor in
                focusBlockTimer = nil
                if !watchingAMovie {
                    AppDelegate.StartScreenTimer()
                }
            }
        }
    }
}

@available(macOS 13.0, *)
enum InterludeExportScope: String, AppEnum {
    case today
    case thisWeek
    case thisMonth

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Stats Scope")
    static var caseDisplayRepresentations: [InterludeExportScope: DisplayRepresentation] = [
        .today: "Today",
        .thisWeek: "This Week",
        .thisMonth: "This Month"
    ]

    var statsScope: StatsScope {
        switch self {
        case .today:
            return .today
        case .thisWeek:
            return .thisWeek
        case .thisMonth:
            return .thisMonth
        }
    }
}

@available(macOS 13.0, *)
enum InterludeExportFormat: String, AppEnum {
    case csv
    case text

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Export Format")
    static var caseDisplayRepresentations: [InterludeExportFormat: DisplayRepresentation] = [
        .csv: "CSV",
        .text: "Text"
    ]

    var statsFormat: StatsExportFormat {
        switch self {
        case .csv:
            return .csv
        case .text:
            return .text
        }
    }
}

@available(macOS 13.0, *)
struct SkipNextBreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Next Break"
    static var description = IntentDescription("Resets the current countdown and starts the next break timer immediately.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            IntentActionRouter.skipNextBreak()
        }
        return .result(dialog: "Skipped the current break and restarted the timer.")
    }
}

@available(macOS 13.0, *)
struct OpenStretchesIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Stretches"
    static var description = IntentDescription("Opens the Interlude stretches window.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            IntentActionRouter.openStretches()
        }
        return .result(dialog: "Opened stretches.")
    }
}

@available(macOS 13.0, *)
struct StartFocusBlockIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Block"
    static var description = IntentDescription("Pauses reminders for a fixed number of minutes and resumes automatically.")

    @Parameter(title: "Minutes")
    var minutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Pause reminders for \(\.$minutes) minutes")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let clampedMinutes = max(1, min(minutes, 240))
        await MainActor.run {
            IntentActionRouter.startFocusBlock(minutes: clampedMinutes)
        }
        return .result(dialog: "Focus block started for \(clampedMinutes) minutes.")
    }
}

@available(macOS 13.0, *)
struct ExportStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Stats"
    static var description = IntentDescription("Exports Interlude stats as CSV or text to your Downloads folder.")

    @Parameter(title: "Scope")
    var scope: InterludeExportScope

    @Parameter(title: "Format")
    var format: InterludeExportFormat

    static var parameterSummary: some ParameterSummary {
        Summary("Export \(\.$scope) stats as \(\.$format)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let destinationURL = try StatsStore.shared.exportStatsToDownloads(scope: scope.statsScope, format: format.statsFormat)
        return .result(dialog: IntentDialog("Exported stats to \(destinationURL.lastPathComponent)."))
    }
}

@available(macOS 13.0, *)
struct InterludeShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SkipNextBreakIntent(), phrases: ["Skip next break in \(.applicationName)"], shortTitle: "Skip Next Break", systemImageName: "forward.fill")
        AppShortcut(intent: OpenStretchesIntent(), phrases: ["Open stretches in \(.applicationName)"], shortTitle: "Open Stretches", systemImageName: "figure.cooldown")
        AppShortcut(intent: StartFocusBlockIntent(), phrases: ["Start focus block in \(.applicationName)"], shortTitle: "Start Focus Block", systemImageName: "timer")
        AppShortcut(intent: ExportStatsIntent(), phrases: ["Export stats from \(.applicationName)"], shortTitle: "Export Stats", systemImageName: "square.and.arrow.up")
    }
}
