package com.margelo.nitro.lunardatepicker.models

import android.graphics.Color
import java.io.Serializable
import java.util.*
import androidx.core.graphics.toColorInt

/**
 * Configuration data class for the lunar date picker
 */
data class PickerConfig(
  val controller: ControllerConfig = ControllerConfig(),
  val dayCell: DayCellConfig = DayCellConfig(),
  val monthHeader: MonthHeaderConfig = MonthHeaderConfig(),
  val weekView: WeekViewConfig = WeekViewConfig(),
  val calendar: CalendarConfig = CalendarConfig(),
  val yearRangeOffset: Int = 100
) : Serializable {
  companion object {
    val default = PickerConfig()
  }
}

/**
 * Configuration for the main controller/dialog
 */
data class ControllerConfig(
  var title: String = "Select Date",
  var isSingleMode: Boolean = false,
  var backgroundColor: Int = Color.WHITE,
  var titleColor: Int = Color.BLACK,
  var secondaryTextColor: Int = Color.BLACK,
  var selectedTextColor: Int = Color.WHITE,
  var submitButtonColor: Int = Color.BLACK,
  var showSubmitButton: Boolean = true,
  var noticeLabelColor: Int = Color.BLACK,
  var noticeBackgroundColor: Int = Color.LTGRAY
) : Serializable

/**
 * Configuration for day cells in the calendar
 */
data class DayCellConfig(
  var dateLabelColor: Int = Color.BLACK,
  var todayLabelColor: Int = "#3B82F6".toColorInt(), // Blue for today's date
  var weekendLabelColor: Int = "#FF9500".toColorInt(), // Orange like iOS
  var lunarDateLabelColor: Int = "#8E8E93".toColorInt(), // iOS secondary label color
  var specialDateLabelColor: Int = "#FF9500".toColorInt(), // Orange for special dates (like first day of lunar month)
  var priceLabelColor: Int = "#8E8E93".toColorInt(), // Default: same as lunar date
  var cheapestPriceLabelColor: Int = "#3B82F6".toColorInt(), // Blue for cheapest price
  
  var rangeBackgroundColor: Int = "#E5F3FF".toColorInt(), // Light blue for range
  var selectedBackgroundColor: Int = "#007AFF".toColorInt(), // iOS blue
  var selectedTextColor: Int = Color.WHITE
) : Serializable

/**
 * Configuration for month headers
 */
data class MonthHeaderConfig(
  var labelColor: Int = Color.BLACK,
  var monthLabelColor: Int = Color.BLACK, // Alias for optimized calendar compatibility
  var monthNames: Array<String> = arrayOf(
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  )
) : Serializable {
  override fun equals(other: Any?): Boolean {
    if (this === other) return true
    if (javaClass != other?.javaClass) return false

    other as MonthHeaderConfig

    if (labelColor != other.labelColor) return false
    if (!monthNames.contentEquals(other.monthNames)) return false

    return true
  }

  override fun hashCode(): Int {
    var result = labelColor
    result = 31 * result + monthNames.contentHashCode()
    return result
  }
}

/**
 * Configuration for week view (weekday labels)
 */
data class WeekViewConfig(
  var backgroundColor: Int = Color.WHITE,
  var weekendLabelColor: Int = "#FF9500".toColorInt(), // Orange like iOS
  var weekLabelColor: Int = Color.BLACK,
  var weekdayNames: Array<String> = arrayOf(
    "T2", "T3", "T4", "T5", "T6", "T7", "CN" // Vietnamese weekday names (Monday first)
  )
) : Serializable {
  override fun equals(other: Any?): Boolean {
    if (this === other) return true
    if (javaClass != other?.javaClass) return false

    other as WeekViewConfig

    if (backgroundColor != other.backgroundColor) return false
    if (weekendLabelColor != other.weekendLabelColor) return false
    if (weekLabelColor != other.weekLabelColor) return false
    if (!weekdayNames.contentEquals(other.weekdayNames)) return false

    return true
  }

  override fun hashCode(): Int {
    var result = backgroundColor
    result = 31 * result + weekendLabelColor
    result = 31 * result + weekLabelColor
    result = 31 * result + weekdayNames.contentHashCode()
    return result
  }
}

/**
 * Configuration for calendar behavior
 */
data class CalendarConfig(
  var timeZone: TimeZone = TimeZone.getDefault(),
  var locale: Locale = Locale.getDefault(),
  // Color properties used by optimized calendar
  var dateLabelColor: Int = Color.BLACK,
  var lunarDateLabelColor: Int = "#8E8E93".toColorInt(),
  var selectedBackgroundColor: Int = "#007AFF".toColorInt(),
  var selectedTextColor: Int = Color.WHITE,
  var rangeBackgroundColor: Int = "#E5F3FF".toColorInt()
) : Serializable
