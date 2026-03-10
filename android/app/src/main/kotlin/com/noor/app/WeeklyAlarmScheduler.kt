package com.noor.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * 📅 WeeklyAlarmScheduler - جدولة أسبوعية
 * يجدول كل الأذانات لـ 7 أيام مقدمًا
 */
object WeeklyAlarmScheduler {
    
    private const val TAG = "WeeklyAlarmScheduler"
    private const val PREFS_NAME = "weekly_scheduler_prefs"
    
    // Request code ranges for different types
    private const val ADHAN_BASE_CODE = 10000
    private const val PRE_REMINDER_BASE_CODE = 20000
    private const val POST_REMINDER_BASE_CODE = 30000
    private const val MOSQUE_MODE_BASE_CODE = 40000
    
    /**
     * Schedule an exact alarm for adhan
     */
    fun scheduleAdhan(
        context: Context,
        prayerId: String,
        prayerName: String,
        prayerNameArabic: String,
        scheduledTimeMillis: Long,
        adhanSoundId: String,
        vibrate: Boolean = true,
        overrideDnd: Boolean = true
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(context, ExactAlarmReceiver::class.java).apply {
            action = ExactAlarmReceiver.ACTION_ADHAN
            putExtra("prayerId", prayerId)
            putExtra("prayerName", prayerName)
            putExtra("prayerNameArabic", prayerNameArabic)
            putExtra("adhanSoundId", adhanSoundId)
            putExtra("vibrate", vibrate)
            putExtra("overrideDnd", overrideDnd)
        }
        
        val requestCode = ADHAN_BASE_CODE + prayerId.hashCode().and(0xFFFF)
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Use setAlarmClock for highest priority
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                val showIntent = PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(scheduledTimeMillis, showIntent),
                    pendingIntent
                )
            }
        } else {
            val showIntent = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(scheduledTimeMillis, showIntent),
                pendingIntent
            )
        }
        
        // Save scheduled alarm
        saveScheduledAlarm(context, prayerId, scheduledTimeMillis)
        
        Log.d(TAG, "Scheduled adhan: $prayerName at ${java.util.Date(scheduledTimeMillis)}")
    }
    
    /**
     * Schedule pre-reminder notification
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
            action = ExactAlarmReceiver.ACTION_PRE_REMINDER
            putExtra("reminderId", reminderId)
            putExtra("prayerName", prayerName)
            putExtra("prayerNameArabic", prayerNameArabic)
            putExtra("minutesBefore", minutesBefore)
        }
        
        val requestCode = PRE_REMINDER_BASE_CODE + reminderId.hashCode().and(0xFFFF)
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        scheduleExact(alarmManager, scheduledTimeMillis, pendingIntent)
        
        Log.d(TAG, "Scheduled pre-reminder: $prayerName at ${java.util.Date(scheduledTimeMillis)}")
    }
    
    /**
     * Schedule post-reminder notification
     */
    fun schedulePostReminder(
        context: Context,
        reminderId: String,
        prayerName: String,
        prayerNameArabic: String,
        scheduledTimeMillis: Long
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(context, ExactAlarmReceiver::class.java).apply {
            action = ExactAlarmReceiver.ACTION_POST_REMINDER
            putExtra("reminderId", reminderId)
            putExtra("prayerName", prayerName)
            putExtra("prayerNameArabic", prayerNameArabic)
        }
        
        val requestCode = POST_REMINDER_BASE_CODE + reminderId.hashCode().and(0xFFFF)
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        scheduleExact(alarmManager, scheduledTimeMillis, pendingIntent)
        
        Log.d(TAG, "Scheduled post-reminder: $prayerName at ${java.util.Date(scheduledTimeMillis)}")
    }
    
    /**
     * Schedule mosque mode
     */
    fun scheduleMosqueMode(
        context: Context,
        prayerId: String,
        scheduledTimeMillis: Long,
        durationMinutes: Int
    ) {
        MosqueModeReceiver.scheduleAt(context, scheduledTimeMillis, durationMinutes)
        Log.d(TAG, "Scheduled mosque mode at ${java.util.Date(scheduledTimeMillis)} for $durationMinutes minutes")
    }
    
    /**
     * Cancel all scheduled alarms
     */
    fun cancelAllAlarms(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val scheduledIds = prefs.getStringSet("scheduled_ids", emptySet()) ?: emptySet()
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        for (id in scheduledIds) {
            val intent = Intent(context, ExactAlarmReceiver::class.java)
            val requestCode = ADHAN_BASE_CODE + id.hashCode().and(0xFFFF)
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
        }
        
        prefs.edit().putStringSet("scheduled_ids", emptySet()).apply()
        
        Log.d(TAG, "Cancelled ${scheduledIds.size} alarms")
    }
    
    private fun scheduleExact(
        alarmManager: AlarmManager,
        timeMillis: Long,
        pendingIntent: PendingIntent
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeMillis,
                    pendingIntent
                )
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                timeMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                timeMillis,
                pendingIntent
            )
        }
    }
    
    private fun saveScheduledAlarm(context: Context, prayerId: String, timeMillis: Long) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val scheduledIds = prefs.getStringSet("scheduled_ids", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        scheduledIds.add(prayerId)
        prefs.edit().putStringSet("scheduled_ids", scheduledIds).apply()
        prefs.edit().putLong("time_$prayerId", timeMillis).apply()
    }
    
    /**
     * Get scheduled alarms count
     */
    fun getScheduledCount(context: Context): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet("scheduled_ids", emptySet())?.size ?: 0
    }
}
