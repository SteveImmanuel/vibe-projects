package com.scrollmuch.scrollmuch

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent
import java.time.LocalDate
import kotlin.math.abs

class ScrollAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private var dpi: Float = 0f

    companion object {
        const val PREFS_NAME = "scroll_tracker_prefs"
        const val KEY_TOTAL_PIXELS = "total_pixels"
        const val KEY_TRACKING_DATE = "tracking_date"
        const val KEY_TRACKING_ENABLED = "tracking_enabled"
        const val INCHES_PER_METER = 39.3701
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        dpi = resources.displayMetrics.densityDpi.toFloat()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_VIEW_SCROLLED) return

        if (!isTrackingEnabled()) return

        checkAndResetForNewDay()

        val scrollDeltaY = event.scrollDeltaY
        if (scrollDeltaY != Int.MIN_VALUE && scrollDeltaY != 0) {
            addScrollPixels(abs(scrollDeltaY).toLong())
        }
    }

    override fun onInterrupt() {}

    private fun isTrackingEnabled(): Boolean {
        return prefs.getBoolean(KEY_TRACKING_ENABLED, true)
    }

    private fun checkAndResetForNewDay() {
        val today = LocalDate.now().toString()
        val storedDate = prefs.getString(KEY_TRACKING_DATE, null)

        if (storedDate != today) {
            prefs.edit()
                .putLong(KEY_TOTAL_PIXELS, 0L)
                .putString(KEY_TRACKING_DATE, today)
                .apply()
        }
    }

    private fun addScrollPixels(pixels: Long) {
        val currentTotal = prefs.getLong(KEY_TOTAL_PIXELS, 0L)
        prefs.edit()
            .putLong(KEY_TOTAL_PIXELS, currentTotal + pixels)
            .apply()
    }

    fun getTotalMeters(): Double {
        val totalPixels = prefs.getLong(KEY_TOTAL_PIXELS, 0L)
        val inches = totalPixels / dpi
        return inches / INCHES_PER_METER
    }
}
