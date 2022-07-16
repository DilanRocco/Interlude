//
//  ContentView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 12/21/21.
//

import SwiftUI

//keeps track of the amount of times in a session a
var timesOverlayDisplayed = 0
struct DefaultOverlay: View {
    @State private var isPresented = false
    @ObservedObject var model = viewModel()
    var width: CGFloat;
    var height: CGFloat;
    // overlay:
    // 1,
    // 2,
    // 3,
    // 1 represents the 20 minute main interval 2 represents the hour interval and 3 represents the 2 hour interval
    var overlay: Int;
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
                Text("It's been an hour and it's recommended that you step away from the computer for a few minutes")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                }else if (overlay == 3){
                Text("Stretch Your Body")
                        .font(.system(size: 100))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                Text("It's been two hours and it's recommended that you step away from the computer and stretch your body")
                    Button("Open Stretches"){
                            
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                }
                Spacer()
                Button("Skip Overlay") {
                    AppDelegate.CloseOverlayButton()
                }.padding(60)
                 .buttonStyle(.borderless)
                    
                
            }.frame(minWidth: width, minHeight:  height)
       
        //(PreferencesTab.ColorDownload() == "#f6f7f6ff") ? Color.clear : (Color(hex:PreferencesTab.ColorDownload()))
            
           }
                            
    }

    



//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

