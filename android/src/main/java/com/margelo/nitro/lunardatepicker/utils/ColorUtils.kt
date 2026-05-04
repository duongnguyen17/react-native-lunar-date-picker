package com.margelo.nitro.lunardatepicker.utils

import android.graphics.Color
import android.util.LruCache
import androidx.core.graphics.toColorInt
import com.margelo.nitro.lunardatepicker.exceptions.LunarDatePickerException

object ColorUtils {

    private val colorCache = LruCache<String, Int>(100)

    fun colorFromHex(hex: String): Int {
        colorCache.get(hex)?.let { return it }
        try {
            val color = hex.toColorInt()
            colorCache.put(hex, color)
            return color
        } catch (_: IllegalArgumentException) {
            throw LunarDatePickerException.ThemeError("Invalid hex color: $hex")
        }
    }

    fun colorWithAlpha(color: Int, alpha: Float): Int {
        val a = (alpha * 255).toInt().coerceIn(0, 255)
        return Color.argb(a, Color.red(color), Color.green(color), Color.blue(color))
    }
}