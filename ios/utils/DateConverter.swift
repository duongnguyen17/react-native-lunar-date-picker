//
//  DateConverter.swift
//  LunarDatePicker
//
//  Utility for converting between JavaScript timestamps and Swift Date objects
//

import Foundation

/// Protocol for date conversion operations
protocol DateConverting {
  func dateFromJavaScriptTimestamp(_ timestamp: Double) -> Date
  func javaScriptTimestampFromDate(_ date: Date) -> Double
  func dateFromString(_ dateString: String, timeZone: TimeZone?) -> Date?
  func stringFromDate(_ date: Date, timeZone: TimeZone?) -> String
  func rangeFromDates(from: Date, to: Date, timeZone: TimeZone?) -> LDP_Range
}

/// Default implementation of DateConverting protocol
struct DateConverter: DateConverting {

  // MARK: - Constants

  private let millisecondsPerSecond: Double = 1000.0

  // MARK: - DateConverting

  /// Converts JavaScript timestamp (milliseconds since epoch) to Swift Date
  /// - Parameter timestamp: JavaScript timestamp in milliseconds
  /// - Returns: Corresponding Swift Date object
  func dateFromJavaScriptTimestamp(_ timestamp: Double) -> Date {
    return Date(timeIntervalSince1970: timestamp / millisecondsPerSecond)
  }

  /// Converts Swift Date to JavaScript timestamp (milliseconds since epoch)
  /// - Parameter date: Swift Date object
  /// - Returns: JavaScript timestamp in milliseconds
  func javaScriptTimestampFromDate(_ date: Date) -> Double {
    return date.timeIntervalSince1970 * millisecondsPerSecond
  }

  /// Parses a date string in DD/MM/YYYY format to Swift Date
  /// - Parameters:
  ///   - dateString: Date string in DD/MM/YYYY format
  ///   - timeZone: Optional timezone, defaults to current timezone
  /// - Returns: Corresponding Swift Date object, or nil if parsing fails
  func dateFromString(_ dateString: String, timeZone: TimeZone? = nil) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM/yyyy"
    formatter.timeZone = timeZone ?? TimeZone.current
    return formatter.date(from: dateString)
  }

  /// Converts Swift Date to a string in DD/MM/YYYY format
  /// - Parameters:
  ///   - date: Swift Date object
  ///   - timeZone: Optional timezone, defaults to current timezone
  /// - Returns: Date string in DD/MM/YYYY format
  func stringFromDate(_ date: Date, timeZone: TimeZone? = nil) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM/yyyy"
    formatter.timeZone = timeZone ?? TimeZone.current
    return formatter.string(from: date)
  }

  /// Creates a Range object from two dates
  /// - Parameters:
  ///   - from: Start date
  ///   - to: End date
  ///   - timeZone: Optional timezone, defaults to current timezone
  /// - Returns: Range object with converted date strings
  func rangeFromDates(from: Date, to: Date, timeZone: TimeZone? = nil) -> LDP_Range {
    return LDP_Range(
      from: stringFromDate(from, timeZone: timeZone),
      to: stringFromDate(to, timeZone: timeZone)
    )
  }

  // Single-date helper removed: picker is range-only
}
