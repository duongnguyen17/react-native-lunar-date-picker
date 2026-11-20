//
//  LunarDatePicker.swift
//  LunarDatePicker
//
//  Main entry point for React Native Nitro Module
//

import Foundation
import UIKit

/// Main class implementing the HybridLunarDatePickerSpec protocol
/// This class serves as the bridge between React Native and native iOS implementation
final class LunarDatePicker: HybridLunarDatePickerSpec {

  // MARK: - Properties

  /// Coordinator responsible for managing the presentation flow
  private let coordinator: LunarDatePickerCoordinator
  private let dateConverter: DateConverting
  private var currentConfig: LDP_ConfigParams?

  // MARK: - Initialization

  /// Initializes the LunarDatePicker with default dependencies
  override init() {
    self.dateConverter = DateConverter()
    self.coordinator = LunarDatePickerCoordinator()
  }

  /// Initializes the LunarDatePicker with custom dependencies (for testing)
  /// - Parameter coordinator: Custom coordinator instance
  init(coordinator: LunarDatePickerCoordinator) {
    self.dateConverter = DateConverter()
    self.coordinator = coordinator
  }

  // MARK: - HybridLunarDatePickerSpec Implementation

  /// Configures the global settings for the date picker
  /// - Parameter config: Configuration parameters including themes, languages, etc.
  /// - Throws: An error if configuration is invalid
  public func configure(config: LDP_ConfigParams) throws {
    // Validate configuration before applying
    try validateConfiguration(config)

    // Apply configuration to coordinator
    coordinator.configure(with: config)
    currentConfig = config
  }

  /// Presents the date picker with the specified parameters
  /// - Parameter params: Presentation parameters including theme, language, etc.
  /// - Throws: An error if presentation fails
  public func present(params: LDP_PresentParams) throws {
    // Validate presentation parameters immediately so errors throw to JS
    try validatePresentationParams(params)

    // Ensure presentation runs on main thread
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        do {
          try self?.coordinator.present(with: params)
        } catch {
          print("[LunarDatePicker] Present failed: \(error)")
        }
      }
      return
    }

    try coordinator.present(with: params)
  }

  /// Replaces the price snapshot shown by the active picker.
  public func updatePrices(params: LDP_PriceUpdateParams) throws {
    DispatchQueue.main.async { [weak self] in
      self?.coordinator.updatePrices(with: params)
    }
  }

  /// Cập nhật maximumDate khi calendar đang mở
  public func updateMaximumDate(maximumDate: String) throws {
    DispatchQueue.main.async { [weak self] in
      self?.coordinator.updateMaximumDate(maximumDate)
    }
  }

  /// Lấy thông tin ngày âm lịch cho một ngày dương lịch
  public func getLunarDate(solarDate: String, timeZoneOffset: Double?) throws -> LDP_LunarDate {
    let timeZone = PickerTimeZoneResolver.resolve(offsetHours: timeZoneOffset ?? currentConfig?.timeZoneOffset ?? 7.0)
    guard let (day, month, year, date) = parseSolarDate(solarDate, timeZone: timeZone) else {
      throw LunarDatePickerError.invalidConfiguration
    }
    let lunar = getVietnameseLunarDate(date, timeZone)
    let isoDate = String(format: "%04d-%02d-%02d", year, month, day)
    return LDP_LunarDate(day: Double(lunar.day), month: Double(lunar.month), year: Double(lunar.year), solarDate: isoDate)
  }

  /// Lấy danh sách ngày âm lịch cho toàn bộ một tháng dương lịch
  public func getLunarMonth(year: Double, month: Double, timeZoneOffset: Double?) throws -> [LDP_LunarDate] {
    let timeZone = PickerTimeZoneResolver.resolve(offsetHours: timeZoneOffset ?? currentConfig?.timeZoneOffset ?? 7.0)
    let y = Int(year)
    let m = Int(month)
    guard m >= 1 && m <= 12 else {
      throw LunarDatePickerError.invalidConfiguration
    }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone

    var startComponents = DateComponents()
    startComponents.year = y
    startComponents.month = m
    startComponents.day = 1
    guard let startDate = calendar.date(from: startComponents),
          let range = calendar.range(of: .day, in: .month, for: startDate) else {
      throw LunarDatePickerError.invalidConfiguration
    }

    var result: [LDP_LunarDate] = []
    result.reserveCapacity(range.count)

    for d in range {
      var dayComponents = DateComponents()
      dayComponents.year = y
      dayComponents.month = m
      dayComponents.day = d
      if let dayDate = calendar.date(from: dayComponents) {
        let lunar = getVietnameseLunarDate(dayDate, timeZone)
        let isoDate = String(format: "%04d-%02d-%02d", y, m, d)
        result.append(LDP_LunarDate(day: Double(lunar.day), month: Double(lunar.month), year: Double(lunar.year), solarDate: isoDate))
      }
    }

    return result
  }

  // MARK: - Private Methods

  private func parseSolarDate(_ dateString: String, timeZone: TimeZone) -> (day: Int, month: Int, year: Int, date: Date)? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone

    if dateString.contains("-") {
      let parts = dateString.split(separator: "-").compactMap { Int($0) }
      if parts.count == 3 {
        let year = parts[0]
        let month = parts[1]
        let day = parts[2]
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        if let date = calendar.date(from: comps) {
          let created = calendar.dateComponents([.year, .month, .day], from: date)
          if created.year == year && created.month == month && created.day == day {
            return (day, month, year, date)
          }
        }
      }
    } else if dateString.contains("/") {
      let parts = dateString.split(separator: "/").compactMap { Int($0) }
      if parts.count == 3 {
        let day = parts[0]
        let month = parts[1]
        let year = parts[2]
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        if let date = calendar.date(from: comps) {
          let created = calendar.dateComponents([.year, .month, .day], from: date)
          if created.year == year && created.month == month && created.day == day {
            return (day, month, year, date)
          }
        }
      }
    }
    return nil
  }

  /// Validates the configuration parameters
  /// - Parameter config: Configuration to validate
  /// - Throws: LunarDatePickerError.invalidConfiguration if validation fails
  private func validateConfiguration(_ config: LDP_ConfigParams) throws {
    // Validate themes
    for (_, theme) in config.themes {
      guard isValidHexColor(theme.backgroundColor),
        isValidHexColor(theme.titleColor),
        isValidHexColor(theme.dateLabelColor),
        isValidHexColor(theme.todayLabelColor),
        isValidHexColor(theme.lunarDateLabelColor),
        isValidHexColor(theme.selectedTextColor),
        isValidHexColor(theme.weekendLabelColor),
        isValidHexColor(theme.specialDayLabelColor),
        isValidHexColor(theme.priceLabelColor),
        isValidHexColor(theme.cheapestPriceLabelColor),
        isValidHexColor(theme.monthLabelColor),
        isValidHexColor(theme.secondColor),
        isValidHexColor(theme.weekViewBackgroundColor),
        isValidHexColor(theme.selectedBackgroundColor),
        isValidHexColor(theme.rangeBackgroundColor),
        isValidHexColor(theme.submitButtonColor),
        isValidHexColor(theme.noticeLabelColor),
        isValidHexColor(theme.noticeBackgroundColor)
      else {
        throw LunarDatePickerError.invalidConfiguration
      }
    }

    // Validate languages
    for (_, language) in config.languages {
      guard language.weekdayNames.count == 7
      else {
        throw LunarDatePickerError.invalidConfiguration
      }
    }
  }

  /// Validates the presentation parameters
  /// - Parameter params: Presentation parameters to validate
  /// - Throws: LunarDatePickerError.invalidConfiguration if validation fails
  private func validatePresentationParams(_ params: LDP_PresentParams) throws {
    let timeZone = PickerTimeZoneResolver.resolve(offsetHours: currentConfig?.timeZoneOffset)

    func parse(_ value: String) throws -> Date {
      guard let date = dateConverter.dateFromString(value, timeZone: timeZone) else {
        throw LunarDatePickerError.invalidConfiguration
      }
      return date
    }

    if let minimumDateString = params.minimumDate,
       let maximumDateString = params.maximumDate {
      let minDate = try parse(minimumDateString)
      let maxDate = try parse(maximumDateString)
      guard minDate <= maxDate else { throw LunarDatePickerError.invalidConfiguration }
    }

    if let initialValue = params.initialValue {
      let fromDate = try parse(initialValue.from)
      if let toString = initialValue.to {
        let toDate = try parse(toString)
        guard fromDate <= toDate else { throw LunarDatePickerError.invalidConfiguration }
      }
    }
  }

  /// Checks if a string is a valid hex color
  /// - Parameter hex: Hex color string to validate
  /// - Returns: true if valid hex color, false otherwise
  private func isValidHexColor(_ hex: String) -> Bool {
    let hexRegex = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$"
    let hexPredicate = NSPredicate(format: "SELF MATCHES %@", hexRegex)
    return hexPredicate.evaluate(with: hex)
  }
}
