package com.margelo.nitro.lunardatepicker.utils

import android.content.res.Resources
import kotlin.math.roundToInt

object ScaleUtils {

    private val displayMetrics = Resources.getSystem().displayMetrics
    private val screenWidthPx = displayMetrics.widthPixels.toFloat()
    private val screenHeightPx = displayMetrics.heightPixels.toFloat()
    private val density = displayMetrics.density

    // Use short dimension in dp like RN
    private val shortDp: Float by lazy {
        val widthDp = screenWidthPx / density
        val heightDp = screenHeightPx / density
        if (widthDp < heightDp) widthDp else heightDp
    }

    private const val guidelineBaseWidth = 375f

    private val widthRatio: Float by lazy {
        ((shortDp / guidelineBaseWidth) * 100f).roundToInt() / 100f
    }

    private val disableScale: Boolean by lazy { widthRatio <= 1f }

    fun scale(value: Float, factor: Float = 1f): Float {
        if (disableScale) return value
        val scaled = value + ((value * widthRatio) - value) * factor
        return ((scaled * 100f).roundToInt() / 100f)
    }

    fun scaleDp(dp: Int, factor: Float = 1f): Int {
        return scale(dp.toFloat(), factor).roundToInt()
    }
}

