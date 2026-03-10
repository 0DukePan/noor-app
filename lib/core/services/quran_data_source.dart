import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'api_fetcher_service.dart';

/// 🕌 مصدر بيانات القرآن - Quran Data Source
/// Hybrid Offline-First Architecture:
/// 1️⃣ assets/quran/ ← المصدر الأساسي (Always Available)
/// 2️⃣ Hive Cache ← تحسين الأداء + التحديثات
/// 3️⃣ API ← تفسير / روايات / تحديث
class QuranDataSource {
  static const _cacheBoxName = 'quran_cache';
  static Box? _cacheBox;
  static final ApiFetcherService _api = ApiFetcherService();

  // Complete Quran in memory (all 114 surahs)
  static Map<String, List<dynamic>>? _quranData;
  static List<Map<String, dynamic>>? _surahsMetadata;

  /// Initialize data source - loads complete Quran into memory
  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
    
    // Load complete Quran on app start (always available)
    await _loadCompleteQuran();
  }

  /// Load complete Quran from bundled assets into memory
  static Future<void> _loadCompleteQuran() async {
    if (_quranData != null) return;
    
    try {
      // Load complete Quran (all 114 surahs in one file)
      final jsonString = await rootBundle.loadString('assets/quran/quran_uthmani.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Convert to proper format
      _quranData = {};
      data.forEach((key, value) {
        _quranData![key] = List<dynamic>.from(value);
      });
      
      // Load surahs metadata
      _surahsMetadata = await getSurahsList();
    } catch (e) {
      throw QuranDataException('فشل تحميل القرآن الكريم: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY: ASSETS (ALWAYS AVAILABLE - 100% OFFLINE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all surahs list (metadata only)
  static Future<List<Map<String, dynamic>>> getSurahsList() async {
    if (_surahsMetadata != null) {
      return _surahsMetadata!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/quran/surahs.json');
      final surahs = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      _surahsMetadata = surahs;
      return surahs;
    } catch (e) {
      throw QuranDataException('فشل تحميل فهرس السور: $e');
    }
  }

  /// Get complete surah with verses - INSTANT from memory
  static Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    // Ensure Quran is loaded
    if (_quranData == null) {
      await _loadCompleteQuran();
    }

    final surahKey = surahNumber.toString();
    final verses = _quranData?[surahKey];
    
    if (verses == null || verses.isEmpty) {
      throw QuranDataException('السورة غير موجودة: $surahNumber');
    }

    // Get surah metadata
    final metadata = _surahsMetadata?.firstWhere(
      (s) => s['number'] == surahNumber,
      orElse: () => {'number': surahNumber, 'name': 'سورة $surahNumber'},
    );

    // Convert verses to expected format
    final ayahs = verses.map((v) => {
      'numberInSurah': v['verse'],
      'text': v['text'],
      'page': 1, // Can be enhanced with page data
      'juz': 1,  // Can be enhanced with juz data
    }).toList();

    return {
      'number': surahNumber,
      'name': metadata?['name'] ?? 'سورة $surahNumber',
      'englishName': metadata?['englishName'] ?? 'Surah $surahNumber',
      'englishNameTranslation': metadata?['englishNameTranslation'] ?? '',
      'revelationType': metadata?['revelationType'] ?? 'Meccan',
      'numberOfAyahs': ayahs.length,
      'ayahs': ayahs,
    };
  }

  /// Get single verse - INSTANT from memory
  static Future<Map<String, dynamic>?> getVerse(int surahNumber, int verseNumber) async {
    if (_quranData == null) {
      await _loadCompleteQuran();
    }

    final verses = _quranData?[surahNumber.toString()];
    if (verses == null) return null;

    final verse = verses.firstWhere(
      (v) => v['verse'] == verseNumber,
      orElse: () => null,
    );

    if (verse == null) return null;

    return {
      'surah': surahNumber,
      'verse': verseNumber,
      'text': verse['text'],
    };
  }

  /// Get all verses count
  static int getTotalVersesCount() {
    if (_quranData == null) return 6236; // Known total
    return _quranData!.values.fold(0, (sum, verses) => sum + verses.length);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCEMENTS: API (OPTIONAL - FOR TAFSIR, AUDIO, ETC)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get tafsir for verse (API + Cache)
  static Future<Map<String, dynamic>?> getTafsir({
    required int surahNumber,
    required int verseNumber,
    String tafsirEdition = 'ar.muyassar',
  }) async {
    final cacheKey = 'tafsir_${surahNumber}_${verseNumber}_$tafsirEdition';

    // Check cache first
    final cached = _cacheBox?.get(cacheKey);
    if (cached != null) {
      return Map<String, dynamic>.from(cached);
    }

    // Fetch from API
    try {
      final data = await _api.fetchTafsir(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafsirEdition: tafsirEdition,
      );
      await _cacheBox?.put(cacheKey, data);
      return data;
    } catch (e) {
      return null; // Tafsir is optional
    }
  }

  /// Get audio URL for verse
  static Future<String?> getAudioUrl({
    required int surahNumber,
    required int verseNumber,
    String reciter = 'ar.alafasy',
  }) async {
    try {
      return await _api.fetchRecitationUrl(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        reciter: reciter,
      );
    } catch (e) {
      return null; // Audio is optional
    }
  }

  /// Clear API cache (keeps bundled Quran)
  static Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  /// Check if Quran is loaded
  static bool get isLoaded => _quranData != null;

  /// Get total surahs count
  static int get totalSurahs => 114;
}

/// Quran data exception
class QuranDataException implements Exception {
  final String message;
  QuranDataException(this.message);

  @override
  String toString() => 'QuranDataException: $message';
}

