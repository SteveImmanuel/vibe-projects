package com.extradim.midnight_filter

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "com.extradim.midnight_filter/overlay"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        if (Settings.canDrawOverlays(this)) {
                            startOverlayService()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "stopService" -> {
                        stopOverlayService()
                        result.success(true)
                    }
                    "setDimLevel" -> {
                        val level = call.argument<Double>("level")?.toFloat() ?: 0.5f
                        updateDimLevel(level)
                        result.success(true)
                    }
                    "isServiceRunning" -> {
                        result.success(OverlayService.isRunning)
                    }
                    "getCurrentDimLevel" -> {
                        val prefs = getSharedPreferences(
                            OverlayService.PREFS_NAME, 
                            Context.MODE_PRIVATE
                        )
                        val level = prefs.getFloat(OverlayService.KEY_DIM_LEVEL, 0.5f)
                        result.success(level.toDouble())
                    }
                    "hasOverlayPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    }
                    "hasBatteryOptimization" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestBatteryOptimization" -> {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    override fun onResume() {
        super.onResume()
        notifyFlutterResume()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // Toggling the Quick Settings tile happens from the notification shade,
        // which steals window focus without pausing this activity — so onResume
        // doesn't fire. Re-sync when focus returns so the in-app toggle reflects
        // service changes made via the tile (or the notification "Turn Off").
        if (hasFocus) notifyFlutterResume()
    }

    private fun notifyFlutterResume() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onResume", null)
        }
    }
    
    private fun startOverlayService() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
        }
        startForegroundService(intent)
    }
    
    private fun stopOverlayService() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_STOP
        }
        startService(intent)
    }
    
    private fun updateDimLevel(level: Float) {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_UPDATE_DIM
            putExtra(OverlayService.EXTRA_DIM_LEVEL, level)
        }
        startService(intent)
    }
}
