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
    var ud = UserDefaults.standard
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
struct BackgroundColorOverlay:Equatable, Hashable{
    var backColor: String 
    var helpText: String
}
struct WatchingAMovie: View {
    @State private var watchingMovie = watchingAMovie
    var body: some View {
        VStack{
        Toggle("Watching A Movie - Pause overlays from displaying", isOn: $watchingMovie).onChange(of: watchingMovie, perform: {watching in
                watchingAMovie = watching
                menuExtrasConfigurator?.createMainMenu()
        })
            
        }.multilineTextAlignment(.leading).frame(width: 450, alignment: .leading)
    }
}

struct BackgroundColorsView: View {
    @ObservedObject var viewModel: GeneralView.ViewModel
   
    var body: some View {
        HStack{
            Text("Overlay Background:")
            ForEach(viewModel.backgroundColors, id: \.self) { color in
                Button(action: {
                    viewModel.selectedBackgroundColor = color.backColor
                }) {
                    Text("").padding(.top, 6)
                        .padding(.bottom, 6)
                        .padding(.leading, 12)
                        .padding(.trailing, 12)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(color.backColor == viewModel.selectedBackgroundColor ? .gray : .clear, lineWidth: color.backColor == viewModel.selectedBackgroundColor ? 3 : 0))
                        .background(RoundedRectangle(cornerRadius: 5).fill((Color(hex: color.backColor)!)))
                }
                .help(color.helpText)
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(), value: viewModel.selectedBackgroundColor)
            }
//            Button(action: {
//                let randColorIndex = Int.random(in: 0..<viewModel.backgroundColors.count)
//                viewModel.selectedBackgroundColor = viewModel.backgroundColors[randColorIndex].backColor
//            }) {
//                Image("shuffle").resizable().frame(width: 28, height: 28)
//            }.buttonStyle(PlainButtonStyle())
            Spacer()
        }
    }
}


struct EnableNotifcaionsView: View {
    
    @State private var presents = ud.bool(forKey: "showSettingsPage")
    @ObservedObject var viewModel: GeneralView.ViewModel
    @State private var hoverOverlay = Color.blue
    @State private var isHovering = false
    
    var body: some View {
        Toggle("Show less a less disruptive Interlude overlay using Notifications", isOn: $viewModel.notificationsOn).onChange(of: viewModel.notificationsOn, perform: {newValue in
            
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { Settings in
                if (Settings.authorizationStatus == .authorized && viewModel.notificationsOn){
                   
                    DispatchQueue.main.async {
                    print("1")
                    viewModel.notificationsOn = true
                    }
                }else if(!(Settings.authorizationStatus == .authorized) && viewModel.notificationsOn){
                    DispatchQueue.main.async {
                        print("2")
                        viewModel.notificationsOn = false;
                        viewModel.displaySettingPage = true;
                    }
                }else{
                    DispatchQueue.main.async {
                    print("3")
                    viewModel.notificationsOn = false
                    }
                }
            })
               
            })
        
        .popover(isPresented:$viewModel.displaySettingPage ,arrowEdge: .bottom) {
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

struct OpenOnboardingSlides: View{
    var body: some View{
        Button("Open Onboarding Slides"){
           openOnboardingWindow()
            
        }
    }
}

//struct GeneralView_Previews: PreviewProvider {
//    static var previews: some View {
//        GeneralView()
//    }
//
//}
