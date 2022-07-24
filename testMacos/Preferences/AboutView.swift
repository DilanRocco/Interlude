//
//  AboutView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import SwiftUI


struct AboutView: View {
    var body: some View {
        VStack{
            HStack{
                Text("About").fontWeight(.bold).font(.largeTitle).padding()
                Spacer()
            }
            
                HStack{
                    Image("icon")
                        .resizable()
                        .frame(width: 128, height: 128, alignment: .center)
                        .cornerRadius(10)
                        .padding()
                        
                        
                    let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
                    let version = nsObject as! String
                    
                    VStack{
                        HStack{
                        Text("Interlude").bold().frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                        Button(action: {
                                  requestReviewManually()
                                }) {
                                    Text("Review App")
                                    
                                }.frame(maxWidth: 90, alignment: .leading).padding(.trailing,  30)
                            
                            
                        }.padding(.top, -15)
                        Text( version) .frame(maxWidth: .infinity, alignment: .leading).foregroundColor(.gray)
                            .padding(.bottom,25)
                        Text("Dilan Rocco Piscatello").frame(maxWidth: .infinity, alignment: .leading).foregroundColor(.gray)
                        
                    }
                    Spacer()
                }
                    
           
                
                
            Text("If you find bugs with Interlude, please either leave a review, or comment on the Github repository. Thanks for downloading, and if you have further questions, you can always message me on any of my socials.").padding()
            HStack{
                Link("Youtube", destination: URL(string: "https://www.youtube.com/dilanrocco")!)
                Link("Website", destination: URL(string: "https://dilanpiscatello.com")!)
                Link("Github", destination: URL(string: "https://github.com/DilanRocco")!)
                Link("Twitter", destination: URL(string: "https://twitter.com/DilanPiscatello")!)
            }
            Spacer()
            
        }
    }
    
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
