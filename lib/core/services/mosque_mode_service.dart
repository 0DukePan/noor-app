import 'dart:async';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'prayer_time_engine.dart';
import 'weekly_scheduler_service.dart';

/// 🕌 وضع المسجد - Mosque Mode Service
/// يحول الهاتف للصامت تلقائيًا عند دخول وقت الصلاة
class MosqueModeService {
  static const _channelName = 'com.noor.app/adhan';
  static const _cacheBoxName = 'mosque_mode';
  
  static final _channel = const MethodChannel(_channelName);
  static Box? _cacheBox;
  
  // Settings
  static bool _isEnabled = false;
  static int _durationMinutes = 20;
  static final Map<PrayerType, bool> _enabledPrayers = {
    PrayerType.fajr: true,
    PrayerType.dhuhr: true,
    PrayerType.asr: true,
    PrayerType.maghrib: true,
    PrayerType.isha: true,
  };

  // State
  static bool _isCurrentlyActive = false;
  static DateTime? _activeUntil;
  static Timer? _deactivateTimer;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize mosque mode
  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
    await _loadSettings();
  }

  /// Load saved settings
  static Future<void> _loadSettings() async {
    _isEnabled = _cacheBox?.get('enabled', defaultValue: false) ?? false;
    _durationMinutes = _cacheBox?.get('duration', defaultValue: 20) ?? 20;
    
    for (final prayer in PrayerType.values) {
      if (prayer == PrayerType.sunrise) continue;
      _enabledPrayers[prayer] = _cacheBox?.get(
        'prayer_${prayer.name}', 
        defaultValue: true,
      ) ?? true;
    }
  }

  /// Save settings
  static Future<void> _saveSettings() async {
    await _cacheBox?.put('enabled', _isEnabled);
    await _cacheBox?.put('duration', _durationMinutes);
    
    for (final entry in _enabledPrayers.entries) {
      await _cacheBox?.put('prayer_${entry.key.name}', entry.value);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENABLE/DISABLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable mosque mode globally
  static Future<void> enable() async {
    _isEnabled = true;
    await _saveSettings();
  }

  /// Disable mosque mode globally
  static Future<void> disable() async {
    _isEnabled = false;
    await _saveSettings();
    
    // Deactivate if currently active
    if (_isCurrentlyActive) {
      await deactivate();
    }
  }

  /// Check if mosque mode is enabled
  static bool get isEnabled => _isEnabled;

  /// Check if mosque mode is currently active
  static bool get isActive => _isCurrentlyActive;

  /// Get remaining active time
  static Duration? get remainingTime {
    if (!_isCurrentlyActive || _activeUntil == null) return null;
    final remaining = _activeUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set duration in minutes
  static Future<void> setDuration(int minutes) async {
    _durationMinutes = minutes.clamp(5, 60);
    await _saveSettings();
  }

  /// Get duration
  static int get durationMinutes => _durationMinutes;

  /// Enable/disable for specific prayer
  static Future<void> setPrayerEnabled(PrayerType prayer, bool enabled) async {
    _enabledPrayers[prayer] = enabled;
    await _saveSettings();
  }

  /// Check if enabled for specific prayer
  static bool isPrayerEnabled(PrayerType prayer) {
    return _enabledPrayers[prayer] ?? true;
  }

  /// Get all enabled prayers
  static Map<PrayerType, bool> get enabledPrayers => Map.from(_enabledPrayers);

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Activate mosque mode now
  static Future<void> activate({int? durationMinutes}) async {
    final duration = durationMinutes ?? _durationMinutes;
    
    try {
      await _channel.invokeMethod('enableMosqueMode', {
        'durationMinutes': duration,
      });
      
      _isCurrentlyActive = true;
      _activeUntil = DateTime.now().add(Duration(minutes: duration));
      
      // Schedule deactivation
      _deactivateTimer?.cancel();
      _deactivateTimer = Timer(Duration(minutes: duration), () {
        deactivate();
      });
      
    } catch (e) {
      // Native call failed, but we can still track state
      _isCurrentlyActive = true;
      _activeUntil = DateTime.now().add(Duration(minutes: duration));
    }
  }

  /// Deactivate mosque mode
  static Future<void> deactivate() async {
    try {
      await _channel.invokeMethod('disableMosqueMode');
    } catch (e) {
      // Native call failed
    }
    
    _isCurrentlyActive = false;
    _activeUntil = null;
    _deactivateTimer?.cancel();
  }

  /// Called by adhan system when prayer time arrives
  static Future<void> onPrayerTime(PrayerType prayer) async {
    if (!_isEnabled) return;
    if (!isPrayerEnabled(prayer)) return;
    
    await activate();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Quick 10 minute mosque mode
  static Future<void> quick10Minutes() async {
    await activate(durationMinutes: 10);
  }

  /// Quick 20 minute mosque mode
  static Future<void> quick20Minutes() async {
    await activate(durationMinutes: 20);
  }

  /// Quick 30 minute mosque mode
  static Future<void> quick30Minutes() async {
    await activate(durationMinutes: 30);
  }

  /// Extend current mosque mode by X minutes
  static Future<void> extend(int minutes) async {
    if (!_isCurrentlyActive || _activeUntil == null) return;
    
    final newEndTime = _activeUntil!.add(Duration(minutes: minutes));
    final remainingMinutes = newEndTime.difference(DateTime.now()).inMinutes;
    
    await activate(durationMinutes: remainingMinutes);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  static void dispose() {
    _deactivateTimer?.cancel();
  }
}
