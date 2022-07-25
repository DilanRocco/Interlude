//
//  AboutView-ViewModel.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import Foundation
import AppKit
func requestReviewManually() {
  let url = "https://apps.apple.com/app/id1604254716?action=write-review"
  guard let writeReviewURL = URL(string: url)
      else { fatalError("Expected a valid URL") }
        NSWorkspace.shared.open(writeReviewURL)
}
