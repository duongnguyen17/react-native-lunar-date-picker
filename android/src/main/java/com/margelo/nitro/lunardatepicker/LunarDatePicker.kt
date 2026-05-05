package com.margelo.nitro.lunardatepicker

// Module imports
import android.util.Log
import com.facebook.proguard.annotations.DoNotStrip
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import com.margelo.nitro.lunardatepicker.coordinators.LunarDatePickerCoordinator
import com.margelo.nitro.lunardatepicker.exceptions.LunarDatePickerException
import com.margelo.nitro.lunardatepicker.services.ConfigurationCacheService
import com.margelo.nitro.lunardatepicker.utils.DateConverter
import com.margelo.nitro.lunardatepicker.utils.MemoryOptimizer
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
  private val configurationCacheService: ConfigurationCacheService by lazy {
    ConfigurationCacheService()
  }

  // MARK: - HybridLunarDatePickerSpec Implementation

  /**
   * Configures the global settings for the date picker
   * @param config Configuration parameters including themes, languages, etc.
   */
  override fun configure(config: LDP_ConfigParams) {
    try {
      

      // Apply configuration to coordinator
      coordinator.configure(config)

      // Initialize performance optimizations
      initializePerformanceOptimizations()

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

  // MARK: - Private Methods

  /**
   * Initializes performance optimizations including object pooling and caching
   */
  private fun initializePerformanceOptimizations() {
    try {
      // Preload object pools for better memory management
      MemoryOptimizer.preloadObjectPools()

      val configuredTimeZone = coordinator.getConfiguredTimeZone()

      // Preload lunar date cache for faster calculations
      MemoryOptimizer.preloadLunarDateCache(dateConverter, configuredTimeZone ?: java.time.ZoneId.systemDefault())

      Log.d(TAG, "Performance optimizations initialized")
    } catch (e: Exception) {
      Log.w(TAG, "Failed to initialize performance optimizations", e)
      // Continue without optimizations - don't fail configuration
    }
  }

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
