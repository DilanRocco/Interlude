//
//  PreferencesView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 1/10/22.
//

import SwiftUI
import UserNotifications
import Combine
import StoreKit
var storeManager = StoreManager ()
struct PreferencesView: View {
    
    @State var selected: Int?
    var tabs = ["Customize","Theory","Interlude+","About"]
    
    
    let productIDs = [
            //Use your product IDs instead
            "com.twenty.twenty.extra.features"]
        
    
        
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
        
        let tabViews =  [AnyView(GeneralView()),AnyView(MethodologyView()),AnyView(MoreView(storeManager: storeManager)
            .onAppear(perform: {
                if alreadyLoaded {
                   return
                }else{
                    storeManager.getProducts(productIDs: productIDs)
                    alreadyLoaded = true
                }})),AnyView(AboutView())]
        
        AnyView(tabViews[selected ?? 0])
        }
    }




