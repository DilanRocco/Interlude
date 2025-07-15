//
//  AboutView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import SwiftUI


struct AboutView: View {
    let europeanCars = ["Audi","Renault","Ferrari"]
    let asianCars = ["Honda","Nissan","Suzuki"]
    var body: some View {
        VStack{
            HStack{
                Text("About").fontWeight(.bold).font(.system(size: 40)).padding()
                Spacer()
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
