//
//  PickerController+CalendarDelegate.swift
//  LunarDatePicker
//
//  Calendar delegate methods for PickerController
//

import Foundation
import JTAppleCalendar

// MARK: - JTACMonthViewDataSource

extension PickerController: JTACMonthViewDataSource {

  public func configureCalendar(_ calendar: JTACMonthView)
    -> ConfigurationParameters
  {
    let configManager = CalendarConfigurationManager(
      config: config,
      minimumDate: privateMinimumDate,
      maximumDate: privateMaximumDate
    )
    return configManager.createConfigurationParameters()
  }

  public func calendar(
    _ calendar: JTACMonthView,
    cellForItemAt date: Date,
    cellState: CellState,
    indexPath: IndexPath
  ) -> JTACDayCell {
    let cell = calendar.dequeueReusableJTAppleCell(
      withReuseIdentifier: dayCellReuseIdentifier,
      for: indexPath
    )
    configureCell(
      cell,
      forItemAt: date,
      cellState: cellState,
      indexPath: indexPath
    )
    return cell
  }

  public func calendar(
    _ calendar: JTACMonthView,
    headerViewForDateRange range: (start: Date, end: Date),
    at indexPath: IndexPath
  ) -> JTACMonthReusableView {
    let header =
      calendar.dequeueReusableJTAppleSupplementaryView(
        withReuseIdentifier: monthHeaderReuseIdentifier,
        for: indexPath
      ) as! MonthHeader

    header.applyConfig(config.monthHeader)
    header.configure(for: range.start, calendar: config.calendar)
    return header
  }

  public func calendarSizeForMonths(_ calendar: JTACMonthView?) -> MonthSize? {
    return MonthSize(defaultSize: Constants.Layout.monthHeaderHeight)
  }
}

// MARK: - JTACMonthViewDelegate

extension PickerController: JTACMonthViewDelegate {

  public func calendar(
    _ calendar: JTACMonthView,
    willDisplay cell: JTACDayCell,
    forItemAt date: Date,
    cellState: CellState,
    indexPath: IndexPath
  ) {
    // Prevent crashes if called during cleanup
    guard !hasCleanedUp else { return }
    
    configureCell(
      cell,
      forItemAt: date,
      cellState: cellState,
      indexPath: indexPath
    )
  }

  public func calendar(
    _ calendar: JTACMonthView,
    didSelectDate date: Date,
    cell: JTACDayCell?,
    cellState: CellState,
    indexPath: IndexPath
  ) {
    // Prevent crashes if called during cleanup
    guard !hasCleanedUp else { return }
    
    if cellState.selectionType == .some(.userInitiated) {
      handleDateTap(in: calendar, date: date)
    } else if let cell {
      configureCell(
        cell,
        forItemAt: date,
        cellState: cellState,
        indexPath: indexPath
      )
    }
  }

  public func calendar(
    _ calendar: JTACMonthView,
    didDeselectDate date: Date,
    cell: JTACDayCell?,
    cellState: CellState,
    indexPath: IndexPath
  ) {
    // Prevent crashes if called during cleanup
    guard !hasCleanedUp else { return }
    
    if cellState.selectionType == .some(.userInitiated) {
      handleDateTap(in: calendar, date: date)
    } else if let cell {
      configureCell(
        cell,
        forItemAt: date,
        cellState: cellState,
        indexPath: indexPath
      )
    }
  }

  public func calendar(
    _ calendar: JTACMonthView,
    shouldSelectDate date: Date,
    cell: JTACDayCell?,
    cellState: CellState,
    indexPath: IndexPath
  ) -> Bool {
    if cellState.dateBelongsTo != .thisMonth {
      return false
    }
    if let minimumDate = privateMinimumDate, date < minimumDate.startOfDay() {
      return false
    }
    if let maximumDate = privateMaximumDate, date > maximumDate.endOfDay() {
      return false
    }
    return true
  }


  public func calendar(
    _ calendar: JTACMonthView,
    shouldDeselectDate date: Date,
    cell: JTACDayCell?,
    cellState: CellState,
    indexPath: IndexPath
  ) -> Bool {
    // Don't clear entire cache - it causes performance issues
    // Cache will be selectively updated during cell configuration
    return true
  }
}
