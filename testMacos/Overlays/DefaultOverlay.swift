//
//  ContentView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 12/21/21.
//

import SwiftUI

struct DefaultOverlay: View {
    @State private var isPresented = false
    @ObservedObject var model = viewModel()
    var width: CGFloat;
    var height: CGFloat;
    var overlay: Int;
    var timeSinceStringfy: String;
    // overlay:
    // 1,
    // 2,
    // 3,
    // 1 represents the 20 minute main interval 2 represents the hour interval and 3 represents the 2 hour interval
    
    var body: some View {
            VStack{
                Spacer()
                
                if (overlay == 1){
                Text("Break Time")
                    .font(.system(size: 100))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                Text(model.getRandonSuggestion())
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                   
                }else if (overlay == 2){
              
                Text("Step Away")
                        .font(.system(size: 100))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .padding([.bottom],1)
                Text("It's been \(timeSinceStringfy) since you stepped away from the computer. Get up and take a break for a few minutes")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                   
                  
                }else if (overlay == 3){
                Text("Stretch Your Body")
                        .font(.system(size: 100))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .padding([.bottom],1)
                Text("It's been \(timeSinceStringfy) since the last stretch break. Try stepping away from the computer to stretch your body")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        
                    Button("Try some Stretches"){
                       OpenStretchHomePage()
                       stretchHomePage.level = NSWindow.Level.popUpMenu
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white)
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

