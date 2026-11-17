package com.margelo.nitro.lunardatepicker.services

import com.margelo.nitro.lunardatepicker.LDP_ConfigParams
import com.margelo.nitro.lunardatepicker.LDP_CustomLanguage
import com.margelo.nitro.lunardatepicker.LDP_CustomStyle
import com.margelo.nitro.lunardatepicker.LDP_Mode
import com.margelo.nitro.lunardatepicker.LDP_PresentParams
import com.margelo.nitro.lunardatepicker.models.PickerConfig
import com.margelo.nitro.lunardatepicker.utils.ColorUtils
import java.util.Locale

class ConfigurationBuilder {

  fun buildPickerConfig(params: LDP_PresentParams, globalConfig: LDP_ConfigParams?): PickerConfig {
    var pickerConfig = PickerConfig.default.copy()

    pickerConfig = pickerConfig.copy(
      controller = pickerConfig.controller.copy(
        title = params.title,
        isSingleMode = params.mode == LDP_Mode.SINGLE
      )
    )

    globalConfig?.let { config ->
      config.themes[params.theme]?.let { theme ->
        pickerConfig = applyTheme(theme, pickerConfig)
      }
      config.languages[params.language]?.let { language ->
        pickerConfig = applyLanguage(language, pickerConfig)
      }
      pickerConfig = applyYearRange(config.yearRangeOffset, pickerConfig)
      // Map showSubmitButton from global config
      pickerConfig = pickerConfig.copy(
        controller = pickerConfig.controller.copy(
          showSubmitButton = config.showSubmitButton
        ),
        calendar = pickerConfig.calendar.copy(
          showLunarDate = config.showLunarDate
        )
      )
    }

    pickerConfig = applyTimeZone(globalConfig?.timeZoneOffset, pickerConfig)

    // Force showSubmitButton to false in single mode
    if (params.mode == LDP_Mode.SINGLE) {
      pickerConfig = pickerConfig.copy(
        controller = pickerConfig.controller.copy(
          showSubmitButton = false
        )
      )
    }

    return pickerConfig
  }

  private fun applyTheme(theme: LDP_CustomStyle, config: PickerConfig): PickerConfig {
    return config.copy(
      controller = config.controller.copy(
        backgroundColor = ColorUtils.colorFromHex(theme.backgroundColor),
        titleColor = ColorUtils.colorFromHex(theme.titleColor),
        secondaryTextColor = ColorUtils.colorFromHex(theme.secondColor),
        submitButtonColor = ColorUtils.colorFromHex(theme.submitButtonColor),
        noticeLabelColor = ColorUtils.colorFromHex(theme.noticeLabelColor),
        noticeBackgroundColor = ColorUtils.colorFromHex(theme.noticeBackgroundColor)
      ),
      dayCell = config.dayCell.copy(
        dateLabelColor = ColorUtils.colorFromHex(theme.dateLabelColor),
        todayLabelColor = ColorUtils.colorFromHex(theme.todayLabelColor),
        weekendLabelColor = ColorUtils.colorFromHex(theme.weekendLabelColor),
        lunarDateLabelColor = ColorUtils.colorFromHex(theme.lunarDateLabelColor),
        specialDateLabelColor = ColorUtils.colorFromHex(theme.specialDayLabelColor),
        priceLabelColor = ColorUtils.colorFromHex(theme.priceLabelColor),
        cheapestPriceLabelColor = ColorUtils.colorFromHex(theme.cheapestPriceLabelColor),
        rangeBackgroundColor = ColorUtils.colorFromHex(theme.rangeBackgroundColor),
        selectedBackgroundColor = ColorUtils.colorFromHex(theme.selectedBackgroundColor),
        selectedTextColor = ColorUtils.colorFromHex(theme.selectedTextColor)
      ),
      monthHeader = config.monthHeader.copy(
        labelColor = ColorUtils.colorFromHex(theme.monthLabelColor)
      ),
      weekView = config.weekView.copy(
        backgroundColor = ColorUtils.colorFromHex(theme.weekViewBackgroundColor),
        weekendLabelColor = ColorUtils.colorFromHex(theme.weekendLabelColor),
        weekLabelColor = ColorUtils.colorFromHex(theme.dateLabelColor)
      )
    )
  }

  private fun applyLanguage(language: LDP_CustomLanguage, config: PickerConfig): PickerConfig {
    return config.copy(
      weekView = config.weekView.copy(
        weekdayNames = language.weekdayNames
      ),
      calendar = config.calendar.copy(
        locale = Locale.forLanguageTag(language.locale.replace('_', '-'))
      )
    )
  }

  private fun applyTimeZone(offset: Double?, config: PickerConfig): PickerConfig {
    return config.copy(
      calendar = config.calendar.copy(
        timeZone = PickerTimeZoneResolver.resolve(offset)
      )
    )
  }

  private fun applyYearRange(offset: Double, config: PickerConfig): PickerConfig {
    return config.copy(
      yearRangeOffset = offset.toInt()
    )
  }
}
