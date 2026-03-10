package com.noor.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 🔄 BootReceiver - Re-schedules all adhans after device reboot
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d(TAG, "Device booted, need to re-schedule adhans")
            
            // Note: In production, you would:
            // 1. Read saved prayer times from SharedPreferences
            // 2. Re-schedule all alarms using ExactAlarmReceiver
            // 3. This requires persisting scheduled alarms
            
            // For now, just log that we received the boot event
            // The Flutter app will re-schedule when opened
            
            AdhanLogger.logAdhan(context, "boot", "system", "device_booted")
        }
    }
}
