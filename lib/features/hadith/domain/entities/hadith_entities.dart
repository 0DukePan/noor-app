import 'package:equatable/equatable.dart';

/// حديث - Hadith Entity
class Hadith extends Equatable {
  final String id;
  final String textArabic;
  final String? textEnglish;
  final String narrator;
  final String narratorChain;
  final String source;
  final String bookName;
  final String chapterName;
  final int? hadithNumber;
  final HadithGrade grade;
  final String? gradingReason;
  final String? explanation;
  final List<String> topics;

  const Hadith({
    required this.id,
    required this.textArabic,
    this.textEnglish,
    this.narrator = '',
    this.narratorChain = '',
    required this.source,
    required this.bookName,
    this.chapterName = '',
    this.hadithNumber,
    required this.grade,
    this.gradingReason,
    this.explanation,
    this.topics = const [],
  });

  @override
  List<Object?> get props => [id, textArabic, source, grade];
}

/// درجة الحديث - Hadith Grade
enum HadithGrade {
  /// صحيح - Authentic
  sahih,

  /// حسن - Good
  hasan,

  /// ضعيف - Weak
  daif,

  /// موضوع - Fabricated
  mawdu,

  /// صحيح لغيره
  sahihLiGhairihi,

  /// حسن لغيره
  hasanLiGhairihi,

  /// غير معروف
  unknown,
}

/// تصنيف الحديث - Hadith Category
class HadithCategory extends Equatable {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final int hadithCount;
  final String? iconName;

  const HadithCategory({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.hadithCount,
    this.iconName,
  });

  @override
  List<Object?> get props => [id, nameArabic];
}

/// شرح الحديث - Hadith Explanation
class HadithExplanation extends Equatable {
  final String hadithId;
  final String explanationText;
  final String scholarName;
  final String bookName;
  final List<ScholarOpinion>? differentOpinions;

  const HadithExplanation({
    required this.hadithId,
    required this.explanationText,
    required this.scholarName,
    required this.bookName,
    this.differentOpinions,
  });

  @override
  List<Object?> get props => [hadithId, scholarName];
}

/// رأي عالم - Scholar Opinion
class ScholarOpinion extends Equatable {
  final String scholarName;
  final String opinion;
  final String? reference;

  const ScholarOpinion({
    required this.scholarName,
    required this.opinion,
    this.reference,
  });

  @override
  List<Object?> get props => [scholarName, opinion];
}
