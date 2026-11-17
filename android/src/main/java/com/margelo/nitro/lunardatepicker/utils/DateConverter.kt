package com.margelo.nitro.lunardatepicker.utils

import android.util.LruCache
import com.margelo.nitro.lunardatepicker.LDP_Range
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive

data class LunarDate(val day: Int, val month: Int, val year: Int)

class DateConverter {

    companion object {
        private val FORMATTER = DateTimeFormatter.ofPattern(DataConstants.Format.ISO_DATE)
        private val lunarMonthSpanCache = LunarMonthSpanCache()

        internal fun calculateWithMonthSpanCache(
            date: LocalDate,
            timeZone: ZoneId,
            cache: LunarMonthSpanCache = lunarMonthSpanCache,
        ): LunarDate {
            val offsetSeconds = date.atStartOfDay(timeZone).offset.totalSeconds
            return cache.getOrCalculate(date, timeZone, offsetSeconds) {
                VietnameseLunarDateCalculator.calculate(date, offsetSeconds / 3600.0)
            }
        }
    }

    private val inMemoryCache = LruCache<String, LunarDate>(1000)
    private val persistentCache by lazy(LazyThreadSafetyMode.SYNCHRONIZED) {
        LunarPersistentCache.getInstance()
    }

    fun dateFromString(dateString: String, timeZone: ZoneId? = null): LocalDate? {
        return try {
            // If timezone is provided, parse with timezone consideration
            timeZone?.let { tz ->
                // Parse as LocalDate first, then adjust for timezone if needed
                LocalDate.parse(dateString, FORMATTER)
            } ?: LocalDate.parse(dateString, FORMATTER)
        } catch (e: Exception) {
            null
        }
    }

    fun stringFromDate(date: LocalDate, timeZone: ZoneId? = null): String {
        return date.format(FORMATTER)
    }

    fun rangeFromDates(fromDate: LocalDate, toDate: LocalDate, timeZone: ZoneId? = null): LDP_Range {
        return LDP_Range(
            from = stringFromDate(fromDate, timeZone),
            to = stringFromDate(toDate, timeZone)
        )
    }

    fun getVietnameseLunarDate(date: LocalDate, timeZone: ZoneId): LunarDate {
        val cacheKey = "${date.toEpochDay()}_${timeZone.id}"

        inMemoryCache.get(cacheKey)?.let { return it }

        persistentCache.get(cacheKey)?.let {
            val parts = it.split("|").map { part -> part.toInt() }
            val lunarDate = LunarDate(parts[0], parts[1], parts[2])
            inMemoryCache.put(cacheKey, lunarDate)
            return lunarDate
        }

        val result = calculateWithMonthSpanCache(date, timeZone)

        inMemoryCache.put(cacheKey, result)
        persistentCache.set(cacheKey, "${result.day}|${result.month}|${result.year}")

        return result
    }

    suspend fun preloadLunarDateCache(startDate: LocalDate, endDate: LocalDate, timeZone: ZoneId) {
        var currentDate = startDate
        while (!currentDate.isAfter(endDate)) {
            currentCoroutineContext().ensureActive()
            getVietnameseLunarDate(currentDate, timeZone)
            currentDate = currentDate.plusDays(1)
        }
    }
}
