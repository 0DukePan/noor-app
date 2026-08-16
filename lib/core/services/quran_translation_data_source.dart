import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// لغة الترجمة.
enum TranslationLanguage {
  /// العربية — تفسير الميسر (Tanzil).
  arabic,

  /// الإنجليزية — Saheeh International.
  english,
}

/// مصدر ترجمات القرآن — عربية (الميسر) وإنجليزية (Saheeh International).
/// تُحمَّل مرة واحدة في خلفية وتُخزَّن في الذاكرة، وتبقى الترجمة محلية دون إنترنت.
class QuranTranslationDataSource {
  static final Map<TranslationLanguage, Map<int, Map<int, String>>> _cache = {};

  /// ترجمة آية معينة، أو null إن لم تتوفر.
  static Future<String?> getTranslation(
    int surah,
    int ayah, {
    TranslationLanguage language = TranslationLanguage.arabic,
  }) async {
    final map = await ensureLoaded(language);
    return map[surah]?[ayah];
  }

  /// ترجمة سورة كاملة (رقم الآية → النص).
  static Future<Map<int, String>?> getSurah(
    int surah, {
    TranslationLanguage language = TranslationLanguage.arabic,
  }) async {
    final map = await ensureLoaded(language);
    return map[surah];
  }

  static Future<Map<int, Map<int, String>>> ensureLoaded(
    TranslationLanguage language,
  ) async {
    final cached = _cache[language];
    if (cached != null) return cached;
    final jsonString = await rootBundle.loadString(_assetPath(language));
    final parsed = await compute(_parseTranslation, jsonString);
    _cache[language] = parsed;
    return parsed;
  }

  static String _assetPath(TranslationLanguage language) {
    switch (language) {
      case TranslationLanguage.arabic:
        return 'assets/quran/translations/ar_muyassar.json';
      case TranslationLanguage.english:
        return 'assets/quran/translations/en_sahih.json';
    }
  }

  /// إعادة تحميل (لأغراض الاختبار).
  static void resetCache() => _cache.clear();
}

/// دالة مستوى أعلى لـ compute — تحليل JSON في عزلة خلفية.
Map<int, Map<int, String>> _parseTranslation(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final data = json['data'] as Map<String, dynamic>;
  final surahs = data['surahs'] as List;
  final result = <int, Map<int, String>>{};
  for (final s in surahs) {
    final sMap = s as Map<String, dynamic>;
    final number = sMap['number'] as int;
    final ayahs = sMap['ayahs'] as List;
    final verses = <int, String>{};
    for (final a in ayahs) {
      final aMap = a as Map<String, dynamic>;
      verses[aMap['numberInSurah'] as int] = aMap['text'] as String;
    }
    result[number] = verses;
  }
  return result;
}
