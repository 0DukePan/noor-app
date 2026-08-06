import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/surah.dart';
import '../../utils/isolate_parser.dart';

class LocalQuranDataSource {
  // In-memory cache for loaded Surahs to avoid re-parsing
  final Map<int, Surah> _surahCache = {};
  
  // Cache for the full text map to avoid re-reading huge JSON on every surah switch
  // But strictly for performance, we might want to keep it or just keeping individual surahs is better?
  // quran_uthmani.json contains ALL surahs. Loading it once is heavy but necessary.
  // We will cache the RAW MAP of quran_uthmani.json
  static Map<String, dynamic>? _fullQuranMap;
  static List<Map<String, dynamic>>? _surahMetadata;

  /// Gets a specific Surah with all its verses.
  Future<Surah> getSurah(int surahNumber) async {
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    // Load Metadata first if needed
    if (_surahMetadata == null) {
      await _loadMetadata();
    }

    // Load Full Text if needed
    if (_fullQuranMap == null) {
      // This is a ~4MB file, acceptable to load once in isolate
      _fullQuranMap = await IsolateParser.parseInBackground(
        assetPath: 'assets/quran/quran_uthmani.json',
        parser: (json) => jsonDecode(json) as Map<String, dynamic>,
      );
    }

    // Build Surah Object
    final surah = await compute(_buildSurahObject, _BuildSurahArgs(
      surahNumber: surahNumber,
      fullText: _fullQuranMap!,
      metadata: _surahMetadata!,
    ));

    _surahCache[surahNumber] = surah;
    return surah;
  }

  Future<void> _loadMetadata() async {
     final jsonList = await IsolateParser.parseInBackground(
        assetPath: 'assets/quran/surahs.json',
        parser: (json) => List<Map<String, dynamic>>.from(jsonDecode(json)),
      );
      _surahMetadata = jsonList;
  }

  /// Get list of all Surahs (Metadata only, for Index Page)
  Future<List<Surah>> getAllSurahs() async {
     if (_surahMetadata == null) {
      await _loadMetadata();
    }
    
    // Map simplified Surah objects (without verses for lightweight list)
    return _surahMetadata!.map((m) => Surah(
      number: m['number'],
      nameArabic: m['name'],
      nameEnglish: m['englishName'],
      englishNameTranslation: m['englishNameTranslation'],
      versesCount: m['numberOfAyahs'],
      revelationType: (m['revelationType'] == 'Meccan') ? RevelationType.meccan : RevelationType.medinan,
      verses: const [], // Empty verses for index list
    )).toList();
  }

  // --- Background Builder ---

  static Surah _buildSurahObject(_BuildSurahArgs args) {
    final meta = args.metadata.firstWhere((m) => m['number'] == args.surahNumber);
    final versesRaw = args.fullText[args.surahNumber.toString()] as List;

    final verses = versesRaw.map((v) => Verse(
      number: 0, // We assume global number might not be in this specific json, or we calculate it
      numberInSurah: v['verse'],
      textUthmani: v['text'],
    )).toList();

    return Surah(
      number: args.surahNumber,
      nameArabic: meta['name'],
      nameEnglish: meta['englishName'],
      englishNameTranslation: meta['englishNameTranslation'],
      versesCount: meta['numberOfAyahs'],
      revelationType: (meta['revelationType'] == 'Meccan') ? RevelationType.meccan : RevelationType.medinan,
      verses: verses,
    );
  }
}

class _BuildSurahArgs {
  final int surahNumber;
  final Map<String, dynamic> fullText;
  final List<Map<String, dynamic>> metadata;

  _BuildSurahArgs({
    required this.surahNumber,
    required this.fullText,
    required this.metadata,
  });
}
