//
//  ConfigurationBuilder.swift
//  LunarDatePicker
//
//  Service for building picker configurations
//

import Foundation

final class ConfigurationBuilder: ConfigurationProviding {

  // MARK: - ConfigurationProviding

  func buildPickerConfig(
    from params: LDP_PresentParams,
    globalConfig: LDP_ConfigParams?
  ) -> PickerConfig {
    var pickerConfig = PickerConfig.default

    // Apply basic configuration
    pickerConfig.controller.title = params.title
    pickerConfig.controller.isSingleMode = (params.mode == .single)

    // Apply theme if available
    if let globalConfig = globalConfig,
      let theme = globalConfig.themes[params.theme]
    {
      applyTheme(theme, to: &pickerConfig)
    }

    // Apply language if available
    if let globalConfig = globalConfig,
      let language = globalConfig.languages[params.language]
    {
      applyLanguage(language, to: &pickerConfig)
    }

    // Use the configured fixed offset, or the device timezone by default.
    applyTimeZone(globalConfig?.timeZoneOffset, to: &pickerConfig)

    // Apply year range if available
    if let yearRangeOffset = globalConfig?.yearRangeOffset {
      applyYearRange(yearRangeOffset, to: &pickerConfig)
    }

    // Apply global settings if available in globalConfig
    if let globalConfig = globalConfig {
      pickerConfig.controller.showSubmitButton = globalConfig.showSubmitButton
      pickerConfig.dayCell.showLunarDate = globalConfig.showLunarDate
    }

    // Force showSubmitButton to false in single mode
    if params.mode == .single {
      pickerConfig.controller.showSubmitButton = false
    }

    return pickerConfig
  }

  func applyTheme(_ theme: LDP_CustomStyle, to config: inout PickerConfig) {
    // Controller colors
    config.controller.backgroundColor = ColorWrapper(
      fromHex: theme.backgroundColor
    )
    config.controller.titleColor = ColorWrapper(fromHex: theme.titleColor)
    config.controller.secondaryTextColor = ColorWrapper(fromHex: theme.secondColor)
    config.controller.submitButtonColor = ColorWrapper(fromHex: theme.submitButtonColor)
    config.controller.noticeLabelColor = ColorWrapper(fromHex: theme.noticeLabelColor)
    config.controller.noticeBackgroundColor = ColorWrapper(fromHex: theme.noticeBackgroundColor)

    // Day cell colors
    config.dayCell.dateLabelColor = ColorWrapper(fromHex: theme.dateLabelColor)
    config.dayCell.todayLabelColor = ColorWrapper(fromHex: theme.todayLabelColor)
    config.dayCell.weekendLabelColor = ColorWrapper(
      fromHex: theme.weekendLabelColor
    )
    config.dayCell.lunarDateLabelColor = ColorWrapper(
      fromHex: theme.lunarDateLabelColor
    )
    config.dayCell.specialDateLabelColor = ColorWrapper(
      fromHex: theme.specialDayLabelColor
    )
    config.dayCell.priceLabelColor = ColorWrapper(
      fromHex: theme.priceLabelColor
    )
    config.dayCell.cheapestPriceLabelColor = ColorWrapper(
      fromHex: theme.cheapestPriceLabelColor
    )
    config.dayCell.rangeBackgroundColor = ColorWrapper(
      fromHex: theme.rangeBackgroundColor
    )
    config.dayCell.selectedBackgroundColor = ColorWrapper(
      fromHex: theme.selectedBackgroundColor
    )
    config.dayCell.selectedTextColor = ColorWrapper(
      fromHex: theme.selectedTextColor
    )

    // Month header colors
    config.monthHeader.labelColor = ColorWrapper(fromHex: theme.monthLabelColor)

    // Week view colors
    config.weekView.backgroundColor = ColorWrapper(
      fromHex: theme.weekViewBackgroundColor
    )
    config.weekView.weekendLabelColor = ColorWrapper(
      fromHex: theme.weekendLabelColor
    )
    config.weekView.weekLabelColor = ColorWrapper(fromHex: theme.dateLabelColor)
  }

  func applyLanguage(_ language: LDP_CustomLanguage, to config: inout PickerConfig)
  {
    config.weekView.weekdayNames = language.weekdayNames
    // Apply locale for formatting while keeping the calendar Monday-first.
    var calendar = config.calendar
    calendar.locale = Locale(identifier: language.locale)
    calendar.firstWeekday = 2
    config.calendar = calendar
  }

  func applyTimeZone(_ offset: Double?, to config: inout PickerConfig) {
    config.calendar.timeZone = PickerTimeZoneResolver.resolve(offsetHours: offset)
  }

  func applyYearRange(_ offset: Double, to config: inout PickerConfig) {
    config.yearRangeOffset = Int(offset)
  }
}
