//
//  String+CapitalizeFirstLetter.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation

extension String {

  func capitalizingFirstLetter() -> String {
    prefix(1).capitalized + dropFirst()
  }

  mutating func capitalizeFirstLetter() {
    self = self.capitalizingFirstLetter()
  }

}

