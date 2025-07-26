//
//  MoreView.swift
//  Interlude
//
//  Created by Dilan Piscatello on 7/25/22.
//
import StoreKit
import SwiftUI


//Fetch Products
//Purchase Product
//Update UI / Fetch Product State

struct MoreView: View {
    @StateObject var storeManager: StoreManager
    @State private var test: Bool = false
        var body: some View {
            VStack{
                ForEach(storeManager.myProducts, id: \.self) { product in
                
                    Text("With Interlude+, it's a one-time fee for lifetime access.").font(.title).bold().padding([.bottom],1)
                    Image("stretches").resizable().frame(width: 400, height: 400)
                    VStack{
                        
                           
                            Group{
                                
                                Text("• The ability to truly follow the patterns of keeping a healthy body while using a computer")
                                Text("• Eight fully animated stretches with descriptions")
                                Text("• A specific overlay every hour that suggests that you step away from the computer")
                                Text("• A specifc overlay every second hour that suggests that you perform stretches")
                            }.frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1).padding([.leading,.trailing])
                    
                    }.padding([.top])
                    
                    HStack {
                        Spacer()
                        if UserDefaults.standard.bool(forKey: product.productIdentifier) {
                            Text("Purchased")
                                .foregroundColor(.green)
                        } else {
                            Button(action: {
                                storeManager.purchaseProduct(product: product)
                            }) {
                                Text("Buy for \(product.price) $")
                            }
                                .foregroundColor(.blue)
                        }
                    }.padding([.top],1)
                    
                }
                Spacer()
                   
        
        }.onAppear{
            print(storeManager.myProducts.count)
        }.padding()
        }

}
