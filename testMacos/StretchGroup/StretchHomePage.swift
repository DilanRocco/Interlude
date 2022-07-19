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
var scrollingAllowedinView = false
struct StretchHomePage: View {
    @ObservedObject private var viewModel = ViewModel()
    @State private var val = false
    let columns = [
            GridItem(.adaptive(minimum: 300))
        ]
    
    @State private var currentSubviewIndex = 0
    @State private var show = false
    
    var body: some View {
        if !show{
            ScrollView{
                LazyVGrid(columns: columns, spacing: 2){
                    ForEach((1...7),  id: \.self){ i in
                        StretchTile(show: $show, index: i,currentSubviewIndex: $currentSubviewIndex).animation(.none)
                    }
                }.animation(.none)
            }.frame(width: 800, height: 800, alignment: .center).transition(AnyTransition.move(edge: .leading)).animation(.default)
        

            
        }
        if show {
            InDepthView(currentSubviewIndex: $currentSubviewIndex, viewModel: viewModel, show: $show).frame(width: 800, height: 800, alignment: .center).transition(AnyTransition.move(edge: .trailing)).animation(.default)
        
        }
    }
}

struct StretchTile: View {
    @State var hovered = false
    @Binding var show: Bool
    @State var index: Int
    @Binding var currentSubviewIndex: Int
   
    let player = AVPlayer(url: Bundle.main.url(forResource: "E_Square", withExtension: "mp4")!)
    var body: some View {
       
        VStack{
            AVPlayerControllerRepresented(player: player)
                .frame(height: 400).animation(.none)
            Text("Leg Movement").foregroundColor(hovered ? .blue : .none).animation(.none)
        }.contentShape(Rectangle())
            .animation(.none)
        .onTapGesture {
            withAnimation(.spring()) {
                show.toggle()
            }
              
              currentSubviewIndex = index
              print("The whole VStack is tappable now!")
            }
        
        .onAppear{
            print("on appear of main page")
            scrollingAllowedinView = false
        }
     
        .animation(.easeIn(duration: 0.4), value: hovered)
        
        .onHover { hovering in
            
            hovered = hovering
            
            if (hovering){
                player.play()
                
                print("hovering")
            }else{
                player.seek(to: CMTime.zero)
                player.pause()
             
            }
        }
        .padding(.bottom)
        
    }
}

//struct StretchHomePage_Previews: PreviewProvider {
//    static var previews: some View {
//        StretchHomePage()
//    }
//}


struct AVPlayerControllerRepresented : NSViewRepresentable {
    var player : AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        return view
    }
    func stop(){
        
    }
    func play(){
        
    }
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        
    }
}

extension AVPlayerView {

    
    override open func hitTest(_ point: NSPoint) -> NSView?{
        // Disable scrolling that can cause accidental video playback control (seek)
        
        print("scorlling")
        if (!scrollingAllowedinView){
            return nil
        }else{
            return super.hitTest(point)
        }

      
    }

    override open func keyDown(with event: NSEvent) {
        // Disable space key (do not pause video playback)

        let spaceBarKeyCode = UInt16(49)
        if event.keyCode == spaceBarKeyCode {
            return
        }
    }

}
