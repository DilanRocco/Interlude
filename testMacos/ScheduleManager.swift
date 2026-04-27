//
//  ScheduleManager.swift
//  testMacos
//

import Foundation
import EventKit

var scheduleWaitTimer: Timer?
var calendarWaitTimer: Timer?

private let calendarBlockingEnabledKey = "calendarBlockingEnabled"

final class CalendarAvailabilityStore {
    static let shared = CalendarAvailabilityStore()

    private let eventStore = EKEventStore()
    private var hasStartedObserving = false
    private var onStoreChanged: (() -> Void)?

    private init() {}

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: calendarBlockingEnabledKey)
    }

    var canReadEvents: Bool {
        let status = authorizationStatus
        if status == .authorized { return true }
        if #available(macOS 14.0, *), status == .fullAccess { return true }
        return false
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        let status = authorizationStatus
        if status == .authorized {
            completion(true)
            return
        }
        if #available(macOS 14.0, *) {
            if status == .fullAccess {
                completion(true)
                return
            }
            if status == .writeOnly {
                completion(false)
                return
            }
        }
        if status == .denied || status == .restricted {
            completion(false)
            return
        }
        if status == .notDetermined {
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { granted, _ in
                    completion(granted)
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, _ in
                    completion(granted)
                }
            }
            return
        }
        completion(false)
    }

    func startObservingStoreChanges(_ handler: @escaping () -> Void) {
        onStoreChanged = handler
        guard !hasStartedObserving else { return }
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.onStoreChanged?()
        }
        hasStartedObserving = true
    }

    func isBlocked(at now: Date = Date()) -> Bool {
        nextUnblockDate(from: now) != nil
    }

    func nextUnblockDate(from now: Date = Date()) -> Date? {
        guard isEnabled, canReadEvents else { return nil }
        let activeEndDates = activeBlockingEvents(at: now).compactMap(\.endDate)
        return activeEndDates.max()
    }

    private func activeBlockingEvents(at now: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let rangeStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let rangeEnd = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        let predicate = eventStore.predicateForEvents(withStart: rangeStart, end: rangeEnd, calendars: nil)
        return eventStore.events(matching: predicate).filter { event in
            event.startDate <= now &&
            event.endDate > now &&
            !event.isAllDay &&
            isBlockingAvailability(event.availability)
        }
    }

    private func isBlockingAvailability(_ availability: EKEventAvailability) -> Bool {
        switch availability {
        case .busy, .tentative, .unavailable:
            return true
        case .free, .notSupported:
            return false
        @unknown default:
            return false
        }
    }
}

func shouldDeferOverlayForCalendar() -> Bool {
    CalendarAvailabilityStore.shared.isBlocked()
}

func deferOverlayUntilCalendarUnblocked() {
    stopCalendarWaitTimer()

    guard let fireDate = CalendarAvailabilityStore.shared.nextUnblockDate(from: Date()) else {
        AppDelegate.StartScreenTimer()
        return
    }

    let delay = max(1, fireDate.timeIntervalSinceNow)
    calendarWaitTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
        calendarWaitTimer = nil
        AppDelegate.StartScreenTimer()
    }
}

func stopCalendarWaitTimer() {
    calendarWaitTimer?.invalidate()
    calendarWaitTimer = nil
}

func handleCalendarStoreChanged() {
    guard calendarWaitTimer != nil else { return }
    if shouldDeferOverlayForCalendar() {
        deferOverlayUntilCalendarUnblocked()
    } else {
        stopCalendarWaitTimer()
        AppDelegate.StartScreenTimer()
    }
}

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
