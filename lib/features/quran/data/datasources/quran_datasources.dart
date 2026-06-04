import '../../../../core/domain/entities/surah.dart';
import '../../domain/entities/quran_entities.dart' hide Surah, Verse, RevelationType;

/// مصدر البيانات المحلي للقرآن - Quran Local Data Source
abstract class QuranLocalDataSource {
  /// Get all Surahs metadata from local storage
  Future<List<SurahModel>> getAllSurahs();

  /// Get Surah with verses from local storage
  Future<SurahModel> getSurahWithVerses(int surahNumber);

  /// Get verses by page
  Future<List<VerseModel>> getVersesByPage(int pageNumber);

  /// Get Tafsir from local storage
  Future<TafsirModel?> getTafsir(int surahNumber, int verseNumber);

  /// Get revelation cause from local storage
  Future<RevelationCauseModel?> getRevelationCause(int surahNumber, int verseNumber);

  /// Search Quran locally
  Future<List<VerseModel>> searchQuran(String query);

  /// Cache Quran data
  Future<void> cacheQuranData(List<SurahModel> surahs);
}

/// مصدر البيانات البعيد للقرآن - Quran Remote Data Source (Supabase)
abstract class QuranRemoteDataSource {
  /// Fetch Quran data from Supabase
  Future<List<SurahModel>> fetchAllSurahs();

  /// Fetch Tafsir from Supabase
  Future<TafsirModel> fetchTafsir(int surahNumber, int verseNumber, String source);

  /// Fetch revelation causes from Supabase
  Future<RevelationCauseModel?> fetchRevelationCause(int surahNumber, int verseNumber);

  /// Sync local data with server
  Future<void> syncQuranData();
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Model for Verse (extends Entity for JSON serialization)
class VerseModel extends Verse {
  const VerseModel({
    required super.number,
    required super.numberInSurah,
    required super.textUthmani,
    super.textSimple,
    required super.page,
    required super.juz,
    required super.hizb,
    required super.quarter,
    super.sajdah,
    super.surahNumber,
    super.surahName,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      number: json['number'] as int? ?? 0,
      numberInSurah: (json['verse'] ?? json['verse_number']) as int,
      textUthmani: (json['text'] ?? json['text_uthmani']) as String,
      textSimple: json['text_simple'] as String?,
      page: json['page'] as int? ?? 0,
      juz: json['juz'] as int? ?? 0,
      hizb: json['hizb'] as int? ?? 0,
      quarter: json['quarter'] as int? ?? 0,
      sajdah: json['sajdah'] as bool? ?? false,
      surahNumber: json['chapter'] as int? ?? json['surah'] as int? ?? 0,
      surahName: json['surah_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah_number': surahNumber,
      'verse_number': numberInSurah,
      'text_uthmani': textUthmani,
      'text_simple': textSimple,
      'page': page,
      'juz': juz,
      'hizb': hizb,
      'quarter': quarter,
      'sajdah': sajdah,
    };
  }
}

/// Model for Surah
class SurahModel extends Surah {
  const SurahModel({
    required super.number,
    required super.nameArabic,
    required super.nameEnglish,
    required super.englishNameTranslation,
    required super.nameTransliteration,
    required super.versesCount,
    required super.revelationType,
    required super.page,
    super.verses = const [],
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] as int,
      nameArabic: (json['name'] ?? json['name_arabic']) as String,
      nameEnglish: (json['englishName'] ?? json['name_english']) as String,
      englishNameTranslation: (json['englishNameTranslation'] ?? json['english_name_translation'] ?? '') as String,
      nameTransliteration: (json['name_transliteration'] ?? '') as String,
      versesCount: (json['numberOfAyahs'] ?? json['verses_count']) as int,
      revelationType: _parseRevelationType(json['revelationType'] ?? json['revelation_type'] ?? ''),
      page: json['page'] as int? ?? 0,
      verses: (json['verses'] as List<dynamic>?)
              ?.map((v) => VerseModel.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static RevelationType _parseRevelationType(String type) {
    final lower = type.toLowerCase();
    if (lower == 'meccan' || lower == 'makki' || lower == 'makkah') {
      return RevelationType.meccan;
    }
    return RevelationType.medinan;
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name_arabic': nameArabic,
      'name_english': nameEnglish,
      'english_name_translation': englishNameTranslation,
      'name_transliteration': nameTransliteration,
      'verses_count': versesCount,
      'revelation_type': revelationType == RevelationType.meccan ? 'makki' : 'madani',
      'page': page,
    };
  }
}

/// Model for Tafsir
class TafsirModel extends Tafsir {
  const TafsirModel({
    required super.surahNumber,
    required super.verseNumber,
    required super.briefText,
    super.detailedText,
    required super.source,
    required super.author,
  });

  factory TafsirModel.fromJson(Map<String, dynamic> json) {
    return TafsirModel(
      surahNumber: json['surah_number'] as int,
      verseNumber: json['verse_number'] as int,
      briefText: json['brief_text'] as String,
      detailedText: json['detailed_text'] as String?,
      source: json['source'] as String,
      author: json['author'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah_number': surahNumber,
      'verse_number': verseNumber,
      'brief_text': briefText,
      'detailed_text': detailedText,
      'source': source,
      'author': author,
    };
  }
}

/// Model for Revelation Cause
class RevelationCauseModel extends RevelationCause {
  const RevelationCauseModel({
    required super.surahNumber,
    required super.verseNumber,
    required super.briefSummary,
    super.fullStory,
    required super.causeType,
    required super.source,
    super.historicalContext,
  });

  factory RevelationCauseModel.fromJson(Map<String, dynamic> json) {
    return RevelationCauseModel(
      surahNumber: json['surah_number'] as int,
      verseNumber: json['verse_number'] as int,
      briefSummary: json['brief_summary'] as String,
      fullStory: json['full_story'] as String?,
      causeType: _parseCauseType(json['cause_type'] as String),
      source: json['source'] as String,
      historicalContext: json['historical_context'] as String?,
    );
  }

  static CauseType _parseCauseType(String type) {
    switch (type) {
      case 'event':
        return CauseType.event;
      case 'question':
        return CauseType.question;
      case 'personal_incident':
        return CauseType.personalIncident;
      case 'legislation':
        return CauseType.legislation;
      default:
        return CauseType.event;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'surah_number': surahNumber,
      'verse_number': verseNumber,
      'brief_summary': briefSummary,
      'full_story': fullStory,
      'cause_type': causeType.name,
      'source': source,
      'historical_context': historicalContext,
    };
  }
}
