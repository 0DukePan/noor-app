package com.noor.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.util.Log

/**
 * 🕌 MosqueModeReceiver - وضع المسجد
 * يحول الهاتف للصامت تلقائيًا عند الصلاة
 */
class MosqueModeReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "MosqueModeReceiver"
        private const val PREFS_NAME = "mosque_mode_prefs"
        
        const val ACTION_ENABLE = "com.noor.app.ACTION_MOSQUE_MODE_ENABLE"
        const val ACTION_DISABLE = "com.noor.app.ACTION_MOSQUE_MODE_DISABLE"
        const val EXTRA_DURATION_MINUTES = "duration_minutes"
        
        /**
         * Enable mosque mode
         */
        fun enable(context: Context, durationMinutes: Int = 20) {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // Save current ringer mode
            val currentMode = audioManager.ringerMode
            prefs.edit().putInt("previous_ringer_mode", currentMode).apply()
            prefs.edit().putBoolean("is_active", true).apply()
            
            // Set to silent
            audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
            
            // Schedule auto-disable
            scheduleDisable(context, durationMinutes)
            
            Log.d(TAG, "Mosque mode enabled for $durationMinutes minutes")
            AdhanLogger.logAdhan(context, "mosque_mode", "system", "enabled")
        }
        
        /**
         * Disable mosque mode
         */
        fun disable(context: Context) {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // Check if mosque mode was active
            val wasActive = prefs.getBoolean("is_active", false)
            if (!wasActive) return
            
            // Restore previous ringer mode
            val previousMode = prefs.getInt("previous_ringer_mode", AudioManager.RINGER_MODE_NORMAL)
            audioManager.ringerMode = previousMode
            
            prefs.edit().putBoolean("is_active", false).apply()
            
            // Cancel any pending disable alarm
            cancelDisable(context)
            
            Log.d(TAG, "Mosque mode disabled, restored to mode: $previousMode")
            AdhanLogger.logAdhan(context, "mosque_mode", "system", "disabled")
        }
        
        /**
         * Check if mosque mode is currently active
         */
        fun isActive(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getBoolean("is_active", false)
        }
        
        /**
         * Schedule mosque mode at a specific time
         */
        fun scheduleAt(context: Context, timeMillis: Long, durationMinutes: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, MosqueModeReceiver::class.java).apply {
                action = ACTION_ENABLE
                putExtra(EXTRA_DURATION_MINUTES, durationMinutes)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                timeMillis.toInt(), // Use time as unique ID
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        timeMillis,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeMillis,
                    pendingIntent
                )
            }
        }
        
        private fun scheduleDisable(context: Context, durationMinutes: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, MosqueModeReceiver::class.java).apply {
                action = ACTION_DISABLE
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                8888, // Fixed ID for disable action
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val disableTime = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)
            
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                disableTime,
                pendingIntent
            )
        }
        
        private fun cancelDisable(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, MosqueModeReceiver::class.java).apply {
                action = ACTION_DISABLE
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                8888,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_ENABLE -> {
                val duration = intent.getIntExtra(EXTRA_DURATION_MINUTES, 20)
                enable(context, duration)
            }
            ACTION_DISABLE -> {
                disable(context)
            }
        }
    }
}
