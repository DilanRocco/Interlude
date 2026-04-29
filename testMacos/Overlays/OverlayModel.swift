//
//  OverlayModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/18/22.
//

import Foundation
import UserNotifications
class Overlay{
    static let suggestionArray = [
        // Eye care
        "It's best to focus on an object 20 feet away",
        "To reset your eyelids, rapidly blink your eyes",
        "Look out the window for 20 seconds",
        "Close your eyes and take a deep breath",
        "Try the 20-20-20 rule: look 20 feet away for 20 seconds",
        "Roll your eyes slowly in a circle to relax them",
        "Let your eyes go out of focus for a moment",
        "Don't look at the screen",
        "Palming: rub your hands together and cup them over your closed eyes",
        "Reduce screen brightness if your eyes are feeling strained",

        // Hydration & food
        "Get a cup of coffee",
        "Do you need a glass of water?",
        "Do you need a snack?",
        "Stay hydrated — when did you last drink water?",
        "A piece of fruit might be just what you need right now",
        "Time for a tea break",
        "Your brain runs on glucose — grab a healthy snack",
        "Go refill your water bottle",
        "Have you eaten enough today?",
        "A handful of nuts is great brain fuel",

        // Posture & body
        "Try to loosen your shoulders",
        "Posture is always important",
        "Roll your shoulders back and sit up straight",
        "Tilt your head side to side to release neck tension",
        "Unclench your jaw — you probably didn't realize it was tight",
        "Stretch your wrists and fingers",
        "Adjust your chair height so your feet are flat on the floor",
        "Make sure your screen is at eye level",
        "Try tucking your chin slightly to relieve neck strain",
        "Squeeze your shoulder blades together and hold for 5 seconds",
        "Wiggle your toes — seriously, it helps",
        "Check your breathing — is it shallow? Take a slow, deep breath",
        "Stand up and stretch your arms above your head",
        "Relax your hands — stop gripping the mouse so hard",
        "Ankle circles are great for circulation",
        "Put both feet flat on the floor right now",
        "Your hips are probably tight — try a quick hip flexor stretch",
        "Look away and do 5 neck rolls",

        // Mental health & mindset
        "Everything is going to be ok",
        "Enjoy the moment",
        "I hope your day is going well.",
        "I hope you are being productive",
        "Reward yourself for all your hard work",
        "You are doing great — keep it up",
        "Take a slow, deep breath in... and let it out",
        "Be kind to yourself today",
        "Progress, not perfection",
        "One task at a time — you've got this",
        "It's okay to not have everything figured out",
        "You are more capable than you think",
        "Take a moment to appreciate what you've accomplished today",
        "Stress is temporary — you will get through this",
        "Remember why you started",
        "Celebrate the small wins",
        "You are allowed to take breaks",
        "It's okay to step away for a minute",
        "Don't let perfect be the enemy of good",
        "Be present in this moment",
        "Rest is productive too",
        "Your mental health matters more than your inbox",
        "It's a marathon, not a sprint",
        "Take things one breath at a time",
        "Something worth doing is worth doing imperfectly",

        // Movement & activity
        "Stand up and take a quick walk around",
        "Do 10 jumping jacks right now",
        "Try a 2-minute standing stretch",
        "Walk to the kitchen and back",
        "Do a few calf raises while you stand",
        "Take the long way to the bathroom",
        "Get up and look out the window for a minute",
        "March in place for 30 seconds",
        "Do a wall stretch for your chest",
        "Try some standing side bends",

        // Focus & productivity
        "Don't look at your phone!",
        "Close any browser tabs you don't need right now",
        "What is the single most important thing you need to do today?",
        "Are you working on the most important task right now?",
        "Block out distractions for the next 25 minutes",
        "Write down what's on your mind to get it out of your head",
        "Is what you're doing right now aligned with your goals?",
        "Clear your desk — a tidy space helps a tidy mind",
        "Turn off notifications for the next hour",
        "If it takes less than 2 minutes, do it now",
        "Break that big task into smaller steps",
        "Set a timer and go heads-down for 25 minutes",

        // Mood & fun
        "Smile — even a fake one boosts your mood",
        "Think of one thing you're grateful for",
        "Send a kind message to someone you appreciate",
        "Listen to a song you love",
        "Step outside for some fresh air if you can",
        "Pet an animal if one is nearby",
        "Laugh at something — go find a meme",
        "Call someone you haven't talked to in a while",
        "Look at a photo that makes you happy",
        "Do something nice for future you",
        "You deserve good things",
        "Happiness is a practice — practice it now"
    ]

        
    static func getRandonSuggestion() -> String{
        return suggestionArray.randomElement() ?? "It's best to focus on an object 20 feet away"
    }
    
    static func timeSinceStringfy() -> String{
        let interval = AppSettingsStore.shared.currentSettings().screenIntervalMinutes
        let time = (interval * overlaysShown) % 360
        
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
           return "a short while"
            }
        }
    
    static func startNotifying(overlaysShown:Int){
        print("startNotifying")
        let overlayInterval = AppSettingsStore.shared.currentSettings().overlayIntervalSeconds
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { Settings in
        if (Settings.authorizationStatus == .authorized){
            let openStretch = UNNotificationAction(identifier: "openStretches", title: "Try Stretches", options: UNNotificationActionOptions.init(rawValue: 0))
            let category = UNNotificationCategory(identifier: "category", actions: [openStretch], intentIdentifiers: [], options:.customDismissAction)
            UNUserNotificationCenter.current().setNotificationCategories([category])
            
            let content = UNMutableNotificationContent()
            if (overlaysShown % 6 == 0){
                content.categoryIdentifier = "category"
                content.title = "Stretch Your Body"
                content.subtitle = "It's been \(Overlay.timeSinceStringfy()) since the last stretch break. Try stepping away from the computer to stretch your body"
            }else if (overlaysShown % 3 == 0){
                content.title = "Step Away"
                content.subtitle = "It's been \(Overlay.timeSinceStringfy()) since you stepped away from the computer. Get up and take a break for a few minutes"
            }else{
                content.title = "Turn Away!"
                content.subtitle = Overlay.getRandonSuggestion()
            }
            
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
