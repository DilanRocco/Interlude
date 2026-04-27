//
//  PreferencesView-ViewModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import Foundation
import UserNotifications
import AppKit
import EventKit

extension GeneralView{
    @MainActor class ViewModel: ObservableObject{
        let backgroundColors: [BackgroundColorOverlay]
        
        @Published var notificationsOn: Bool {
            didSet {
                UserDefaults.standard.set(notificationsOn, forKey: "useNotifications")
            }
        }
        
        @Published var displaySettingPage: Bool = false
        
        @Published var selectedIntervalTime:Int {
            didSet {
                UserDefaults.standard.set(selectedIntervalTime, forKey: "screenInterval")
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }
       
        @Published var selectedOverlayTime: Int {
            didSet {
                UserDefaults.standard.set(selectedOverlayTime, forKey: "overlayInterval")
            }
        }
        
        @Published var selectedBackgroundColor: BackgroundColorOverlay{
            didSet{
                UserDefaults.backgroundColor = selectedBackgroundColor
            }
        }

        // MARK: - Schedule

        @Published var scheduleEnabled: Bool {
            didSet {
                UserDefaults.standard.set(scheduleEnabled, forKey: "scheduleEnabled")
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }

        @Published var scheduleStart: Date {
            didSet {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: scheduleStart)
                UserDefaults.standard.set(comps.hour ?? 9,   forKey: "scheduleStartHour")
                UserDefaults.standard.set(comps.minute ?? 0, forKey: "scheduleStartMinute")
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }

        @Published var scheduleEnd: Date {
            didSet {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: scheduleEnd)
                UserDefaults.standard.set(comps.hour ?? 18,  forKey: "scheduleEndHour")
                UserDefaults.standard.set(comps.minute ?? 0, forKey: "scheduleEndMinute")
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }

        @Published var scheduleWeekdaysOnly: Bool {
            didSet {
                UserDefaults.standard.set(scheduleWeekdaysOnly, forKey: "scheduleWeekdaysOnly")
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }

        @Published var calendarBlockingEnabled: Bool {
            didSet {
                handleCalendarBlockingToggle()
            }
        }

        @Published var calendarAccessStatusText: String

        private var isSyncingCalendarToggle = false

        private static func timeFromHourMinute(hourKey: String, minuteKey: String) -> Date {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = UserDefaults.standard.integer(forKey: hourKey)
            comps.minute = UserDefaults.standard.integer(forKey: minuteKey)
            comps.second = 0
            return Calendar.current.date(from: comps) ?? Date()
        }

        init(){
            backgroundColors = [Constants.DefaultBackgroundColor,BackgroundColorOverlay.init(backColor: "#0a104599", helpText: "Royal Blue Dark",dark: true),BackgroundColorOverlay.init(backColor:  "#da416799", helpText: "Cerise",dark: true),BackgroundColorOverlay.init(backColor: "#edae4999", helpText: "Sunray",dark: false),BackgroundColorOverlay.init(backColor: "#067bc299", helpText: "Star Command Blue",dark: true),BackgroundColorOverlay.init(backColor: "#64b6ac99", helpText: "Green Sheen",dark: false),BackgroundColorOverlay.init(backColor: "#13111299", helpText: "Smoky Black",dark: true)]
            
            selectedIntervalTime = (UserDefaults.standard.integer(forKey: "screenInterval"))
            selectedOverlayTime = (UserDefaults.standard.integer(forKey: "overlayInterval"))
            selectedBackgroundColor = UserDefaults.backgroundColor
            notificationsOn = (UserDefaults.standard.bool(forKey: "useNotifications"))

            scheduleEnabled = UserDefaults.standard.bool(forKey: "scheduleEnabled")
            scheduleStart = ViewModel.timeFromHourMinute(hourKey: "scheduleStartHour", minuteKey: "scheduleStartMinute")
            scheduleEnd   = ViewModel.timeFromHourMinute(hourKey: "scheduleEndHour",   minuteKey: "scheduleEndMinute")
            scheduleWeekdaysOnly = UserDefaults.standard.bool(forKey: "scheduleWeekdaysOnly")
            calendarBlockingEnabled = UserDefaults.standard.bool(forKey: "calendarBlockingEnabled")
            calendarAccessStatusText = ViewModel.calendarAuthorizationStatusText()
        }

        private func handleCalendarBlockingToggle() {
            guard !isSyncingCalendarToggle else { return }

            UserDefaults.standard.set(calendarBlockingEnabled, forKey: "calendarBlockingEnabled")
            if !calendarBlockingEnabled {
                stopCalendarWaitTimer()
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
                calendarAccessStatusText = ViewModel.calendarAuthorizationStatusText()
                return
            }

            CalendarAvailabilityStore.shared.requestAccess { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.calendarAccessStatusText = ViewModel.calendarAuthorizationStatusText()
                    } else {
                        self.isSyncingCalendarToggle = true
                        self.calendarBlockingEnabled = false
                        self.isSyncingCalendarToggle = false
                        UserDefaults.standard.set(false, forKey: "calendarBlockingEnabled")
                        self.calendarAccessStatusText = ViewModel.calendarAuthorizationStatusText()
                    }
                }
            }
        }

        private static func calendarAuthorizationStatusText() -> String {
            let status = EKEventStore.authorizationStatus(for: .event)
            if status == .authorized { return "Calendar access granted." }
            if #available(macOS 14.0, *), status == .fullAccess { return "Calendar access granted." }
            if #available(macOS 14.0, *), status == .writeOnly { return "Calendar write-only access; meeting blocking needs full access." }
            if status == .notDetermined { return "Calendar access not requested." }
            if status == .restricted { return "Calendar access restricted by system." }
            if status == .denied { return "Calendar access denied." }
            return "Calendar access unavailable."
            }
        }
    }
    


   







    





