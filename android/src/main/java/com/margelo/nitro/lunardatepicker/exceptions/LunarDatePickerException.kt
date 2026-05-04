package com.margelo.nitro.lunardatepicker.exceptions

/**
 * Exception types for LunarDatePicker
 */
sealed class LunarDatePickerException(
    message: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    /**
     * Thrown when unable to find a suitable context or activity for presentation
     */
    class NoContextAvailable(message: String = "Unable to find context for presentation") 
        : LunarDatePickerException(message)
    
    /**
     * Thrown when configuration parameters are invalid
     */
    class InvalidConfiguration(message: String = "Invalid configuration parameters provided") 
        : LunarDatePickerException(message)
    
    /**
     * Thrown when presentation fails
     */
    class PresentationFailed(message: String = "Failed to present the date picker") 
        : LunarDatePickerException(message)
    
    /**
     * Thrown when date conversion fails
     */
    class DateConversionError(message: String = "Failed to convert date") 
        : LunarDatePickerException(message)
    
    /**
     * Thrown when theme processing fails
     */
    class ThemeError(message: String = "Theme processing error") 
        : LunarDatePickerException(message)
} 