package com.margelo.nitro.lunardatepicker.utils

import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.Collections
import java.util.Random
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LunarMonthSpanCacheTest {
    @Test
    fun matchesExactConversionAcrossGregorianYearsAndOffsets() {
        val zones = listOf(
            ZoneOffset.UTC,
            ZoneId.of("Asia/Ho_Chi_Minh"),
            ZoneOffset.ofHoursMinutes(5, 45),
        )
        val years = listOf(1600, 1700, 1800, 1900, 1969, 2000, 2012, 2023, 2024, 2100, 2200, 2399)

        for (zone in zones) {
            for (year in years) {
                val cache = LunarMonthSpanCache()
                val exactCalls = AtomicInteger()
                var date = LocalDate.of(year, 1, 1)
                val end = LocalDate.of(year, 12, 31)
                while (!date.isAfter(end)) {
                    assertMatchesExact(cache, date, zone, exactCalls)
                    date = date.plusDays(1)
                }
                assertTrue(
                    "Expected fewer exact calculations for $year in $zone: ${exactCalls.get()}",
                    exactCalls.get() < end.lengthOfYear() / 2,
                )
            }
        }
    }

    @Test
    fun matchesExactConversionForDateLineTransitionsAndDsts() {
        val cases = listOf(
            ZoneId.of("Pacific/Apia") to LocalDate.of(2011, 12, 20),
            ZoneId.of("Pacific/Kiritimati") to LocalDate.of(1994, 12, 20),
            ZoneId.of("America/New_York") to LocalDate.of(2024, 3, 1),
            ZoneId.of("America/New_York") to LocalDate.of(2024, 10, 20),
        )

        for ((zone, start) in cases) {
            val cache = LunarMonthSpanCache()
            val exactCalls = AtomicInteger()
            for (offset in 0L until 24L) {
                assertMatchesExact(cache, start.plusDays(offset), zone, exactCalls)
            }
        }
    }

    @Test
    fun randomReverseAccessMatchesExactAcrossLeapMonths() {
        val zone = ZoneId.of("Asia/Ho_Chi_Minh")
        val dates = (0L until 366L)
            .map { LocalDate.of(2023, 1, 1).plusDays(it) }
            .toMutableList()
        Collections.shuffle(dates, Random(0x1A2B3C))

        val cache = LunarMonthSpanCache()
        val exactCalls = AtomicInteger()
        dates.forEach { date -> assertMatchesExact(cache, date, zone, exactCalls) }

        assertTrue("Reverse access should reuse anchored month spans", exactCalls.get() < dates.size / 2)
    }

    @Test
    fun productionConverterWrapperUsesTheExactZoneOffsetAndSpanCache() {
        val date = LocalDate.of(2024, 3, 10)
        val zone = ZoneId.of("America/New_York")
        val cache = LunarMonthSpanCache()

        assertEquals(
            exact(date, zone),
            DateConverter.calculateWithMonthSpanCache(date, zone, cache),
        )
    }

    @Test
    fun anExactDay30CanBeReusedButMonthBoundaryNeedsExactMetadata() {
        val zone = ZoneId.of("Asia/Ho_Chi_Minh")
        val day30Date = datesBetween(LocalDate.of(2024, 1, 1), LocalDate.of(2024, 12, 31))
            .first { exact(it, zone).day == 30 }
        val day30Cache = LunarMonthSpanCache()
        val day30Calls = AtomicInteger()

        val exactDay30 = cachedExact(day30Cache, day30Date, zone, day30Calls)
        assertEquals(30, exactDay30.day)
        assertEquals(exactDay30, cachedExact(day30Cache, day30Date, zone, day30Calls))
        assertEquals("Exact day 30 may extend only its own span", 1, day30Calls.get())

        val dayOneStart = datesBetween(LocalDate.of(2023, 1, 1), LocalDate.of(2023, 11, 30))
            .firstOrNull { date ->
                exact(date, zone).day == 1 && exact(date.plusDays(29), zone).day == 1
            }
            ?: error("Expected a 29-day lunar month within 2023")
        val boundaryCache = LunarMonthSpanCache()
        val boundaryCalls = AtomicInteger()

        assertEquals(1, cachedExact(boundaryCache, dayOneStart, zone, boundaryCalls).day)
        val nextMonthDayOne = dayOneStart.plusDays(29)
        assertEquals(exact(nextMonthDayOne, zone), cachedExact(boundaryCache, nextMonthDayOne, zone, boundaryCalls))
        assertEquals("Next-month/year metadata must come from an exact conversion", 2, boundaryCalls.get())
    }

    @Test
    fun zoneAndGregorianYearArePartOfSpanIdentity() {
        val cache = LunarMonthSpanCache()
        val utc = ZoneOffset.UTC
        val hcm = ZoneId.of("Asia/Ho_Chi_Minh")
        val date = LocalDate.of(2024, 2, 10)
        val calls = AtomicInteger()

        val first = cachedExact(cache, date, utc, calls)
        val sameOffsetDifferentZone = cachedExact(cache, date, ZoneId.of("Etc/GMT"), calls)
        val otherZone = cachedExact(cache, date, hcm, calls)
        assertEquals(first, sameOffsetDifferentZone)
        assertEquals(exact(date, hcm), otherZone)
        assertEquals("Distinct zone identities require independent exact anchors", 3, calls.get())

        val yearBoundaryCache = LunarMonthSpanCache()
        val dec31 = LocalDate.of(2023, 12, 31)
        val jan1 = LocalDate.of(2024, 1, 1)
        val boundaryCalls = AtomicInteger()
        assertMatchesExact(yearBoundaryCache, dec31, utc, boundaryCalls)
        assertMatchesExact(yearBoundaryCache, jan1, utc, boundaryCalls)
        assertEquals("A Gregorian year change requires exact metadata", 2, boundaryCalls.get())
    }

    @Test
    fun datesOutsideValidatedGregorianRangeAlwaysUseExactConversion() {
        val cache = LunarMonthSpanCache()
        val zone = ZoneOffset.UTC
        val calls = AtomicInteger()
        val dates = listOf(
            LocalDate.of(1500, 6, 1),
            LocalDate.of(1582, 10, 14),
            LocalDate.of(1599, 12, 31),
            LocalDate.of(2400, 1, 1),
        )

        dates.forEach { assertMatchesExact(cache, it, zone, calls) }
        assertEquals("Unsafe and out-of-range years must not be inferred", dates.size, calls.get())
    }

    @Test
    fun boundedCacheRemainsCorrectUnderConcurrentAccess() {
        val cache = LunarMonthSpanCache(maxSpans = 4)
        val zone = ZoneId.of("Asia/Ho_Chi_Minh")
        val dates = (0L until 120L).map { LocalDate.of(2024, 1, 1).plusDays(it) }
        val pool = Executors.newFixedThreadPool(8)
        try {
            val tasks = dates.map { date ->
                Callable {
                    val calls = AtomicInteger()
                    repeat(8) {
                        assertEquals(exact(date, zone), cachedExact(cache, date, zone, calls))
                    }
                }
            }
            pool.invokeAll(tasks).forEach { it.get() }
        } finally {
            pool.shutdownNow()
        }
    }

    @Test
    fun printsHostExactCallAndTimingComparisonForSequentialCalendarAccess() {
        val zone = ZoneId.of("Asia/Ho_Chi_Minh")
        val dates = (0L until 365L * 3)
            .map { LocalDate.of(2021, 1, 1).plusDays(it) }
        val exactExpected = dates.map { exact(it, zone) }

        val exactStart = System.nanoTime()
        val exactRepeated = dates.map { exact(it, zone) }
        val exactElapsed = System.nanoTime() - exactStart
        assertEquals(exactExpected, exactRepeated)

        val cache = LunarMonthSpanCache()
        val exactCalls = AtomicInteger()
        val cachedStart = System.nanoTime()
        val inferred = dates.map { cachedExact(cache, it, zone, exactCalls) }
        val cachedElapsed = System.nanoTime() - cachedStart
        assertEquals(exactExpected, inferred)

        println(
            "lunar-span host benchmark: dates=${dates.size}, exactCalls=${exactCalls.get()}, " +
                "exactMs=${exactElapsed / 1_000_000.0}, spanMs=${cachedElapsed / 1_000_000.0}",
        )
    }

    private fun assertMatchesExact(
        cache: LunarMonthSpanCache,
        date: LocalDate,
        zone: ZoneId,
        exactCalls: AtomicInteger,
    ) {
        assertEquals(exact(date, zone), cachedExact(cache, date, zone, exactCalls))
    }

    private fun cachedExact(
        cache: LunarMonthSpanCache,
        date: LocalDate,
        zone: ZoneId,
        exactCalls: AtomicInteger,
    ): LunarDate {
        val offsetSeconds = date.atStartOfDay(zone).offset.totalSeconds
        return cache.getOrCalculate(date, zone, offsetSeconds) {
            exactCalls.incrementAndGet()
            VietnameseLunarDateCalculator.calculate(date, offsetSeconds / 3600.0)
        }
    }

    private fun exact(date: LocalDate, zone: ZoneId): LunarDate {
        val offsetSeconds = date.atStartOfDay(zone).offset.totalSeconds
        return OriginalDateConverterLunarOracle.calculate(date, offsetSeconds / 3600.0)
    }

    private fun datesBetween(start: LocalDate, endInclusive: LocalDate): Sequence<LocalDate> =
        generateSequence(start) { it.plusDays(1) }.takeWhile { !it.isAfter(endInclusive) }
}
