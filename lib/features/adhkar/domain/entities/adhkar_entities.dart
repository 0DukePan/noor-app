import 'package:equatable/equatable.dart';

/// ذكر - Dhikr Entity
class Dhikr extends Equatable {
  final String id;
  final String textArabic;
  final String? textEnglish;
  final String? transliteration;
  final int targetCount;
  final String? reward;
  final String? source;
  final DhikrCategory category;
  final MoodType? moodType;

  const Dhikr({
    required this.id,
    required this.textArabic,
    this.textEnglish,
    this.transliteration,
    required this.targetCount,
    this.reward,
    this.source,
    required this.category,
    this.moodType,
  });

  @override
  List<Object?> get props => [id, textArabic, category];
}

/// تصنيف الذكر - Dhikr Category
enum DhikrCategory {
  /// أذكار الصباح
  morning,

  /// أذكار المساء
  evening,

  /// أذكار بعد الصلاة
  afterPrayer,

  /// أذكار النوم
  sleep,

  /// أذكار الاستيقاظ
  wakeUp,

  /// أذكار متفرقة
  general,

  /// أذكار حسب الحالة
  moodBased,
}

/// الحالة الشعورية - Mood Type
enum MoodType {
  /// قلق - Anxiety
  anxiety,

  /// حزن - Sadness
  sadness,

  /// فرح - Joy
  joy,

  /// خوف - Fear
  fear,

  /// غضب - Anger
  anger,

  /// شكر - Gratitude
  gratitude,
}

/// مجموعة أذكار - Adhkar Collection
class AdhkarCollection extends Equatable {
  final String id;
  final String titleArabic;
  final String? titleEnglish;
  final DhikrCategory category;
  final List<Dhikr> adhkar;
  final String? iconName;

  const AdhkarCollection({
    required this.id,
    required this.titleArabic,
    this.titleEnglish,
    required this.category,
    required this.adhkar,
    this.iconName,
  });

  int get totalCount => adhkar.fold(0, (sum, d) => sum + d.targetCount);

  @override
  List<Object?> get props => [id, category];
}

/// سجل الذكر - Dhikr Progress
class DhikrProgress extends Equatable {
  final String dhikrId;
  final int currentCount;
  final int targetCount;
  final DateTime date;
  final bool isCompleted;

  const DhikrProgress({
    required this.dhikrId,
    required this.currentCount,
    required this.targetCount,
    required this.date,
  }) : isCompleted = currentCount >= targetCount;

  double get progressPercentage => targetCount > 0 ? currentCount / targetCount : 0;

  @override
  List<Object?> get props => [dhikrId, currentCount, date];
}

/// إعدادات السبحة - Tasbeeh Settings
class TasbeehSettings extends Equatable {
  final String selectedDhikr;
  final int targetCount;
  final bool hapticEnabled;
  final bool soundEnabled;
  final bool vibrateOnComplete;

  const TasbeehSettings({
    required this.selectedDhikr,
    required this.targetCount,
    this.hapticEnabled = true,
    this.soundEnabled = false,
    this.vibrateOnComplete = true,
  });

  @override
  List<Object?> get props => [selectedDhikr, targetCount];
}
