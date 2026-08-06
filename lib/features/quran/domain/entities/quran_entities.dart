import 'package:equatable/equatable.dart';

export '../../../../core/domain/entities/surah.dart';
// Verse is defined in surah.dart alongside Surah

/// تفسير - Tafsir Entity
class Tafsir extends Equatable {
  final int surahNumber;
  final int verseNumber;
  final String briefText;
  final String? detailedText;
  final String source;
  final String author;

  const Tafsir({
    required this.surahNumber,
    required this.verseNumber,
    required this.briefText,
    this.detailedText,
    required this.source,
    required this.author,
  });

  @override
  List<Object?> get props => [surahNumber, verseNumber, source];
}

/// سبب النزول - Revelation Cause Entity
class RevelationCause extends Equatable {
  final int surahNumber;
  final int verseNumber;
  final String briefSummary;
  final String? fullStory;
  final CauseType causeType;
  final String source;
  final String? historicalContext;

  const RevelationCause({
    required this.surahNumber,
    required this.verseNumber,
    required this.briefSummary,
    this.fullStory,
    required this.causeType,
    required this.source,
    this.historicalContext,
  });

  @override
  List<Object?> get props => [surahNumber, verseNumber, causeType];
}

/// نوع سبب النزول - Cause Type
enum CauseType {
  /// حدث - Event
  event,

  /// سؤال - Question
  question,

  /// واقعة شخصية - Personal incident
  personalIncident,

  /// تشريع - Legislation
  legislation,
}

/// ختمة - Khatmah (Quran Completion Plan)
class Khatmah extends Equatable {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? targetEndDate;
  final int currentSurah;
  final int currentVerse;
  final int currentPage;
  final double progressPercentage;

  const Khatmah({
    required this.id,
    required this.name,
    required this.startDate,
    this.targetEndDate,
    required this.currentSurah,
    required this.currentVerse,
    required this.currentPage,
    required this.progressPercentage,
  });

  @override
  List<Object?> get props => [id, name, progressPercentage];
}

/// تدبر - Tadabbur (Personal Reflection)
class Tadabbur extends Equatable {
  final String id;
  final int surahNumber;
  final int verseNumber;
  final String encryptedNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Tadabbur({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    required this.encryptedNote,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, surahNumber, verseNumber];
}
