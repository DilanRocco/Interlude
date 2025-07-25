//
//  Constants.swift
//  testMacos
//
//  Created by Dilan Piscatello on 7/4/22.
//

import Foundation

//GLOBAL CONSTANTS
let ud = UserDefaults.standard


struct Constants{
    // background color used for the overlay screen
    static let DefaultBackgroundColor = BackgroundColorOverlay(backColor: "#f6f7f680", helpText: "Semi-Transparent", dark: false)
    
    
    
}




struct BackgroundColorOverlay:Equatable, Hashable,Codable{
    var backColor: String
    var helpText: String
    var dark: Bool
}
