package com.margelo.nitro.lunardatepicker.utils

import android.util.Log
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import java.time.LocalDate
import java.time.ZoneId

object MemoryOptimizer {

  private const val TAG = DataConstants.LogTags.MAIN

  fun preloadObjectPools() {
    try {
      val gradientPool = ObjectPoolManager.gradientDrawablePool
      repeat(10) {
        val drawable = gradientPool.acquire()
        gradientPool.release(drawable)
      }

      val lunarPool = ObjectPoolManager.lunarDatePool
      repeat(20) {
        val lunarDate = lunarPool.acquire()
        lunarPool.release(lunarDate)
      }

      DimensionUtils.precomputeCommonDimensions()

      Log.i(TAG, "Object pools and dimensions preloaded successfully")
    } catch (e: Exception) {
      Log.e(TAG, "Failed to preload object pools", e)
    }
  }

  fun preloadLunarDateCache(
    dateConverter: DateConverter,
    timeZone: ZoneId = ZoneId.systemDefault()
  ) {
    try {
      val currentDate = LocalDate.now(timeZone)
      val startDate = currentDate.minusMonths(DataConstants.Calendar.MONTHS_TO_PRELOAD.toLong())
      val endDate = currentDate.plusMonths(DataConstants.Calendar.MONTHS_TO_PRELOAD.toLong())

      Log.i(TAG, "Preloading lunar date cache from $startDate to $endDate")
      dateConverter.preloadLunarDateCache(startDate, endDate, timeZone)

      Log.i(TAG, "Lunar date cache preloaded successfully")
    } catch (e: Exception) {
      Log.e(TAG, "Failed to preload lunar date cache", e)
    }
  }
}