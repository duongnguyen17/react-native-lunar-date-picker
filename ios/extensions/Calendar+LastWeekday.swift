//
//  Calendar+LastWeekday.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation

extension Calendar {
  var lastWeekday: Int {
    let numDays = self.weekdaySymbols.count
    let res = (self.firstWeekday + numDays - 1) % numDays
    return res != 0 ? res : self.weekdaySymbols.count
  }
}

