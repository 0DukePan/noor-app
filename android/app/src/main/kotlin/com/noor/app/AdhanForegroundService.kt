package com.noor.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * 🕌 AdhanForegroundService - Plays adhan audio in foreground
 * 
 * This service ensures adhan plays reliably even when:
 * - App is in background
 * - Device is in Doze mode
 * - Screen is off
 */
class AdhanForegroundService : Service() {
    
    companion object {
        private const val TAG = "AdhanForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "adhan_channel"
        private const val CHANNEL_NAME = "Adhan Notifications"
        
        const val ACTION_PLAY_ADHAN = "com.noor.app.ACTION_PLAY_ADHAN"
        const val ACTION_STOP_ADHAN = "com.noor.app.ACTION_STOP_ADHAN"
    }
    
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var originalVolume: Int = 0
    private var audioManager: AudioManager? = null
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY_ADHAN -> {
                val prayerName = intent.getStringExtra(ExactAlarmReceiver.EXTRA_PRAYER_NAME) ?: "Prayer"
                val prayerNameArabic = intent.getStringExtra(ExactAlarmReceiver.EXTRA_PRAYER_NAME_ARABIC) ?: prayerName
                val adhanSoundId = intent.getStringExtra(ExactAlarmReceiver.EXTRA_ADHAN_SOUND_ID) ?: "makkah"
                val vibrate = intent.getBooleanExtra(ExactAlarmReceiver.EXTRA_VIBRATE, true)
                val overrideDnd = intent.getBooleanExtra(ExactAlarmReceiver.EXTRA_OVERRIDE_DND, true)
                
                startForeground(NOTIFICATION_ID, createNotification(prayerNameArabic))
                playAdhan(adhanSoundId, vibrate, overrideDnd)
            }
            ACTION_STOP_ADHAN -> {
                stopAdhan()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        
        return START_NOT_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Adhan prayer call notifications"
                setBypassDnd(true) // Override DND
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setShowBadge(true)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(prayerName: String): Notification {
        // Intent to open app
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Intent to stop adhan
        val stopIntent = Intent(this, AdhanForegroundService::class.java).apply {
            action = ACTION_STOP_ADHAN
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("حان وقت الصلاة")
            .setContentText(prayerName)
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode_off)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(openAppPendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "إيقاف", stopPendingIntent)
            .setOngoing(true)
            .build()
    }
    
    private fun playAdhan(soundId: String, vibrate: Boolean, overrideDnd: Boolean) {
        try {
            // Save original volume
            originalVolume = audioManager?.getStreamVolume(AudioManager.STREAM_ALARM) ?: 0
            
            // Set volume to max if override DND
            if (overrideDnd) {
                val maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_ALARM) ?: 15
                audioManager?.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)
            }
            
            // Get adhan audio resource
            val resourceId = getAdhanResourceId(soundId)
            
            // Create and configure MediaPlayer
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                
                // Load from raw resources
                val afd = resources.openRawResourceFd(resourceId)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                
                prepare()
                
                setOnCompletionListener {
                    Log.d(TAG, "Adhan completed")
                    stopAdhan()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                
                start()
            }
            
            // Vibrate if enabled
            if (vibrate) {
                startVibration()
            }
            
            Log.d(TAG, "Adhan started: $soundId")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error playing adhan", e)
            stopSelf()
        }
    }
    
    private fun getAdhanResourceId(soundId: String): Int {
        // Adhan audio files in res/raw/
        return when (soundId) {
            "al_qatami" -> R.raw.adhan_al_qatami
            "makkah" -> R.raw.adhan_al_qatami      // Using Al-Qatami as default
            "madinah" -> R.raw.adhan_al_qatami    // Using Al-Qatami as default
            "alaqsa" -> R.raw.adhan_al_qatami     // Using Al-Qatami as default
            "mishary" -> R.raw.adhan_al_qatami    // Using Al-Qatami as default
            "abdulbasit" -> R.raw.adhan_al_qatami // Using Al-Qatami as default
            "fajr_special" -> R.raw.adhan_al_qatami
            else -> R.raw.adhan_al_qatami
        }
    }
    
    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as Vibrator
        }
        
        // Vibrate pattern: wait 0ms, vibrate 500ms, wait 200ms, vibrate 500ms
        val pattern = longArrayOf(0, 500, 200, 500)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, -1)
        }
    }
    
    private fun stopAdhan() {
        // Stop media player
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null
        
        // Stop vibration
        vibrator?.cancel()
        vibrator = null
        
        // Restore volume
        audioManager?.setStreamVolume(AudioManager.STREAM_ALARM, originalVolume, 0)
        
        Log.d(TAG, "Adhan stopped")
    }
    
    override fun onDestroy() {
        stopAdhan()
        super.onDestroy()
    }
}
