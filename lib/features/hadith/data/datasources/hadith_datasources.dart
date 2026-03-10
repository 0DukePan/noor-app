import '../../domain/entities/hadith_entities.dart';

/// مصدر بيانات الحديث المحلي - Hadith Local Data Source
abstract class HadithLocalDataSource {
  /// Get all categories
  Future<List<HadithCategoryModel>> getCategories();

  /// Get hadiths by category
  Future<List<HadithModel>> getHadithsByCategory(String categoryId);

  /// Get hadith by ID
  Future<HadithModel?> getHadithById(String id);

  /// Search hadiths
  Future<List<HadithModel>> searchHadiths(String query);

  /// Cache hadiths
  Future<void> cacheHadiths(String categoryId, List<HadithModel> hadiths);

  /// Get bookmarked hadiths
  Future<List<String>> getBookmarkedHadithIds();

  /// Toggle bookmark
  Future<void> toggleBookmark(String hadithId);
}

/// مصدر بيانات الحديث البعيد - Hadith Remote Data Source (Supabase)
abstract class HadithRemoteDataSource {
  /// Fetch all categories from Supabase
  Future<List<HadithCategoryModel>> fetchCategories();

  /// Fetch hadiths by category from Supabase
  Future<List<HadithModel>> fetchHadithsByCategory(String categoryId);

  /// Fetch hadith explanation
  Future<HadithExplanationModel?> fetchHadithExplanation(String hadithId);
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Hadith Model
class HadithModel extends Hadith {
  const HadithModel({
    required super.id,
    required super.textArabic,
    super.textEnglish,
    required super.narrator,
    required super.source,
    required super.bookName,
    super.hadithNumber,
    required super.grade,
    super.gradingReason,
    super.explanation,
    super.topics,
  });

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      id: json['id'] as String,
      textArabic: json['text_arabic'] as String,
      textEnglish: json['text_english'] as String?,
      narrator: json['narrator'] as String,
      source: json['source'] as String,
      bookName: json['book_name'] as String,
      hadithNumber: json['hadith_number'] as int?,
      grade: _parseGrade(json['grade'] as String),
      gradingReason: json['grading_reason'] as String?,
      explanation: json['explanation'] as String?,
      topics: (json['topics'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static HadithGrade _parseGrade(String grade) {
    switch (grade) {
      case 'sahih':
        return HadithGrade.sahih;
      case 'hasan':
        return HadithGrade.hasan;
      case 'daif':
        return HadithGrade.daif;
      case 'mawdu':
        return HadithGrade.mawdu;
      case 'sahih_li_ghairihi':
        return HadithGrade.sahihLiGhairihi;
      case 'hasan_li_ghairihi':
        return HadithGrade.hasanLiGhairihi;
      default:
        return HadithGrade.sahih;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text_arabic': textArabic,
      'text_english': textEnglish,
      'narrator': narrator,
      'source': source,
      'book_name': bookName,
      'hadith_number': hadithNumber,
      'grade': grade.name,
      'grading_reason': gradingReason,
      'explanation': explanation,
      'topics': topics,
    };
  }
}

/// Hadith Category Model
class HadithCategoryModel extends HadithCategory {
  const HadithCategoryModel({
    required super.id,
    required super.nameArabic,
    required super.nameEnglish,
    required super.hadithCount,
    super.iconName,
  });

  factory HadithCategoryModel.fromJson(Map<String, dynamic> json) {
    return HadithCategoryModel(
      id: json['id'] as String,
      nameArabic: json['name_arabic'] as String,
      nameEnglish: json['name_english'] as String,
      hadithCount: json['hadith_count'] as int? ?? 0,
      iconName: json['icon_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_arabic': nameArabic,
      'name_english': nameEnglish,
      'hadith_count': hadithCount,
      'icon_name': iconName,
    };
  }
}

/// Hadith Explanation Model
class HadithExplanationModel extends HadithExplanation {
  const HadithExplanationModel({
    required super.hadithId,
    required super.explanationText,
    required super.scholarName,
    required super.bookName,
    super.differentOpinions,
  });

  factory HadithExplanationModel.fromJson(Map<String, dynamic> json) {
    return HadithExplanationModel(
      hadithId: json['hadith_id'] as String,
      explanationText: json['explanation_text'] as String,
      scholarName: json['scholar_name'] as String,
      bookName: json['book_name'] as String,
      differentOpinions: (json['different_opinions'] as List<dynamic>?)
          ?.map((e) => ScholarOpinion(
                scholarName: e['scholar_name'] as String,
                opinion: e['opinion'] as String,
                reference: e['reference'] as String?,
              ))
          .toList(),
    );
  }
}
