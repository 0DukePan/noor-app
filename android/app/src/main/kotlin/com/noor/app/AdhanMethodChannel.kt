package com.noor.app

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 🔌 AdhanMethodChannel - Bridge between Flutter and native Android
 */
class AdhanMethodChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {
    
    companion object {
        private const val CHANNEL_NAME = "com.noor.app/adhan"
    }
    
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    
    init {
        channel.setMethodCallHandler(this)
        AdhanLogger.init(context)
        AdhanNotificationManager.init(context)
        
        // Start midnight validation
        MidnightValidator.scheduleDailyValidation(context)
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scheduleExactAdhan" -> {
                val prayerId = call.argument<String>("prayerId") ?: return result.error("INVALID", "prayerId required", null)
                val prayerName = call.argument<String>("prayerName") ?: return result.error("INVALID", "prayerName required", null)
                val prayerNameArabic = call.argument<String>("prayerNameArabic") ?: prayerName
                val scheduledTimeMillis = call.argument<Long>("scheduledTimeMillis") ?: return result.error("INVALID", "scheduledTimeMillis required", null)
                val adhanSoundId = call.argument<String>("adhanSoundId") ?: "al_qatami"
                val vibrate = call.argument<Boolean>("vibrate") ?: true
                val overrideDnd = call.argument<Boolean>("overrideDnd") ?: true
                
                WeeklyAlarmScheduler.scheduleAdhan(
                    context,
                    prayerId,
                    prayerName,
                    prayerNameArabic,
                    scheduledTimeMillis,
                    adhanSoundId,
                    vibrate,
                    overrideDnd
                )
                
                result.success(true)
            }
            
            "schedulePreReminder" -> {
                val reminderId = call.argument<String>("reminderId") ?: return result.error("INVALID", "reminderId required", null)
                val prayerName = call.argument<String>("prayerName") ?: return result.error("INVALID", "prayerName required", null)
                val prayerNameArabic = call.argument<String>("prayerNameArabic") ?: prayerName
                val scheduledTimeMillis = call.argument<Long>("scheduledTimeMillis") ?: return result.error("INVALID", "scheduledTimeMillis required", null)
                val minutesBefore = call.argument<Int>("minutesBefore") ?: 15
                
                WeeklyAlarmScheduler.schedulePreReminder(
                    context,
                    reminderId,
                    prayerName,
                    prayerNameArabic,
                    scheduledTimeMillis,
                    minutesBefore
                )
                
                result.success(true)
            }
            
            "schedulePostReminder" -> {
                val reminderId = call.argument<String>("reminderId") ?: return result.error("INVALID", "reminderId required", null)
                val prayerName = call.argument<String>("prayerName") ?: return result.error("INVALID", "prayerName required", null)
                val prayerNameArabic = call.argument<String>("prayerNameArabic") ?: prayerName
                val scheduledTimeMillis = call.argument<Long>("scheduledTimeMillis") ?: return result.error("INVALID", "scheduledTimeMillis required", null)
                
                WeeklyAlarmScheduler.schedulePostReminder(
                    context,
                    reminderId,
                    prayerName,
                    prayerNameArabic,
                    scheduledTimeMillis
                )
                
                result.success(true)
            }
            
            "scheduleMosqueMode" -> {
                val prayerId = call.argument<String>("prayerId") ?: return result.error("INVALID", "prayerId required", null)
                val scheduledTimeMillis = call.argument<Long>("scheduledTimeMillis") ?: return result.error("INVALID", "scheduledTimeMillis required", null)
                val durationMinutes = call.argument<Int>("durationMinutes") ?: 20
                
                WeeklyAlarmScheduler.scheduleMosqueMode(
                    context,
                    prayerId,
                    scheduledTimeMillis,
                    durationMinutes
                )
                
                result.success(true)
            }
            
            "enableMosqueMode" -> {
                val durationMinutes = call.argument<Int>("durationMinutes") ?: 20
                MosqueModeReceiver.enable(context, durationMinutes)
                result.success(true)
            }
            
            "disableMosqueMode" -> {
                MosqueModeReceiver.disable(context)
                result.success(true)
            }
            
            "isMosqueModeActive" -> {
                result.success(MosqueModeReceiver.isActive(context))
            }
            
            "scheduleFallbackNotification" -> {
                val prayerId = call.argument<String>("prayerId") ?: return result.error("INVALID", "prayerId required", null)
                val prayerName = call.argument<String>("prayerName") ?: return result.error("INVALID", "prayerName required", null)
                val prayerNameArabic = call.argument<String>("prayerNameArabic") ?: prayerName
                val scheduledTimeMillis = call.argument<Long>("scheduledTimeMillis") ?: return result.error("INVALID", "scheduledTimeMillis required", null)
                
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val intent = Intent(context, ExactAlarmReceiver::class.java).apply {
                    action = ExactAlarmReceiver.ACTION_FALLBACK
                    putExtra(ExactAlarmReceiver.EXTRA_PRAYER_ID, prayerId)
                    putExtra(ExactAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
                    putExtra(ExactAlarmReceiver.EXTRA_PRAYER_NAME_ARABIC, prayerNameArabic)
                }
                
                val pendingIntent = android.app.PendingIntent.getBroadcast(
                    context,
                    prayerId.hashCode() + 2000,
                    intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    scheduledTimeMillis,
                    pendingIntent
                )
                
                result.success(true)
            }
            
            "stopAdhan" -> {
                val intent = Intent(context, AdhanForegroundService::class.java).apply {
                    action = AdhanForegroundService.ACTION_STOP_ADHAN
                }
                context.startService(intent)
                result.success(true)
            }
            
            "cancelAllAdhans" -> {
                WeeklyAlarmScheduler.cancelAllAlarms(context)
                result.success(true)
            }
            
            "getScheduledCount" -> {
                result.success(WeeklyAlarmScheduler.getScheduledCount(context))
            }
            
            "requestExactAlarmPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    if (!alarmManager.canScheduleExactAlarms()) {
                        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                            data = Uri.parse("package:${context.packageName}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                } else {
                    result.success(true)
                }
            }
            
            "requestBatteryOptimization" -> {
                val success = BatteryOptimizationHelper.requestDisableBatteryOptimization(context)
                result.success(success)
            }
            
            "isExactAlarmAllowed" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    result.success(alarmManager.canScheduleExactAlarms())
                } else {
                    result.success(true)
                }
            }
            
            "isBatteryOptimizationDisabled" -> {
                result.success(BatteryOptimizationHelper.isIgnoringBatteryOptimizations(context))
            }
            
            "checkAllPermissions" -> {
                val status = BatteryOptimizationHelper.checkAllPermissions(context)
                result.success(mapOf(
                    "batteryOptimizationDisabled" to status.batteryOptimizationDisabled,
                    "exactAlarmAllowed" to status.exactAlarmAllowed,
                    "allGranted" to status.allGranted
                ))
            }
            
            "getAdhanLog" -> {
                result.success(AdhanLogger.getLog())
            }
            
            else -> result.notImplemented()
        }
    }
}

