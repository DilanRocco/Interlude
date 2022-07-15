//
//  Date.swift
//  testMacos
//
//  Created by Dilan Piscatello on 12/30/21.
//

import Foundation

struct InitalDateContents{
    static var time = Date()
    static var year = convertDate(time, "yyyy")
    static var day = convertDate(time, "d")
    static var hour = convertDate(time, "H")
    static var minute = convertDate(time, "m")
    static var second = convertDate(time, "s")
    
}

func convertDate(_ date: Date, _ format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: date)
}


