/// 📿 نماذج بيانات الأذكار - Adhkar Data Models
library;

/// نوع الأذكار
enum AdhkarType {
  morning,     // أذكار الصباح
  evening,     // أذكار المساء
  afterPrayer, // أذكار بعد الصلاة
  sleep,       // أذكار النوم
  wakeUp,      // أذكار الاستيقاظ
  general,     // أذكار عامة
}

/// ذكر واحد
class Zekr {

  const Zekr({
    required this.index,
    required this.text,
    required this.repeat,
    required this.type, this.bless,
  });

  factory Zekr.fromJson(Map<String, dynamic> json, int index, AdhkarType type) {
    return Zekr(
      index: index,
      text: (json['zekr'] as String?) ?? '',
      repeat: (json['repeat'] as num?)?.toInt() ?? 1,
      bless: ((json['bless'] as String?) ?? '').isNotEmpty
          ? json['bless'] as String
          : null,
      type: type,
    );
  }
  final int index;
  final String text;
  final int repeat;
  final String? bless;
  final AdhkarType type;

  /// المفتاح الفريد
  String get key => '${type.name}:$index';
}

/// مجموعة أذكار
class AdhkarCollection {

  const AdhkarCollection({
    required this.title,
    required this.type,
    required this.adhkar,
  });

  factory AdhkarCollection.fromJson(Map<String, dynamic> json, AdhkarType type) {
    final content = json['content'] as List? ?? [];
    return AdhkarCollection(
      title: (json['title'] as String?) ?? '',
      type: type,
      adhkar: content.asMap().entries.map((e) => 
        Zekr.fromJson(Map<String, dynamic>.from(e.value as Map), e.key, type),
      ).toList(),
    );
  }
  final String title;
  final AdhkarType type;
  final List<Zekr> adhkar;

  /// عدد الأذكار
  int get count => adhkar.length;

  /// إجمالي التكرارات
  int get totalRepeat => adhkar.fold(0, (sum, z) => sum + z.repeat);
}

/// حالة تقدم الأذكار
class AdhkarProgress {

  const AdhkarProgress({
    required this.type,
    this.currentIndex = 0,
    this.currentCount = 0,
    this.isCompleted = false,
    this.startedAt,
    this.completedAt,
  });

  factory AdhkarProgress.fromJson(Map<String, dynamic> json) {
    return AdhkarProgress(
      type: AdhkarType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AdhkarType.general,
      ),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
    );
  }
  final AdhkarType type;
  final int currentIndex;
  final int currentCount;
  final bool isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// نسخة مع تقدم
  AdhkarProgress increment() => AdhkarProgress(
    type: type,
    currentIndex: currentIndex,
    currentCount: currentCount + 1,
    isCompleted: isCompleted,
    startedAt: startedAt ?? DateTime.now(),
  );

  /// نسخة مع الانتقال للذكر التالي
  AdhkarProgress nextZekr() => AdhkarProgress(
    type: type,
    currentIndex: currentIndex + 1,
    isCompleted: isCompleted,
    startedAt: startedAt,
  );

  /// نسخة مكتملة
  AdhkarProgress complete() => AdhkarProgress(
    type: type,
    currentIndex: currentIndex,
    currentCount: currentCount,
    isCompleted: true,
    startedAt: startedAt,
    completedAt: DateTime.now(),
  );

  /// إعادة تعيين
  AdhkarProgress reset() => AdhkarProgress(type: type);

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'currentIndex': currentIndex,
    'currentCount': currentCount,
    'isCompleted': isCompleted,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };
}

/// إحصائيات الأذكار اليومية
class DailyAdhkarStats {

  const DailyAdhkarStats({
    required this.date,
    this.morningCompleted = false,
    this.eveningCompleted = false,
    this.afterPrayerCount = 0,
    this.totalAdhkarCount = 0,
  });

  factory DailyAdhkarStats.fromJson(Map<String, dynamic> json) {
    return DailyAdhkarStats(
      date: DateTime.parse(json['date'] as String),
      morningCompleted: json['morningCompleted'] as bool? ?? false,
      eveningCompleted: json['eveningCompleted'] as bool? ?? false,
      afterPrayerCount: (json['afterPrayerCount'] as num?)?.toInt() ?? 0,
      totalAdhkarCount: (json['totalAdhkarCount'] as num?)?.toInt() ?? 0,
    );
  }
  final DateTime date;
  final bool morningCompleted;
  final bool eveningCompleted;
  final int afterPrayerCount;
  final int totalAdhkarCount;

  /// هل اكتمل اليوم؟
  bool get isComplete => morningCompleted && eveningCompleted;

  /// نسبة الإتمام
  double get progress {
    var completed = 0;
    if (morningCompleted) completed++;
    if (eveningCompleted) completed++;
    return completed / 2.0;
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'morningCompleted': morningCompleted,
    'eveningCompleted': eveningCompleted,
    'afterPrayerCount': afterPrayerCount,
    'totalAdhkarCount': totalAdhkarCount,
  };
}

/// إعدادات عرض الأذكار
class AdhkarDisplaySettings { // milliseconds

  const AdhkarDisplaySettings({
    this.fontSize = 22.0,
    this.showBless = true,
    this.vibrateOnComplete = true,
    this.autoAdvance = false,
    this.autoAdvanceDelay = 500,
  });

  factory AdhkarDisplaySettings.fromJson(Map<String, dynamic> json) {
    return AdhkarDisplaySettings(
      fontSize: ((json['fontSize'] ?? 22.0) as num).toDouble(),
      showBless: json['showBless'] as bool? ?? true,
      vibrateOnComplete: json['vibrateOnComplete'] as bool? ?? true,
      autoAdvance: json['autoAdvance'] as bool? ?? false,
      autoAdvanceDelay: (json['autoAdvanceDelay'] as num?)?.toInt() ?? 500,
    );
  }
  final double fontSize;
  final bool showBless;
  final bool vibrateOnComplete;
  final bool autoAdvance;
  final int autoAdvanceDelay;

  AdhkarDisplaySettings copyWith({
    double? fontSize,
    bool? showBless,
    bool? vibrateOnComplete,
    bool? autoAdvance,
    int? autoAdvanceDelay,
  }) {
    return AdhkarDisplaySettings(
      fontSize: fontSize ?? this.fontSize,
      showBless: showBless ?? this.showBless,
      vibrateOnComplete: vibrateOnComplete ?? this.vibrateOnComplete,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      autoAdvanceDelay: autoAdvanceDelay ?? this.autoAdvanceDelay,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'showBless': showBless,
    'vibrateOnComplete': vibrateOnComplete,
    'autoAdvance': autoAdvance,
    'autoAdvanceDelay': autoAdvanceDelay,
  };
}

/// معلومات نوع الأذكار
extension AdhkarTypeInfo on AdhkarType {
  String get arabicName {
    switch (this) {
      case AdhkarType.morning: return 'أذكار الصباح';
      case AdhkarType.evening: return 'أذكار المساء';
      case AdhkarType.afterPrayer: return 'أذكار بعد الصلاة';
      case AdhkarType.sleep: return 'أذكار النوم';
      case AdhkarType.wakeUp: return 'أذكار الاستيقاظ';
      case AdhkarType.general: return 'أذكار عامة';
    }
  }

  String get icon {
    switch (this) {
      case AdhkarType.morning: return '🌅';
      case AdhkarType.evening: return '🌇';
      case AdhkarType.afterPrayer: return '🕌';
      case AdhkarType.sleep: return '🌙';
      case AdhkarType.wakeUp: return '☀️';
      case AdhkarType.general: return '📿';
    }
  }

  String get assetPath {
    switch (this) {
      case AdhkarType.morning: return 'assets/adhkar/morning.json';
      case AdhkarType.evening: return 'assets/adhkar/evening.json';
      case AdhkarType.afterPrayer: return 'assets/adhkar/after_prayer.json';
      case AdhkarType.sleep: return 'assets/adhkar/sleep.json';
      case AdhkarType.wakeUp: return 'assets/adhkar/wakeup.json';
      case AdhkarType.general: return 'assets/adhkar/general.json';
    }
  }
}
