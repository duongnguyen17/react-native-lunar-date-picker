package com.margelo.nitro.lunardatepicker.utils

import java.time.LocalDate
import java.time.ZoneId
import java.util.LinkedHashMap
import kotlin.math.floor

/**
 * Reuses exact lunar month metadata for dates within a known month.
 *
 * An exact result gives both the date's lunar day and the month/year metadata. From that pair we
 * can derive the month start and safely infer days 1 through 29. Day 30 is only reusable after an
 * exact calculation has confirmed that this particular month has a thirtieth day.
 */
internal class LunarMonthSpanCache(
    private val maxSpans: Int = DEFAULT_MAX_SPANS,
) {
    private data class SpanIdentity(
        val zoneId: String,
        val offsetSeconds: Int,
        val gregorianYear: Int,
        val startJdn: Long,
    )

    private data class BucketKey(
        val zoneId: String,
        val offsetSeconds: Int,
        val gregorianYear: Int,
        val synodicMonthIndex: Int,
    )

    private data class MonthSpan(
        val lunarMonth: Int,
        val lunarYear: Int,
        val hasDay30: Boolean,
    )

    private val spans = LinkedHashMap<SpanIdentity, MonthSpan>(maxSpans, LOAD_FACTOR, true)
    private val bucketIndex = HashMap<BucketKey, MutableSet<SpanIdentity>>()

    init {
        require(maxSpans > 0) { "maxSpans must be positive" }
    }

    fun getOrCalculate(
        date: LocalDate,
        timeZone: ZoneId,
        offsetSeconds: Int,
        calculateExact: () -> LunarDate,
    ): LunarDate {
        if (isSafeDate(date)) {
            infer(date, timeZone, offsetSeconds)?.let { return it }
        }

        val exact = calculateExact()
        recordExact(date, timeZone, offsetSeconds, exact)
        return exact
    }

    /** Records a result produced by the exact conversion oracle. */
    fun recordExact(date: LocalDate, timeZone: ZoneId, offsetSeconds: Int, lunarDate: LunarDate) {
        if (!isSafeDate(date) ||
            lunarDate.day !in FIRST_LUNAR_DAY..LAST_LUNAR_DAY ||
            lunarDate.month !in FIRST_LUNAR_MONTH..LAST_LUNAR_MONTH
        ) return

        val dateJdn = toGregorianJdn(date)
        val startJdn = dateJdn - (lunarDate.day - 1)
        val identity = SpanIdentity(
            zoneId = timeZone.id,
            offsetSeconds = offsetSeconds,
            gregorianYear = date.year,
            startJdn = startJdn,
        )
        val bucket = bucketKey(timeZone.id, offsetSeconds, date.year, startJdn)
        synchronized(spans) {
            val previous = spans[identity]
            val preservesExactDay30 = previous?.let {
                it.lunarMonth == lunarDate.month &&
                    it.lunarYear == lunarDate.year &&
                    it.hasDay30
            } == true
            if (previous == null) {
                bucketIndex.getOrPut(bucket) { LinkedHashSet() }.add(identity)
            }
            spans[identity] = MonthSpan(
                lunarMonth = lunarDate.month,
                lunarYear = lunarDate.year,
                hasDay30 = lunarDate.day.toLong() == LAST_LUNAR_DAY || preservesExactDay30,
            )
            while (spans.size > maxSpans) {
                val eldestIdentity = spans.entries.iterator().next().key
                spans.remove(eldestIdentity)
                val eldestBucket = bucketKey(
                    eldestIdentity.zoneId,
                    eldestIdentity.offsetSeconds,
                    eldestIdentity.gregorianYear,
                    eldestIdentity.startJdn,
                )
                bucketIndex[eldestBucket]?.let { identities ->
                    identities.remove(eldestIdentity)
                    if (identities.isEmpty()) bucketIndex.remove(eldestBucket)
                }
            }
        }
    }

    private fun infer(date: LocalDate, timeZone: ZoneId, offsetSeconds: Int): LunarDate? {
        val dateJdn = toGregorianJdn(date)
        val queryMonthIndex = synodicMonthIndex(dateJdn)
        synchronized(spans) {
            for (monthIndex in queryMonthIndex - MONTH_INDEX_SEARCH_RADIUS..queryMonthIndex + MONTH_INDEX_SEARCH_RADIUS) {
                val bucket = BucketKey(timeZone.id, offsetSeconds, date.year, monthIndex)
                for (identity in bucketIndex[bucket].orEmpty()) {
                    val span = spans[identity] ?: continue // Refreshes this entry in the access-order LRU.
                    val lunarDay = dateJdn - identity.startJdn + 1
                    val lastDay = if (span.hasDay30) LAST_LUNAR_DAY else MAX_INFERRED_DAY
                    if (lunarDay in FIRST_LUNAR_DAY..lastDay) {
                        return LunarDate(lunarDay.toInt(), span.lunarMonth, span.lunarYear)
                    }
                }
            }
            return null
        }
    }

    private fun isSafeDate(date: LocalDate): Boolean {
        val jdn = toGregorianJdn(date)
        return date.year in FIRST_SAFE_YEAR..LAST_SAFE_YEAR &&
            jdn >= FIRST_SAFE_GREGORIAN_JDN &&
            jdn <= Int.MAX_VALUE
    }

    private fun toGregorianJdn(date: LocalDate): Long = date.toEpochDay() + UNIX_EPOCH_JDN

    private fun synodicMonthIndex(jdn: Long): Int =
        floor((jdn - LUNAR_MONTH_EPOCH) / LUNAR_MONTH_DAYS).toInt()

    private fun bucketKey(
        zoneId: String,
        offsetSeconds: Int,
        gregorianYear: Int,
        startJdn: Long,
    ): BucketKey = BucketKey(zoneId, offsetSeconds, gregorianYear, synodicMonthIndex(startJdn))

    companion object {
        private const val DEFAULT_MAX_SPANS = 24
        private const val LOAD_FACTOR = 0.75f
        private const val UNIX_EPOCH_JDN = 2_440_588L
        private const val LUNAR_MONTH_EPOCH = 2_415_021.076998695
        private const val LUNAR_MONTH_DAYS = 29.530588853
        private const val FIRST_SAFE_GREGORIAN_JDN = 2_299_161L // 1582-10-15
        private const val FIRST_SAFE_YEAR = 1600
        private const val LAST_SAFE_YEAR = 2399
        private const val FIRST_LUNAR_DAY = 1L
        private const val FIRST_LUNAR_MONTH = 1
        private const val LAST_LUNAR_MONTH = 12
        private const val MAX_INFERRED_DAY = 29L
        private const val LAST_LUNAR_DAY = 30L
        private const val MONTH_INDEX_SEARCH_RADIUS = 1
    }
}
