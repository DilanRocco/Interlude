//
//  TwoHourOverlay.swift
//  testMacos
//
//  Created by Dilan Piscatello on 1/9/22.
//

import SwiftUI

struct TwoHourOverlay: View {
    var width: Int
    var height: Int
    var body: some View {
        VStack{
        Text("Time to Stretch!")
        Button("Skip Screen") {
            print("hi")
            AppDelegate.CloseOverlayButton()
        }
        }
    }
}

//struct TwoHourOverlay_Previews: PreviewProvider {
//    static var previews: some View {
//        TwoHourOverlay()
//    }
//}
