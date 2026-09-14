import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'hive_box_registry.dart';

/// Self-hosted, opt-in, aggregate-only usage statistics (decided 2026-09-03).
///
/// What this is: named counters (`app_open` → 42). No identities, no
/// timestamps, no per-user anything, no third-party SDK. Counts stay on the
/// device unless ALL of these hold: the user opted in, AND the owner
/// configured a first-party endpoint. With the default settings this class
/// is a pure local counter — the store listing's "no tracking" claim holds
/// out of the box.
///
/// What this is NOT: per-user tracking. `PrivacyPolicy.canTrackUser` stays
/// false; that gate covers identifying telemetry, this class covers
/// anonymous aggregates behind its own explicit opt-in.
class AnalyticsService {
  static Box<int>? _box;

  /// Explicit user opt-in. Default false: recording is a no-op until the
  /// settings screen sets this to true (with an explanation shown there).
  static bool optedIn = false;

  /// First-party upload URL, or null (default) for local-only counting.
  /// Garbage values are safe: flush() treats unusable URLs as "no endpoint"
  /// and sends nothing (the parse/send failure is absorbed, counts kept).
  static String? endpoint;

  /// The only event names ever counted. Anything else is dropped: a typo'd
  /// call site must fail visibly in tests, not silently mint new keys.
  static const Set<String> allowedEvents = {
    'app_open',
    'prayer_viewed',
    'surah_opened',
    'tafsir_opened',
    'hadith_opened',
    'adhkar_completed',
    'search_used',
    'qibla_viewed',
  };

  static const String _boxName = HiveBoxes.analytics;

  /// Reserved key holding the opt-in flag (0/1). Never counted, never
  /// uploaded: snapshot() and flush() exclude it.
  static const String _optedInKey = '_opted_in';

  /// Wire up the backing store (owned Hive box `analytics`). Call once at
  /// startup; tests call it against their own temp Hive dir. Restores the
  /// persisted opt-in flag so the choice survives restarts.
  static Future<void> init() async {
    _box = await Hive.openBox<int>(_boxName);
    optedIn = (_box?.get(_optedInKey) ?? 0) == 1;
  }

  /// Persist the user's opt-in choice (settings screen calls this; the flag
  /// survives restarts via the owned box).
  static Future<void> setOptedIn({required bool value}) async {
    optedIn = value;
    await _box?.put(_optedInKey, value ? 1 : 0);
  }

  /// Count one occurrence. No-op unless opted in; unknown/empty/oversize
  /// names are dropped (never stored, never sent).
  static void record(String event) {
    if (!optedIn) return;
    if (!_isAllowed(event)) return;
    final box = _box;
    if (box == null) return;
    box.put(event, (box.get(event, defaultValue: 0) ?? 0) + 1);
  }

  static bool _isAllowed(String event) {
    if (event.isEmpty || event.length > 32) return false;
    return allowedEvents.contains(event);
  }

  static int count(String event) => _box?.get(event, defaultValue: 0) ?? 0;

  /// A copy of all counters (never the live box). The internal opt-in flag
  /// key is excluded so it can never be counted or uploaded.
  static Map<String, int> snapshot() {
    final box = _box;
    if (box == null) return {};
    return {
      for (final key in box.keys)
        if (key != _optedInKey) key as String: (box.get(key) ?? 0),
    };
  }

  /// Upload the counters to the configured endpoint and clear them on
  /// success. Returns false (sending nothing) when opted out, when no
  /// endpoint is configured, or when the upload fails — counts are kept in
  /// every failure case and retried next time.
  static Future<bool> flush({http.Client? client}) async {
    final target = endpoint;
    final box = _box;
    if (!optedIn || target == null || box == null) return false;
    // Fail fast on garbage URLs: no pointless socket attempt, no request
    // object, counts untouched.
    final uri = Uri.tryParse(target);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    final payload = snapshot();
    if (payload.isEmpty) return true;
    final httpClient = client ?? http.Client();
    final closeClient = client == null;
    try {
      final response = await httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'events': payload}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await box.clear();
        return true;
      }
      return false;
    } on Object {
      return false;
    } finally {
      if (closeClient) httpClient.close();
    }
  }

  /// Test hook: clear flags, endpoint and counters.
  static Future<void> resetForTest() async {
    optedIn = false;
    endpoint = null;
    await _box?.clear();
    _box = null;
  }
}
