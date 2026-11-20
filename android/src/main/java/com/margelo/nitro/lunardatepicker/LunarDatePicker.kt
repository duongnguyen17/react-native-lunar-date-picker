package com.margelo.nitro.lunardatepicker

// Module imports
import android.util.Log
import com.facebook.proguard.annotations.DoNotStrip
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import com.margelo.nitro.lunardatepicker.coordinators.LunarDatePickerCoordinator
import com.margelo.nitro.lunardatepicker.exceptions.LunarDatePickerException
import com.margelo.nitro.lunardatepicker.services.PickerTimeZoneResolver
import com.margelo.nitro.lunardatepicker.utils.DateConverter
import java.time.LocalDate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.margelo.nitro.NitroModules

@DoNotStrip
class LunarDatePicker : HybridLunarDatePickerSpec() {

  companion object {
    private const val TAG = DataConstants.LogTags.MAIN
  }

  // MARK: - Properties
  private val coordinator: LunarDatePickerCoordinator by lazy {
    LunarDatePickerCoordinator()
  }
  private val dateConverter: DateConverter by lazy {
    DateConverter()
  }
  private var currentConfig: LDP_ConfigParams? = null

  // MARK: - HybridLunarDatePickerSpec Implementation

  /**
   * Configures the global settings for the date picker
   * @param config Configuration parameters including themes, languages, etc.
   */
  override fun configure(config: LDP_ConfigParams) {
    try {
      // Apply configuration to coordinator
      coordinator.configure(config)
      currentConfig = config

      Log.d(TAG, "Configuration applied successfully")
    } catch (e: Exception) {
      Log.e(TAG, "Failed to configure: ${e.message}", e)
      throw LunarDatePickerException.InvalidConfiguration(e.message ?: "Invalid configuration")
    }
  }

  /**
   * Presents the date picker with the specified parameters
   * @param params Presentation parameters including mode, theme, language, etc.
   */
  override fun present(params: LDP_PresentParams) {
    try {
      // Validate presentation parameters
      validatePresentationParams(params)

      // Ensure we're presenting on main thread
      CoroutineScope(Dispatchers.Main).launch {
        coordinator.present(params)
      }

      Log.d(TAG, "Date picker presented successfully")
    } catch (e: Exception) {
      Log.e(TAG, "Failed to present: ${e.message}", e)
      throw LunarDatePickerException.PresentationFailed(e.message ?: "Presentation failed")
    }
  }

  /**
   * Cập nhật giá cho một tháng cụ thể
   * Có thể gọi khi calendar đang mở để cập nhật UI ngay lập tức
   */
  override fun updatePrices(params: LDP_PriceUpdateParams) {
    try {
      coordinator.updatePrices(params)
      Log.d(TAG, "Prices updated successfully")
    } catch (e: Exception) {
      Log.w(TAG, "Failed to update prices: ${e.message}", e)
    }
  }

  /**
   * Cập nhật maximumDate khi calendar đang mở
   */
  override fun updateMaximumDate(maximumDate: String) {
    try {
      coordinator.updateMaximumDate(maximumDate)
      Log.d(TAG, "Maximum date updated successfully")
    } catch (e: Exception) {
      Log.w(TAG, "Failed to update maximum date: ${e.message}", e)
    }
  }

  /**
   * Lấy thông tin ngày âm lịch cho một ngày dương lịch
   */
  override fun getLunarDate(solarDate: String, timeZoneOffset: Double?): LDP_LunarDate {
    val offset = timeZoneOffset ?: currentConfig?.timeZoneOffset ?: 7.0
    val timeZone = PickerTimeZoneResolver.resolve(offset).toZoneId()
    val localDate = parseSolarDate(solarDate)
      ?: throw LunarDatePickerException.InvalidConfiguration("Invalid date format: $solarDate")

    val lunar = dateConverter.getVietnameseLunarDate(localDate, timeZone)
    val isoDate = String.format("%04d-%02d-%02d", localDate.year, localDate.monthValue, localDate.dayOfMonth)
    return LDP_LunarDate(lunar.day.toDouble(), lunar.month.toDouble(), lunar.year.toDouble(), isoDate)
  }

  /**
   * Lấy danh sách ngày âm lịch cho toàn bộ một tháng dương lịch
   */
  override fun getLunarMonth(year: Double, month: Double, timeZoneOffset: Double?): Array<LDP_LunarDate> {
    val offset = timeZoneOffset ?: currentConfig?.timeZoneOffset ?: 7.0
    val timeZone = PickerTimeZoneResolver.resolve(offset).toZoneId()
    val y = year.toInt()
    val m = month.toInt()
    if (m < 1 || m > 12) {
      throw LunarDatePickerException.InvalidConfiguration("Invalid month: $month")
    }

    val firstDay = LocalDate.of(y, m, 1)
    val daysInMonth = firstDay.lengthOfMonth()
    val list = ArrayList<LDP_LunarDate>(daysInMonth)

    for (d in 1..daysInMonth) {
      val date = LocalDate.of(y, m, d)
      val lunar = dateConverter.getVietnameseLunarDate(date, timeZone)
      val isoDate = String.format("%04d-%02d-%02d", y, m, d)
      list.add(LDP_LunarDate(lunar.day.toDouble(), lunar.month.toDouble(), lunar.year.toDouble(), isoDate))
    }

    return list.toTypedArray()
  }

  private fun parseSolarDate(dateString: String): LocalDate? {
    return try {
      if (dateString.contains("-")) {
        val parts = dateString.split("-").map { it.toInt() }
        if (parts.size == 3) LocalDate.of(parts[0], parts[1], parts[2]) else null
      } else if (dateString.contains("/")) {
        val parts = dateString.split("/").map { it.toInt() }
        if (parts.size == 3) LocalDate.of(parts[2], parts[1], parts[0]) else null
      } else {
        null
      }
    } catch (e: Exception) {
      null
    }
  }


  // MARK: - Private Methods

  /**
   * Validates the presentation parameters
   * @param params Presentation parameters to validate
   * @throws LunarDatePickerException.InvalidConfiguration if validation fails
   */
  private fun validatePresentationParams(params: LDP_PresentParams) {
    // Get timezone from coordinator's configuration for validation
    val timeZone = coordinator.getConfiguredTimeZone()
    
    // Validate date ranges if provided
    val minimumDateString = params.minimumDate
    val maximumDateString = params.maximumDate

    if (minimumDateString != null && maximumDateString != null) {
      val minimumDate = dateConverter.dateFromString(minimumDateString, timeZone)
      val maximumDate = dateConverter.dateFromString(maximumDateString, timeZone)

      if (minimumDate == null) {
        throw LunarDatePickerException.InvalidConfiguration("Invalid minimum date format. Expected DD/MM/YYYY")
      }
      if (maximumDate == null) {
        throw LunarDatePickerException.InvalidConfiguration("Invalid maximum date format. Expected DD/MM/YYYY")
      }

      if (minimumDate >= maximumDate) {
        throw LunarDatePickerException.InvalidConfiguration("Minimum date must be less than maximum date")
      }
    }

    // Validate initial value if provided
    params.initialValue?.let { initialValue ->
      val fromDate = dateConverter.dateFromString(initialValue.from, timeZone)
      if (fromDate == null) {
        throw LunarDatePickerException.InvalidConfiguration("Invalid initial value 'from' date format. Expected DD/MM/YYYY")
      }

      initialValue.to?.let { toDateString ->
        val toDate = dateConverter.dateFromString(toDateString, timeZone)
        if (toDate == null) {
          throw LunarDatePickerException.InvalidConfiguration("Invalid initial value 'to' date format. Expected DD/MM/YYYY")
        }
        if (fromDate > toDate) {
          throw LunarDatePickerException.InvalidConfiguration("Initial value 'from' date must be less than or equal to 'to' date")
        }
      }
    }
  }
}
