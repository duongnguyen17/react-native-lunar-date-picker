package com.margelo.nitro.lunardatepicker.utils

import android.util.LruCache
import com.margelo.nitro.lunardatepicker.LDP_Range
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.sin

data class LunarDate(val day: Int, val month: Int, val year: Int)

class DateConverter {

    companion object {
        private const val DAY_OFFSET = 2415021.076998695
        private const val LUNAR_MONTH_DAYS = 29.530588853
        private const val DAY_THRESHOLD = 2299161
        private const val DAY_CONSTANT = 32045
        private const val DAY_CONSTANT_OLD = 32083
        private val FORMATTER = DateTimeFormatter.ofPattern(DataConstants.Format.ISO_DATE)
    }

    private val inMemoryCache = LruCache<String, LunarDate>(1000)
    private val persistentCache = LunarPersistentCache.getInstance()

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

        val day = date.dayOfMonth
        val month = date.monthValue
        val year = date.year

        val dayNumber = jdFromDate(day, month, year)
        val timeZoneOffset = timeZone.rules.getOffset(date.atStartOfDay()).totalSeconds / 3600

        val (lunarYear, lunarMonth, lunarDay) = calculateLunarDate(
            dayNumber,
            timeZoneOffset.toInt(),
            date,
            year
        )

        val result = LunarDate(lunarDay, lunarMonth, lunarYear)

        inMemoryCache.put(cacheKey, result)
        persistentCache.set(cacheKey, "${result.day}|${result.month}|${result.year}")

        return result
    }

    fun preloadLunarDateCache(startDate: LocalDate, endDate: LocalDate, timeZone: ZoneId) {
        var currentDate = startDate
        while (!currentDate.isAfter(endDate)) {
            getVietnameseLunarDate(currentDate, timeZone)
            currentDate = currentDate.plusDays(1)
        }
    }

    private fun jdFromDate(day: Int, month: Int, year: Int): Int {
        val a = (14 - month) / 12
        val y = year + 4800 - a
        val m = month + 12 * a - 3
        val jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - DAY_CONSTANT
        return if (jd < DAY_THRESHOLD) {
            day + (153 * m + 2) / 5 + 365 * y + y / 4 - DAY_CONSTANT_OLD
        } else {
            jd
        }
    }

    private fun getNewMoonDay(k: Int, timeZone: Int): Int {
        val T = k.toDouble() / 1236.85
        val T2 = T * T
        val T3 = T2 * T
        val dr = PI / 180
        val Jd1 = 2415020.75933 + LUNAR_MONTH_DAYS * k + 0.0001178 * T2 - 0.000000155 * T3 +
                0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)

        val M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3
        val Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3
        val F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3

        var C1 = (0.1734 - 0.000393 * T) * sin(dr * M)
        C1 += 0.0021 * sin(2 * dr * M)
        C1 -= 0.4068 * sin(dr * Mpr)
        C1 += 0.0161 * sin(2 * dr * Mpr)
        C1 -= 0.0004 * sin(3 * dr * Mpr)
        C1 += 0.0104 * sin(2 * dr * F)
        C1 -= 0.0051 * sin(dr * (M + Mpr))
        C1 -= 0.0074 * sin(dr * (M - Mpr))
        C1 += 0.0004 * sin(dr * (2 * F + M))
        C1 -= 0.0004 * sin(dr * (2 * F - M))
        C1 -= 0.0006 * sin(dr * (2 * F + Mpr))
        C1 += 0.0010 * sin(dr * (2 * F - Mpr))
        C1 += 0.0005 * sin(dr * (2 * Mpr + M))

        val deltaT = if (T < -11) {
            0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3
        } else {
            -0.000278 + 0.000265 * T + 0.000262 * T2
        }

        val JdNew = Jd1 + C1 - deltaT
        return floor(JdNew + 0.5 + timeZone.toDouble() / 24).toInt()
    }

    private fun getSunLongitude(jdn: Int, timeZone: Int): Int {
        val T = (jdn.toDouble() - 2451545.5 - timeZone.toDouble() / 24) / 36525
        val T2 = T * T
        val dr = PI / 180
        val M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
        val L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2

        var DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(dr * M)
        DL += (0.019993 - 0.000101 * T) * sin(dr * 2 * M)
        DL += 0.000290 * sin(dr * 3 * M)

        var L = (L0 + DL) * dr
        L -= 2 * PI * floor(L / (2 * PI))
        return floor(L / PI * 6).toInt()
    }

    private fun getLunarMonth11(year: Int, timeZone: Int, date: LocalDate): Int {
        val endOfYear = LocalDate.of(year, 12, 31)
        val d = endOfYear.dayOfMonth
        val m = endOfYear.monthValue
        val y = endOfYear.year

        val off = jdFromDate(d, m, y) - 2415021
        val k = floor(off.toDouble() / 29.530588853).toInt()
        var nm = getNewMoonDay(k, timeZone)
        if (getSunLongitude(nm, timeZone) >= 9) {
            nm = getNewMoonDay(k - 1, timeZone)
        }
        return nm
    }

    private fun getLeapMonthOffset(a11: Int, timeZone: Int): Int {
        val k = floor((a11.toDouble() - 2415021.076998695) / 29.530588853 + 0.5).toInt()
        var last = getSunLongitude(getNewMoonDay(k + 1, timeZone), timeZone)
        for (i in 2..14) {
            val arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone)
            if (arc == last) return i - 1
            last = arc
        }
        return 0
    }

    private fun calculateLunarDate(
        dayNumber: Int,
        timeZone: Int,
        date: LocalDate,
        year: Int
    ): Triple<Int, Int, Int> {
        val k = floor((dayNumber.toDouble() - DAY_OFFSET) / LUNAR_MONTH_DAYS).toInt()
        var monthStart = getNewMoonDay(k + 1, timeZone)
        if (monthStart > dayNumber) {
            monthStart = getNewMoonDay(k, timeZone)
        }

        var a11 = getLunarMonth11(year, timeZone, date)
        var b11 = getLunarMonth11(year + 1, timeZone, date)
        var lunarYear = year + 1

        if (a11 >= monthStart) {
            lunarYear = year
            a11 = getLunarMonth11(year - 1, timeZone, date)
            b11 = getLunarMonth11(year, timeZone, date)
        }

        val lunarDay = dayNumber - monthStart + 1
        val diff = floor((monthStart - a11).toDouble() / 29).toInt()
        var lunarMonth = diff + 11

        if (b11 - a11 > 365) {
            val leapMonth = getLeapMonthOffset(a11, timeZone)
            if (diff >= leapMonth) {
                lunarMonth -= 1
            }
        }

        if (lunarMonth > 12) {
            lunarMonth -= 12
        }
        if (lunarMonth >= 11 && diff < 4) {
            lunarYear -= 1
        }

        return Triple(lunarYear, lunarMonth, lunarDay)
    }
}
