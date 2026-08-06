/// سياسة العمل بدون إنترنت - Offline Policy
/// Enforces offline-first architecture at the code level.
/// Core worship features MUST work without internet.
abstract class OfflinePolicy {
  /// Check if this feature requires network connectivity
  bool requiresNetwork(FeatureType feature);

  /// Get cached data for offline use
  Future<T?> getCachedData<T>(String key);

  /// Store data for offline access
  Future<void> cacheData<T>(String key, T data);

  /// Check if cached data is stale and needs refresh
  bool isCacheStale(String key, Duration maxAge);

  /// Priority: Local first, then network
  bool get isOfflineFirst => true;
}

/// Types of features for offline policy decisions
enum FeatureType {
  /// Quran text reading - MUST work offline
  quranReading,

  /// Quran audio recitation - can require network for streaming
  quranAudio,

  /// Tafsir reading - MUST have basic offline, extended needs network
  tafsir,

  /// Hadith reading - MUST work offline
  hadith,

  /// Prayer times calculation - MUST work offline (GPS only)
  prayerTimes,

  /// Qibla direction - MUST work offline (compass + GPS)
  qibla,

  /// Adhkar reading - MUST work offline
  adhkar,

  /// Semantic search - requires network for AI
  semanticSearch,

  /// Content sync - requires network
  contentSync,
}

/// Default implementation of Offline Policy
class DefaultOfflinePolicy implements OfflinePolicy {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  @override
  bool requiresNetwork(FeatureType feature) {
    switch (feature) {
      // Core worship features - NEVER require network
      case FeatureType.quranReading:
      case FeatureType.hadith:
      case FeatureType.prayerTimes:
      case FeatureType.qibla:
      case FeatureType.adhkar:
        return false;

      // Tafsir - basic works offline, extended may need network
      case FeatureType.tafsir:
        return false; // Basic tafsir bundled with app

      // Audio streaming - can require network
      case FeatureType.quranAudio:
        return true; // But we cache recently played

      // AI features - require network
      case FeatureType.semanticSearch:
        return true;

      // Sync features - obviously require network
      case FeatureType.contentSync:
        return true;
    }
  }

  @override
  Future<T?> getCachedData<T>(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T?;
    }
    return null;
  }

  @override
  Future<void> cacheData<T>(String key, T data) async {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  @override
  bool isCacheStale(String key, Duration maxAge) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp) > maxAge;
  }

  @override
  bool get isOfflineFirst => true;
}

/// Strict offline policy for critical worship features
class StrictOfflinePolicy implements OfflinePolicy {
  final DefaultOfflinePolicy _delegate = DefaultOfflinePolicy();

  @override
  bool requiresNetwork(FeatureType feature) {
    // Even stricter: only sync and AI features need network
    return feature == FeatureType.contentSync ||
        feature == FeatureType.semanticSearch;
  }

  @override
  Future<T?> getCachedData<T>(String key) => _delegate.getCachedData(key);

  @override
  Future<void> cacheData<T>(String key, T data) => _delegate.cacheData(key, data);

  @override
  bool isCacheStale(String key, Duration maxAge) =>
      _delegate.isCacheStale(key, maxAge);

  @override
  bool get isOfflineFirst => true;
}
