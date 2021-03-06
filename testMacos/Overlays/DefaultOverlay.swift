//
//  ContentView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 12/21/21.
//

import SwiftUI

struct DefaultOverlay: View {
    @State private var isPresented = false
   
    var width: CGFloat;
    var height: CGFloat;
    var overlay: Int;
    var timeSinceStringfy: String;
    var dark: Bool
    // overlay:
    // 1,
    // 2,
    // 3,
    // 1 represents the 20 minute main interval 2 represents the hour interval and 3 represents the 2 hour interval
    
    var body: some View {
            VStack{
                Spacer()
                
                if (overlay == 1){
                Text("Turn Away")
                    .font(.system(size: 100))
                    .fontWeight(.heavy)
                    .foregroundColor(dark ? .white : .black)
                    
                Text(Overlay.getRandonSuggestion())
                    .font(.system(size: 17))
                    .foregroundColor(dark ? .white : .black)
                    
                   
                }else if (overlay == 2){
              
                Text("Step Away")
                        .font(.system(size: 100))
                        .fontWeight(.heavy)
                        .foregroundColor(dark ? .white : .black)
                        .padding([.bottom],1)
                Text("It's been \(timeSinceStringfy) since you stepped away from the computer. Get up and take a break for a few minutes")
                    .font(.system(size: 17))
                    .foregroundColor(dark ? .white : .black)
                    .frame(maxWidth: 500, alignment: .center)
                    .multilineTextAlignment(.center)
                   
                  
                }else if (overlay == 3){
                Text("Stretch Your Body")
                        .font(.system(size: 100))
                        .fontWeight(.heavy)
                        .foregroundColor(dark ? .white : .black)
                        .padding([.bottom],1)
                Text("It's been \(timeSinceStringfy) since the last stretch break. Try stepping away from the computer to stretch your body")
                        .font(.system(size: 17))
                        .foregroundColor(dark ? .white : .black)
                        .frame(maxWidth: 600, alignment: .center)
                        .multilineTextAlignment(.center)
                        
                    Button("Try some Stretches"){
                       OpenStretchHomePage()
                       stretchHomePage.level = NSWindow.Level.popUpMenu
                    }
                    .font(.system(size: 15))
                    .foregroundColor(dark ? .white : .black)
                }
                Spacer()
                Button("Skip Overlay") {
                    AppDelegate.CloseOverlayButton()
                }.padding(60)
                 .buttonStyle(.borderless)
                    
                
            }.frame(minWidth: width, minHeight:  height)
       
            
           }
                            
    }

    



//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

