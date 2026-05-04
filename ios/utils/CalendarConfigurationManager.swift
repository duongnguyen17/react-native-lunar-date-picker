//
//  CalendarConfigurationManager.swift
//  LunarDatePicker
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation
import JTAppleCalendar

final class CalendarConfigurationManager {
  private let config: PickerConfig
  private let minimumDate: Date?
  private let maximumDate: Date?

  init(
    config: PickerConfig,
    minimumDate: Date?,
    maximumDate: Date?
  ) {
    self.config = config
    self.minimumDate = minimumDate
    self.maximumDate = maximumDate
  }

  // Cached date formatter for better performance
  private lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MM dd"
    formatter.timeZone = config.calendar.timeZone
    formatter.locale = config.calendar.locale
    return formatter
  }()

  func createConfigurationParameters() -> ConfigurationParameters {
    let currentDate = Date()
    let calendar = config.calendar

    // Calculate date range (10 years before and after)
    guard let tenYearsBefore = calendar.date(
      byAdding: .year,
      value: -config.yearRangeOffset,
      to: currentDate
    ),
    let tenYearsAfter = calendar.date(
      byAdding: .year,
      value: config.yearRangeOffset,
      to: currentDate
    ),
    let startDate = dateFormatter.date(
      from: dateFormatter.string(from: tenYearsBefore)
    ),
    let endDate = dateFormatter.date(
      from: dateFormatter.string(from: tenYearsAfter)
    ) else {
      // Fallback to reasonable defaults if date calculation fails
      let fallbackStart = calendar.date(byAdding: .year, value: -10, to: currentDate) ?? currentDate
      let fallbackEnd = calendar.date(byAdding: .year, value: 10, to: currentDate) ?? currentDate
      return ConfigurationParameters(
        startDate: fallbackStart,
        endDate: fallbackEnd,
        numberOfRows: Constants.Calendar.numberOfRows,
        calendar: calendar,
        generateInDates: .forAllMonths,
        generateOutDates: .tillEndOfRow,
        firstDayOfWeek: nil,
        hasStrictBoundaries: true
      )
    }

    var adjustedStartDate = startDate
    var adjustedEndDate = endDate

    // Adjust end date based on maximum date constraint
    if let maximumDate = self.maximumDate,
      let endOfNextMonth = calendar.date(
        byAdding: .month,
        value: 0,
        to: maximumDate
      )?.endOfMonth(in: calendar)
    {
      adjustedEndDate = endOfNextMonth
    }

    // Adjust start date based on minimum date constraint
    if let minimumDate = self.minimumDate,
      let startOfPreviousMonth = calendar.date(
        byAdding: .month,
        value: 0,
        to: minimumDate
      )?.startOfMonth(in: calendar)
    {
      adjustedStartDate = startOfPreviousMonth
    }

    return ConfigurationParameters(
      startDate: adjustedStartDate,
      endDate: adjustedEndDate,
      numberOfRows: Constants.Calendar.numberOfRows,
      calendar: calendar,
      generateInDates: .forAllMonths,
      generateOutDates: .tillEndOfRow,
      firstDayOfWeek: nil,
      hasStrictBoundaries: true
    )
  }

  func createCalendarView<Value: PickerValue>(for valueType: Value.Type)
    -> JTACMonthView
  {
    let monthView = JTACMonthView()
    monthView.translatesAutoresizingMaskIntoConstraints = false
    monthView.backgroundColor = config.controller.backgroundColor.toUIColor()
    monthView.minimumLineSpacing = Constants.UI.minimumLineSpacing
    monthView.minimumInteritemSpacing = Constants.UI.minimumInteritemSpacing
    monthView.showsVerticalScrollIndicator = false
    monthView.cellSize = Constants.UI.cellSizeWithoutPrice
    monthView.allowsMultipleSelection = true
    monthView.allowsRangedSelection = true
    monthView.rangeSelectionMode = .continuous
    monthView.contentInsetAdjustmentBehavior = .always

    return monthView
  }
}
