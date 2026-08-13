import 'package:equatable/equatable.dart';

export '../../../../core/domain/entities/surah.dart';
// Verse is defined in surah.dart alongside Surah

/// تفسير - Tafsir Entity
class Tafsir extends Equatable {

  const Tafsir({
    required this.surahNumber,
    required this.verseNumber,
    required this.briefText,
    required this.source, required this.author, this.detailedText,
  });
  final int surahNumber;
  final int verseNumber;
  final String briefText;
  final String? detailedText;
  final String source;
  final String author;

  @override
  List<Object?> get props => [surahNumber, verseNumber, source];
}

/// سبب النزول - Revelation Cause Entity
class RevelationCause extends Equatable {

  const RevelationCause({
    required this.surahNumber,
    required this.verseNumber,
    required this.briefSummary,
    required this.causeType, required this.source, this.fullStory,
    this.historicalContext,
  });
  final int surahNumber;
  final int verseNumber;
  final String briefSummary;
  final String? fullStory;
  final CauseType causeType;
  final String source;
  final String? historicalContext;

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

/// تدبر - Tadabbur (Personal Reflection)
class Tadabbur extends Equatable {

  const Tadabbur({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    required this.encryptedNote,
    required this.createdAt,
    this.updatedAt,
  });
  final String id;
  final int surahNumber;
  final int verseNumber;
  final String encryptedNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, surahNumber, verseNumber];
}
