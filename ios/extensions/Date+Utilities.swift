//
//  Date+Utilities.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation

extension Date {

  func startOfMonth(in calendar: Calendar = .current) -> Date {
    guard let startOfMonth = calendar.date(
      from: calendar.dateComponents(
        [.year, .month],
        from: calendar.startOfDay(for: self)
      )
    ) else {
      return calendar.startOfDay(for: self)
    }
    return startOfMonth.startOfDay(in: calendar)
  }

  func endOfMonth(in calendar: Calendar = .current) -> Date {
    guard let endOfMonth = calendar.date(
      byAdding: DateComponents(month: 1, day: -1),
      to: self.startOfMonth(in: calendar)
    ) else {
      return self.endOfDay(in: calendar)
    }
    return endOfMonth.endOfDay(in: calendar)
  }

  func isInSameDay(in calendar: Calendar = .current, date: Date) -> Bool {
    calendar.isDate(self, equalTo: date, toGranularity: .day)
  }

  func startOfDay(in calendar: Calendar = .current) -> Date {
    calendar.startOfDay(for: self)
  }
  
  func startOfDay() -> Date {
    Calendar.current.startOfDay(for: self)
  }

  func endOfDay(in calendar: Calendar = .current) -> Date {
    guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: self)),
          let endOfDay = calendar.date(byAdding: .second, value: -1, to: startOfNextDay) else {
      // Fallback to 23:59:59 if date calculation fails
      return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
    return endOfDay
  }
  
  func endOfDay() -> Date {
    endOfDay(in: Calendar.current)
  }

}
