//
//  MenuBarView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 1/6/22.
//

import SwiftUI

struct MenuBarView: View {
    @State  var hovered = false
    @State private var watchingAMovie = false
    var body: some View {
        NavigationView {

        VStack{
            HStack{
            Text("Downtime")
                .fontWeight(.bold)
                .font(.system(size: 13))
                .padding(EdgeInsets(top: 2, leading: 10, bottom: 0, trailing: 0))
                Spacer()
                    
            }
            Divider().padding(0)
            HStack{
                
            
            Button("Reset Break"){
                print("Reset Break")
                closePopOver()
                
                AppDelegate.StopScreenTimer()
                AppDelegate.StartScreenTimer()
            }.buttonStyle(.borderless)
                Spacer()
            }
            Button("Stretch!"){
                print("strech")
                
            }
            if (!watchingAMovie){
                HStack{
                Button("Watching A Movie"){
                    print("Watching A Movie")
                    closePopOver()
                    
                    AppDelegate.StopScreenTimer()
                    watchingAMovie = true;
                    AppDelegate.StartScreenTimer()
                }.buttonStyle(.borderless)
                    Spacer()
                }
            }else{
                HStack{
                Button("Finished The Movie"){
                    print("Watching A Movie")
                    closePopOver()
                    
                    AppDelegate.StopScreenTimer()
                    AppDelegate.StartScreenTimer()
                    watchingAMovie = false;
                }.buttonStyle(.borderless)
                    Spacer()
            }
            }
            HStack{
            Button("Preferences"){
                if (false == prefencesWin.isVisible){
                OpenPreferencesWindow()
                closePopOver()
                  
                }else{
                prefencesWin.orderFrontRegardless()
                }
            }.buttonStyle(.borderless)
                Spacer()
            }
            HStack{
                if #available(macOS 12.0, *) {
                    Button("Quit Downtime") {
                        print("Closed App")
                        NSApp.terminate(self)
                        
                    }.cornerRadius(5).buttonStyle(PlainButtonStyle()).padding(3)
                        .background(hovered ? .blue : .clear)
                        .onHover { hovering in
                            hovered = hovering
                        }
                        
                        
                       
                    
                       
                } else {
                    // Fallback on earlier versions
                }
                Spacer()
            }
            Spacer()
        }
        
        }
}
}
