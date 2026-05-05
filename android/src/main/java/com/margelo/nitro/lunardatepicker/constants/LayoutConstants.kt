package com.margelo.nitro.lunardatepicker.constants

import com.margelo.nitro.lunardatepicker.utils.DimensionUtils.dpToPx
import com.margelo.nitro.lunardatepicker.utils.ScaleUtils

/**
 * Layout-related constants including paddings, margins, and dimensions
 */
object LayoutConstants {

    // Text sizes
    object TextSize {
        val TITLE = ScaleUtils.scale(16f)
        val MONTH_HEADER = ScaleUtils.scale(18f)
        val DAY_TEXT = ScaleUtils.scale(16f)
        val WEEK_DAY = ScaleUtils.scale(14f)
        val LUNAR_TEXT = ScaleUtils.scale(9f)
        val PRICE_TEXT = ScaleUtils.scale(7f)
    }

    // Padding values
    object Padding {
        const val TITLE_HORIZONTAL = 24
        const val TITLE_VERTICAL = 16
        const val MONTH_HEADER_HORIZONTAL = 0
        val MONTH_HEADER_TOP = dpToPx(16)
        val MONTH_HEADER_BOTTOM = ScaleUtils.scaleDp(8)
        val WEEK_VIEW_ALL = ScaleUtils.scaleDp(12)
        val MONTH_VIEW_HORIZONTAL = dpToPx(12)
        val WEEK_VIEW_HORIZONTAL = dpToPx(12)
        val CELL_VERTICAL = ScaleUtils.scaleDp(3)
    }

    // Margin values
    object Margin {
        const val MONTH_HEADER_VERTICAL = 0
        const val WEEK_VIEW_VERTICAL = 0
    }

    // Dimensions
    object Dimensions {
        const val MATCH_PARENT = android.view.ViewGroup.LayoutParams.MATCH_PARENT
        const val WRAP_CONTENT = android.view.ViewGroup.LayoutParams.WRAP_CONTENT
        const val WEIGHT_EQUAL = 1f
        const val WEIGHT_FULL = 1.0f
        val CLOSE_ICON_SIZE = dpToPx(ScaleUtils.scaleDp(20))
    }
}
