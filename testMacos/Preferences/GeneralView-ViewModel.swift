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
import AVFoundation

extension GeneralView{
    @MainActor class ViewModel: ObservableObject{
        let backgroundColors: [BackgroundColorOverlay]
        private let settingsStore = AppSettingsStore.shared
        
        @Published var notificationsOn: Bool {
            didSet {
                settingsStore.updateNotificationsOn(notificationsOn)
            }
        }

        @Published var aiBreakTimeEnabled: Bool {
            didSet {
                settingsStore.updateAIBreakTimeEnabled(aiBreakTimeEnabled)
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }
        
        @Published var displaySettingPage: Bool = false
        
        @Published var selectedIntervalTime:Int {
            didSet {
                settingsStore.updateScreenIntervalMinutes(selectedIntervalTime)
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }
       
        @Published var selectedOverlayTime: Int {
            didSet {
                settingsStore.updateOverlayIntervalSeconds(selectedOverlayTime)
            }
        }
        
        @Published var selectedBackgroundColor: BackgroundColorOverlay{
            didSet{
                settingsStore.updateBackgroundColor(selectedBackgroundColor)
            }
        }

        @Published var iCloudSyncEnabled: Bool {
            didSet {
                let changed = settingsStore.setICloudSyncEnabled(iCloudSyncEnabled)
                if changed {
                    iCloudSyncStatusText = "Sync preference saved. Restart Interlude to apply this change."
                }
            }
        }

        @Published var iCloudSyncStatusText: String

        // MARK: - Schedule

        @Published var scheduleEnabled: Bool {
            didSet {
                settingsStore.updateScheduleEnabled(scheduleEnabled)
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }

        @Published var scheduleStart: Date {
            didSet {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: scheduleStart)
                settingsStore.updateScheduleStart(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }

        @Published var scheduleEnd: Date {
            didSet {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: scheduleEnd)
                settingsStore.updateScheduleEnd(hour: comps.hour ?? 18, minute: comps.minute ?? 0)
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }
        }

        @Published var scheduleWeekdaysOnly: Bool {
            didSet {
                settingsStore.updateScheduleWeekdaysOnly(scheduleWeekdaysOnly)
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

        @Published var autoPostureCheckEnabled: Bool {
            didSet { handleAutoPostureToggle() }
        }

        @Published var cameraAccessStatusText: String

        private var isSyncingPostureToggle = false
        private var isSyncingCalendarToggle = false

        private static func timeFromHourMinute(hour: Int, minute: Int) -> Date {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            return Calendar.current.date(from: comps) ?? Date()
        }

        init(){
            let settings = settingsStore.currentSettings()
            backgroundColors = [Constants.DefaultBackgroundColor,BackgroundColorOverlay.init(backColor: "#0a104599", helpText: "Royal Blue Dark",dark: true),BackgroundColorOverlay.init(backColor:  "#da416799", helpText: "Cerise",dark: true),BackgroundColorOverlay.init(backColor: "#edae4999", helpText: "Sunray",dark: false),BackgroundColorOverlay.init(backColor: "#067bc299", helpText: "Star Command Blue",dark: true),BackgroundColorOverlay.init(backColor: "#64b6ac99", helpText: "Green Sheen",dark: false),BackgroundColorOverlay.init(backColor: "#13111299", helpText: "Smoky Black",dark: true)]
            
            selectedIntervalTime = settings.screenIntervalMinutes
            selectedOverlayTime = settings.overlayIntervalSeconds
            selectedBackgroundColor = settings.backgroundColor
            notificationsOn = settings.notificationsOn
            aiBreakTimeEnabled = settings.aiBreakTimeEnabled
            iCloudSyncEnabled = settingsStore.isICloudSyncEnabled
            iCloudSyncStatusText = settingsStore.isICloudSyncEnabled
                ? "iCloud sync is enabled."
                : "Local-only storage is enabled."

            scheduleEnabled = settings.scheduleEnabled
            scheduleStart = ViewModel.timeFromHourMinute(hour: settings.scheduleStartHour, minute: settings.scheduleStartMinute)
            scheduleEnd   = ViewModel.timeFromHourMinute(hour: settings.scheduleEndHour, minute: settings.scheduleEndMinute)
            scheduleWeekdaysOnly = settings.scheduleWeekdaysOnly
            calendarBlockingEnabled = settings.calendarBlockingEnabled
            calendarAccessStatusText = ViewModel.calendarAuthorizationStatusText()
            autoPostureCheckEnabled = settings.autoPostureCheckEnabled
            cameraAccessStatusText = ViewModel.cameraAuthorizationStatusText()
        }

        private func handleCalendarBlockingToggle() {
            guard !isSyncingCalendarToggle else { return }

            settingsStore.updateCalendarBlockingEnabled(calendarBlockingEnabled)
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
                        self.settingsStore.updateCalendarBlockingEnabled(false)
                        self.calendarAccessStatusText = ViewModel.calendarAuthorizationStatusText()
                    }
                }
            }
        }

        private func handleAutoPostureToggle() {
            guard !isSyncingPostureToggle else { return }

            settingsStore.updateAutoPostureCheckEnabled(autoPostureCheckEnabled)
            if !autoPostureCheckEnabled {
                stopPostureBackgroundTimer()
                cameraAccessStatusText = ViewModel.cameraAuthorizationStatusText()
                return
            }

            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                stopPostureBackgroundTimer()
                startPostureBackgroundTimer()
                cameraAccessStatusText = ViewModel.cameraAuthorizationStatusText()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if granted {
                            stopPostureBackgroundTimer()
                            startPostureBackgroundTimer()
                        } else {
                            self.isSyncingPostureToggle = true
                            self.autoPostureCheckEnabled = false
                            self.isSyncingPostureToggle = false
                            self.settingsStore.updateAutoPostureCheckEnabled(false)
                        }
                        self.cameraAccessStatusText = ViewModel.cameraAuthorizationStatusText()
                    }
                }
            default:
                isSyncingPostureToggle = true
                autoPostureCheckEnabled = false
                isSyncingPostureToggle = false
                settingsStore.updateAutoPostureCheckEnabled(false)
                cameraAccessStatusText = ViewModel.cameraAuthorizationStatusText()
            }
        }

        private static func cameraAuthorizationStatusText() -> String {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized: return "Camera access granted."
            case .notDetermined: return "Camera access will be requested when enabled."
            case .denied: return "Camera access denied. Enable in System Settings → Privacy & Security → Camera."
            case .restricted: return "Camera access restricted by system."
            @unknown default: return "Camera access unavailable."
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
    


   







    





