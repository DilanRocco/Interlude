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
                
                    Group{
                    Text("Interlude+").font(.title).bold().padding([.bottom],1)
                    }.frame(maxWidth: .infinity, alignment: .center)
                    Image("stretches").resizable().frame(width: 350, height: 350)
                    VStack{
                        
                        Group{
                            Group{
                                Text("It's a one-time fee for lifetime access.").bold()
                            }.frame(maxWidth: .infinity, alignment: .center)
                                Text("• The ability to truly follow the patterns of keeping a healthy body while using a computer")
                                Text("• Eight fully animated stretches with descriptions")
                                Text("• A specific overlay every hour that suggests that you step away from the computer")
                                Text("• A specifc overlay every second hour that suggests that you perform stretches")
                            }.frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1).padding([.leading,.trailing])
                    
                    }.padding([.top])
                    
                    HStack {
                        Spacer()
                        ForEach(storeManager.myProducts, id: \.self) { product in
                        if UserDefaults.standard.bool(forKey: product.productIdentifier) {
                            Text("Purchased")
                                .foregroundColor(.green)
                                .padding([.trailing])
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Button(action: {
                                storeManager.purchaseProduct(product: product)
                            }) {
                                Text("Buy for \(product.price) $")
                                    
                            }
                                .padding([.trailing])
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }.padding([.top],1)
                    
                }
                Spacer()
                   
        
        }.onAppear{
            print(storeManager.myProducts.count)
        }.padding()
        }

}

struct MoreView2: View {
    @StateObject var storeManager: StoreManager
    @State private var test: Bool = false
        var body: some View {
            VStack{
                
                    Group{
                    Text("Interlude+").font(.title).bold().padding([.bottom],1)
                    }.frame(maxWidth: .infinity, alignment: .center)
                    HStack{
                    Image("stretches").resizable().frame(width: 350, height: 350)
                    VStack{
                        
                        Group{
                            Group{
                                Text("It's a one-time fee for lifetime access.").font(.title3).bold()
                            }.frame(maxWidth: .infinity, alignment: .center)
                            Text("• The ability to truly follow the patterns of keeping a healthy body while using a computer").font(.title3)
                                Text("• Eight fully animated stretches with descriptions").font(.title3)
                                Text("• A specific overlay every hour that suggests that you step away from the computer").font(.title3)
                            Text("• A specifc overlay every second hour that suggests that you perform stretches").font(.title3).padding([.bottom])
                            ForEach(storeManager.myProducts, id: \.self) { product in
                            if UserDefaults.standard.bool(forKey: product.productIdentifier) {
                                Text("Purchased")
                                    .foregroundColor(.green)
                                    .padding([.trailing])
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Button(action: {
                                    storeManager.purchaseProduct(product: product)
                                }) {
                                    Text("Buy for \(product.price) $")
                                        
                                }
                                    .padding([.trailing])
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            }.frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1).padding([.leading,.trailing])
                    }
                    }.padding([.top])
                    
                    
                    
                }
                Spacer()
                   
        
        }.onAppear{
            print(storeManager.myProducts.count)
        }.padding()
        }

}
