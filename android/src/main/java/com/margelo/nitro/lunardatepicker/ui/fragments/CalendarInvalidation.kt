package com.margelo.nitro.lunardatepicker.ui.fragments

import com.margelo.nitro.lunardatepicker.LDP_PriceData
import com.margelo.nitro.lunardatepicker.models.DateSelection
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.time.format.ResolverStyle
import java.util.Locale

/** Pure month selection for RecyclerView-backed calendar refreshes. A null result means full refresh. */
internal object CalendarInvalidation {
  private const val MAX_MONTHS = 6
  private val PRICE_DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/uuuu", Locale.ROOT)
    .withResolverStyle(ResolverStyle.STRICT)

  fun selectionMonths(
    previous: DateSelection,
    current: DateSelection,
    firstCalendarMonth: YearMonth,
    lastCalendarMonth: YearMonth
  ): Set<YearMonth>? {
    if (previous == current) return emptySet()
    val months = linkedSetOf<YearMonth>()
    if (!addSelectionMonths(months, previous, firstCalendarMonth, lastCalendarMonth)) {
      return null
    }
    if (!addSelectionMonths(months, current, firstCalendarMonth, lastCalendarMonth)) {
      return null
    }
    return months
  }

  fun priceMonths(
    previous: Map<String, LDP_PriceData>?,
    current: Map<String, LDP_PriceData>?,
    firstCalendarMonth: YearMonth,
    lastCalendarMonth: YearMonth
  ): Set<YearMonth>? {
    if ((previous == null) != (current == null)) return null
    if (previous == null || current == null) return emptySet()

    val months = linkedSetOf<YearMonth>()
    for ((date, oldPrice) in previous) {
      val newPrice = current[date]
      if (newPrice == null || !sameRenderedPrice(oldPrice, newPrice)) {
        if (!addPriceMonth(months, date, firstCalendarMonth, lastCalendarMonth)) return null
      }
    }
    for (date in current.keys) {
      if (!previous.containsKey(date)) {
        if (!addPriceMonth(months, date, firstCalendarMonth, lastCalendarMonth)) return null
      }
    }
    return months
  }

  private fun addSelectionMonths(
    months: MutableSet<YearMonth>,
    selection: DateSelection,
    firstCalendarMonth: YearMonth,
    lastCalendarMonth: YearMonth
  ): Boolean {
    val startDate = selection.startDate ?: return true
    val endDate = selection.endDate
    var firstMonth = YearMonth.from(minOf(startDate, endDate ?: startDate))
    var lastMonth = YearMonth.from(maxOf(startDate, endDate ?: startDate))
    if (endDate != null) {
      firstMonth = firstMonth.minusMonths(1)
      lastMonth = lastMonth.plusMonths(1)
    }
    return addMonthRange(months, firstMonth, lastMonth, firstCalendarMonth, lastCalendarMonth)
  }

  private fun addPriceMonth(
    months: MutableSet<YearMonth>,
    date: String,
    firstCalendarMonth: YearMonth,
    lastCalendarMonth: YearMonth
  ): Boolean {
    val parsedDate = try {
      LocalDate.parse(date, PRICE_DATE_FORMAT)
    } catch (_: DateTimeParseException) {
      return false
    }
    val month = YearMonth.from(parsedDate)
    if (month.isBefore(firstCalendarMonth) || month.isAfter(lastCalendarMonth)) return true
    months.add(month)
    return months.size <= MAX_MONTHS
  }

  private fun addMonthRange(
    months: MutableSet<YearMonth>,
    firstMonth: YearMonth,
    lastMonth: YearMonth,
    firstCalendarMonth: YearMonth,
    lastCalendarMonth: YearMonth
  ): Boolean {
    val first = maxOf(firstMonth, firstCalendarMonth)
    val last = minOf(lastMonth, lastCalendarMonth)
    if (last.isBefore(first)) return true

    var month = first
    while (!month.isAfter(last)) {
      months.add(month)
      if (months.size > MAX_MONTHS) return false
      month = month.plusMonths(1)
    }
    return true
  }

  private fun sameRenderedPrice(first: LDP_PriceData, second: LDP_PriceData): Boolean {
    return first.price == second.price && first.isCheapest == second.isCheapest
  }
}
