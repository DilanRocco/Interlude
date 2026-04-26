//
//  ScheduleManager.swift
//  testMacos
//

import Foundation

var scheduleWaitTimer: Timer?

/// Returns true if the app should be active right now (i.e. break reminders should run).
/// Returns true unconditionally when schedule is disabled.
func isWithinSchedule() -> Bool {
    let ud = UserDefaults.standard
    guard ud.bool(forKey: "scheduleEnabled") else { return true }

    let calendar = Calendar.current
    let now = Date()
    let weekday = calendar.component(.weekday, from: now) // 1=Sun, 7=Sat

    if ud.bool(forKey: "scheduleWeekdaysOnly") {
        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend { return false }
    }

    let currentHour = calendar.component(.hour, from: now)
    let currentMinute = calendar.component(.minute, from: now)
    let currentTotalMinutes = currentHour * 60 + currentMinute

    let startTotalMinutes = ud.integer(forKey: "scheduleStartHour") * 60 + ud.integer(forKey: "scheduleStartMinute")
    let endTotalMinutes = ud.integer(forKey: "scheduleEndHour") * 60 + ud.integer(forKey: "scheduleEndMinute")

    return currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
}

/// Starts a one-shot timer that fires exactly when the next schedule window opens,
/// then calls AppDelegate.StartScreenTimer().
func startScheduleWaitTimer() {
    stopScheduleWaitTimer()

    guard let fireDate = nextScheduleStart() else { return }
    let delay = fireDate.timeIntervalSinceNow
    guard delay > 0 else {
        // Window opens immediately (shouldn't normally happen but guard against it)
        AppDelegate.StartScreenTimer()
        return
    }

    scheduleWaitTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
        scheduleWaitTimer = nil
        AppDelegate.StartScreenTimer()
    }
}

func stopScheduleWaitTimer() {
    scheduleWaitTimer?.invalidate()
    scheduleWaitTimer = nil
}

/// Computes the next Date at which the schedule window opens.
/// Returns nil if scheduleEnabled is false (no waiting needed).
private func nextScheduleStart() -> Date? {
    let ud = UserDefaults.standard
    guard ud.bool(forKey: "scheduleEnabled") else { return nil }

    let calendar = Calendar.current
    let now = Date()

    let startHour = ud.integer(forKey: "scheduleStartHour")
    let startMinute = ud.integer(forKey: "scheduleStartMinute")
    let weekdaysOnly = ud.bool(forKey: "scheduleWeekdaysOnly")

    // Build a candidate start time for today
    var components = calendar.dateComponents([.year, .month, .day], from: now)
    components.hour = startHour
    components.minute = startMinute
    components.second = 0

    guard var candidate = calendar.date(from: components) else { return nil }

    // If today's start time has already passed, move to tomorrow
    if candidate <= now {
        candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }

    // If weekdays only, skip forward past weekend days
    if weekdaysOnly {
        for _ in 0..<7 {
            let weekday = calendar.component(.weekday, from: candidate)
            let isWeekend = weekday == 1 || weekday == 7
            if !isWeekend { break }
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
    }

    return candidate
}
