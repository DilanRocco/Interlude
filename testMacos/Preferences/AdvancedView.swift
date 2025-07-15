//
//  AdvancedView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import SwiftUI


struct AdvancedView: View {
        var body: some View {
            VStack{
                HStack{
                    Text("Advanced").fontWeight(.bold).font(.system(size: 40)).padding()
                    Spacer()
                }
                Spacer()
        }
                
    }
}


struct AdvancedView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedView()
    }
}
