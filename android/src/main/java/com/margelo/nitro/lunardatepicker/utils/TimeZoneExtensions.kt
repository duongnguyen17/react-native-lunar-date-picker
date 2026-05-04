package com.margelo.nitro.lunardatepicker.utils

import java.time.ZoneId
import java.util.TimeZone

/**
 * Extension method to convert java.util.TimeZone to java.time.ZoneId
 */
fun TimeZone.toZoneId(): ZoneId {
  return ZoneId.of(this.id)
}
