
import Cocoa

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject {

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let mainAppIdentifier = "com.twenty.twenty"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty

        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.terminate), name: .killLauncher, object: mainAppIdentifier)

            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("testMacos") //main app name
            let newPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.twenty.twenty")!
            //let newPath = NSString.path(withComponents: components)
            print("running app")
            NSWorkspace.shared.openApplication(at: newPath, configuration: NSWorkspace.OpenConfiguration() , completionHandler: nil)
        }
        else {
            self.terminate()
        }
    }
}
