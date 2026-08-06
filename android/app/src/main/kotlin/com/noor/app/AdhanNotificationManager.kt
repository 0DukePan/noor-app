package com.noor.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * 🔔 AdhanNotificationManager - Manages all adhan-related notifications
 */
object AdhanNotificationManager {
    
    private const val PRE_REMINDER_CHANNEL_ID = "pre_reminder_channel"
    private const val PRE_REMINDER_CHANNEL_NAME = "Prayer Reminders"
    private const val FALLBACK_CHANNEL_ID = "fallback_adhan_channel"
    private const val FALLBACK_CHANNEL_NAME = "Prayer Time Alerts"
    
    fun init(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            
            // Pre-reminder channel (normal priority)
            val preReminderChannel = NotificationChannel(
                PRE_REMINDER_CHANNEL_ID,
                PRE_REMINDER_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Reminders before prayer time"
            }
            
            // Fallback channel (high priority with sound)
            val fallbackChannel = NotificationChannel(
                FALLBACK_CHANNEL_ID,
                FALLBACK_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Prayer time alerts when foreground service unavailable"
                setBypassDnd(true)
            }
            
            notificationManager.createNotificationChannel(preReminderChannel)
            notificationManager.createNotificationChannel(fallbackChannel)
        }
    }
    
    fun showPreReminderNotification(
        context: Context,
        prayerName: String,
        prayerNameArabic: String,
        minutesBefore: Int
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, PRE_REMINDER_CHANNEL_ID)
            .setContentTitle("تذكير بالصلاة")
            .setContentText("باقي $minutesBefore دقائق على صلاة $prayerNameArabic")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        notificationManager.notify(prayerName.hashCode(), notification)
    }
    
    fun showFallbackNotification(
        context: Context,
        prayerName: String,
        prayerNameArabic: String
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, FALLBACK_CHANNEL_ID)
            .setContentTitle("حان وقت الصلاة")
            .setContentText("حان الآن وقت صلاة $prayerNameArabic")
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode_off)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()
        
        notificationManager.notify(prayerName.hashCode() + 1000, notification)
    }
}
