package com.margelo.nitro.lunardatepicker.services

import android.util.LruCache
import com.margelo.nitro.lunardatepicker.LDP_ConfigParams
import com.margelo.nitro.lunardatepicker.LDP_CustomLanguage
import com.margelo.nitro.lunardatepicker.LDP_CustomStyle
import com.margelo.nitro.lunardatepicker.LDP_Mode
import com.margelo.nitro.lunardatepicker.LDP_PresentParams
import com.margelo.nitro.lunardatepicker.models.PickerConfig
import java.security.MessageDigest
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

class ConfigurationCacheService {

  companion object {
    private const val TAG = "ConfigurationCache"
    private const val CONFIG_CACHE_SIZE = 50
    private const val TEMPLATE_CACHE_SIZE = 30
  }

  private val configurationCache: LruCache<String, PickerConfig> = LruCache(CONFIG_CACHE_SIZE)
  private val colorCache: ConcurrentHashMap<String, Int> = ConcurrentHashMap()
  private val templateCache: LruCache<String, ConfigurationTemplate> = LruCache(TEMPLATE_CACHE_SIZE)

  fun getOrBuildConfiguration(
    params: LDP_PresentParams,
    globalConfig: LDP_ConfigParams?
  ): PickerConfig {
    val cacheKey = generateConfigurationKey(params, globalConfig)
    configurationCache.get(cacheKey)?.let { return it }

    val config = buildConfigurationWithCache(params, globalConfig)
    configurationCache.put(cacheKey, config)
    return config
  }

  private fun buildConfigurationWithCache(
    params: LDP_PresentParams,
    globalConfig: LDP_ConfigParams?
  ): PickerConfig {
    var config = PickerConfig.default.copy()

    config = config.copy(
      controller = config.controller.copy(
        title = params.title,
        isSingleMode = params.mode == LDP_Mode.SINGLE
      )
    )

    globalConfig?.let { globalConf ->
      globalConf.themes[params.theme]?.let { theme ->
        globalConf.languages[params.language]?.let { language ->
          val template = getOrCreateTemplate(theme, language)
          config = applyTemplate(config, template)
        }
      }
      config = applyTimeZone(globalConf.timeZoneOffset, config)
      config = applyYearRange(globalConf.yearRangeOffset, config)
      config = config.copy(
        controller = config.controller.copy(
          showSubmitButton = globalConf.showSubmitButton
        )
      )
    }

    // Force showSubmitButton to false in single mode
    if (params.mode == LDP_Mode.SINGLE) {
      config = config.copy(
        controller = config.controller.copy(
          showSubmitButton = false
        )
      )
    }

    return config
  }

  private fun applyTemplate(config: PickerConfig, template: ConfigurationTemplate): PickerConfig {
    val normalizedTag = template.localeTag.replace('_', '-')
    val locale = Locale.forLanguageTag(normalizedTag).let { built ->
      if (built.language.isNullOrEmpty()) Locale.getDefault() else built
    }
    return config.copy(
      controller = config.controller.copy(
        backgroundColor = template.backgroundColor,
        titleColor = template.titleColor,
        secondaryTextColor = template.secondColor,
        submitButtonColor = template.submitButtonColor
      ),
      dayCell = config.dayCell.copy(
        dateLabelColor = template.dateLabelColor,
        todayLabelColor = template.todayLabelColor,
        weekendLabelColor = template.weekendLabelColor,
        lunarDateLabelColor = template.lunarDateLabelColor,
        specialDateLabelColor = template.specialDateLabelColor,
        rangeBackgroundColor = template.rangeBackgroundColor,
        selectedBackgroundColor = template.selectedBackgroundColor,
        selectedTextColor = template.selectedTextColor
      ),
      monthHeader = config.monthHeader.copy(
        labelColor = template.monthLabelColor
      ),
      weekView = config.weekView.copy(
        backgroundColor = template.weekViewBackgroundColor,
        weekendLabelColor = template.weekendLabelColor,
        weekLabelColor = template.weekLabelColor,
        weekdayNames = template.weekdayNames
      ),
      calendar = config.calendar.copy(
        locale = locale
      )
    )
  }

  private fun getOrCreateTemplate(
    theme: LDP_CustomStyle?,
    language: LDP_CustomLanguage?
  ): ConfigurationTemplate {
    val cacheKey = generateTemplateKey(theme, language)
    templateCache.get(cacheKey)?.let { return it }

    val template = createConfigurationTemplate(theme, language)
    templateCache.put(cacheKey, template)
    return template
  }

  private fun createConfigurationTemplate(
    theme: LDP_CustomStyle?,
    language: LDP_CustomLanguage?
  ): ConfigurationTemplate {
    val backgroundColor = if (theme != null) parseColor(theme.backgroundColor) else android.graphics.Color.WHITE
    val titleColor = if (theme != null) parseColor(theme.titleColor) else android.graphics.Color.BLACK
    val dateLabelColor = if (theme != null) parseColor(theme.dateLabelColor) else android.graphics.Color.BLACK
    val todayLabelColor = if (theme != null) parseColor(theme.todayLabelColor) else parseColor("#3B82F6")
    val weekendLabelColor = if (theme != null) parseColor(theme.weekendLabelColor) else parseColor("#FF9500")
    val lunarDateLabelColor = if (theme != null) parseColor(theme.lunarDateLabelColor) else parseColor("#8E8E93")
    val specialDateLabelColor = if (theme != null) parseColor(theme.specialDayLabelColor) else parseColor("#FF9500")
    val rangeBackgroundColor = if (theme != null) parseColor(theme.rangeBackgroundColor) else parseColor("#E5F3FF")
    val selectedBackgroundColor = if (theme != null) parseColor(theme.selectedBackgroundColor) else parseColor("#007AFF")
    val selectedTextColor = if (theme != null) parseColor(theme.selectedTextColor) else android.graphics.Color.WHITE
    val monthLabelColor = if (theme != null) parseColor(theme.monthLabelColor) else android.graphics.Color.BLACK
    val weekViewBackgroundColor = if (theme != null) parseColor(theme.weekViewBackgroundColor) else android.graphics.Color.WHITE
    val weekLabelColor = if (theme != null) parseColor(theme.dateLabelColor) else android.graphics.Color.BLACK
    val weekdayNames = language?.weekdayNames ?: arrayOf("T2", "T3", "T4", "T5", "T6", "T7", "CN")
    val localeTag = language?.locale ?: Locale.getDefault().toLanguageTag()
    val secondColor = if (theme != null) parseColor(theme.secondColor) else android.graphics.Color.WHITE
    val submitButtonColor = if (theme != null) parseColor(theme.submitButtonColor) else android.graphics.Color.BLACK

    return ConfigurationTemplate(
      backgroundColor = backgroundColor,
      titleColor = titleColor,
      dateLabelColor = dateLabelColor,
      todayLabelColor = todayLabelColor,
      weekendLabelColor = weekendLabelColor,
      lunarDateLabelColor = lunarDateLabelColor,
      specialDateLabelColor = specialDateLabelColor,
      rangeBackgroundColor = rangeBackgroundColor,
      selectedBackgroundColor = selectedBackgroundColor,
      selectedTextColor = selectedTextColor,
      monthLabelColor = monthLabelColor,
      weekViewBackgroundColor = weekViewBackgroundColor,
      weekLabelColor = weekLabelColor,
      weekdayNames = weekdayNames,
      localeTag = localeTag,
      secondColor = secondColor,
      submitButtonColor = submitButtonColor
    )
  }

  private fun parseColor(hex: String): Int {
    colorCache[hex]?.let { return it }
    val color = try {
      android.graphics.Color.parseColor(hex)
    } catch (e: IllegalArgumentException) {
      throw com.margelo.nitro.lunardatepicker.exceptions.LunarDatePickerException.ThemeError("Invalid hex color: $hex")
    }
    colorCache[hex] = color
    return color
  }

  private fun applyTimeZone(offset: Double, config: PickerConfig): PickerConfig {
    val timeZone = java.util.TimeZone.getTimeZone("GMT${if (offset >= 0) "+" else ""}${offset.toInt()}")
    return config.copy(calendar = config.calendar.copy(timeZone = timeZone))
  }

  private fun applyYearRange(offset: Double, config: PickerConfig): PickerConfig {
    return config.copy(yearRangeOffset = offset.toInt())
  }

  private fun generateConfigurationKey(params: LDP_PresentParams, globalConfig: LDP_ConfigParams?): String {
    val keyBuilder = StringBuilder()
    keyBuilder.append(params.theme).append("|")
    keyBuilder.append(params.language).append("|")
    keyBuilder.append(params.title).append("|")
    keyBuilder.append(params.mode.name).append("|")
    globalConfig?.let {
      keyBuilder.append(it.timeZoneOffset).append("|")
      keyBuilder.append(it.yearRangeOffset).append("|")
      keyBuilder.append(it.showSubmitButton).append("|")
    }
    return generateMD5Hash(keyBuilder.toString())
  }

  private fun generateTemplateKey(theme: LDP_CustomStyle?, language: LDP_CustomLanguage?): String {
    val keyBuilder = StringBuilder()
    theme?.let { t ->
      keyBuilder.append(t.backgroundColor).append(",")
      keyBuilder.append(t.titleColor).append(",")
      keyBuilder.append(t.dateLabelColor).append(",")
      keyBuilder.append(t.todayLabelColor).append(",")
      keyBuilder.append(t.lunarDateLabelColor).append(",")
      keyBuilder.append(t.selectedTextColor).append(",")
      keyBuilder.append(t.weekendLabelColor).append(",")
      keyBuilder.append(t.specialDayLabelColor).append(",")
      keyBuilder.append(t.monthLabelColor).append(",")
      keyBuilder.append(t.weekViewBackgroundColor).append(",")
      keyBuilder.append(t.selectedBackgroundColor).append(",")
      keyBuilder.append(t.rangeBackgroundColor).append(",")
      keyBuilder.append(t.submitButtonColor).append("|")
    }
    language?.let { l ->
      keyBuilder.append(l.weekdayNames.joinToString(",")).append("|")
    }
    return generateMD5Hash(keyBuilder.toString())
  }

  private fun generateMD5Hash(input: String): String {
    val md = MessageDigest.getInstance("MD5")
    val digest = md.digest(input.toByteArray())
    return digest.joinToString("") { "%02x".format(it) }
  }

  data class ConfigurationTemplate(
    val backgroundColor: Int,
    val titleColor: Int,
    val dateLabelColor: Int,
    val todayLabelColor: Int,
    val weekendLabelColor: Int,
    val lunarDateLabelColor: Int,
    val specialDateLabelColor: Int,
    val rangeBackgroundColor: Int,
    val selectedBackgroundColor: Int,
    val selectedTextColor: Int,
    val monthLabelColor: Int,
    val weekViewBackgroundColor: Int,
    val weekLabelColor: Int,
    val weekdayNames: Array<String>,
    val localeTag: String,
    val secondColor: Int,
    val submitButtonColor: Int
  )

  sealed class ValidationResult {
    object Valid : ValidationResult()
    data class Invalid(val error: String) : ValidationResult()
  }
}
