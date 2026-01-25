package com.scrollmuch.scrollmuch

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.scrollmuch/scroll_tracker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTodayScrollMeters" -> {
                    val meters = getTodayScrollMeters()
                    result.success(meters)
                }
                "isServiceEnabled" -> {
                    val enabled = isAccessibilityServiceEnabled()
                    result.success(enabled)
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "setTrackingEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    setTrackingEnabled(enabled)
                    result.success(true)
                }
                "isTrackingEnabled" -> {
                    val enabled = isTrackingEnabled()
                    result.success(enabled)
                }
                "getScreenDpi" -> {
                    val dpi = resources.displayMetrics.densityDpi
                    result.success(dpi)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getTodayScrollMeters(): Double {
        val prefs = getSharedPreferences(ScrollAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
        val totalPixels = prefs.getLong(ScrollAccessibilityService.KEY_TOTAL_PIXELS, 0L)
        val dpi = resources.displayMetrics.densityDpi.toFloat()
        val inches = totalPixels / dpi
        return inches / ScrollAccessibilityService.INCHES_PER_METER
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "$packageName/${ScrollAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.let {
            TextUtils.SimpleStringSplitter(':').apply { setString(it) }
                .any { componentName -> componentName.equals(serviceName, ignoreCase = true) }
        } ?: false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun setTrackingEnabled(enabled: Boolean) {
        val prefs = getSharedPreferences(ScrollAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(ScrollAccessibilityService.KEY_TRACKING_ENABLED, enabled).apply()
    }

    private fun isTrackingEnabled(): Boolean {
        val prefs = getSharedPreferences(ScrollAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(ScrollAccessibilityService.KEY_TRACKING_ENABLED, true)
    }
}
