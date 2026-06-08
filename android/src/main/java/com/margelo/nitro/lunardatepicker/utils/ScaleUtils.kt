package com.margelo.nitro.lunardatepicker.utils

import android.content.res.Resources
import kotlin.math.min
import kotlin.math.ceil

object ScaleUtils {

    private val displayMetrics = Resources.getSystem().displayMetrics
    private val screenWidthPx = displayMetrics.widthPixels.toFloat()
    private val density = displayMetrics.density

    private val screenWidthDp: Float by lazy {
        screenWidthPx / density
    }

    private const val BASE_WIDTH = 390f
    private const val MAX_WIDTH = 430f
    private const val BASE_SPACING = 4f

    fun scale(value: Float, factor: Float = 1f): Float {
        val calcWidth = min(screenWidthDp, MAX_WIDTH)
        val rawSize = (value / BASE_WIDTH) * calcWidth
        return ceil(rawSize)
    }

    fun scaleDp(dp: Int, factor: Float = 1f): Int {
        return scale(dp.toFloat(), factor).toInt()
    }

    fun spacing(multiplier: Number): Float {
        val designSize = BASE_SPACING * multiplier.toFloat()
        return scale(designSize)
    }

    fun spacingDp(multiplier: Number): Int {
        val designSize = BASE_SPACING * multiplier.toFloat()
        return scale(designSize).toInt()
    }
}


