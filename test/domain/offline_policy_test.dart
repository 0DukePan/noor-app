import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/domain/policies/offline_policy.dart';

/// Tests for the offline-first policy classes. Core worship features must
/// never require network; only audio-streaming / AI / sync may.
void main() {
  group('DefaultOfflinePolicy', () {
    final policy = DefaultOfflinePolicy();

    test('core worship features never require network', () {
      for (final f in [
        FeatureType.quranReading,
        FeatureType.hadith,
        FeatureType.prayerTimes,
        FeatureType.qibla,
        FeatureType.adhkar,
        FeatureType.tafsir,
      ]) {
        expect(
          policy.requiresNetwork(f),
          isFalse,
          reason: '$f must work offline',
        );
      }
    });

    test('audio / AI / sync features may require network', () {
      expect(policy.requiresNetwork(FeatureType.quranAudio), isTrue);
      expect(policy.requiresNetwork(FeatureType.semanticSearch), isTrue);
      expect(policy.requiresNetwork(FeatureType.contentSync), isTrue);
    });

    test('is offline-first by default', () {
      expect(policy.isOfflineFirst, isTrue);
    });

    test('cache stores and retrieves data', () async {
      await policy.cacheData<String>('greeting', 'السلام عليكم');
      expect(await policy.getCachedData<String>('greeting'), 'السلام عليكم');
      expect(await policy.getCachedData<String>('missing'), isNull);
    });

    test('uncached keys are stale; fresh cache is not', () async {
      expect(policy.isCacheStale('never', const Duration(minutes: 1)), isTrue);
      await policy.cacheData<int>('count', 7);
      expect(policy.isCacheStale('count', const Duration(minutes: 1)), isFalse);
    });
  });

  group('StrictOfflinePolicy', () {
    final policy = StrictOfflinePolicy();

    test('only sync and AI require network', () {
      expect(policy.requiresNetwork(FeatureType.contentSync), isTrue);
      expect(policy.requiresNetwork(FeatureType.semanticSearch), isTrue);
      expect(policy.requiresNetwork(FeatureType.quranAudio), isFalse);
      expect(policy.requiresNetwork(FeatureType.qibla), isFalse);
    });

    test('delegates caching to the default policy', () async {
      await policy.cacheData<String>('k', 'v');
      expect(await policy.getCachedData<String>('k'), 'v');
      expect(policy.isOfflineFirst, isTrue);
    });
  });
}
