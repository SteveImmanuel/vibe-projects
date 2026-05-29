package com.scrollmuch.scrollmuch

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import java.time.LocalDate
import kotlin.math.abs
import kotlin.math.sqrt

class ScrollAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private var dpi: Float = 0f
    private var maxPixelDelta: Int = 0
    private var wasTracking: Boolean = true
    private val fallbackScrolledApps = mutableSetOf<String>()
    private val handler = Handler(Looper.getMainLooper())
    private val gestureEndRunnables = mutableMapOf<String, Runnable>()

    // Last seen absolute scroll position per package, used to derive distance
    // when scrollDeltaX/Y is unreliable (apps commonly report 0 or ±1).
    private val lastScrollY = mutableMapOf<String, Int>()
    private val lastMaxScrollY = mutableMapOf<String, Int>()
    private val lastScrollX = mutableMapOf<String, Int>()
    private val lastMaxScrollX = mutableMapOf<String, Int>()
    // Packages that have produced a real pixel distance — they never need the
    // coarse 5cm gesture estimate, which would otherwise inflate their total.
    private val hasRealPixels = mutableSetOf<String>()

    // Packages whose scrolling should not be counted: our own app (so scrolling
    // the in-app list doesn't feed back into the total), the system UI shell,
    // and the home launcher(s).
    private val excludedPackages = mutableSetOf<String>()

    companion object {
        private const val FALLBACK_CM = 5.0
        private const val GESTURE_END_TIMEOUT_MS = 300L
        // A scroller whose total range is below this is treated as reporting
        // coarse/index units rather than pixels (e.g. Reddit's 0..66), so its
        // position deltas are ignored in favour of the gesture estimate.
        private const val COARSE_MAX_SCROLL = 500
        const val PREFS_NAME = "scroll_tracker_prefs"
        const val KEY_TRACKING_DATE = "tracking_date"
        const val KEY_TRACKING_ENABLED = "tracking_enabled"
        const val KEY_TRACKED_PACKAGES = "tracked_packages"
        const val KEY_EXCLUDED_PACKAGES = "excluded_packages"
        const val KEY_APP_PIXELS_PREFIX = "app_pixels_"
        const val INCHES_PER_METER = 39.3701
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        dpi = resources.displayMetrics.densityDpi.toFloat()
        // Reject implausible position jumps (scroller switches / teleports):
        // cap a single event's distance at a few screen heights.
        maxPixelDelta = (resources.displayMetrics.heightPixels.takeIf { it > 0 } ?: 3000) * 4

        excludedPackages.clear()
        excludedPackages.add(packageName)
        excludedPackages.add("com.android.systemui")
        excludedPackages.addAll(launcherPackages())
        // Persist so MainActivity hides these from the list/total too, including
        // any data accumulated before the exclusion existed.
        prefs.edit().putStringSet(KEY_EXCLUDED_PACKAGES, excludedPackages).apply()
    }

    private fun launcherPackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return packageManager.queryIntentActivities(intent, 0)
            .mapNotNull { it.activityInfo?.packageName }
            .toSet()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_VIEW_SCROLLED) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName in excludedPackages) return

        val tracking = isTrackingEnabled()
        // On resume, drop stale baselines so the first event doesn't register a
        // jump from wherever the user scrolled while tracking was paused.
        if (tracking && !wasTracking) clearBaselines()
        wasTracking = tracking
        if (!tracking) return

        checkAndResetForNewDay()

        val pixels = scrollDistancePixels(packageName, event)
        val pixelScale = isPixelScale(event.scrollY, event.maxScrollY) ||
            isPixelScale(event.scrollX, event.maxScrollX)

        if (pixels > 0L) {
            hasRealPixels.add(packageName)
            addScrollPixels(packageName, pixels)
            cancelGestureEndTimeout(packageName)
        } else if (pixelScale || packageName in hasRealPixels) {
            // Pixel-scale scroller that simply didn't move this event — don't
            // estimate; just clear any pending fallback.
            cancelGestureEndTimeout(packageName)
        } else {
            // Coarse / no-signal scroller (e.g. Reddit): estimate a fixed
            // distance once the gesture settles (debounced per app).
            fallbackScrolledApps.add(packageName)
            cancelGestureEndTimeout(packageName)
            scheduleGestureEndTimeout(packageName)
        }
    }

    /// Distance in pixels for this scroll event. Prefers a real per-event delta;
    /// otherwise derives it from the change in absolute scroll position.
    private fun scrollDistancePixels(pkg: String, event: AccessibilityEvent): Long {
        val dy = event.scrollDeltaY.let { if (it == Int.MIN_VALUE) 0 else it }
        val dx = event.scrollDeltaX.let { if (it == Int.MIN_VALUE) 0 else it }

        // Always refresh position baselines so they stay current either way.
        val yd = axisDelta(pkg, lastScrollY, lastMaxScrollY, event.scrollY, event.maxScrollY)
        val xd = axisDelta(pkg, lastScrollX, lastMaxScrollX, event.scrollX, event.maxScrollX)

        // Trust the per-event delta only when it carries a real magnitude;
        // many apps report 0 or direction-only ±1.
        if (abs(dx) > 1 || abs(dy) > 1) {
            return sqrt(dx.toDouble() * dx + dy.toDouble() * dy).toLong()
        }
        return sqrt(xd.toDouble() * xd + yd.toDouble() * yd).toLong()
    }

    /// A scroller reports pixel positions (not coarse/index units) when its
    /// position or total range is large.
    private fun isPixelScale(pos: Int, max: Int): Boolean {
        return pos >= COARSE_MAX_SCROLL || max >= COARSE_MAX_SCROLL
    }

    /// Gated absolute-position delta for one axis. Updates the baseline, then
    /// returns the movement in pixels, or 0 for coarse units, teleports, or
    /// scroller switches.
    private fun axisDelta(
        pkg: String,
        last: MutableMap<String, Int>,
        lastMax: MutableMap<String, Int>,
        pos: Int,
        max: Int
    ): Long {
        if (pos < 0) return 0L
        val prev = last[pkg]
        val prevMax = lastMax[pkg]
        // Only compare maxima when both are real positives, else a 0/-1 sentinel
        // would spuriously look like a 4x change.
        val scrollerChanged = prevMax != null && prevMax > 0 && max > 0 &&
            (max > prevMax * 4 || max * 4 < prevMax)
        last[pkg] = pos
        if (max >= 0) lastMax[pkg] = max
        if (prev == null || scrollerChanged) return 0L
        if (!isPixelScale(pos, max)) return 0L
        val d = abs(pos - prev)
        return if (d in 1..maxPixelDelta) d.toLong() else 0L
    }

    private fun clearBaselines() {
        lastScrollY.clear()
        lastMaxScrollY.clear()
        lastScrollX.clear()
        lastMaxScrollX.clear()
    }

    private fun scheduleGestureEndTimeout(packageName: String) {
        val runnable = Runnable {
            if (fallbackScrolledApps.remove(packageName)) {
                val fallbackPixels = (FALLBACK_CM / 100.0 * INCHES_PER_METER * dpi).toLong()
                checkAndResetForNewDay()
                addScrollPixels(packageName, fallbackPixels)
            }
            gestureEndRunnables.remove(packageName)
        }

        gestureEndRunnables[packageName] = runnable
        handler.postDelayed(runnable, GESTURE_END_TIMEOUT_MS)
    }

    private fun cancelGestureEndTimeout(packageName: String) {
        gestureEndRunnables[packageName]?.let { runnable ->
            handler.removeCallbacks(runnable)
            gestureEndRunnables.remove(packageName)
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
        gestureEndRunnables.clear()
        fallbackScrolledApps.clear()
        hasRealPixels.clear()
        clearBaselines()
    }

    private fun isTrackingEnabled(): Boolean {
        return prefs.getBoolean(KEY_TRACKING_ENABLED, true)
    }

    private fun checkAndResetForNewDay() {
        val today = LocalDate.now().toString()
        val storedDate = prefs.getString(KEY_TRACKING_DATE, null)

        if (storedDate != today) {
            // Drop any fallback gestures and stale positions pending from the
            // previous day so nothing is credited to the new day's reset.
            handler.removeCallbacksAndMessages(null)
            gestureEndRunnables.clear()
            fallbackScrolledApps.clear()
            clearBaselines()

            val editor = prefs.edit()
            val tracked = prefs.getStringSet(KEY_TRACKED_PACKAGES, emptySet()) ?: emptySet()
            for (pkg in tracked) {
                editor.remove(KEY_APP_PIXELS_PREFIX + pkg)
            }
            editor.remove(KEY_TRACKED_PACKAGES)
            editor.putString(KEY_TRACKING_DATE, today)
            editor.apply()
        }
    }

    private fun addScrollPixels(packageName: String, pixels: Long) {
        if (pixels <= 0L) return

        val editor = prefs.edit()

        val appKey = KEY_APP_PIXELS_PREFIX + packageName
        val newAppTotal = prefs.getLong(appKey, 0L) + pixels
        editor.putLong(appKey, newAppTotal)

        val tracked = prefs.getStringSet(KEY_TRACKED_PACKAGES, emptySet()) ?: emptySet()
        if (!tracked.contains(packageName)) {
            editor.putStringSet(KEY_TRACKED_PACKAGES, tracked + packageName)
        }

        editor.apply()
    }
}
