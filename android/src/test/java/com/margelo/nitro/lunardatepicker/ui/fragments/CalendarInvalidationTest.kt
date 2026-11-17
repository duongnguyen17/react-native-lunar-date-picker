package com.margelo.nitro.lunardatepicker.ui.fragments

import com.margelo.nitro.lunardatepicker.LDP_PriceData
import com.margelo.nitro.lunardatepicker.models.DateSelection
import java.time.LocalDate
import java.time.YearMonth
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CalendarInvalidationTest {
  private val firstMonth = YearMonth.of(2024, 1)
  private val lastMonth = YearMonth.of(2024, 12)

  @Test
  fun unchangedSelectionDoesNotInvalidateMonths() {
    val selection = DateSelection(LocalDate.of(2024, 3, 10), LocalDate.of(2024, 3, 12))

    assertEquals(
      emptySet<YearMonth>(),
      CalendarInvalidation.selectionMonths(selection, selection, firstMonth, lastMonth)
    )
  }

  @Test
  fun selectionRefreshIncludesOldRangeAndNewSelectionWithBoundaryMonths() {
    val previous = DateSelection(LocalDate.of(2024, 1, 31), LocalDate.of(2024, 2, 1))
    val current = DateSelection(LocalDate.of(2024, 3, 15))

    assertEquals(
      setOf(YearMonth.of(2024, 1), YearMonth.of(2024, 2), YearMonth.of(2024, 3)),
      CalendarInvalidation.selectionMonths(previous, current, firstMonth, lastMonth)
    )
  }

  @Test
  fun selectionBoundaryMonthsAreClampedToCalendarBounds() {
    val completed = DateSelection(LocalDate.of(2024, 1, 1), LocalDate.of(2024, 1, 3))

    assertEquals(
      setOf(YearMonth.of(2024, 1)),
      CalendarInvalidation.selectionMonths(
        DateSelection(),
        completed,
        YearMonth.of(2024, 1),
        YearMonth.of(2024, 1)
      )
    )
  }

  @Test
  fun incompleteSingleDateRefreshesOnlyItsOwnMonth() {
    val selected = DateSelection(LocalDate.of(2024, 3, 15))

    assertEquals(
      setOf(YearMonth.of(2024, 3)),
      CalendarInvalidation.selectionMonths(DateSelection(), selected, firstMonth, lastMonth)
    )
  }

  @Test
  fun broadSelectionChangesUseFullRefreshFallback() {
    val previous = DateSelection(LocalDate.of(2024, 1, 1), LocalDate.of(2024, 5, 1))
    val current = DateSelection(LocalDate.of(2024, 7, 1))

    assertNull(CalendarInvalidation.selectionMonths(previous, current, firstMonth, lastMonth))
  }

  @Test
  fun unchangedPriceValuesDoNotInvalidateMonths() {
    val oldPrices = mapOf("12/03/2024" to price("12/03/2024", 100.0, false))
    val sameRenderedPrice = mapOf("12/03/2024" to price("12/03/2024", 100.0, false))

    assertEquals(
      emptySet<YearMonth>(),
      CalendarInvalidation.priceMonths(oldPrices, sameRenderedPrice, firstMonth, lastMonth)
    )
  }

  @Test
  fun priceReplacementIncludesChangedAndRemovedKeys() {
    val oldPrices = mapOf(
      "12/03/2024" to price("12/03/2024", 100.0, false),
      "15/04/2024" to price("15/04/2024", 200.0, false)
    )
    val newPrices = mapOf(
      "12/03/2024" to price("12/03/2024", 100.0, true),
      "20/05/2024" to price("20/05/2024", 300.0, false)
    )

    assertEquals(
      setOf(YearMonth.of(2024, 4), YearMonth.of(2024, 3), YearMonth.of(2024, 5)),
      CalendarInvalidation.priceMonths(oldPrices, newPrices, firstMonth, lastMonth)
    )
  }

  @Test
  fun togglingPriceAreaVisibilityUsesFullRefreshFallback() {
    assertNull(CalendarInvalidation.priceMonths(null, emptyMap(), firstMonth, lastMonth))
    assertNull(CalendarInvalidation.priceMonths(emptyMap(), null, firstMonth, lastMonth))
  }

  @Test
  fun invalidPriceDateUsesFullRefreshFallback() {
    val invalid = mapOf("not-a-date" to price("not-a-date", 100.0, false))

    assertNull(CalendarInvalidation.priceMonths(emptyMap(), invalid, firstMonth, lastMonth))
    val impossible = mapOf("31/02/2024" to price("31/02/2024", 100.0, false))
    assertNull(CalendarInvalidation.priceMonths(emptyMap(), impossible, firstMonth, lastMonth))
  }

  @Test
  fun priceChangesOutsideConfiguredMonthsDoNotInvalidateCalendar() {
    val outsidePrices = mapOf("12/12/2023" to price("12/12/2023", 100.0, false))

    assertEquals(
      emptySet<YearMonth>(),
      CalendarInvalidation.priceMonths(emptyMap(), outsidePrices, firstMonth, lastMonth)
    )
  }

  @Test
  fun priceChangesAcrossManyMonthsUseFullRefreshFallback() {
    val prices = (1..7).associate { month ->
      val date = "01/${month.toString().padStart(2, '0')}/2024"
      date to price(date, month.toDouble(), false)
    }

    assertNull(CalendarInvalidation.priceMonths(emptyMap(), prices, firstMonth, lastMonth))
  }

  private fun price(date: String, amount: Double, cheapest: Boolean) =
    LDP_PriceData(date, amount, cheapest)
}
