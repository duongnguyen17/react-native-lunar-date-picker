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
import com.margelo.nitro.lunardatepicker.LDP_PriceData
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import com.margelo.nitro.lunardatepicker.constants.LayoutConstants
import com.margelo.nitro.lunardatepicker.constants.UIConstants
import com.margelo.nitro.lunardatepicker.models.PickerConfig
import com.margelo.nitro.lunardatepicker.utils.ContinuousSelectionHelper.isInDateBetweenSelection
import com.margelo.nitro.lunardatepicker.utils.ContinuousSelectionHelper.isOutDateBetweenSelection
import com.margelo.nitro.lunardatepicker.utils.DateConverter
import com.margelo.nitro.lunardatepicker.utils.DimensionUtils.dpToPx
import com.margelo.nitro.lunardatepicker.utils.ObjectPoolManager
import com.margelo.nitro.lunardatepicker.utils.ScaleUtils
import java.time.LocalDate
import java.time.ZoneId

class DayViewHolder(
  view: View,
  private val config: PickerConfig,
  private val dateConverter: DateConverter,
  private val timeZone: ZoneId,
  private val isDateEnabled: (LocalDate) -> Boolean,
  private val onDateClick: (LocalDate) -> Unit,
  /**
   * Map giá: key = "DD/MM/YYYY", value = LDP_PriceData
   * null = prices không được truyền vào → ẩn price area
   */
  private var priceMap: Map<String, LDP_PriceData>? = null
) : ViewContainer(view) {

  private lateinit var dayText: TextView
  private lateinit var lunarText: TextView
  private lateinit var priceText: TextView
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

  /**
   * Cập nhật price map và rebind view nếu cần
   */
  fun updatePriceMap(newPriceMap: Map<String, LDP_PriceData>?) {
    this.priceMap = newPriceMap
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
        FrameLayout.LayoutParams.MATCH_PARENT
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
      includeFontPadding = false
    }

    lunarText = TextView(context).apply {
      gravity = Gravity.CENTER
      textSize = LayoutConstants.TextSize.LUNAR_TEXT
      includeFontPadding = false
    }

    priceText = TextView(context).apply {
      gravity = Gravity.CENTER
      textSize = if (config.calendar.showLunarDate) {
        LayoutConstants.TextSize.PRICE_TEXT
      } else {
        ScaleUtils.scale(9f)
      }
      includeFontPadding = false
      visibility = View.GONE
    }

    selectionContainer = LinearLayout(context).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.CENTER
      setPadding(
        dpToPx(ScaleUtils.scaleDp(2)),
        0,
        dpToPx(ScaleUtils.scaleDp(2)),
        0
      )
      layoutParams = LinearLayout.LayoutParams(
        UIConstants.DayCell.SELECTED_CIRCLE_SIZE,
        UIConstants.DayCell.SELECTED_CIRCLE_SIZE
      )
    }

    selectionContainer.addView(dayText)
    selectionContainer.addView(lunarText)
    selectionContainer.addView(priceText)

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
    priceText.visibility = View.GONE
    priceText.text = ""
    lunarText.visibility = View.VISIBLE
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

    if (config.calendar.showLunarDate) {
      val lunarInfo = getLunarDateInfo(data.date)
      lunarText.apply {
        visibility = View.VISIBLE
        text = lunarInfo.text
        setTextColor(lunarInfo.color)
      }
    } else {
      lunarText.visibility = View.GONE
      lunarText.text = ""
    }

    // Configure price label
    configurePriceLabel(data.date)

    if (!isDateEnabled(data.date)) {
      dayText.alpha = UIConstants.Alpha.DISABLED_DATE
    } else {
      applyDateSelection(data.date)
    }
  }

  private fun configurePriceLabel(date: LocalDate) {
    val map = priceMap
    if (map == null) {
      // prices không được truyền vào → ẩn hoàn toàn
      priceText.visibility = View.GONE
      return
    }

    // prices được truyền vào (kể cả rỗng) → luôn dành chỗ
    priceText.visibility = View.VISIBLE

    val key = dateConverter.stringFromDate(date, timeZone) // DD/MM/YYYY
    val priceData = map[key]
    if (priceData != null) {
      priceText.text = formatPrice(priceData.price)
      priceText.setTextColor(
        if (priceData.isCheapest == true) config.dayCell.cheapestPriceLabelColor
        else config.dayCell.priceLabelColor
      )
    } else {
      priceText.text = " "
    }
  }

  /**
   * Format giá sang dạng "1.000K", "2.897K"
   * 1000000 / 1000 = 1000.000 → "1000.000K" — cần làm tròn tới phần nghìn thứ 3
   * Ví dụ: 1000000 → 1.000K, 2897000 → 2.897K
   */
  @SuppressLint("DefaultLocale")
  private fun formatPrice(price: Double): String {
    val thousands = (price / 1000.0).toLong()
    val format = java.text.DecimalFormat("#,###")
    val dfs = java.text.DecimalFormatSymbols()
    dfs.groupingSeparator = '.'
    format.decimalFormatSymbols = dfs
    return "${format.format(thousands)}K"
  }

  private fun applyDateSelection(date: LocalDate) {
    when {
      (date == selectedFromDate && date == selectedToDate) -> {
        applySelectedBackground()
      }

      selectedFromDate == date && selectedToDate == null -> {
        applySelectedBackground()
      }

      date == selectedFromDate -> {
        applySelectedBackground()
        rightRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
      }

      selectedFromDate != null && selectedToDate != null &&
        (date > selectedFromDate && date < selectedToDate) -> {
        rightRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
        leftRangeView.setBackgroundColor(config.dayCell.rangeBackgroundColor)
      }

      date == selectedToDate -> {
        applySelectedBackground()
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
    priceText.visibility = View.GONE
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

  private fun applySelectedBackground() {
    val bg = ObjectPoolManager.gradientDrawablePool.acquire().apply {
      shape = GradientDrawable.RECTANGLE
      cornerRadius = ScaleUtils.scale(12f)
      setColor(config.calendar.selectedBackgroundColor)
    }
    
    currentDrawable = bg
    
    selectionContainer.background = bg
    dayText.setTextColor(config.calendar.selectedTextColor)
    lunarText.setTextColor(config.calendar.selectedTextColor)
    priceText.setTextColor(config.calendar.selectedTextColor)
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