//
//  InDepthView.swift
//  Interlude
//
//  Created by Dilan Piscatello on 7/18/22.
//

import Foundation
import SwiftUI
import Cocoa
import MediaPlayer
import AVKit

struct InDepthView: View {
    
  
    @Binding var currentSubviewIndex: Int
    @ObservedObject var viewModel: StretchHomePage.ViewModel
    @Binding var show: Bool
    var body: some View {
        // //[FileName,Title, Description]
        let player = AVPlayer(url: Bundle.main.url(forResource: viewModel.stretches[currentSubviewIndex][0], withExtension: "mp4")!)
        VStack{
            HStack{
                
                Button {
                    show = false
                } label: {
                    Image(systemName: "arrow.backward").animation(.none).frame(width: 30, height: 30, alignment: .center)
                        
                }.padding()
               
                Spacer()
                Text(viewModel.stretches[currentSubviewIndex][1]).bold().font(.system(size: 15)).padding(.leading, -75)
                Spacer()
               
            }
            
            VideoPlayer(player: player).frame(width: 600, height: 400, alignment: .center)
                
                
            Text(viewModel.stretches[currentSubviewIndex][2]).font(.system(size: 15)).padding().frame(width: 600, alignment: .center)
                Spacer()
                Spacer()
        
        }.onAppear{
            scrollingAllowedinView = true
            player.play()
        }
            
        
    }
    
}

