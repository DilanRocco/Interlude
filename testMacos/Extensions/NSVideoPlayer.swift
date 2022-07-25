//
//  GIF.swift
//  testMacos
//
//  Created by Dilan Piscatello on 7/15/22.
//

import Foundation
import AppKit
import AVKit
import SwiftUI
import AVFoundation
struct NSVideoPlayer: NSViewRepresentable {
    
    var videoURL: URL
    
    func makeNSView(context: Context) -> AVPlayerView {
        let item = AVPlayerItem(url: videoURL)
        let queue = AVQueuePlayer(playerItem: item)
        context.coordinator.looper = AVPlayerLooper(player: queue, templateItem: item)
        
        let view = AVPlayerView()
        view.player = queue
        view.controlsStyle = .none
        view.player?.playImmediately(atRate: 1)
        return view
    }
    func stop(){
        
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var looper: AVPlayerLooper? = nil
    }
}
