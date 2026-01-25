package com.extradim.midnight_filter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Point
import android.os.Build
import android.os.IBinder
import android.view.Display
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.view.WindowMetrics

class OverlayService : Service() {
    
    companion object {
        const val CHANNEL_ID = "midnight_filter_channel"
        const val NOTIFICATION_ID = 1001
        const val PREFS_NAME = "midnight_filter_prefs"
        const val KEY_DIM_LEVEL = "dim_level"
        const val KEY_IS_ACTIVE = "is_active"
        
        const val ACTION_START = "com.extradim.midnight_filter.START"
        const val ACTION_STOP = "com.extradim.midnight_filter.STOP"
        const val ACTION_UPDATE_DIM = "com.extradim.midnight_filter.UPDATE_DIM"
        const val EXTRA_DIM_LEVEL = "dim_level"
        
        var isRunning = false
            private set
        
        var currentDimLevel = 0.5f
            private set
    }
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var prefs: SharedPreferences? = null
    
    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        currentDimLevel = prefs?.getFloat(KEY_DIM_LEVEL, 0.5f) ?: 0.5f
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                startForeground(NOTIFICATION_ID, createNotification())
                showOverlay()
                isRunning = true
                savePref(KEY_IS_ACTIVE, true)
            }
            ACTION_STOP -> {
                hideOverlay()
                isRunning = false
                savePref(KEY_IS_ACTIVE, false)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            ACTION_UPDATE_DIM -> {
                val dimLevel = intent.getFloatExtra(EXTRA_DIM_LEVEL, currentDimLevel)
                updateDimLevel(dimLevel)
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        hideOverlay()
        isRunning = false
        super.onDestroy()
    }
    
    private fun showOverlay() {
        if (overlayView != null) return
        
        overlayView = View(this).apply {
            setBackgroundColor(Color.BLACK)
            alpha = currentDimLevel
        }
        
        val screenSize = getFullScreenSize()
        
        val params = WindowManager.LayoutParams(
            screenSize.x,
            screenSize.y,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        
        params.x = 0
        params.y = -100
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            params.layoutInDisplayCutoutMode = 
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        } else {
            params.layoutInDisplayCutoutMode = 
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        
        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun getFullScreenSize(): Point {
        val wm = windowManager ?: return Point(1080, 2400)
        
        val baseSize = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics: WindowMetrics = wm.maximumWindowMetrics
            Point(metrics.bounds.width(), metrics.bounds.height())
        } else {
            val display: Display? = wm.defaultDisplay
            val size = Point()
            display?.getRealSize(size)
            size
        }
        
        // add extra padding to ensure full coverage on devices with chin/nav bar/curved edges
        baseSize.x += 100
        baseSize.y += 400
        return baseSize
    }
    
    private fun hideOverlay() {
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        overlayView = null
    }
    
    private fun updateDimLevel(level: Float) {
        currentDimLevel = level.coerceIn(0f, 0.9f)
        overlayView?.alpha = currentDimLevel
        savePref(KEY_DIM_LEVEL, currentDimLevel)
    }
    
    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Midnight Filter Service",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows when screen dimming is active"
            setShowBadge(false)
        }
        
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.createNotificationChannel(channel)
    }
    
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val stopIntent = Intent(this, OverlayService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Midnight Filter Active")
            .setContentText("Screen dimmed to ${(currentDimLevel * 100).toInt()}%")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentIntent(pendingIntent)
            .addAction(
                Notification.Action.Builder(
                    null,
                    "Turn Off",
                    stopPendingIntent
                ).build()
            )
            .setOngoing(true)
            .build()
    }
    
    private fun savePref(key: String, value: Boolean) {
        prefs?.edit()?.putBoolean(key, value)?.apply()
    }
    
    private fun savePref(key: String, value: Float) {
        prefs?.edit()?.putFloat(key, value)?.apply()
    }
}
