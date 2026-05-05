package com.margelo.nitro.lunardatepicker.coordinators

import android.util.Log
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.UiThreadUtil
import com.margelo.nitro.NitroModules
import com.margelo.nitro.lunardatepicker.LDP_ConfigParams
import com.margelo.nitro.lunardatepicker.LDP_PresentParams
import com.margelo.nitro.lunardatepicker.LDP_PriceData
import com.margelo.nitro.lunardatepicker.LDP_PriceUpdateParams
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import com.margelo.nitro.lunardatepicker.exceptions.LunarDatePickerException
import com.margelo.nitro.lunardatepicker.models.PickerConfig
import com.margelo.nitro.lunardatepicker.services.ConfigurationBuilder
import com.margelo.nitro.lunardatepicker.ui.fragments.LunarDatePickerFragment
import com.margelo.nitro.lunardatepicker.utils.DateConverter
import com.margelo.nitro.lunardatepicker.utils.toZoneId

class LunarDatePickerCoordinator(
  private val configurationBuilder: ConfigurationBuilder = ConfigurationBuilder(),
  private val dateConverter: DateConverter = DateConverter()
) {

  companion object {
    private const val TAG = DataConstants.LogTags.COORDINATOR
  }

  private var globalConfig: LDP_ConfigParams? = null
  private var currentFragment: LunarDatePickerFragment? = null

  fun cleanup() {
    currentFragment?.let { fragment ->
      if (fragment.isAdded && !fragment.isDetached) {
        fragment.dismiss()
      }
    }
    currentFragment = null
  }

  fun configure(config: LDP_ConfigParams) {
    this.globalConfig = config
    Log.d(TAG, "Global configuration applied")
  }

  fun getConfiguredTimeZone(): java.time.ZoneId? {
    return globalConfig?.let { config ->
      val timeZone = java.util.TimeZone.getTimeZone("GMT${if (config.timeZoneOffset >= 0) "+" else ""}${config.timeZoneOffset.toInt()}")
      timeZone.toZoneId()
    }
  }

  /**
   * Cập nhật giá theo tháng — merge vào fragment đang hiển thị nếu có
   */
  fun updatePrices(params: LDP_PriceUpdateParams) {
    val fragment = currentFragment ?: return
    // Convert LDP_PriceData list to map keyed by date (DD/MM/YYYY)
    val newMap: Map<String, LDP_PriceData> = params.prices.associateBy { it.date }
    UiThreadUtil.runOnUiThread {
      fragment.updatePrices(newMap)
    }
  }

  suspend fun present(params: LDP_PresentParams) {
    try {
      val activity = getCurrentActivity()
        ?: throw LunarDatePickerException.NoContextAvailable("No FragmentActivity available for presentation. Make sure your Activity extends FragmentActivity.")

      val pickerConfig = configurationBuilder.buildPickerConfig(params, globalConfig)

      UiThreadUtil.runOnUiThread {
        presentRangePicker(activity, params, pickerConfig)
      }

    } catch (e: Exception) {
      Log.e(TAG, "Failed to present date picker", e)
      when (e) {
        is LunarDatePickerException -> throw e
        else -> throw LunarDatePickerException.PresentationFailed("Presentation failed: ${e.message}")
      }
    }
  }

  private fun getCurrentActivity(): FragmentActivity? {
    return try {
      val context = NitroModules.applicationContext ?: return null
      val currentActivity = context.currentActivity
      currentActivity as? FragmentActivity
    } catch (e: Exception) {
      Log.w(TAG, "Failed to get current activity from NitroModules", e)
      null
    }
  }

  private fun presentRangePicker(
    activity: FragmentActivity,
    params: LDP_PresentParams,
    config: PickerConfig
  ) {
    try {
      val timeZone = getConfiguredTimeZone()

      // Build initial price map if prices are provided
      val priceMap: Map<String, LDP_PriceData>? = params.prices?.associateBy { it.date }

      val pickerFragment = LunarDatePickerFragment.newInstance(
        config = config,
        minimumDate = params.minimumDate?.let { dateConverter.dateFromString(it, timeZone) },
        maximumDate = params.maximumDate?.let { dateConverter.dateFromString(it, timeZone) },
        initialValue = params.initialValue,
        prices = priceMap,
        notice = params.notice,
        onMounted = params.onMounted,
        onSelectFromDate = params.onSelectFromDate,
        onResult = { result ->
          currentFragment = null
          params.onDone(result)
        }
      )

      currentFragment = pickerFragment
      pickerFragment.show(activity.supportFragmentManager, "LunarDatePickerRange")

    } catch (e: Exception) {
      Log.e(TAG, "Failed to present range picker", e)
      throw LunarDatePickerException.PresentationFailed("Failed to present range picker: ${e.message}")
    }
  }
}