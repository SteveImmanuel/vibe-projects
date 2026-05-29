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
        
        // OverlayService processes the start/stop Intent asynchronously, so
        // OverlayService.isRunning hasn't flipped yet at this point. Drive the
        // tile from the action we're taking so it toggles immediately instead
        // of waiting for the next onStartListening (shade reopen).
        val willBeActive = !OverlayService.isRunning
        if (willBeActive) {
            startOverlayService()
        } else {
            stopOverlayService()
        }

        updateTileState(willBeActive)
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
    
    private fun updateTileState(activeOverride: Boolean? = null) {
        val active = activeOverride ?: OverlayService.isRunning
        qsTile?.let { tile ->
            if (active) {
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
