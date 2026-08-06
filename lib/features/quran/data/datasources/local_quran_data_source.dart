import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/isolate_parser.dart';
import '../../domain/entities/quran_entities.dart'; // Surah entity
import 'quran_datasources.dart'; // Abstract class and Models

class LocalQuranDataSourceImpl implements QuranLocalDataSource {
  // In-memory cache
  final Map<int, SurahModel> _surahCache = {};
  
  static Map<String, dynamic>? _fullQuranMap;
  static List<SurahModel>? _surahMetadata;

  @override
  Future<List<SurahModel>> getAllSurahs() async {
    if (_surahMetadata == null) {
      await _loadMetadata();
    }
    return _surahMetadata!;
  }

  Future<void> _loadMetadata() async {
     final jsonList = await IsolateParser.parseInBackground(
        assetPath: 'assets/quran/surahs.json',
        parser: (json) => List<Map<String, dynamic>>.from(jsonDecode(json)),
      );
      
      _surahMetadata = jsonList.map((json) => SurahModel.fromJson(json)).toList();
  }

  @override
  Future<SurahModel> getSurahWithVerses(int surahNumber) async {
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    if (_surahMetadata == null) {
      await _loadMetadata();
    }

    if (_fullQuranMap == null) {
      _fullQuranMap = await IsolateParser.parseInBackground(
        assetPath: 'assets/quran/quran_uthmani.json',
        parser: (json) => jsonDecode(json) as Map<String, dynamic>,
      );
    }

    final surah = await compute(_buildSurahObject, _BuildSurahArgs(
      surahNumber: surahNumber,
      fullText: _fullQuranMap!,
      metadata: _surahMetadata!,
    ));

    _surahCache[surahNumber] = surah;
    return surah;
  }

  static Map<String, dynamic>? _pagesMap;

  @override
  Future<List<VerseModel>> getVersesByPage(int pageNumber) async {
    if (_pagesMap == null) {
      _pagesMap = await IsolateParser.parseInBackground(
        assetPath: 'assets/quran/quran_pages.json',
        parser: (json) => jsonDecode(json) as Map<String, dynamic>,
      );
    }

    final pageKey = pageNumber.toString();
    final versesRaw = _pagesMap![pageKey] as List?;
    if (versesRaw == null || versesRaw.isEmpty) return [];

    return versesRaw.map((v) {
      final map = v as Map<String, dynamic>;
      return VerseModel(
        number: 0,
        numberInSurah: map['ayah'] as int,
        textUthmani: map['text'] as String,
        page: pageNumber,
        juz: map['juz'] as int? ?? 0,
        hizb: map['hizb'] as int? ?? 0,
        quarter: 0,
        surahNumber: map['surah'] as int? ?? 0,
        surahName: map['surah_name'] as String?,
      );
    }).toList();
  }

  @override
  Future<TafsirModel?> getTafsir(int surahNumber, int verseNumber) async {
    // Implementation for local tafsir
    // For now return null or implement if we have assets
    return null;
  }

  @override
  Future<RevelationCauseModel?> getRevelationCause(int surahNumber, int verseNumber) async {
    return null;
  }

  @override
  Future<List<VerseModel>> searchQuran(String query) async {
    if (query.trim().isEmpty) return [];
    
    if (_fullQuranMap == null) {
      _fullQuranMap = await IsolateParser.parseInBackground(
        assetPath: 'assets/quran/quran_uthmani.json',
        parser: (json) => jsonDecode(json) as Map<String, dynamic>,
      );
    }
    
    // Normalize query for Arabic search (remove diacritics)
    final normalizedQuery = _normalizeArabic(query);
    final List<VerseModel> results = [];
    
    _fullQuranMap!.forEach((surahNum, verses) {
      for (final v in (verses as List)) {
        final text = v['text'] as String? ?? v['text_uthmani'] as String? ?? '';
        final normalizedText = _normalizeArabic(text);
        if (normalizedText.contains(normalizedQuery)) {
          results.add(VerseModel.fromJson(v));
        }
      }
    });
    
    return results;
  }
  
  /// Normalize Arabic text by removing diacritics for better search matching
  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  @override
  Future<void> cacheQuranData(List<SurahModel> surahs) async {
    // No-op for local json source
  }

  // --- Background Builder ---

  static SurahModel _buildSurahObject(_BuildSurahArgs args) {
    final meta = args.metadata.firstWhere((m) => m.number == args.surahNumber);
    final versesRaw = args.fullText[args.surahNumber.toString()] as List;

    final verses = versesRaw.map((v) => VerseModel.fromJson(v)).toList();

    // Reconstruct SurahModel with verses
    return SurahModel(
      number: meta.number,
      nameArabic: meta.nameArabic,
      nameEnglish: meta.nameEnglish,
      englishNameTranslation: meta.englishNameTranslation,
      nameTransliteration: meta.nameTransliteration,
      versesCount: meta.versesCount,
      revelationType: meta.revelationType,
      page: meta.page,
      verses: verses,
    );
  }
}

class _BuildSurahArgs {
  final int surahNumber;
  final Map<String, dynamic> fullText;
  final List<SurahModel> metadata;

  _BuildSurahArgs({
    required this.surahNumber,
    required this.fullText,
    required this.metadata,
  });
}
