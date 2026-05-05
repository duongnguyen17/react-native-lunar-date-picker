package com.margelo.nitro.lunardatepicker.constants

/**
 * Data-related constants including bundle keys, formats, and calculation values
 */
object DataConstants {
    
    // Bundle keys
    object BundleKeys {
        const val ARG_CONFIG = "config"
        const val ARG_MODE = "mode"
        const val ARG_MIN_DATE = "min_date"
        const val ARG_MAX_DATE = "max_date"
        const val ARG_INITIAL_VALUE = "initial_value"
        const val ARG_NOTICE = "notice"
    }
    
    // Format strings
    object Format {
        const val PRICE_MILLION = "%.2ftr"
        const val PRICE_THOUSAND = "%.0fk"
        const val DATE_KEY = "%d-%02d-%02d"
        const val MONTH_KEY = "%d-%02d"
        const val LUNAR_FIRST_DAY = "%d/%d"
        const val LUNAR_OTHER_DAY = "%d"
        const val DATE_PADDING = "%02d"
        const val ISO_DATE = "dd/MM/yyyy"
    }
    
    // Numeric constants
    object Numeric {
        const val MILLION_DIVIDER = 1_000_000
        const val THOUSAND_DIVIDER = 1_000
        const val LUNAR_DAY_MOD = 30
        const val FIRST_DAY_OF_MONTH = 1
        const val FIFTEENTH_DAY_OF_MONTH = 15  // Special lunar day
        const val ZERO = 0
        const val ONE = 1
        const val TWO = 2
        const val THREE = 3
    }
    
    // Calendar constants
    object Calendar {
        const val LUNAR_MONTH_OFFSET = 0
        const val MONTH_RANGE_OFFSET = 2
        const val YEAR_RANGE_DEFAULT = 100
        const val MONTHS_TO_PRELOAD = 3
    }
    
    // Scroll and performance constants
    object Performance {
        const val DEBOUNCE_DELAY_DEFAULT = 0.6
        const val SCROLL_SETTLE_DELAY = 100L
        const val PRICE_UPDATE_BATCH_SIZE = 50
    }
    
    // Cache configuration constants
    object Cache {
        const val LUNAR_DATE_CACHE_SIZE = 1000  // ~3 years of calendar data
        const val CACHE_PRELOAD_MONTHS = 6     // Number of months to preload
        const val CACHE_CLEANUP_THRESHOLD = 0.8  // Clean when 80% full
        
        // Object pool sizes
        const val DRAWABLE_POOL_SIZE = 50      // Pool for GradientDrawable objects
        const val DATA_POOL_SIZE = 100         // Pool for data objects like LunarDate
        const val UI_POOL_SIZE = 30            // Pool for UI helper objects
    }
    
    // Log tags
    object LogTags {
        const val MAIN = "LunarDatePicker"
        const val FRAGMENT = "LunarDatePickerFragment"
        const val COORDINATOR = "LunarDatePickerCoordinator"
        const val CONFIG_BUILDER = "ConfigurationBuilder"
        const val DATE_CONVERTER = "DateConverter"
    }
} 