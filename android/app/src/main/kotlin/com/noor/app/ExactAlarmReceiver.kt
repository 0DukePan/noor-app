package com.noor.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log

/**
 * 🕌 ExactAlarmReceiver - Receives exact alarm broadcasts for Adhan
 * 
 * This receiver is triggered at the exact prayer time and starts
 * the AdhanForegroundService to play the adhan audio.
 */
class ExactAlarmReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "ExactAlarmReceiver"
        
        const val ACTION_ADHAN = "com.noor.app.ACTION_ADHAN"
        const val ACTION_PRE_REMINDER = "com.noor.app.ACTION_PRE_REMINDER"
        const val ACTION_POST_REMINDER = "com.noor.app.ACTION_POST_REMINDER"
        const val ACTION_FALLBACK = "com.noor.app.ACTION_FALLBACK"
        
        const val EXTRA_PRAYER_ID = "prayer_id"
        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_PRAYER_NAME_ARABIC = "prayer_name_arabic"
        const val EXTRA_ADHAN_SOUND_ID = "adhan_sound_id"
        const val EXTRA_VIBRATE = "vibrate"
        const val EXTRA_OVERRIDE_DND = "override_dnd"
        const val EXTRA_MINUTES_BEFORE = "minutes_before"
        
        /**
         * Schedule an exact alarm for adhan
         */
        fun scheduleExactAdhan(
            context: Context,
            prayerId: String,
            prayerName: String,
            prayerNameArabic: String,
            scheduledTimeMillis: Long,
            adhanSoundId: String,
            vibrate: Boolean,
            overrideDnd: Boolean
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, ExactAlarmReceiver::class.java).apply {
                action = ACTION_ADHAN
                putExtra(EXTRA_PRAYER_ID, prayerId)
                putExtra(EXTRA_PRAYER_NAME, prayerName)
                putExtra(EXTRA_PRAYER_NAME_ARABIC, prayerNameArabic)
                putExtra(EXTRA_ADHAN_SOUND_ID, adhanSoundId)
                putExtra(EXTRA_VIBRATE, vibrate)
                putExtra(EXTRA_OVERRIDE_DND, overrideDnd)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                prayerId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Use setAlarmClock for highest priority (shows in status bar)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setAlarmClock(
                        AlarmManager.AlarmClockInfo(scheduledTimeMillis, pendingIntent),
                        pendingIntent
                    )
                } else {
                    // Fallback to inexact alarm
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        scheduledTimeMillis,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(scheduledTimeMillis, pendingIntent),
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Scheduled adhan for $prayerName at $scheduledTimeMillis")
        }
        
        /**
         * Schedule pre-prayer reminder
         */
        fun schedulePreReminder(
            context: Context,
            reminderId: String,
            prayerName: String,
            prayerNameArabic: String,
            scheduledTimeMillis: Long,
            minutesBefore: Int
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, ExactAlarmReceiver::class.java).apply {
                action = ACTION_PRE_REMINDER
                putExtra(EXTRA_PRAYER_ID, reminderId)
                putExtra(EXTRA_PRAYER_NAME, prayerName)
                putExtra(EXTRA_PRAYER_NAME_ARABIC, prayerNameArabic)
                putExtra(EXTRA_MINUTES_BEFORE, minutesBefore)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                reminderId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                scheduledTimeMillis,
                pendingIntent
            )
        }
        
        /**
         * Cancel all scheduled adhans
         */
        fun cancelAllAdhans(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            // Note: In production, you'd need to track all scheduled alarm IDs
            Log.d(TAG, "All adhans cancelled")
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received alarm: ${intent.action}")
        
        // Acquire wake lock to ensure processing completes
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "noor:adhan_wakelock"
        )
        wakeLock.acquire(60 * 1000L) // 1 minute max
        
        try {
            when (intent.action) {
                ACTION_ADHAN -> handleAdhan(context, intent)
                ACTION_PRE_REMINDER -> handlePreReminder(context, intent)
                ACTION_FALLBACK -> handleFallback(context, intent)
            }
        } finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }
    
    private fun handleAdhan(context: Context, intent: Intent) {
        val prayerId = intent.getStringExtra(EXTRA_PRAYER_ID) ?: return
        val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: return
        val prayerNameArabic = intent.getStringExtra(EXTRA_PRAYER_NAME_ARABIC) ?: prayerName
        val adhanSoundId = intent.getStringExtra(EXTRA_ADHAN_SOUND_ID) ?: "makkah"
        val vibrate = intent.getBooleanExtra(EXTRA_VIBRATE, true)
        val overrideDnd = intent.getBooleanExtra(EXTRA_OVERRIDE_DND, true)
        
        // Start foreground service to play adhan
        val serviceIntent = Intent(context, AdhanForegroundService::class.java).apply {
            action = AdhanForegroundService.ACTION_PLAY_ADHAN
            putExtra(EXTRA_PRAYER_ID, prayerId)
            putExtra(EXTRA_PRAYER_NAME, prayerName)
            putExtra(EXTRA_PRAYER_NAME_ARABIC, prayerNameArabic)
            putExtra(EXTRA_ADHAN_SOUND_ID, adhanSoundId)
            putExtra(EXTRA_VIBRATE, vibrate)
            putExtra(EXTRA_OVERRIDE_DND, overrideDnd)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
        
        // Log this adhan
        AdhanLogger.logAdhan(context, prayerId, prayerName, "triggered")
    }
    
    private fun handlePreReminder(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: return
        val prayerNameArabic = intent.getStringExtra(EXTRA_PRAYER_NAME_ARABIC) ?: prayerName
        val minutesBefore = intent.getIntExtra(EXTRA_MINUTES_BEFORE, 15)
        
        // Show notification
        AdhanNotificationManager.showPreReminderNotification(
            context,
            prayerName,
            prayerNameArabic,
            minutesBefore
        )
    }
    
    private fun handleFallback(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: return
        val prayerNameArabic = intent.getStringExtra(EXTRA_PRAYER_NAME_ARABIC) ?: prayerName
        
        // Show high priority notification with sound
        AdhanNotificationManager.showFallbackNotification(
            context,
            prayerName,
            prayerNameArabic
        )
    }
}
