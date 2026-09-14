import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Mushaf text-integrity guard: the bundled Uthmani Quran must match the
/// canonical Hafs verse counts exactly — 6,236 verses across 114 surahs.
/// A truncated, merged, or mis-sourced asset fails here before it reaches
/// the reader. (This is the checksum-level check achievable without an
/// external canonical corpus in the repo.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, dynamic>> loadQuran() async {
    final jsonString =
        await rootBundle.loadString('assets/quran/quran_uthmani.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  test('the bundled mushaf has exactly 114 surahs and 6236 verses', () async {
    final quran = await loadQuran();
    expect(quran.length, 114);

    final totalVerses = quran.values
        .map((v) => (v as List).length)
        .fold<int>(0, (a, b) => a + b);
    expect(
      totalVerses,
      6236,
      reason: 'the canonical Hafs mushaf has 6,236 verses',
    );
  });

  test('spot-checked surah verse counts match the canonical Hafs table',
      () async {
    final quran = await loadQuran();
    const canonical = <int, int>{
      1: 7, // Al-Fatiha
      2: 286, // Al-Baqara
      3: 200, // Aal-Imran
      4: 176, // An-Nisa
      5: 120, // Al-Ma'ida
      6: 165, // Al-An'am
      18: 110, // Al-Kahf
      36: 83, // Ya-Sin
      55: 78, // Ar-Rahman
      112: 4, // Al-Ikhlas
      114: 6, // An-Nas
    };
    for (final entry in canonical.entries) {
      final verses = quran['${entry.key}'] as List;
      expect(
        verses.length,
        entry.value,
        reason: 'surah ${entry.key} must have ${entry.value} verses',
      );
    }
  });

  test('every verse has a number and non-empty text', () async {
    final quran = await loadQuran();
    for (final entry in quran.entries) {
      for (final verse in entry.value as List) {
        final map = verse as Map;
        expect(
          map['verse'],
          isA<int>(),
          reason: 'surah ${entry.key} verse number',
        );
        expect(
          (map['text'] as String).trim(),
          isNotEmpty,
          reason: 'surah ${entry.key} verse ${map['verse']} text',
        );
      }
    }
  });
}
