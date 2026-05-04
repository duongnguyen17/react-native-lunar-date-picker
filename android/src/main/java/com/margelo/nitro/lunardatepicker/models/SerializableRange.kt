package com.margelo.nitro.lunardatepicker.models

import java.io.Serializable
import com.margelo.nitro.lunardatepicker.LDP_Range

/**
 * Serializable wrapper for Range class
 */
data class SerializableRange(
    val from: String, // DD/MM/YYYY format
    val to: String?   // DD/MM/YYYY format
) : Serializable {

    /**
     * Converts to Range
     */
    fun toRange(): LDP_Range = LDP_Range(from, to)

    companion object {
        /**
         * Creates SerializableRange from Range
         */
        fun fromRange(range: LDP_Range): SerializableRange {
            return SerializableRange(range.from, range.to)
        }
    }
}
