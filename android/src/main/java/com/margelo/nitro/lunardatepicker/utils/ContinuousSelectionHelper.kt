package com.margelo.nitro.lunardatepicker.utils

import com.kizitonwose.calendar.core.atStartOfMonth
import com.kizitonwose.calendar.core.nextMonth
import com.kizitonwose.calendar.core.previousMonth
import com.kizitonwose.calendar.core.yearMonth
import com.margelo.nitro.lunardatepicker.models.DateSelection
import java.time.LocalDate

object ContinuousSelectionHelper {
  fun getSelection(
    clickedDate: LocalDate,
    dateSelection: DateSelection,
  ): DateSelection {
    val (selectionStartDate, selectionEndDate) = dateSelection
    return if (clickedDate < selectionStartDate || selectionEndDate != null) {
      DateSelection(startDate = clickedDate, endDate = null)
    } else if (clickedDate != selectionStartDate) {
      DateSelection(startDate = selectionStartDate, endDate = clickedDate)
    } else {
      DateSelection(startDate = clickedDate, endDate = null)
    }

  }

  fun isInDateBetweenSelection(
    inDate: LocalDate,
    startDate: LocalDate,
    endDate: LocalDate,
  ): Boolean {
    if (startDate.yearMonth == endDate.yearMonth) return false
    if (inDate.yearMonth == startDate.yearMonth) return true
    val firstDateInThisMonth = inDate.yearMonth.nextMonth.atStartOfMonth()
    return firstDateInThisMonth in startDate..endDate && startDate != firstDateInThisMonth
  }

  fun isOutDateBetweenSelection(
    outDate: LocalDate,
    startDate: LocalDate,
    endDate: LocalDate,
  ): Boolean {
    if (startDate.yearMonth == endDate.yearMonth) return false
    if (outDate.yearMonth == endDate.yearMonth) return true
    val lastDateInThisMonth = outDate.yearMonth.previousMonth.atEndOfMonth()
    return lastDateInThisMonth in startDate..endDate && endDate != lastDateInThisMonth
  }
}
