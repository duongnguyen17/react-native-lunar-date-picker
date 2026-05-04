package com.margelo.nitro.lunardatepicker.utils

import android.util.Log
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicInteger

/**
 * Generic thread-safe object pool implementation
 * Reduces memory allocation and GC pressure by reusing objects
 */
abstract class ObjectPool<T>(
  private val maxSize: Int,
  private val resetObject: (T) -> Unit = {}
) {

  private val pool = ConcurrentLinkedQueue<T>()
  private val currentSize = AtomicInteger(0)

  // Statistics for monitoring
  private val acquiredCount = AtomicInteger(0)
  private val releasedCount = AtomicInteger(0)
  private val createdCount = AtomicInteger(0)

  /**
   * Abstract method to create new objects when pool is empty
   */
  protected abstract fun createObject(): T

  /**
   * Acquires an object from the pool, creating a new one if pool is empty
   */
  fun acquire(): T {
    val obj = pool.poll()
    return if (obj != null) {
      acquiredCount.incrementAndGet()
      obj
    } else {
      val newObj = createObject()
      createdCount.incrementAndGet()
      acquiredCount.incrementAndGet()
      newObj
    }
  }

  /**
   * Releases an object back to the pool
   * @param obj Object to release
   */
  fun release(obj: T) {
    if (currentSize.get() < maxSize) {
      try {
        resetObject(obj)
        pool.offer(obj)
        currentSize.incrementAndGet()
        releasedCount.incrementAndGet()
      } catch (e: Exception) {
        Log.w("ObjectPool", "Failed to reset object for pooling", e)
      }
    }
    // If pool is full, let object be GC'd
  }

  /**
   * Clears all objects from the pool
   */
  fun clear() {
    pool.clear()
    currentSize.set(0)
  }

  /**
   * Gets pool statistics for monitoring
   */
  fun getStats(): PoolStats {
    return PoolStats(
      poolSize = currentSize.get(),
      maxSize = maxSize,
      acquiredCount = acquiredCount.get(),
      releasedCount = releasedCount.get(),
      createdCount = createdCount.get(),
      hitRate = if (acquiredCount.get() > 0) {
        (acquiredCount.get() - createdCount.get()).toDouble() / acquiredCount.get()
      } else 0.0
    )
  }

  /**
   * Pool statistics data class
   */
  data class PoolStats(
    val poolSize: Int,
    val maxSize: Int,
    val acquiredCount: Int,
    val releasedCount: Int,
    val createdCount: Int,
    val hitRate: Double
  ) {
    override fun toString(): String {
      return "PoolStats(size=$poolSize/$maxSize, acquired=$acquiredCount, released=$releasedCount, created=$createdCount, hitRate=${
        "%.2f".format(
          hitRate * 100
        )
      }%)"
    }
  }
}

/**
 * Specialized pool for GradientDrawable objects used in calendar selection
 */
class GradientDrawablePool(
  maxSize: Int = DataConstants.Cache.DRAWABLE_POOL_SIZE
) : ObjectPool<android.graphics.drawable.GradientDrawable>(maxSize, { drawable ->
  // Reset drawable to clean state
  drawable.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
  drawable.setColor(android.graphics.Color.TRANSPARENT)
  drawable.cornerRadius = 0f
  drawable.setStroke(0, android.graphics.Color.TRANSPARENT)
}) {

  override fun createObject(): android.graphics.drawable.GradientDrawable {
    return android.graphics.drawable.GradientDrawable()
  }

  companion object {
    @Volatile
    private var INSTANCE: GradientDrawablePool? = null

    fun getInstance(): GradientDrawablePool {
      return INSTANCE ?: synchronized(this) {
        INSTANCE ?: GradientDrawablePool().also { INSTANCE = it }
      }
    }
  }
}

/**
 * Specialized pool for LunarDate data objects
 */
class LunarDatePool(
  maxSize: Int = DataConstants.Cache.DATA_POOL_SIZE
) : ObjectPool<MutableLunarDate>(maxSize, { lunarDate ->
  // Reset to default values
  lunarDate.day = 1
  lunarDate.month = 1
  lunarDate.year = 2000
}) {

  override fun createObject(): MutableLunarDate {
    return MutableLunarDate()
  }

  companion object {
    @Volatile
    private var INSTANCE: LunarDatePool? = null

    fun getInstance(): LunarDatePool {
      return INSTANCE ?: synchronized(this) {
        INSTANCE ?: LunarDatePool().also { INSTANCE = it }
      }
    }
  }
}

/**
 * Mutable version of LunarDate for pooling
 * Regular LunarDate is immutable data class, this allows reuse
 */
class MutableLunarDate(
  var day: Int = 1,
  var month: Int = 1,
  var year: Int = 2000
) {

  fun copyFrom(lunarDate: LunarDate) {
    this.day = lunarDate.day
    this.month = lunarDate.month
    this.year = lunarDate.year
  }

  fun toImmutable(): LunarDate {
    return LunarDate(day, month, year)
  }

  override fun toString(): String {
    return "MutableLunarDate(day=$day, month=$month, year=$year)"
  }
}

/**
 * Object pool manager for centralized pool access and monitoring
 */
object ObjectPoolManager {

  private const val TAG = "ObjectPoolManager"

  val gradientDrawablePool: GradientDrawablePool by lazy { GradientDrawablePool.getInstance() }
  val lunarDatePool: LunarDatePool by lazy { LunarDatePool.getInstance() }

  /**
   * Gets statistics for all pools
   */
  fun getAllPoolStats(): Map<String, Any> {
    return mapOf(
      "GradientDrawable" to gradientDrawablePool.getStats(),
      "LunarDate" to lunarDatePool.getStats()
    )
  }

  /**
   * Logs statistics for all pools
   */
  fun logPoolStats() {
    Log.i(TAG, "=== Object Pool Statistics ===")
    getAllPoolStats().forEach { entry ->
      Log.i(TAG, "${entry.key} Pool: ${entry.value}")
    }
  }

  /**
   * Clears all pools
   */
  fun clearAllPools() {
    gradientDrawablePool.clear()
    lunarDatePool.clear()
    Log.i(TAG, "All object pools cleared")
  }
}
