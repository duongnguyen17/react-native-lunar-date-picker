package com.margelo.nitro.lunardatepicker.services

import java.time.ZoneOffset
import java.util.TimeZone
import kotlin.math.roundToInt

/** Resolves a fixed UTC offset or falls back to the device timezone. */
internal object PickerTimeZoneResolver {
  fun resolve(offsetHours: Double?): TimeZone {
    if (offsetHours == null) return TimeZone.getDefault()

    val offset = runCatching {
      ZoneOffset.ofTotalSeconds((offsetHours * SECONDS_PER_HOUR).roundToInt())
    }.getOrNull() ?: return TimeZone.getDefault()

    val zoneId = if (offset == ZoneOffset.UTC) "GMT+00:00" else "GMT${offset.id}"
    return TimeZone.getTimeZone(zoneId)
  }

  private const val SECONDS_PER_HOUR = 3600.0
}
