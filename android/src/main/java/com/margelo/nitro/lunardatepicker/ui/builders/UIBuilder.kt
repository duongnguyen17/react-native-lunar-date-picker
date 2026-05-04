package com.margelo.nitro.lunardatepicker.ui.builders

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import com.margelo.nitro.lunardatepicker.constants.LayoutConstants
import com.margelo.nitro.lunardatepicker.constants.UIConstants
import com.margelo.nitro.lunardatepicker.models.PickerConfig

/**
 * Builder class for creating UI components
 */
class UIBuilder(
    private val context: Context,
    private val config: PickerConfig
) {
    
    /**
     * Creates the handle view for the bottom sheet
     */
    fun createHandleView(): View {
        val handleContainer = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(
                0,
                UIConstants.Handle.CONTAINER_TOP_PADDING,
                0,
                UIConstants.Handle.CONTAINER_BOTTOM_PADDING
            )
        }
        
        val handle = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                UIConstants.Handle.WIDTH,
                UIConstants.Handle.HEIGHT
            )
            setBackgroundColor(UIConstants.Handle.COLOR.toInt())
        }
        
        handleContainer.addView(handle)
        return handleContainer
    }
    
    /**
     * Creates the title view
     */
    fun createTitleView(): TextView {
        return TextView(context).apply {
            text = config.controller.title
            textSize = LayoutConstants.TextSize.TITLE
            setTextColor(config.controller.titleColor)
            gravity = Gravity.CENTER
            setPadding(
                LayoutConstants.Padding.TITLE_HORIZONTAL,
                LayoutConstants.Padding.TITLE_VERTICAL,
                LayoutConstants.Padding.TITLE_HORIZONTAL,
                LayoutConstants.Padding.TITLE_VERTICAL
            )
        }
    }
    
    /**
     * Creates the week view showing day names
     */
    fun createWeekView(): LinearLayout {
        val weekLayout = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            background = createRoundedBackground(
                config.weekView.backgroundColor,
                UIConstants.CornerRadius.DEFAULT
            )
            setPadding(
                0,
                LayoutConstants.Padding.WEEK_VIEW_ALL,
                0,
                LayoutConstants.Padding.WEEK_VIEW_ALL
            )
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(
                    LayoutConstants.Padding.WEEK_VIEW_HORIZONTAL,
                    0,
                    LayoutConstants.Padding.WEEK_VIEW_HORIZONTAL,
                    0
                )
            }
        }
        
        config.weekView.weekdayNames.forEachIndexed { index, dayName ->
            val textView = TextView(context).apply {
                text = dayName
                gravity = Gravity.CENTER
                textSize = LayoutConstants.TextSize.WEEK_DAY
                setTextColor(
                    if (index == 5 || index == 6) config.weekView.weekendLabelColor
                    else config.weekView.weekLabelColor
                )
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    LayoutConstants.Dimensions.WEIGHT_EQUAL
                )
            }
            weekLayout.addView(textView)
        }
        
        return weekLayout
    }
    
    /**
     * Creates a rounded background drawable
     */
    private fun createRoundedBackground(color: Int, cornerRadius: Float): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(color)
            this.cornerRadius = cornerRadius * context.resources.displayMetrics.density
        }
    }
} 