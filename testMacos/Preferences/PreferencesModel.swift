//
//  PreferencesModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 1/10/22.
//

import Foundation
import AppKit
import SwiftUI


var prefencesWin = NSWindow(
contentRect: NSRect(x: 0, y: 0, width: 700, height: 700),
styleMask: [.titled, .miniaturizable, .closable, .resizable, .fullSizeContentView, ],
backing: .buffered, defer: false)
func OpenPreferencesWindow(selected: Int){
    let PrefView = PreferencesView(selected:selected)
    prefencesWin.center()
    prefencesWin.collectionBehavior = .fullScreenAuxiliary
    prefencesWin.makeKeyAndOrderFront(nil)
    prefencesWin.isReleasedWhenClosed = false
    prefencesWin.orderFrontRegardless()
    prefencesWin.contentView?.layerUsesCoreImageFilters = true
    prefencesWin.contentView = NSHostingView(rootView: PrefView)
    prefencesWin.title = "Preferences"
}



