//
//  testMacosApp.swift
//  testMacos
//
//  Created by Dilan Piscatello on 12/21/21.
//
import SwiftUI
import AppKit
import UserNotifications
import ServiceManagement
import Cocoa

let appDelegate = AppDelegate()

@main
struct testMacosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var window: NSWindow?
    var body: some Scene {
      WindowGroup {
            ZStack {
                EmptyView()
            }
        }
    }
}



// time when you can use the computer // default is 20 minutes 1200.0
var overlaysShown: Int = 0
 //time when you are supposed to look away // default is 20 minutes
var NotificationTimer: Timer?
var timerTest: Timer?
var timerOverlay: Timer?




class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var updateConfig: UpdateStatus?
    
    // array of screens connected to computer (e.g monitor, and main screen)
    static var windows:[NSWindow] = Array(repeating: NSWindow(), count: NSScreen.screens.count)
    static var blurWindows:[NSWindow] = Array(repeating: NSWindow(), count: NSScreen.screens.count)
  
    
    //performs the actions of the notification buttons
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.content.categoryIdentifier == "category"{
            switch response.actionIdentifier{
            case "openStretches":
                OpenStretchHomePage()
            default:
                break
            }
        }
    }
    
    static func openPauseOverlay(){
        let backgroundColor = UserDefaults.backgroundColor
        NSApp.activate(ignoringOtherApps: true)

        //count keeps track of which screen we are in the array of windows, and blurWindows
        var count = 0;
        
        NSScreen.screens.forEach { NSScreen in
            windows[count] = NSWindow(
                contentRect: NSRect(x: 0, y:0, width: NSScreen.frame.width, height: NSScreen.frame.height),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered, defer: false)
            windows[count].setFrameOrigin(NSScreen.frame.origin)
            windows[count].isOpaque = false
            windows[count].alphaValue = 0.01
            var menuView:AnyView = AnyView(DefaultOverlay(width: NSScreen.frame.width, height: NSScreen.frame.height, overlay: 1,timeSinceStringfy: Overlay.timeSinceStringfy(), dark: backgroundColor.dark))
            if (overlaysShown % 6 == 0){
                menuView = AnyView(DefaultOverlay(width: NSScreen.frame.width, height: NSScreen.frame.height, overlay: 3, timeSinceStringfy: Overlay.timeSinceStringfy(), dark: backgroundColor.dark))
            } else if (overlaysShown % 3 == 0) {
                menuView = AnyView(DefaultOverlay(width: NSScreen.frame.width, height: NSScreen.frame.height, overlay: 2,timeSinceStringfy: Overlay.timeSinceStringfy(), dark: backgroundColor.dark))
            }
           
            blurWindows[count] = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: NSScreen.frame.width, height: NSScreen.frame.height),
                        styleMask: [.borderless, .fullSizeContentView],
                        backing: .buffered, defer: false)
            blurWindows[count].setFrameOrigin(NSScreen.frame.origin)
            blurWindows[count].isOpaque = false
            blurWindows[count].alphaValue = 0.01
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 0.5
                windows[count].animator().alphaValue = 1.0
              })
            
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 0.5
                blurWindows[count].animator().alphaValue = 0.96
              })
            
            
            
            let blurView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: NSScreen.frame.width, height: NSScreen.frame.height))
            blurView.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
            blurView.material = .fullScreenUI
            blurView.state = .active
            
            blurWindows[count].contentView?.addSubview(blurView)
            blurWindows[count].isReleasedWhenClosed = false
            blurWindows[count].makeKeyAndOrderFront(nil)
            blurWindows[count].orderFrontRegardless()
            blurWindows[count].level = NSWindow.Level.popUpMenu
        
            windows[count].contentView? = NSHostingView(rootView: menuView)
            windows[count].backgroundColor = NSColor(hex: UserDefaults.backgroundColor.backColor)

            windows[count].standardWindowButton(.zoomButton)?.isHidden = true
            windows[count].standardWindowButton(.miniaturizeButton)?.isHidden = true
            windows[count].standardWindowButton(.closeButton)?.isHidden = true
            windows[count].isReleasedWhenClosed = false
            windows[count].makeKeyAndOrderFront(nil)
            windows[count].orderFrontRegardless()
            statusItem?.button?.image = NSImage(named: "hourglass100%")
            windows[count].level = NSWindow.Level.popUpMenu
            count+=1;
        }
        let presentationOptions: NSApplication.PresentationOptions = [
            .hideDock                  ,   // Dock is entirely unavailable. Spotlight menu is disabled.
            .disableProcessSwitching   ,   // Cmd+Tab UI is disabled. All Exposé functionality is also disabled.
            .hideMenuBar,
            .disableAppleMenu,
            .disableSessionTermination ,   // PowerKey panel and Restart/Shut Down/Log Out are disabled.
            .disableHideApplication    ,   // Application "Hide" menu item is disabled.
            ]
        let application = NSApplication.shared
        application.presentationOptions = presentationOptions
        
        //When timer ends, the overlay stops sharing, and CloseTimerOverlay is called
        CloseTimerOverlay()
       
 }
    
    static func StartScreenTimer(){
            // have this as a global somewhere
            func getFourth() -> Double{
                0.25 * UserDefaults.standard.double(forKey: "screenInterval") * 60}
        //TESTING
//        func getFourth() -> Double{
//            return 2.5
//
//        }
            print("StartScreenTimer")

            
            menuExtrasConfigurator?.createMenu(imageName: "hourglass100%")
            guard timerTest == nil else { return }
            timerTest = Timer.scheduledTimer(withTimeInterval: getFourth(), repeats: false){
                    timer in
                menuExtrasConfigurator?.createMenu(imageName: "hourglass75%")
                    
                    timerTest = Timer.scheduledTimer(withTimeInterval: getFourth(), repeats: false) { timer in
                        menuExtrasConfigurator?.createMenu(imageName: "hourglass50%")
                        timerTest = Timer.scheduledTimer(withTimeInterval: getFourth(), repeats: false) { timer in
                            menuExtrasConfigurator?.createMenu(imageName: "hourglass25%")
                            timerTest = Timer.scheduledTimer(withTimeInterval: getFourth(), repeats: false) { timer in
                                overlaysShown += 1
                                StopScreenTimer()
                                if (UserDefaults.standard.bool(forKey: "useNotifications")){
                                    Overlay.startNotifying(overlaysShown: overlaysShown)
                                }else{
                                    openPauseOverlay()
                                }
                                }
                            }
                        }
                    }
    }
    static func CloseAllOverlayWindows(){
        print("CloseBothWindows")
        if (windows[0].isVisible){
        for index in 0...windows.count-1{
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.125
            windows[index].animator().alphaValue = 0.01
          }, completionHandler: windows[index].close)
        
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.125
            blurWindows[index].animator().alphaValue = 0.01
          }, completionHandler: blurWindows[index].close)
        
        }
        }
    }

    
    //CloseTimerOverlay closes the overlay after the variable overlayInterval has been counted down
    static func CloseTimerOverlay(){
        print("closeTimerOverlay")
        print(Double(UserDefaults.standard.integer(forKey: "overlayInterval")))
        guard timerOverlay == nil else { return }
        
        
        timerOverlay = Timer.scheduledTimer(withTimeInterval: Double(UserDefaults.standard.integer(forKey: "overlayInterval")), repeats: false) { timer in
                print("in overlay")
                StopTimerOverlay()
                CloseOverlayButton()
        }
    }
    //StopTimerOverlay invalidates the timer timerOverlay
    static func StopTimerOverlay() {
        print("stopTimerOverlay")
        timerOverlay?.invalidate()
        timerOverlay = nil
    }
    
    //StopScreenTimer invalidates the timer timertest
    static func StopScreenTimer() {
        print("stopScreenTimer")
        timerTest?.invalidate()
        timerTest = Timer()
    }

    //CloseOverlayButton is called when either the OverlayInterval is called or the button is clicked on the overlay to
    //skip the overlay and a new timer
    static func CloseOverlayButton(){
        print("CloseOverlayButton")
        stretchHomePage.level = .normal
        CloseAllOverlayWindows()
        NSApplication.shared.presentationOptions = []
        StopTimerOverlay()
        StartScreenTimer()
    }
    
    
   
    @objc func onWakeNote(note: NSNotification) {
        print("on wake")
       AppDelegate.StartScreenTimer()
    }

    @objc func onSleepNote(note: NSNotification) {
        print("on sleep")
       overlaysShown = 0
       AppDelegate.CloseAllOverlayWindows()
       AppDelegate.StopScreenTimer()
    
        
    }
   
    // deals with computer going to sleep and waking up
    func fileNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
               self, selector: #selector(onWakeNote(note:)),
               name: NSWorkspace.didWakeNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote(note:)),
            name: NSWorkspace.willSleepNotification, object: nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
         
   }
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        fileNotifications()
        NSApp.setActivationPolicy(.accessory)
        menuExtrasConfigurator = .init(imageName: "hourglass100%")
        //ud.set(false, forKey: "isAppAlreadyLaunchedOnce")
        if (UserDefaults.standard.bool(forKey: "isAppAlreadyLaunchedOnce")){
            print("App has already launched once before")
        }else{
            ud.set(false, forKey: "useNotifications")
            UserDefaults.backgroundColor = Constants.DefaultBackgroundColor
            ud.set(20, forKey: "screenInterval")
            ud.set(20, forKey: "overlayInterval")
            ud.set(true, forKey: "isAppAlreadyLaunchedOnce")
            openOnboardingWindow()
        }
        
        UNUserNotificationCenter.current().delegate = self
        AppDelegate.StartScreenTimer()
        
        let launcherAppId = "com.Rocco-Piscatello.LauncherApp"
        let runningApps = NSWorkspace.shared.runningApplications
        
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        print(isRunning)
        SMLoginItemSetEnabled(launcherAppId as CFString, true)
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
        
    }
   
}







