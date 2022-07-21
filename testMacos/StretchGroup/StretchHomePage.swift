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
                    ForEach(0..<viewModel.stretches.count) { i in
                        StretchTile(show: $show, index: i,currentSubviewIndex: $currentSubviewIndex,  viewModel: viewModel).animation(.none)
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
    @ObservedObject var viewModel: StretchHomePage.ViewModel

   
    var body: some View {
        
        VStack{
               
            Image(nsImage: viewModel.generateThumbnail(path: Bundle.main.url(forResource: viewModel.stretches[index][0],withExtension: "mp4")!)!).scaleEffect(hovered ? 1 : 1.1).clipped().animation(.default, value: hovered)
   
            Text(viewModel.stretches[index][1]).foregroundColor(hovered ? .blue : .none).animation(.none).font(.title3)
                
        }
        .contentShape(Rectangle())
            .animation(.none)
        .onTapGesture {
            withAnimation(.spring()) {
                show.toggle()
                print(viewModel.stretches.count)
            
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
                //player.play()
           
                print("hovering")
            }else{
                print("not hovering")
                print(index)
           
                
            
             
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
