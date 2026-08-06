package com.noor.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * 🔋 BatteryOptimizationHelper - إدارة تحسين البطارية
 * يطلب إعفاء التطبيق من تحسين البطارية للأذان الدقيق
 */
object BatteryOptimizationHelper {
    
    private const val TAG = "BatteryOptimization"
    
    /**
     * Check if battery optimization is disabled for this app
     */
    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }
    
    /**
     * Request to disable battery optimization
     * Returns true if already disabled or request sent
     */
    fun requestDisableBatteryOptimization(context: Context): Boolean {
        if (isIgnoringBatteryOptimizations(context)) {
            Log.d(TAG, "Already ignoring battery optimizations")
            return true
        }
        
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            Log.d(TAG, "Requested battery optimization exemption")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request battery optimization exemption", e)
            return false
        }
    }
    
    /**
     * Open battery optimization settings
     */
    fun openBatteryOptimizationSettings(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open battery settings", e)
            // Fallback to general settings
            openGeneralSettings(context)
        }
    }
    
    /**
     * Open general settings
     */
    private fun openGeneralSettings(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open settings", e)
        }
    }
    
    /**
     * Get explanation text for battery optimization
     */
    fun getExplanationText(): String {
        return """
            لضمان عمل الأذان بدقة حتى عندما يكون التطبيق مغلقًا:
            
            ١. اضغط على "إعفاء من تحسين البطارية"
            ٢. اختر "نور" من القائمة
            ٣. اختر "عدم التحسين"
            
            هذا يسمح للتطبيق بإيقاظ الهاتف في وقت الصلاة.
        """.trimIndent()
    }
    
    /**
     * Get explanation text in English
     */
    fun getExplanationTextEnglish(): String {
        return """
            To ensure Adhan works accurately even when the app is closed:
            
            1. Tap "Disable Battery Optimization"
            2. Select "Noor" from the list
            3. Choose "Don't Optimize"
            
            This allows the app to wake up the phone at prayer time.
        """.trimIndent()
    }
    
    /**
     * Check all permissions needed for reliable adhan
     */
    fun checkAllPermissions(context: Context): PermissionStatus {
        val batteryOptimizationDisabled = isIgnoringBatteryOptimizations(context)
        
        val exactAlarmAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
        
        return PermissionStatus(
            batteryOptimizationDisabled = batteryOptimizationDisabled,
            exactAlarmAllowed = exactAlarmAllowed,
            allGranted = batteryOptimizationDisabled && exactAlarmAllowed
        )
    }
    
    data class PermissionStatus(
        val batteryOptimizationDisabled: Boolean,
        val exactAlarmAllowed: Boolean,
        val allGranted: Boolean
    )
}
