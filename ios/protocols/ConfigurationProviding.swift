//
//  ConfigurationProviding.swift
//  LunarDatePicker
//
//  Protocol for configuration management
//

import Foundation

protocol ConfigurationProviding {
  func buildPickerConfig(
    from params: LDP_PresentParams,
    globalConfig: LDP_ConfigParams?
  ) -> PickerConfig
  func applyTheme(_ theme: LDP_CustomStyle, to config: inout PickerConfig)
  func applyLanguage(_ language: LDP_CustomLanguage, to config: inout PickerConfig)
  func applyTimeZone(_ offset: Double, to config: inout PickerConfig)
  func applyYearRange(_ offset: Double, to config: inout PickerConfig)
}
