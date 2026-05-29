package com.scrollmuch.scrollmuch

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.provider.Settings
import android.text.TextUtils
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.scrollmuch/scroll_tracker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTodayScrollMeters" -> {
                    result.success(getTodayScrollMeters())
                }
                "getPerAppScrollMeters" -> {
                    result.success(getPerAppScrollMeters())
                }
                "getAppIcon" -> {
                    val pkg = call.argument<String>("package")
                    result.success(if (pkg != null) getAppIcon(pkg) else null)
                }
                "isServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
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
                    result.success(isTrackingEnabled())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pixelsToMeters(pixels: Long): Double {
        val dpi = resources.displayMetrics.densityDpi.toFloat()
        val inches = pixels / dpi
        return inches / ScrollAccessibilityService.INCHES_PER_METER
    }

    /// Per-app pixel totals for today, excluding hidden packages. The daily
    /// total is the sum of these, so it always matches the per-app list.
    private fun trackedPixels(): Map<String, Long> {
        val prefs = getSharedPreferences(ScrollAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
        val tracked = prefs.getStringSet(ScrollAccessibilityService.KEY_TRACKED_PACKAGES, emptySet()) ?: emptySet()
        val excluded = prefs.getStringSet(ScrollAccessibilityService.KEY_EXCLUDED_PACKAGES, emptySet()) ?: emptySet()

        val result = LinkedHashMap<String, Long>()
        for (pkg in tracked) {
            if (pkg in excluded) continue
            val pixels = prefs.getLong(ScrollAccessibilityService.KEY_APP_PIXELS_PREFIX + pkg, 0L)
            if (pixels > 0L) result[pkg] = pixels
        }
        return result
    }

    private fun getTodayScrollMeters(): Double {
        return pixelsToMeters(trackedPixels().values.sum())
    }

    private fun getPerAppScrollMeters(): List<Map<String, Any>> {
        val pm = packageManager
        return trackedPixels().entries
            .map { (pkg, pixels) ->
                val label = try {
                    pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
                } catch (e: Exception) {
                    pkg
                }
                mapOf(
                    "package" to pkg,
                    "label" to label,
                    "meters" to pixelsToMeters(pixels)
                )
            }
            .sortedByDescending { it["meters"] as Double }
    }

    private fun getAppIcon(pkg: String): String? {
        return try {
            val drawable = packageManager.getApplicationIcon(pkg)
            val size = 96
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
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
