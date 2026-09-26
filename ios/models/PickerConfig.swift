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

  public var calendar: Calendar = {
    var calendar = Calendar.current
    // Foundation uses 1-based weekday values: Sunday = 1, Monday = 2.
    calendar.firstWeekday = 2
    return calendar
  }()

  public var yearRangeOffset = Constants.Calendar.yearRangeOffset

  public var controller = PickerConfig.PickerController()

  public var monthHeader = PickerConfig.MonthHeader(
    monthNames: Constants.MonthNames.english
  )

  public var dayCell = PickerConfig.DayCell()

  public var weekView = PickerConfig.WeekView()
}
