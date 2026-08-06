package com.noor.app

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.util.Log

/**
 * 🎵 AudioFocusManager - إدارة Audio Focus
 * يضمن تشغيل الأذان بأولوية كاملة
 */
class AudioFocusManager(private val context: Context) {
    
    companion object {
        private const val TAG = "AudioFocusManager"
    }
    
    private val audioManager: AudioManager = 
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus = false
    
    private var onFocusGained: (() -> Unit)? = null
    private var onFocusLost: (() -> Unit)? = null
    private var onFocusLostTransient: (() -> Unit)? = null
    private var onDuck: (() -> Unit)? = null
    
    private val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                Log.d(TAG, "Audio focus gained")
                hasAudioFocus = true
                onFocusGained?.invoke()
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                Log.d(TAG, "Audio focus lost permanently")
                hasAudioFocus = false
                onFocusLost?.invoke()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                Log.d(TAG, "Audio focus lost transiently")
                hasAudioFocus = false
                onFocusLostTransient?.invoke()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                Log.d(TAG, "Audio focus duck")
                onDuck?.invoke()
            }
        }
    }
    
    /**
     * Request audio focus for adhan playback
     * Returns true if focus was granted
     */
    fun requestFocus(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            requestFocusOreo()
        } else {
            requestFocusLegacy()
        }
    }
    
    private fun requestFocusOreo(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        
        audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(audioAttributes)
            .setOnAudioFocusChangeListener(focusChangeListener)
            .setAcceptsDelayedFocusGain(false)
            .setWillPauseWhenDucked(false)
            .build()
        
        val result = audioManager.requestAudioFocus(audioFocusRequest!!)
        hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        
        Log.d(TAG, "Audio focus request result: $result, granted: $hasAudioFocus")
        return hasAudioFocus
    }
    
    @Suppress("DEPRECATION")
    private fun requestFocusLegacy(): Boolean {
        val result = audioManager.requestAudioFocus(
            focusChangeListener,
            AudioManager.STREAM_ALARM,
            AudioManager.AUDIOFOCUS_GAIN
        )
        hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        return hasAudioFocus
    }
    
    /**
     * Release audio focus
     */
    fun releaseFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let {
                audioManager.abandonAudioFocusRequest(it)
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusChangeListener)
        }
        hasAudioFocus = false
        Log.d(TAG, "Audio focus released")
    }
    
    /**
     * Set callbacks
     */
    fun setCallbacks(
        onGained: (() -> Unit)? = null,
        onLost: (() -> Unit)? = null,
        onLostTransient: (() -> Unit)? = null,
        onDuck: (() -> Unit)? = null
    ) {
        this.onFocusGained = onGained
        this.onFocusLost = onLost
        this.onFocusLostTransient = onLostTransient
        this.onDuck = onDuck
    }
    
    /**
     * Check if we have audio focus
     */
    fun hasFocus(): Boolean = hasAudioFocus
    
    /**
     * Set volume to maximum for alarm stream
     */
    fun setMaxVolume() {
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)
    }
    
    /**
     * Get current alarm volume
     */
    fun getCurrentVolume(): Int {
        return audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
    }
    
    /**
     * Set alarm volume
     */
    fun setVolume(volume: Int) {
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        val safeVolume = volume.coerceIn(0, maxVolume)
        audioManager.setStreamVolume(AudioManager.STREAM_ALARM, safeVolume, 0)
    }
}
