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
    // Ensure we're on the main thread for UI operations
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        try? self?.present(params: params)
      }
      return
    }

    // Validate presentation parameters
    try validatePresentationParams(params)

    // Present using coordinator
    try coordinator.present(with: params)
  }

  /// Cập nhật giá cho một tháng cụ thể
  public func updatePrices(params: LDP_PriceUpdateParams) throws {
    coordinator.updatePrices(with: params)
  }

  /// Cập nhật maximumDate khi calendar đang mở
  public func updateMaximumDate(maximumDate: String) throws {
    coordinator.updateMaximumDate(maximumDate)
  }


  // MARK: - Private Methods

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
    let timeZone = currentConfig.flatMap { config in
      TimeZone(secondsFromGMT: Int(config.timeZoneOffset * 3600))
    }

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
