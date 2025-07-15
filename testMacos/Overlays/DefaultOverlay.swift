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
    var body: some View {
            VStack{
                Spacer()
                Text("Break Time")
                    .font(.system(size: 100))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                Text(model.getRandonSuggestion())
                    .font(.system(size: 17))
                    .foregroundColor(.white)
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

