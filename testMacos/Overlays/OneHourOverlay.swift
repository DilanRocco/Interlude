//
//  OneHourOverlay.swift
//  testMacos
//
//  Created by Dilan Piscatello on 1/9/22.
//

import SwiftUI

struct OneHourOverlay: View {
    var width: Int
    var height: Int
    var body: some View {
        VStack{
            Text("It's best to step away from the Computer. You've been on the computer for an hour")
            
            Button("Skip Screen") {
                print("hi")
                AppDelegate.CloseOverlayButton()
            }
        }.frame(minWidth: NSScreen.main?.frame.size.width, minHeight: NSScreen.main?.frame.size.height)

        
    }
}
//struct OneHourOverlay_Previews: PreviewProvider {
//    static var previews: some View {
//        OneHourOverlay()
//    }
//}
