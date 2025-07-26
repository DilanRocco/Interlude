//
//  GeneralView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import SwiftUI
import UserNotifications

struct GeneralView: View {
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack{
            HStack{
                Text("Customize").fontWeight(.bold).font(.largeTitle)
                Spacer()
            }.padding()
            VStack{
                Picker("Duration between Breaks", selection: $viewModel.selectedIntervalTime) {
                    ForEach(viewModel.screenIntervals, id: \.self) { time in
                        Text("\(time)" + " Minutes")
                    }
                }.padding()
                Picker("Break Duration", selection: $viewModel.selectedOverlayTime) {
                    ForEach(viewModel.overlayIntervals, id: \.self) { time in
                        Text("\(time)" + " Seconds")
                    }
                }.padding()
                BackgroundColorsView(viewModel:viewModel).padding()
                EnableNotifcaionsView(viewModel:viewModel).padding()
                WatchingAMovie().padding()
                OpenOnboardingSlides().padding()
                ResetView(viewModel:viewModel).padding()
                
            }.font(.system(size:15))
            Spacer()
        }
        
        
    }
}

// toggle for setting if watching a movie
struct WatchingAMovie: View {
    @State private var watchingMovie = watchingAMovie
    var body: some View {
        VStack{
            Toggle("Watching A Movie - Pause overlays from displaying", isOn: $watchingMovie).onChange(of: watchingMovie, perform: {watching in
                watchingAMovie = watching
                menuExtrasConfigurator?.createMainMenu()
                if watching {
                    AppDelegate.StopScreenTimer()
                } else {
                    AppDelegate.StartScreenTimer()
                }
            })
        }.multilineTextAlignment(.leading).frame(width: 450, alignment: .leading)
    }
}

//pick background color
struct BackgroundColorsView: View {
    @ObservedObject var viewModel: GeneralView.ViewModel
   
    var body: some View {
        HStack{
            Text("Overlay Background:")
            ForEach(viewModel.backgroundColors, id: \.self) { color in
                Button(action: {
                    viewModel.selectedBackgroundColor = color
                }) {
                    Text("").padding(.top, 6)
                        .padding(.bottom, 6)
                        .padding(.leading, 12)
                        .padding(.trailing, 12)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                        .stroke(color.backColor == viewModel.selectedBackgroundColor.backColor ? .gray : .clear, lineWidth: color.backColor == viewModel.selectedBackgroundColor.backColor ? 3 : 0))
                        .background(RoundedRectangle(cornerRadius: 5).fill((Color(hex: color.backColor)!)))
                }
                .help(color.helpText)
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(), value: viewModel.selectedBackgroundColor)
            }
            Spacer()
        }
    }
}

// enable notifications control
struct EnableNotifcaionsView: View {
    @ObservedObject var viewModel: GeneralView.ViewModel
    @State private var isHovering = false
    
    var body: some View {
        Toggle("Show less a less disruptive Interlude overlay using Notifications", isOn: $viewModel.notificationsOn).onChange(of: viewModel.notificationsOn, perform: { newValue in
                UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { Settings in
                    if (Settings.authorizationStatus == .authorized && viewModel.notificationsOn){
                        DispatchQueue.main.async {
                            viewModel.notificationsOn = true
                        }
                    }else if(!(Settings.authorizationStatus == .authorized) && viewModel.notificationsOn){
                        DispatchQueue.main.async {
                            viewModel.notificationsOn = false;
                            viewModel.displaySettingPage = true;
                        }
                    }else{
                        DispatchQueue.main.async {
                        viewModel.notificationsOn = false
                        }
                    }
                })
               
            })
        
        .popover(isPresented:$viewModel.displaySettingPage, arrowEdge: .bottom) {
            ZStack{
                isHovering ? Color.blue.scaleEffect(1.5) : Color.blue.opacity(0.8).scaleEffect(1.5)
                    Button(action: {Notifications.openSettings()}){
                        Text("Enable Notifications").frame(width: 200, height: 50, alignment: .center)
                    }.buttonStyle(.borderless).padding()
                }
            .frame(width: 200, height: 50)
            .onHover { isHovered in
                isHovering = isHovered
            
            }
            
        }
    }
}


// Reset button controls
struct ResetView: View{
    @ObservedObject var viewModel: GeneralView.ViewModel
    var body: some View{
        Button("Reset Settings"){
            viewModel.selectedIntervalTime = 20
            viewModel.selectedOverlayTime = 20
            viewModel.selectedBackgroundColor = Constants.DefaultBackgroundColor
            viewModel.notificationsOn = false
            watchingAMovie = false
            
            
        }
    }
}

// Open Oboarding Toggle
struct OpenOnboardingSlides: View{
    var body: some View{
        Button("Open Onboarding Slides"){
           openOnboardingWindow()
            
        }
    }
}

