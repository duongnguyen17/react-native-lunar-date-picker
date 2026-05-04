package com.margelo.nitro.lunardatepicker.ui.viewholders

import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.kizitonwose.calendar.core.CalendarMonth
import com.kizitonwose.calendar.view.ViewContainer
import com.margelo.nitro.lunardatepicker.constants.LayoutConstants
import com.margelo.nitro.lunardatepicker.models.PickerConfig
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * ViewHolder for month headers in the calendar
 */
class MonthViewHolder(
    view: View,
    private val config: PickerConfig
) : ViewContainer(view) {
    
    private val monthText: TextView = TextView(view.context).apply {
        gravity = Gravity.START
        textSize = LayoutConstants.TextSize.MONTH_HEADER
        setTextColor(config.monthHeader.monthLabelColor)
        setPadding(
            LayoutConstants.Padding.MONTH_HEADER_HORIZONTAL,
            LayoutConstants.Padding.MONTH_HEADER_TOP,
            LayoutConstants.Padding.MONTH_HEADER_HORIZONTAL,
            LayoutConstants.Padding.MONTH_HEADER_BOTTOM
        )
    }
    
    init {
        setupViews()
    }
    
    private fun setupViews() {
        (view as? ViewGroup)?.let { viewGroup ->
            viewGroup.removeAllViews()
            viewGroup.addView(monthText)
        }
    }
    
    fun bind(data: CalendarMonth) {
        val locale: Locale = config.calendar.locale
        val formatter = DateTimeFormatter.ofPattern("LLLL yyyy", locale)
        monthText.text = data.yearMonth.atDay(1).format(formatter)
    }
} 