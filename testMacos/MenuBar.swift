//
//  MenuBar.swift
//  Interlude
//
//  Created by Dilan Piscatello on 7/25/22.
//

import Foundation
import AppKit
import SwiftUI
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
            AppDelegate.StopScreenTimer()
            AppDelegate.StartScreenTimer()
        }
        
        @objc private func preferencesAction(_ sender: Any?) {
            if (prefencesWin.isVisible){
                prefencesWin.orderFrontRegardless()
            }else{
                OpenPreferencesWindow(selected: 0)
                closePopOver()
            }
        }
        @objc private func stretchesAction(_ sender: Any?)
        {
            if (ud.bool(forKey: "com.twenty.twenty.extra.features")){
                OpenStretchHomePage()
            }else{
                OpenPreferencesWindow(selected: 2)
            }
        }
        
        @objc private func watchMovieAction(_ sender: Any?) {
            if (watchingAMovie){
                AppDelegate.StartScreenTimer()
            } else{
                AppDelegate.StopScreenTimer()
            }
            watchingAMovie = !watchingAMovie
            menuExtrasConfigurator?.createMainMenu()
           
        }
        
        @objc private func closeAppAction(_ sender: Any?) {
            NSApp.terminate(self)

        }
        
    }


func closePopOver(){
    menu.cancelTrackingWithoutAnimation()
}
