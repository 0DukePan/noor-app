import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/policies/policies.dart';
import '../services/services.dart';
import '../../features/quran/presentation/providers/quran_providers.dart'
    show quranRepositoryProvider;

// ═══════════════════════════════════════════════════════════════════════════
// CORE SERVICES PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Location Service Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Compass Service Provider
final compassServiceProvider = Provider<CompassService>((ref) {
  return CompassService();
});

/// Prayer Calculation Service Provider
final prayerCalculationServiceProvider = Provider<PrayerCalculationService>((ref) {
  return PrayerCalculationService();
});

// ═══════════════════════════════════════════════════════════════════════════
// DOMAIN POLICIES PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Khushu Policy Provider
final khushuPolicyProvider = Provider<KhushuPolicy>((ref) {
  return const DefaultKhushuPolicy();
});

/// Privacy Policy Provider
final privacyPolicyProvider = Provider<PrivacyPolicy>((ref) {
  // In production, use secure key management
  return DefaultPrivacyPolicy(encryptionKey: 'noor_app_secure_key_32_chars__');
});

/// Offline Policy Provider
final offlinePolicyProvider = Provider<OfflinePolicy>((ref) {
  return DefaultOfflinePolicy();
});

// ═══════════════════════════════════════════════════════════════════════════
// QURAN PROVIDERS (delegated to feature-level quran_providers.dart)
// ═══════════════════════════════════════════════════════════════════════════
// quranRepositoryProvider is re-exported from quran_providers.dart
// All use-case providers have been moved to quran_providers.dart

// ═══════════════════════════════════════════════════════════════════════════
// KHUSHU MODE STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Khushu Mode State Provider
final khushuModeProvider = StateNotifierProvider<KhushuModeNotifier, bool>((ref) {
  return KhushuModeNotifier();
});

class KhushuModeNotifier extends StateNotifier<bool> {
  KhushuModeNotifier() : super(false);

  void enable() => state = true;
  void disable() => state = false;
  void toggle() => state = !state;
}

// ═══════════════════════════════════════════════════════════════════════════
// READING PROGRESS STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Last Reading Position Provider
final lastReadingPositionProvider =
    FutureProvider<({int surahNumber, int verseNumber, int page})>((ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  final result = await repository.getLastReadingPosition();
  return result.fold(
    (failure) => (surahNumber: 1, verseNumber: 1, page: 1),
    (position) => position,
  );
});
