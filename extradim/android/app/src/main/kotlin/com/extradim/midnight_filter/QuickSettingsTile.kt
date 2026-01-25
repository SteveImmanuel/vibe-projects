package com.extradim.midnight_filter

import android.content.Intent
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class QuickSettingsTile : TileService() {
    
    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }
    
    override fun onClick() {
        super.onClick()
        
        if (!Settings.canDrawOverlays(this)) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivityAndCollapse(intent)
            return
        }
        
        if (OverlayService.isRunning) {
            stopOverlayService()
        } else {
            startOverlayService()
        }
        
        updateTileState()
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
    
    private fun updateTileState() {
        qsTile?.let { tile ->
            if (OverlayService.isRunning) {
                tile.state = Tile.STATE_ACTIVE
                tile.label = "Dim: ${(OverlayService.currentDimLevel * 100).toInt()}%"
            } else {
                tile.state = Tile.STATE_INACTIVE
                tile.label = "Midnight Filter"
            }
            tile.updateTile()
        }
    }
}
