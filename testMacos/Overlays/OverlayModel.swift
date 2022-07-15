//
//  OverlayModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/18/22.
//

import Foundation
extension DefaultOverlay{
    @MainActor class viewModel: ObservableObject{
        let suggestionArray = ["It's best to focus on an object 20 feet away","To reset your eyelids, rapidly blinking your eyes resets your something","Get a cup of coffee", "Everything is going to be ok"]
        
        func getRandonSuggestion() -> String{
            return "Need to refill your Water?"
            //return suggestionArray.randomElement() ?? "It's best to focus on an object 20 feet away"
            
        }
    }
    
    
}
