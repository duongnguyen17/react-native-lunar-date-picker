//
//  Value.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation

public protocol PickerValue {
  func outOfRange(minDate: Date?, maxDate: Date?) -> Bool
}

public struct PickerRange: PickerValue, Hashable {

  public var fromDate: Date

  public var toDate: Date?

  public init(from fromDate: Date, to toDate: Date? = nil) {
    self.fromDate = fromDate
    self.toDate = toDate
  }

  public static func from(_ fromDate: Date, to toDate: Date? = nil) -> PickerRange {
    PickerRange(from: fromDate, to: toDate)
  }

  public var onSameDay: Bool {
    guard let toDate = self.toDate else { return false }
    return self.fromDate.isInSameDay(date: toDate)
  }

  public func outOfRange(minDate: Date?, maxDate: Date?) -> Bool {
    let fromOutOfRange = self.fromDate < minDate ?? self.fromDate
    let toOutOfRange = self.toDate.map { $0 > maxDate ?? $0 } ?? false
    return fromOutOfRange || toOutOfRange
  }
}
