package com.margelo.nitro.lunardatepicker.constants

import com.margelo.nitro.lunardatepicker.utils.DimensionUtils.dpToPx
import com.margelo.nitro.lunardatepicker.utils.ScaleUtils

/**
 * UI-related constants
 */
object UIConstants {
    
    // Handle
    object Handle {
        val WIDTH = dpToPx(ScaleUtils.scaleDp(120))
        val HEIGHT = dpToPx(ScaleUtils.scaleDp(4))
        const val COLOR = 0xFFCCCCCC
        val CONTAINER_TOP_PADDING = ScaleUtils.scaleDp(12)
        val CONTAINER_BOTTOM_PADDING = ScaleUtils.scaleDp(8)
    }
    
    // Corner radius
    object CornerRadius {
        const val DEFAULT = 8f
    }
    
    // Day cell
    object DayCell {
        val SELECTED_CIRCLE_SIZE = dpToPx(ScaleUtils.scaleDp(42))
    }
    
    // Colors
    object Colors {
        const val TODAY_COLOR = android.graphics.Color.BLUE
        const val TRANSPARENT = android.graphics.Color.TRANSPARENT
    }
    
    // Alpha values
    object Alpha {
        const val DISABLED_DATE = 0.5f
        const val FULLY_VISIBLE = 1.0f
    }
    
    // Gravity
    object Gravity {
        const val CENTER = android.view.Gravity.CENTER
        const val START = android.view.Gravity.START
        const val END = android.view.Gravity.END
    }
    
    // Orientation
    object Orientation {
        const val VERTICAL = android.widget.LinearLayout.VERTICAL
        const val HORIZONTAL = android.widget.LinearLayout.HORIZONTAL
    }
    
    // Visibility
    object Visibility {
        const val VISIBLE = android.view.View.VISIBLE
        const val GONE = android.view.View.GONE
        const val INVISIBLE = android.view.View.INVISIBLE
    }
    
    // Shapes
    object Shapes {
        const val OVAL = android.graphics.drawable.GradientDrawable.OVAL
        const val RECTANGLE = android.graphics.drawable.GradientDrawable.RECTANGLE
    }
} 