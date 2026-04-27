//
//  StretchHomePage-ViewModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 7/5/22.
//

import Foundation
import AppKit
import SwiftUI
import AVKit

var stretchHomePage = NSWindow(
contentRect: NSRect(x: 0, y: 0, width: 800, height: 828),
styleMask: [.titled, .miniaturizable, .closable, .resizable, .fullSizeContentView, ],
backing: .buffered, defer: false)

func OpenStretchHomePage(){
    print("open Stretches")
    if (stretchHomePage.isVisible){
        stretchHomePage.orderFrontRegardless()
        print("open")
    }else{
    print("test")
    let stretchView = StretchHomePage()
    stretchHomePage.center()
    stretchHomePage.collectionBehavior = .fullScreenAuxiliary
    stretchHomePage.makeKeyAndOrderFront(true)
    stretchHomePage.isReleasedWhenClosed = false
    stretchHomePage.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
    stretchHomePage.contentView?.layerUsesCoreImageFilters = true
    stretchHomePage.contentView = NSHostingView(rootView: stretchView)
    
    stretchHomePage.title = "Stretches"
    }
}

enum StretchCategory: String, CaseIterable {
    case all       = "All"
    case back      = "Back"
    case wrists    = "Wrists"
    case neck      = "Neck"
    case shoulders = "Shoulders"
    case eyes      = "Eyes"

    var systemImage: String {
        switch self {
        case .all:       return "square.grid.2x2"
        case .back:      return "figure.walk"
        case .wrists:    return "hand.raised"
        case .neck:      return "person.bust"
        case .shoulders: return "figure.arms.open"
        case .eyes:      return "eye"
        }
    }
}

extension StretchHomePage{
    @MainActor class ViewModel: ObservableObject{
        //[FileName, Title, Description, Category]
        let stretches: [[String]] = [
            ["A", "Pectoral stretch",
             "Do this when you find yourself slouching. Clasp your hands behind your head. Tuck in your chin, press the back of your head into your hands, and push your elbows as far back as you can. Hold for 3 seconds, then relax and repeat 5 times.",
             StretchCategory.back.rawValue],
            ["B", "Disk reliever",
             "Do this to reverse the effects of repetitive or sustained bending. Place your hands in the hollow of your back. While focusing your eyes straight ahead, bend backward over your hands without bending your knees, then immediately straighten up.",
             StretchCategory.back.rawValue],
            ["C", "Pelvic tilt",
             "Do this to reverse the effects of standing with sway back. Begin by standing with your back to the wall. Tighten your stomach muscles to flatten your back. Hold for several seconds. Once you've mastered the exercise, do it sitting or standing.",
             StretchCategory.back.rawValue],
            ["D", "Wrist/finger",
             "Hold one hand with fingers upward. Gently push fingers and wrist back with the other hand. Hold for 3 sec. Repeat 5 times for each hand.",
             StretchCategory.wrists.rawValue],
            ["E", "Thumb",
             "Hold one hand with fingers upward. Gently pull back the thumb with the fingers of the other hand. Hold for 3 sec. Repeat 5 times for each hand.",
             StretchCategory.wrists.rawValue],
            ["F", "Whole hand",
             "Spread the fingers of both hands apart and back while keeping your wrists straight. Hold for 3 sec. Repeat this exercise 5 times for each hand.",
             StretchCategory.wrists.rawValue],
            ["G", "Head roll",
             "Relax your shoulders and pull your head forward as far as it will go. Hold for just two seconds. Then slowly rotate your head along your shoulders until it is all the way back. Continue rolling around to the other side until you return to your original position. Roll your head in one direction three cycles, then reverse the direction for another three cycles. Feel the upper shoulder muscles relax. Do these slowly and feel the stretch in the neck muscles.",
             StretchCategory.neck.rawValue],
            ["H", "Shoulder squeeze",
             "Another excellent stretch for slouchers. Lace your fingers behind your back with the palms facing in. Slowly raise and straighten your arms. Hold for 5 to 10 sec. Repeat 5 to 10 times.",
             StretchCategory.shoulders.rawValue]
        ]

        /// Returns the original indices of stretches matching the given category.
        func filteredIndices(for category: StretchCategory) -> [Int] {
            guard category != .all else { return Array(stretches.indices) }
            return stretches.indices.filter { stretches[$0][3] == category.rawValue }
        }

        func generateThumbnail(path: URL) -> NSImage? {
                    do {
                        let asset = AVURLAsset(url: path, options: nil)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                        let thumbnail = NSImage(cgImage: cgImage, size: NSSize(width: 396,height: 396))
                        return thumbnail
                    } catch let error {
                        print("*** Error generating thumbnail: \(error.localizedDescription)")
                        return nil
                    }
                }
        
    }
    
}
