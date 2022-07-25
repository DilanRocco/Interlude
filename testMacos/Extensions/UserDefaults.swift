//
//  UserDefaults.swift
//  Interlude
//
//  Created by Dilan Piscatello on 7/24/22.
//

import Foundation

extension UserDefaults {

    private enum keys {

        static let color = "BackgroundColor"

    }

    class var backgroundColor: BackgroundColorOverlay {
        get {
            
            if let data = UserDefaults.standard.data(forKey: keys.color) {
                    do {
                        // Create JSON Decoder
                        let decoder = JSONDecoder()

                        // Decode Note
                        return try decoder.decode(BackgroundColorOverlay.self, from: data)
                        
                    } catch {
                        print("Unable to Encode Array of Notes (\(error))")
                        return Constants.DefaultBackgroundColor
                    }
                    
                    
                }else{
                    return Constants.DefaultBackgroundColor
                }
                
        }
        set {
            do{
                let encoder = JSONEncoder()

                // Encode Note
                let data = try encoder.encode(newValue)

                // Write/Set Data
                UserDefaults.standard.set(data, forKey: keys.color)
            
            } catch {
                print("Unable to Encode Array of Notes (\(error))")
            }

        }
    }

}
