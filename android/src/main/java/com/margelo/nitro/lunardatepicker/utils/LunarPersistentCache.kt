package com.margelo.nitro.lunardatepicker.utils

import android.content.Context
import android.content.SharedPreferences
import com.margelo.nitro.NitroModules

class LunarPersistentCache private constructor(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun get(key: String): String? {
        return prefs.getString(key, null)
    }

    fun set(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    companion object {
        private const val PREFS_NAME = "LunarDatePickerCache"

        @Volatile
        private var INSTANCE: LunarPersistentCache? = null

        fun getInstance(): LunarPersistentCache {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: LunarPersistentCache(NitroModules.applicationContext as Context ).also { INSTANCE = it }
            }
        }
    }
}
