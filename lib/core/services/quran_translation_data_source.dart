import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// مصدر الترجمة العربية (تفسير الميسر) — يُحمَّل مرة واحدة في خلفية
/// ويُخزَّن في الذاكرة، وتبقى الترجمة محلية دون إنترنت.
///
/// البيانات من نص تنزيل (Tanzil) عبر API مفتوح — مراجعة المصدر مطلوبة.
class QuranTranslationDataSource {
  static Map<int, Map<int, String>>? _cache;

  /// ترجمة آية معينة، أو null إن لم تتوفر.
  static Future<String?> getTranslation(int surah, int ayah) async {
    final map = await ensureLoaded();
    return map[surah]?[ayah];
  }

  /// ترجمة سورة كاملة (رقم الآية → النص).
  static Future<Map<int, String>?> getSurah(int surah) async {
    final map = await ensureLoaded();
    return map[surah];
  }

  static Future<Map<int, Map<int, String>>> ensureLoaded() async {
    if (_cache != null) return _cache!;
    final jsonString =
        await rootBundle.loadString('assets/quran/translations/ar_muyassar.json');
    _cache = await compute(_parseTranslation, jsonString);
    return _cache!;
  }

  /// إعادة تحميل (لأغراض الاختبار).
  static void resetCache() => _cache = null;
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
