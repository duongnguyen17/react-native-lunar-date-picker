package com.margelo.nitro.lunardatepicker.models

import java.time.LocalDate

data class DateSelection(
  val startDate: LocalDate? = null,
  val endDate: LocalDate? = null
)
