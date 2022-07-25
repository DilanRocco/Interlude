//
//  Notification.swift
//  Interlude
//
//  Created by Dilan Piscatello on 7/25/22.
//

import Foundation
import AppKit
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
