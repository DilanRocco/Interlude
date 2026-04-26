//
//  PreferencesView-ViewModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import Foundation
import UserNotifications
import AppKit

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
        }
        
        
       
    }
    
}
    


   







    





