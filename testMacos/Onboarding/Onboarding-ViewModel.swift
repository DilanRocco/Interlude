//
//  Onboarding-ViewModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 7/14/22.
//

import Foundation
import AppKit
import AVKit
import SwiftUI
import AVFoundation
import SDWebImage
import SDWebImageSwiftUI


var onboardingWindow = NSWindow(
contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
styleMask: [.titled, .miniaturizable, .closable, .fullSizeContentView, ],
backing: .buffered, defer: false)
func openOnboardingWindow(){
    print("test")
    let stretchView = OnboardingView(pages: OnboardingPage.fullOnboarding)
    onboardingWindow.center()
    onboardingWindow.collectionBehavior = .fullScreenAuxiliary
    onboardingWindow.makeKeyAndOrderFront(nil)
    onboardingWindow.isReleasedWhenClosed = false
    onboardingWindow.orderFrontRegardless()
    onboardingWindow.contentView?.layerUsesCoreImageFilters = true
    onboardingWindow.contentView = NSHostingView(rootView: stretchView)
    onboardingWindow.title = ""
    onboardingWindow.titlebarAppearsTransparent = true
    NSApp.activate(ignoringOtherApps: true)
}

enum OnboardingPage: CaseIterable {
    case welcome
    case overlay
    case overview
    case end
    static let fullOnboarding = OnboardingPage.allCases
    
    var shouldShowNextButton: Bool {
        switch self {
        case  .welcome, .overview, .overlay:
            
            return true
        default:
            return false
        }
        
    }
 
   
    @ViewBuilder
    func view(action: @escaping () -> Void) -> some View {
        switch self {
        case .welcome:
            //AnimatedImage(url: )
            Spacer()
            AnimatedImage(url: Bundle.main.url(forResource: "hourglassf", withExtension: "gif")!).customLoopCount(1000)
                .resizable()
                .frame(width: 250, height: 250, alignment: .center)
                
            Text("Welcome to Interlude!").font(.system(size:40)).bold()
            Spacer()
        case .overview:
            VStack{
                Image("clock").resizable().frame(width: 250, height: 250)
                Text("Interludes occur every 20 minutes").font(.system(size:20)).bold().padding()
                Text("From research, it has been found that 20 minutes intervals of 20 seconds give you just the right amount of time to reset your eyes. Then, every hour that goes by, it will recommended that you step away from the computer. Then, every second hour it will recommended that you stretch where instructions and videos are provided.").font(.system(size:20)).padding([.leading, .trailing], 50).multilineTextAlignment(.center)
            Spacer()
            }
        case .overlay:
                OverlayView()
            
                
                
                // This button should only be enabled once permissions are set:
               
            
        case .end:
            VStack{
                Text("Everything is already setup!").font(.system(size:20).bold()).padding().multilineTextAlignment(.center)
                Text("For more information, there is now a menu bar app resembling an hourglass that will be your hub for this app. There you can learn more about how the theory behind this app, and modify preferences to your liking.").font(.system(size:20)).padding().multilineTextAlignment(.center).padding([.leading, .trailing], 50)
                
                
                Button(action: closeOnboardingWindow, label: {
                    Text("Done").animation(.none)
                
            })
            }
        }
   
    }
    func closeOnboardingWindow(){
        onboardingWindow.close()
       
    }
}



struct OverlayView: View {
    var body: some View {

            
            VStack{
                HStack{
                    Text("An Interlude will look like this...").font(.system(size:30).bold()).padding([.leading], 80)
                    Spacer()
                }
                
                let URL = Bundle.main.url(forResource: "overlayDefault", withExtension: "mov")!
                NSVideoPlayer(videoURL: URL).frame(width: 640, height: 360)
                
            
            
            
    }
   

}
    }
