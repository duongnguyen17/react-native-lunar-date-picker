//
//  PickerConfig.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation

public struct PickerConfig {

  public static var `default` = PickerConfig()

  private init() {}

  public var calendar: Calendar = .current

  public var yearRangeOffset = Constants.Calendar.yearRangeOffset

  public var controller = PickerConfig.PickerController()

  public var monthHeader = PickerConfig.MonthHeader(
    monthNames: Constants.MonthNames.english
  )

  public var dayCell = PickerConfig.DayCell()

  public var weekView = PickerConfig.WeekView()
}
