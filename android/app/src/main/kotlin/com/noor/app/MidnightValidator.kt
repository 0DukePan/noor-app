package com.noor.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * 🌙 MidnightValidator - فحص منتصف الليل
 * يتحقق من دقة المواقيت ويعيد الجدولة إذا لزم الأمر
 */
class MidnightValidator : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "MidnightValidator"
        const val ACTION_VALIDATE = "com.noor.app.ACTION_MIDNIGHT_VALIDATE"
        
        /**
         * Schedule daily midnight validation
         */
        fun scheduleDailyValidation(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, MidnightValidator::class.java).apply {
                action = ACTION_VALIDATE
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                9999, // Unique ID for midnight validator
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Calculate next midnight (00:01)
            val calendar = java.util.Calendar.getInstance().apply {
                add(java.util.Calendar.DAY_OF_YEAR, 1)
                set(java.util.Calendar.HOUR_OF_DAY, 0)
                set(java.util.Calendar.MINUTE, 1)
                set(java.util.Calendar.SECOND, 0)
            }
            
            // Schedule repeating alarm at midnight
            alarmManager.setRepeating(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                AlarmManager.INTERVAL_DAY,
                pendingIntent
            )
            
            Log.d(TAG, "Scheduled daily validation at midnight")
        }
        
        /**
         * Cancel midnight validation
         */
        fun cancelDailyValidation(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, MidnightValidator::class.java).apply {
                action = ACTION_VALIDATE
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                9999,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_VALIDATE) return
        
        Log.d(TAG, "Midnight validation triggered")
        
        // Log the validation
        AdhanLogger.logAdhan(context, "midnight", "system", "validation_triggered")
        
        // Notify Flutter to re-validate and reschedule
        // This will be handled by the Flutter side through method channel
        // For now, just log that validation was triggered
        
        // In production, you would:
        // 1. Fetch cached prayer times
        // 2. Recalculate today's prayer times
        // 3. Compare and log any discrepancies
        // 4. Trigger reschedule if needed
    }
}
