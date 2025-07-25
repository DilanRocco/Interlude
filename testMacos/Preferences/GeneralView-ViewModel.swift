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
        //in minutes
        let screenIntervals: [Int]
        
        //in seconds
        let overlayIntervals: [Int]
        
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
                UserDefaults.standard.set(selectedIntervalTime, forKey: "overlayInterval")
                
            }
        }
        
        @Published var selectedBackgroundColor: BackgroundColorOverlay{
            didSet{
                UserDefaults.backgroundColor = selectedBackgroundColor
            }
        }
        
     
        
        init(){
            screenIntervals = [10, 20, 30, 40, 60]
            overlayIntervals = [10, 20, 30, 40, 60]
            backgroundColors = [Constants.DefaultBackgroundColor,BackgroundColorOverlay.init(backColor: "#0a104599", helpText: "Royal Blue Dark",dark: true),BackgroundColorOverlay.init(backColor:  "#da416799", helpText: "Cerise",dark: true),BackgroundColorOverlay.init(backColor: "#edae4999", helpText: "Sunray",dark: false),BackgroundColorOverlay.init(backColor: "#067bc299", helpText: "Star Command Blue",dark: true),BackgroundColorOverlay.init(backColor: "#64b6ac99", helpText: "Green Sheen",dark: false),BackgroundColorOverlay.init(backColor: "#13111299", helpText: "Smoky Black",dark: true)]
            
            selectedIntervalTime = (UserDefaults.standard.integer(forKey: "screenInterval"))
            selectedOverlayTime = (UserDefaults.standard.integer(forKey: "overlayInterval"))
            selectedBackgroundColor = UserDefaults.backgroundColor
            notificationsOn = (UserDefaults.standard.bool(forKey: "useNotifications"))
        }
        
        
       
    }
    
}
    


   







    





