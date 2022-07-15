//
//  StretchHomePage.swift
//  testMacos
//
//  Created by Dilan Piscatello on 7/5/22.
//

import SwiftUI
import Cocoa
import MediaPlayer
import AVKit
struct StretchHomePage: View {
    @ObservedObject private var viewModel = ViewModel()
    let columns = [
            GridItem(.adaptive(minimum: 300))
        ]
    var body: some View {
        ScrollView{
        LazyVGrid(columns: columns, spacing: 0){
//            ForEach(viewModel.stretches, id: \.self){
//                stretch in
//                VStack{
//                Image(nsImage: viewModel.generateThumbnail(path:Bundle.main.url(forResource: stretch[0], withExtension: "mp4")!)!)
//                Text(stretch[1])
//                }
//                //Text("Test")
//            }
            
            ForEach((1...7),  id: \.self){ i in
                StretchTile()
            }
        }
            
        }.frame(width: 800, height: 800, alignment: .center)
    }
}
struct StretchTile: View {
    @State var hovered = false

    var body: some View {
        VStack{
            Image("test")
            Text("Leg Movement")
        }
        .animation(.easeIn(duration: 0.4), value: hovered)
        .zIndex(hovered ? 1000 : 1)
        .onHover { hovering in
            hovered = hovering
        }
        .onTapGesture {
            
        }
            .padding(.bottom)
        
    }
}

//struct StretchHomePage_Previews: PreviewProvider {
//    static var previews: some View {
//        StretchHomePage()
//    }
//}


