package com.noor.app

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * 📊 AdhanLogger - Logs all adhan events for debugging
 */
object AdhanLogger {
    
    private const val PREFS_NAME = "adhan_log"
    private const val KEY_LOG = "log_entries"
    private const val MAX_LOG_ENTRIES = 100
    
    private lateinit var prefs: SharedPreferences
    
    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    fun logAdhan(context: Context, prayerId: String, prayerName: String, status: String) {
        if (!::prefs.isInitialized) {
            init(context)
        }
        
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        
        val entry = JSONObject().apply {
            put("prayerId", prayerId)
            put("prayerName", prayerName)
            put("status", status)
            put("timestamp", timestamp)
        }
        
        val existingLog = prefs.getString(KEY_LOG, "[]") ?: "[]"
        val logArray = JSONArray(existingLog)
        
        // Add new entry
        logArray.put(entry)
        
        // Trim old entries
        while (logArray.length() > MAX_LOG_ENTRIES) {
            logArray.remove(0)
        }
        
        prefs.edit().putString(KEY_LOG, logArray.toString()).apply()
    }
    
    fun getLog(): List<Map<String, String>> {
        val existingLog = prefs.getString(KEY_LOG, "[]") ?: "[]"
        val logArray = JSONArray(existingLog)
        val result = mutableListOf<Map<String, String>>()
        
        for (i in logArray.length() - 1 downTo 0) {
            val entry = logArray.getJSONObject(i)
            result.add(mapOf(
                "prayerId" to entry.getString("prayerId"),
                "prayerName" to entry.getString("prayerName"),
                "status" to entry.getString("status"),
                "timestamp" to entry.getString("timestamp")
            ))
        }
        
        return result
    }
    
    fun clearLog() {
        prefs.edit().putString(KEY_LOG, "[]").apply()
    }
}
