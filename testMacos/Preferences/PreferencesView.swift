//
//  PreferencesView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 1/10/22.
//

import SwiftUI

import UserNotifications
import Combine
struct PreferencesView: View {
    
    @State var selected: Int? = 0
    //https://betterprogramming.pub/using-sidebar-in-swiftui-without-a-navigationview-94f4181c09b
    var tabs = ["Basic Configurations","Methodology","Advanced", "About"]
    var tabViews = [AnyView(GeneralView()),AnyView(MethodologyView()),AnyView(AdvancedView()),AnyView(AboutView())]
    var body: some View {
        HStack {
            List(0...tabs.count-1, id: \.self, selection: $selected) { number in
                HStack {
                    Text(tabs[number])
                    Spacer()
                }
            }.contentShape(Rectangle())
            .frame(width: 200)
            .listStyle(SidebarListStyle())
            
            Spacer()
            detailView
            Spacer()
        }.frame(width: 700, height: 700, alignment: .center)
        
    }
    
    @ViewBuilder var detailView: some View {
        AnyView(tabViews[selected ?? 0])
        }
    }





struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}

extension Color {
    public init?(hex: String) {
        let r, g, b: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                   

                    self.init(red: r, green: g, blue: b)
                    return
                }
            }
        }

        return nil
       
    }
}


