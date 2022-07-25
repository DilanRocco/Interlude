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
    var tabs = ["Customize","Theory", "About"]
    var tabViews = [AnyView(GeneralView()),AnyView(MethodologyView()),AnyView(AboutView())]

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




