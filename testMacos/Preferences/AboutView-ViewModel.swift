//
//  AboutView-ViewModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import Foundation
import AppKit
func requestReviewManually() {
  // TODO: replace xxxxxxxxxx in the following URL with your Apps Apple ID
  let url = "https://apps.apple.com/app/id572561420?action=write-review"
  guard let writeReviewURL = URL(string: url)
      else { fatalError("Expected a valid URL") }
    NSWorkspace.shared.open(writeReviewURL)
}
