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
    //Conecting the App Delegate
  
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var window: NSWindow?
    var body: some Scene {
      WindowGroup {
            ZStack {
                EmptyView()
                        
                
            }
              //.environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}


// Conform to UNUserNotificationCenterDelegate

// time when you can use the computer // default is 20 minutes 1200.0
var overlaysShown: Int = 0
 //time when you are supposed to look away // default is 20 minutes
var NotificationTimer: Timer?
var timerTest: Timer?
var timerOverlay: Timer?
var watchingAMovie: Bool = false
var statusItem: NSStatusItem?
let menu = NSMenu()

class UpdateStatus: NSObject{

    func setStatusImage(imageName: String){
        if let statusBarButton = statusItem?.button {
          statusBarButton.image = NSImage(named: imageName)
        }
    }
}
var menuExtrasConfigurator: MacExtrasConfigurator?


    class MacExtrasConfigurator: NSObject {
      
       var statusBar: NSStatusBar
        var statusItem: NSStatusItem
        var mainView: NSView
      
      private struct MenuView: View {
        var body: some View {
          HStack {
            Text("Hello from SwiftUI View")
            Spacer()
          }
          .background(Color.blue)
          .padding()
        }
      }
      
      // MARK: - Lifecycle
      
        init(imageName: String) {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        mainView = NSHostingView(rootView: MenuView())
        mainView.frame = NSRect(x: 0, y: 0, width: 300, height: 250)
        
        super.init()
        
            createMenu(imageName: imageName)
            createMainMenu()
      }
      
      
       
        func createMenu(imageName:String) {
            print("made it")
            if let statusBarButton = statusItem.button {
                statusBarButton.image = NSImage(named: imageName)
            }
        }
        func createMainMenu(){
            let mainMenu = NSMenu()
            
            let rootItem = NSMenuItem()
            rootItem.title = "Reset Break"
            rootItem.target = self
            if (!watchingAMovie){
                rootItem.action = #selector(Self.skipBreakAction(_:))
            }
            mainMenu.addItem(rootItem)
            
            let rootItem1 = NSMenuItem()
            rootItem1.title = watchingAMovie ?  "Finished The Movie" : "Watching A Movie"
            rootItem1.target = self
            rootItem1.action = #selector(Self.watchMovieAction(_:))
            mainMenu.addItem(rootItem1)
            
            let rootItem2 = NSMenuItem()
            rootItem2.title = "Stretches"
            rootItem2.target = self
            rootItem2.action = #selector(Self.stretchesAction(_:))
            mainMenu.addItem(rootItem2)
            
            let rootItem3 = NSMenuItem()
            rootItem3.title = "Preferences"
            rootItem3.target = self
            rootItem3.action = #selector(Self.preferencesAction(_:))
            mainMenu.addItem(rootItem3)
            
            mainMenu.addItem(.separator())
            
            let rootItem4 = NSMenuItem()
            rootItem4.title = "Close Interlude"
            rootItem4.target = self
            rootItem4.action = #selector(Self.closeAppAction(_:))
            mainMenu.addItem(rootItem4)
            statusItem.menu = mainMenu
        }
        
        @objc private func skipBreakAction(_ sender: Any?) {
            print("skipped break")
            AppDelegate.StopScreenTimer()
            AppDelegate.StartScreenTimer()
        }
        
        @objc private func preferencesAction(_ sender: Any?) {
            print("preferences action")
            if (prefencesWin.isVisible){
                prefencesWin.orderFrontRegardless()
            }else{
                OpenPreferencesWindow()
                closePopOver()
            }
        }
        @objc private func stretchesAction(_ sender: Any?){
           OpenStretchHomePage()
        }
        
        @objc private func watchMovieAction(_ sender: Any?) {
            
            if (watchingAMovie){
                AppDelegate.StartScreenTimer()
                print("finished watching movie")
            } else{
                AppDelegate.StopScreenTimer()
                print("starting watching movie")
            }
            watchingAMovie = !watchingAMovie
            menuExtrasConfigurator?.createMainMenu()
           
        }
        
        @objc private func closeAppAction(_ sender: Any?) {
            print("closed the app action")
            
            NSApp.terminate(self)
           
        }
        
    }
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var updateConfig: UpdateStatus?
    static var windows:[NSWindow] = Array(repeating: NSWindow(), count: NSScreen.screens.count)
    static var blurWindows:[NSWindow] = Array(repeating: NSWindow(), count: NSScreen.screens.count)
    //static var window = NSWindow()
    
   
    
    static var monitor = NSWindow()
    
    static func openPauseOverlay(){
        overlaysShown += 1
        
        print(overlaysShown)
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
            var menuView:AnyView = AnyView(DefaultOverlay(width: NSScreen.frame.width, height: NSScreen.frame.height, overlay: 1,timeSinceStringfy: timeSinceStringfy() ))
            if (overlaysShown % 6 == 0){
                menuView = AnyView(DefaultOverlay(width: NSScreen.frame.width, height: NSScreen.frame.height, overlay: 3, timeSinceStringfy: timeSinceStringfy()))
            }else if (overlaysShown % 3 == 0){
                menuView = AnyView(DefaultOverlay(width: NSScreen.frame.width, height: NSScreen.frame.height, overlay: 2,timeSinceStringfy: timeSinceStringfy()))
            }
            func timeSinceStringfy() -> String{
                let time = ud.integer(forKey: "screenInterval") * overlaysShown
                
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
                   return "an hour"
                }
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
            windows[count].backgroundColor = NSColor(hex: UserDefaults.standard.string(forKey: "backgroundColor") ?? Constants.DefaultBackgroundColor)

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
            print()

            
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
                                if (UserDefaults.standard.bool(forKey: "useNotifications")){
                                    startNotifying()
                                }else{
                               StopScreenTimer()
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
    
    //StartScreenTimer starts the timer for when the user can use the screen again. Once the variable screenInterval
    //runs out, the overlay will appear again
    var screenTimerCounter:Double = 0
    
    

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
        CloseAllOverlayWindows()
        NSApplication.shared.presentationOptions = []
        StopTimerOverlay()
        StartScreenTimer()
    }
    
    
    static func startNotifying(){
    print("stratNotifying")
    let interval = UserDefaults.standard.integer(forKey: "screenInterval")
    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { Settings in
        print(Settings)
        if (Settings.authorizationStatus == .authorized){
            print("Notifications are authoirzed ")
            let content = UNMutableNotificationContent()
            content.title = "Break Time!"
            content.subtitle = "Try to look away from the screen"
           //content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30,  repeats: false)
            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            
            }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                StartScreenTimer()
            
        }
                                                               
    })


}
    @objc func onWakeNote(note: NSNotification) {
       AppDelegate.StartScreenTimer()
    }

    @objc func onSleepNote(note: NSNotification) {
       overlaysShown = 0
       AppDelegate.CloseAllOverlayWindows()
       AppDelegate.StopScreenTimer()
    
        
    }
    
    func fileNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
               self, selector: #selector(onWakeNote(note:)),
               name: NSWorkspace.didWakeNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote(note:)),
            name: NSWorkspace.willSleepNotification, object: nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        
        print("app is going to terminate")
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
         
   }
    
    
    var popover: NSPopover!
    

    func applicationDidFinishLaunching(_ notification: Notification) {
        fileNotifications()
        NSApp.setActivationPolicy(.accessory)
        menuExtrasConfigurator = .init(imageName: "hourglass100%")
        //UserDefaults.standard.set(false, forKey: "isAppAlreadyLaunchedOnce")
        if (UserDefaults.standard.bool(forKey: "isAppAlreadyLaunchedOnce")){
            print("App has already launched once before")
        }else{
            UserDefaults.standard.set(false, forKey: "useNotifications")
            UserDefaults.standard.set(Constants.DefaultBackgroundColor, forKey: "backgroundColor")
            UserDefaults.standard.set(20, forKey: "screenInterval")
            UserDefaults.standard.set(20, forKey: "overlayInterval")
            UserDefaults.standard.set(true, forKey: "isAppAlreadyLaunchedOnce")
            openOnboardingWindow()
        }
        UNUserNotificationCenter.current().delegate = self
        AppDelegate.StartScreenTimer()
        
        
        print("hello")
        let launcherAppId = "com.Rocco-Piscatello.LauncherApp"
        let runningApps = NSWorkspace.shared.runningApplications

        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        print(isRunning)
        print("isrunning")
        SMLoginItemSetEnabled(launcherAppId as CFString, true)
        print("test")
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
        //For Testing the Overlay
        //OverlayWindow.openPauseOverlay()
    }
   
}
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

func closePopOver(){
    menu.cancelTrackingWithoutAnimation()
}


extension NSColor {
    
 convenience init(hex: String) {
    let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
    let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
    let ui64 = UInt64(hexString, radix: 16)
    let value = ui64 != nil ? Int(ui64!) : 0
    // #RRGGBB
    var components = (
        R: CGFloat((value >> 16) & 0xff) / 255,
        G: CGFloat((value >> 08) & 0xff) / 255,
        B: CGFloat((value >> 00) & 0xff) / 255,
        a: CGFloat(1)
    )
    if String(hexString).count == 8 {
        // #RRGGBBAA
        components = (
            R: CGFloat((value >> 24) & 0xff) / 255,
            G: CGFloat((value >> 16) & 0xff) / 255,
            B: CGFloat((value >> 08) & 0xff) / 255,
            a: CGFloat((value >> 00) & 0xff) / 255
        )
    }
    self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
}

func toHex(alpha: Bool = false) -> String? {
    guard let components = cgColor.components, components.count >= 3 else {
        return nil
    }
    
    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)
    
    if components.count >= 4 {
        a = Float(components[3])
    }
    
    if alpha {
        return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
    } else {
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
}
 
    let nscol = NSColor(hex: "#2196f3")




