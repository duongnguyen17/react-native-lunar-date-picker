package com.margelo.nitro.lunardatepicker.utils

import android.content.res.Resources
import java.util.concurrent.ConcurrentHashMap

object DimensionUtils {

  // Cache for dimension calculations to improve performance
  private val dimensionCache = ConcurrentHashMap<Int, Int>()
  private val floatDimensionCache = ConcurrentHashMap<Float, Int>()

  /**
   * Convert dp to px using system density (global) - with caching for performance
   */
  fun dpToPx(dp: Int): Int {
    return dimensionCache.getOrPut(dp) {
      (dp * Resources.getSystem().displayMetrics.density).toInt()
    }
  }

  /**
   * Convert dp to px using provided density
   */
  fun dpToPx(dp: Int, density: Float): Int {
    return (dp * density).toInt()
  }

  /**
   * Convert dp to px using system density (global) - Float version with caching
   */
  fun dpToPx(dp: Float): Int {
    return floatDimensionCache.getOrPut(dp) {
      (dp * Resources.getSystem().displayMetrics.density).toInt()
    }
  }

  /**
   * Convert dp to px using provided density - Float version
   */
  fun dpToPx(dp: Float, density: Float): Int {
    return (dp * density).toInt()
  }

  /**
   * Get system density
   */
  fun getDensity(): Float {
    return Resources.getSystem().displayMetrics.density
  }

  /**
   * Pre-compute commonly used dimensions to improve performance
   * Call this once during app initialization
   */
  fun precomputeCommonDimensions() {
    // Pre-compute common dimension values used throughout the app
    val commonDpValues = intArrayOf(
      0, 1, 2, 3, 4, 8, 12, 16, 24, 42, 120 // Common values from constants
    )

    commonDpValues.forEach { dp ->
      dpToPx(dp) // This will cache the values
    }

    val commonFloatValues = floatArrayOf(
      0f, 3f, 4f, 8f, 12f, 16f
    )

    commonFloatValues.forEach { dp ->
      dpToPx(dp) // This will cache the values
    }
  }

  /**
   * Get cache statistics for performance monitoring
   */
  fun getCacheStats(): DimensionCacheStats {
    return DimensionCacheStats(
      intCacheSize = dimensionCache.size,
      floatCacheSize = floatDimensionCache.size,
      totalCachedValues = dimensionCache.size + floatDimensionCache.size
    )
  }

  /**
   * Clear dimension cache (useful for testing or memory cleanup)
   */
  fun clearCache() {
    dimensionCache.clear()
    floatDimensionCache.clear()
  }

  /**
   * Data class for cache statistics
   */
  data class DimensionCacheStats(
    val intCacheSize: Int,
    val floatCacheSize: Int,
    val totalCachedValues: Int
  ) {
    override fun toString(): String {
      return "DimensionCache(int=$intCacheSize, float=$floatCacheSize, total=$totalCachedValues)"
    }
  }
}
