//
//  OverlayModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/18/22.
//

import Foundation
import UserNotifications
class Overlay{
    static let suggestionArray = ["It's best to focus on an object 20 feet away","To reset your eyelids, rapidly blink your eyes","Get a cup of coffee", "Everything is going to be ok", "Don't look at your phone!","I hope you are being productive", "Don't look at the screen", "Enjoy the moment", "Try to loosen your shoulders", "I hope your day is going well.", "Do you need a glass of water?", "Do you need a snack?", "Posture is always important", "Reward yourself for all your hard work"]

        
    static func getRandonSuggestion() -> String{
        return suggestionArray.randomElement() ?? "It's best to focus on an object 20 feet away"

        
    }
    static func timeSinceStringfy() -> String{
        let time = (ud.integer(forKey: "screenInterval") * (overlaysShown)) % 360
        
        switch time{
        case 60:
            return "an hour"
        case 60...119:
            return "over an hour"
        case 120:
            return "two hours"
        case 121...179:
            return "over two hours"
        case 180:
            return "three hours"
        case 180...239:
            return "over three hours"
        case 240:
            return "four hours"
        case 240...299:
            return "over four hours"
        case 300:
            return "five hours"
        case 300...359:
            return "over five hours"
        case 360:
            return "six hours"
        default:
           return "deafult"
        }
    }
    
    static func startNotifying(overlaysShown:Int){
    print("stratNotifying")
        let overlayInterval = ud.integer(forKey: "overlayInterval")
    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { Settings in
        print(Settings)
        if (Settings.authorizationStatus == .authorized){
            print("Notifications are authoirzed ")
//         var category = UNNotificationCategory(identifier: "stretchescat", actions: [], intentIdentifiers: [], options: [])
            let openStretch = UNNotificationAction(identifier: "openStretches", title: "Try Stretches", options: UNNotificationActionOptions.init(rawValue: 0))
            let category = UNNotificationCategory(identifier: "category", actions: [openStretch], intentIdentifiers: [], options:.customDismissAction)
            UNUserNotificationCenter.current().setNotificationCategories([category])
            
            let content = UNMutableNotificationContent()
            if (overlaysShown % 6 == 0){
                print("overlaysShown: \(overlaysShown), if: 6")
               
                content.categoryIdentifier = "category"
                content.title = "Stretch Your Body"
                content.subtitle = "It's been \(Overlay.timeSinceStringfy()) since the last stretch break. Try stepping away from the computer to stretch your body"
            }else if (overlaysShown % 3 == 0){
                print("overlaysShown: \(overlaysShown), if: 3")
                content.title = "Step Away"
                content.subtitle = "It's been \(Overlay.timeSinceStringfy()) since you stepped away from the computer. Get up and take a break for a few minutes"
            }else{
                print("overlaysShown: \(overlaysShown), if: 1")
                content.title = "Turn Away!"
                content.subtitle = Overlay.getRandonSuggestion()
            }
            
           //content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,  repeats: false)
            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
           
            UNUserNotificationCenter.current().add(request)
            
            }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(overlayInterval)) {
                        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            AppDelegate.StartScreenTimer()
            }
        })
    }
    
}
