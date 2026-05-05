package com.margelo.nitro.lunardatepicker.ui.viewholders

import android.annotation.SuppressLint
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.kizitonwose.calendar.core.CalendarDay
import com.kizitonwose.calendar.core.DayPosition
import com.kizitonwose.calendar.view.ViewContainer
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import com.margelo.nitro.lunardatepicker.constants.LayoutConstants
import com.margelo.nitro.lunardatepicker.constants.UIConstants
import com.margelo.nitro.lunardatepicker.models.PickerConfig
import com.margelo.nitro.lunardatepicker.utils.ContinuousSelectionHelper.isInDateBetweenSelection
import com.margelo.nitro.lunardatepicker.utils.ContinuousSelectionHelper.isOutDateBetweenSelection
import com.margelo.nitro.lunardatepicker.utils.DateConverter
import com.margelo.nitro.lunardatepicker.utils.DimensionUtils.dpToPx
import com.margelo.nitro.lunardatepicker.utils.ObjectPoolManager
import java.time.LocalDate
import java.time.ZoneId

class DayViewHolder(
  view: View,
  private val config: PickerConfig,
  private val dateConverter: DateConverter,
  private val timeZone: ZoneId,
  private val isDateEnabled: (LocalDate) -> Boolean,
  private val onDateClick: (LocalDate) -> Unit
) : ViewContainer(view) {

  private lateinit var dayText: TextView
  private lateinit var lunarText: TextView
  private lateinit var rootFrame: FrameLayout
  private lateinit var leftRangeView: View
  private lateinit var rightRangeView: View
  private lateinit var selectionContainer: LinearLayout

  var selectedFromDate: LocalDate? = null
  var selectedToDate: LocalDate? = null

  private var currentDrawable: GradientDrawable? = null

  companion object {
    // Today will be calculated per instance using timezone
  }

  init {
    setupViews()
  }

  private fun getTodayInTimezone(): LocalDate {
    return LocalDate.now(timeZone)
  }

  private fun setupViews() {
    val context = view.context

    rootFrame = FrameLayout(context).apply {
      layoutParams = FrameLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.WRAP_CONTENT
      )
    }

    val rangeContainer = LinearLayout(context).apply {
      orientation = LinearLayout.HORIZONTAL
      setPadding(
        0,
        dpToPx(LayoutConstants.Padding.CELL_VERTICAL),
        0,
        dpToPx(LayoutConstants.Padding.CELL_VERTICAL)
      )
      layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        UIConstants.DayCell.SELECTED_CIRCLE_SIZE
      )
    }

    leftRangeView = View(context).apply {
      layoutParams = LinearLayout.LayoutParams(
        0,
        LinearLayout.LayoutParams.MATCH_PARENT,
        LayoutConstants.Dimensions.WEIGHT_EQUAL
      )
    }

    rightRangeView = View(context).apply {
      layoutParams = LinearLayout.LayoutParams(
        0,
        LinearLayout.LayoutParams.MATCH_PARENT,
        LayoutConstants.Dimensions.WEIGHT_EQUAL
      )
    }

    rangeContainer.addView(leftRangeView)
    rangeContainer.addView(rightRangeView)

    val cellVertical = LinearLayout(context).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.CENTER
      layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.WRAP_CONTENT
      )
    }

    dayText = TextView(context).apply {
      gravity = Gravity.CENTER
      textSize = LayoutConstants.TextSize.DAY_TEXT
    }

    lunarText = TextView(context).apply {
      gravity = Gravity.CENTER
      textSize = LayoutConstants.TextSize.LUNAR_TEXT
    }

    selectionContainer = LinearLayout(context).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.CENTER
      layoutParams = LinearLayout.LayoutParams(
        UIConstants.DayCell.SELECTED_CIRCLE_SIZE,
        UIConstants.DayCell.SELECTED_CIRCLE_SIZE
      )
    }

    selectionContainer.addView(dayText)
    selectionContainer.addView(lunarText)

    cellVertical.addView(selectionContainer)

    rootFrame.addView(rangeContainer)
    rootFrame.addView(cellVertical)

    (view as? ViewGroup)?.let { viewGroup ->
      viewGroup.removeAllViews()
      viewGroup.addView(rootFrame)
    }
  }

  fun bind(data: CalendarDay) {
    resetViews()

    when (data.position) {
      DayPosition.MonthDate -> bindMonthDate(data)
      DayPosition.InDate -> bindInDateAndOutDate(data)
      DayPosition.OutDate -> bindOutDateAndInDate(data)
    }

    setupClickListener(data)
  }

  private fun resetViews() {
    currentDrawable?.let { drawable ->
      ObjectPoolManager.gradientDrawablePool.release(drawable)
      currentDrawable = null
    }
    
    selectionContainer.background = null
    rightRangeView.setBackgroundColor(UIConstants.Colors.TRANSPARENT)
    leftRangeView.setBackgroundColor(UIConstants.Colors.TRANSPARENT)
  }

  private fun bindMonthDate(data: CalendarDay) {
    // Check if it's weekend (Saturday = 6, Sunday = 7)
    val isWeekend = data.date.dayOfWeek.value >= 6
    
    val isToday = data.date == getTodayInTimezone()

    dayText.apply {
      // Set color based on whether it's weekend or not
      setTextColor(
        if (isWeekend) config.dayCell.weekendLabelColor 
        else config.dayCell.dateLabelColor
      )
      typeface = if (isToday) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
      text = data.date.dayOfMonth.toString()
      alpha = UIConstants.Alpha.FULLY_VISIBLE
    }

    val lunarInfo = getLunarDateInfo(data.date)
    lunarText.apply {
      text = lunarInfo.text
      setTextColor(lunarInfo.color)
    }

    if (!isDateEnabled(data.date)) {
      dayText.alpha = UIConstants.Alpha.DISABLED_DATE
    } else {
      applyDateSelection(data.date)
    }
  }

  private fun applyDateSelection(date: LocalDate) {
    when {
      (date == selectedFromDate && date == selectedToDate) -> {
        applySelectedCircle()
      }

      selectedFromDate == date && selectedToDate == null -> {
        applySelectedCircle()
      }

      date == selectedFromDate -> {
        applySelectedCircle()
        rightRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
      }

      selectedFromDate != null && selectedToDate != null &&
        (date > selectedFromDate && date < selectedToDate) -> {
        rightRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
        leftRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
      }

      date == selectedToDate -> {
        applySelectedCircle()
        leftRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
      }

      date == getTodayInTimezone() -> {
        dayText.apply {
          setTextColor(config.dayCell.todayLabelColor)
        }
      }
    }
  }

  private fun bindInDateAndOutDate(data: CalendarDay) {
    dayText.text = ""
    lunarText.text = ""
    selectionContainer.background = null

    if (selectedFromDate != null && selectedToDate != null) {
      when (data.position) {
        DayPosition.InDate -> {
          if (isInDateBetweenSelection(data.date, selectedFromDate!!, selectedToDate!!)) {
            rightRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
            leftRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
          }
        }

        DayPosition.OutDate -> {
          if (isOutDateBetweenSelection(data.date, selectedFromDate!!, selectedToDate!!)) {
            rightRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
            leftRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
          }
        }

        else -> {}
      }
    }
  }

  private fun bindOutDateAndInDate(data: CalendarDay) {
    bindInDateAndOutDate(data)
  }

  private fun applySelectedCircle() {
    val circle = ObjectPoolManager.gradientDrawablePool.acquire().apply {
      shape = GradientDrawable.OVAL
      setColor(config.calendar.selectedBackgroundColor)
    }
    
    currentDrawable = circle
    
    selectionContainer.background = circle
    dayText.setTextColor(config.calendar.selectedTextColor)
    lunarText.setTextColor(config.calendar.selectedTextColor)
  }

  private fun setupClickListener(data: CalendarDay) {
    if (isDateEnabled(data.date)) {
      rootFrame.setOnClickListener {
        onDateClick(data.date)
      }
    } else {
      rootFrame.setOnClickListener(null)
    }
  }

  private data class LunarDateInfo(
    val text: String,
    val color: Int
  )

  @SuppressLint("DefaultLocale")
  private fun getLunarDateInfo(date: LocalDate): LunarDateInfo {
    return try {
      val lunarDate = dateConverter.getVietnameseLunarDate(date, timeZone)
      
      val text = if (lunarDate.day == DataConstants.Numeric.FIRST_DAY_OF_MONTH) {
        String.format(DataConstants.Format.LUNAR_FIRST_DAY, lunarDate.day, lunarDate.month)
      } else {
        String.format(DataConstants.Format.LUNAR_OTHER_DAY, lunarDate.day)
      }
      
      val color = when (lunarDate.day) {
        DataConstants.Numeric.FIRST_DAY_OF_MONTH, 
        DataConstants.Numeric.FIFTEENTH_DAY_OF_MONTH -> config.dayCell.specialDateLabelColor
        else -> config.dayCell.lunarDateLabelColor
      }
      
      LunarDateInfo(text, color)
    } catch (_: Exception) {
      val fallbackText = "${date.dayOfMonth % DataConstants.Numeric.LUNAR_DAY_MOD}"
      LunarDateInfo(fallbackText, config.dayCell.lunarDateLabelColor)
    }
  }

  fun cleanup() {
    currentDrawable?.let { drawable ->
      ObjectPoolManager.gradientDrawablePool.release(drawable)
      currentDrawable = null
    }
  }
}