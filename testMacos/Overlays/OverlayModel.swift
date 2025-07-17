//
//  OverlayModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/18/22.
//

import Foundation
extension DefaultOverlay{
    @MainActor class viewModel: ObservableObject{
        let suggestionArray = ["It's best to focus on an object 20 feet away","To reset your eyelids, rapidly blinking your eyes","Get a cup of coffee", "Everything is going to be ok", "Don't look at your phone!","I hope you are being productive", "Don't look at the screen", "Enjoy the moment", "Try to loosen your shoulders", "I hope your day is going well.", "Do you need a glass of water?", "Do you need a snack?", "Posture is always important", "Reward yourself for all your hard work"]
        
        func getRandonSuggestion() -> String{
            return suggestionArray.randomElement() ?? "It's best to focus on an object 20 feet away"
            
        }
    }
    
    
}
