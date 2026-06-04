import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SURAH REFERENCE DATA — ALL 114 surahs with Mushaf Madina page numbers
// ═══════════════════════════════════════════════════════════════════════════

const _surahPages = <int, ({String name, int startPage})>{
  1: (name: 'الفاتحة', startPage: 1),
  2: (name: 'البقرة', startPage: 2),
  3: (name: 'آل عمران', startPage: 50),
  4: (name: 'النساء', startPage: 77),
  5: (name: 'المائدة', startPage: 106),
  6: (name: 'الأنعام', startPage: 128),
  7: (name: 'الأعراف', startPage: 151),
  8: (name: 'الأنفال', startPage: 177),
  9: (name: 'التوبة', startPage: 187),
  10: (name: 'يونس', startPage: 208),
  11: (name: 'هود', startPage: 221),
  12: (name: 'يوسف', startPage: 235),
  13: (name: 'الرعد', startPage: 249),
  14: (name: 'إبراهيم', startPage: 255),
  15: (name: 'الحجر', startPage: 262),
  16: (name: 'النحل', startPage: 267),
  17: (name: 'الإسراء', startPage: 282),
  18: (name: 'الكهف', startPage: 293),
  19: (name: 'مريم', startPage: 305),
  20: (name: 'طه', startPage: 312),
  21: (name: 'الأنبياء', startPage: 322),
  22: (name: 'الحج', startPage: 332),
  23: (name: 'المؤمنون', startPage: 342),
  24: (name: 'النور', startPage: 350),
  25: (name: 'الفرقان', startPage: 359),
  26: (name: 'الشعراء', startPage: 367),
  27: (name: 'النمل', startPage: 377),
  28: (name: 'القصص', startPage: 385),
  29: (name: 'العنكبوت', startPage: 396),
  30: (name: 'الروم', startPage: 404),
  31: (name: 'لقمان', startPage: 411),
  32: (name: 'السجدة', startPage: 415),
  33: (name: 'الأحزاب', startPage: 418),
  34: (name: 'سبأ', startPage: 428),
  35: (name: 'فاطر', startPage: 434),
  36: (name: 'يس', startPage: 440),
  37: (name: 'الصافات', startPage: 446),
  38: (name: 'ص', startPage: 453),
  39: (name: 'الزمر', startPage: 458),
  40: (name: 'غافر', startPage: 467),
  41: (name: 'فصلت', startPage: 477),
  42: (name: 'الشورى', startPage: 483),
  43: (name: 'الزخرف', startPage: 489),
  44: (name: 'الدخان', startPage: 496),
  45: (name: 'الجاثية', startPage: 499),
  46: (name: 'الأحقاف', startPage: 502),
  47: (name: 'محمد', startPage: 507),
  48: (name: 'الفتح', startPage: 511),
  49: (name: 'الحجرات', startPage: 515),
  50: (name: 'ق', startPage: 518),
  51: (name: 'الذاريات', startPage: 520),
  52: (name: 'الطور', startPage: 523),
  53: (name: 'النجم', startPage: 526),
  54: (name: 'القمر', startPage: 528),
  55: (name: 'الرحمن', startPage: 531),
  56: (name: 'الواقعة', startPage: 534),
  57: (name: 'الحديد', startPage: 537),
  58: (name: 'المجادلة', startPage: 542),
  59: (name: 'الحشر', startPage: 545),
  60: (name: 'الممتحنة', startPage: 549),
  61: (name: 'الصف', startPage: 551),
  62: (name: 'الجمعة', startPage: 553),
  63: (name: 'المنافقون', startPage: 554),
  64: (name: 'التغابن', startPage: 556),
  65: (name: 'الطلاق', startPage: 558),
  66: (name: 'التحريم', startPage: 560),
  67: (name: 'الملك', startPage: 562),
  68: (name: 'القلم', startPage: 564),
  69: (name: 'الحاقة', startPage: 566),
  70: (name: 'المعارج', startPage: 568),
  71: (name: 'نوح', startPage: 570),
  72: (name: 'الجن', startPage: 572),
  73: (name: 'المزمل', startPage: 574),
  74: (name: 'المدثر', startPage: 575),
  75: (name: 'القيامة', startPage: 577),
  76: (name: 'الإنسان', startPage: 578),
  77: (name: 'المرسلات', startPage: 580),
  78: (name: 'النبأ', startPage: 582),
  79: (name: 'النازعات', startPage: 583),
  80: (name: 'عبس', startPage: 585),
  81: (name: 'التكوير', startPage: 586),
  82: (name: 'الانفطار', startPage: 587),
  83: (name: 'المطففين', startPage: 587),
  84: (name: 'الانشقاق', startPage: 588),
  85: (name: 'البروج', startPage: 590),
  86: (name: 'الطارق', startPage: 591),
  87: (name: 'الأعلى', startPage: 591),
  88: (name: 'الغاشية', startPage: 592),
  89: (name: 'الفجر', startPage: 593),
  90: (name: 'البلد', startPage: 594),
  91: (name: 'الشمس', startPage: 595),
  92: (name: 'الليل', startPage: 595),
  93: (name: 'الضحى', startPage: 596),
  94: (name: 'الشرح', startPage: 596),
  95: (name: 'التين', startPage: 597),
  96: (name: 'العلق', startPage: 597),
  97: (name: 'القدر', startPage: 598),
  98: (name: 'البينة', startPage: 598),
  99: (name: 'الزلزلة', startPage: 599),
  100: (name: 'العاديات', startPage: 599),
  101: (name: 'القارعة', startPage: 600),
  102: (name: 'التكاثر', startPage: 600),
  103: (name: 'العصر', startPage: 601),
  104: (name: 'الهمزة', startPage: 601),
  105: (name: 'الفيل', startPage: 601),
  106: (name: 'قريش', startPage: 602),
  107: (name: 'الماعون', startPage: 602),
  108: (name: 'الكوثر', startPage: 602),
  109: (name: 'الكافرون', startPage: 603),
  110: (name: 'النصر', startPage: 603),
  111: (name: 'المسد', startPage: 603),
  112: (name: 'الإخلاص', startPage: 604),
  113: (name: 'الفلق', startPage: 604),
  114: (name: 'الناس', startPage: 604),
};

/// Get surah name by number
String surahName(int number) {
  return _surahPages[number]?.name ?? 'سورة $number';
}

/// Get surahs that fall within a page range (uses full 114 surah data)
String _surahsInRange(int fromPage, int toPage) {
  final sorted = _surahPages.entries
      .where((e) => e.value.startPage >= fromPage && e.value.startPage <= toPage)
      .map((e) => e.value.name)
      .toList();
  if (sorted.isEmpty) return '';
  if (sorted.length <= 3) return sorted.join(' - ');
  return '${sorted.first} - ... - ${sorted.last}';
}

// ═══════════════════════════════════════════════════════════════════════════
// KHATMAH DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class Khatmah {
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
    this.currentSurah = 1,
    this.currentVerse = 1,
    this.currentPage = 1,
    this.progressPercentage = 0.0,
  });

  Khatmah copyWith({
    String? name,
    DateTime? targetEndDate,
    int? currentSurah,
    int? currentVerse,
    int? currentPage,
    double? progressPercentage,
  }) {
    return Khatmah(
      id: id,
      name: name ?? this.name,
      startDate: startDate,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      currentSurah: currentSurah ?? this.currentSurah,
      currentVerse: currentVerse ?? this.currentVerse,
      currentPage: currentPage ?? this.currentPage,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'targetEndDate': targetEndDate?.toIso8601String(),
    'currentSurah': currentSurah,
    'currentVerse': currentVerse,
    'currentPage': currentPage,
    'progressPercentage': progressPercentage,
  };

  factory Khatmah.fromMap(Map<dynamic, dynamic> map) {
    return Khatmah(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      targetEndDate: map['targetEndDate'] != null
          ? DateTime.parse(map['targetEndDate'] as String)
          : null,
      currentSurah: map['currentSurah'] as int? ?? 1,
      currentVerse: map['currentVerse'] as int? ?? 1,
      currentPage: map['currentPage'] as int? ?? 1,
      progressPercentage: (map['progressPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Smart daily pages — guards against division by zero, max 50
  int get dailyPagesNeeded {
    if (targetEndDate == null) return 20;
    final remaining = targetEndDate!.difference(DateTime.now()).inDays;
    final pagesLeft = 604 - currentPage;
    if (pagesLeft <= 0) return 0; // Khatmah complete
    if (remaining <= 0) return pagesLeft.clamp(1, 50); // ✅ Clamp to max 50
    return (pagesLeft / remaining).ceil().clamp(1, 50);
  }

  /// Whether the khatmah is complete (page 604 reached)
  bool get isComplete => currentPage >= 604;
}

// ═══════════════════════════════════════════════════════════════════════════
// READING SCHEDULE — algorithmically generated
// ═══════════════════════════════════════════════════════════════════════════

class ReadingDay {
  final String dayLabel;
  final String surahRange;
  final String pageRange;
  final bool isToday;

  const ReadingDay({
    required this.dayLabel,
    required this.surahRange,
    required this.pageRange,
    this.isToday = false,
  });
}

/// Generate a 3-day reading schedule from current position
List<ReadingDay> generateSchedule(Khatmah khatmah) {
  final pagesPerDay = khatmah.dailyPagesNeeded;
  if (pagesPerDay <= 0) return []; // ✅ Guard: khatmah complete
  final labels = ['اليوم', 'غداً', 'بعد غد'];
  final result = <ReadingDay>[];

  for (int i = 0; i < 3; i++) {
    final fromPage = khatmah.currentPage + (pagesPerDay * i);
    final toPage = (khatmah.currentPage + (pagesPerDay * (i + 1)) - 1).clamp(1, 604);
    if (fromPage > 604) break;

    result.add(ReadingDay(
      dayLabel: labels[i],
      surahRange: _surahsInRange(fromPage, toPage),
      pageRange: '$fromPage - $toPage',
      isToday: i == 0,
    ));
  }
  return result;
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPLETED KHATMAH MODEL
// ═══════════════════════════════════════════════════════════════════════════

class CompletedKhatmah {
  final String name;
  final DateTime completedDate;
  final int durationDays;

  const CompletedKhatmah({
    required this.name,
    required this.completedDate,
    required this.durationDays,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'completedDate': completedDate.toIso8601String(),
    'durationDays': durationDays,
  };

  factory CompletedKhatmah.fromMap(Map<dynamic, dynamic> map) {
    return CompletedKhatmah(
      name: map['name'] as String,
      completedDate: DateTime.parse(map['completedDate'] as String),
      durationDays: map['durationDays'] as int,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KHATMAH STATE NOTIFIER (Hive-backed, cached box)
// ═══════════════════════════════════════════════════════════════════════════

class KhatmahNotifier extends StateNotifier<Khatmah?> {
  static const _boxName = 'khatmah_box';
  static const _activeKey = 'active_khatmah';
  static const _completedKey = 'completed_khatmahs';
  static const _todayPagesKey = 'today_pages';
  static const _todayDateKey = 'today_date';

  /// ✅ Cached Hive box — opened once, reused everywhere
  Box? _box;

  KhatmahNotifier() : super(null) {
    _loadFromHive();
  }

  /// ✅ Single box instance — no repeated openBox() calls
  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  Future<void> _loadFromHive() async {
    final box = await _getBox();
    final data = box.get(_activeKey);
    if (data != null) {
      state = Khatmah.fromMap(Map<dynamic, dynamic>.from(data));
    }
  }

  Future<void> _saveToHive() async {
    final box = await _getBox();
    if (state != null) {
      await box.put(_activeKey, state!.toMap());
    } else {
      await box.delete(_activeKey);
    }
  }

  /// Start a new Khatmah
  Future<void> startNew({
    required String name,
    DateTime? targetEndDate,
  }) async {
    state = Khatmah(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isEmpty ? 'ختمتي' : name,
      startDate: DateTime.now(),
      targetEndDate: targetEndDate,
    );
    await _saveToHive();
    await _resetTodayPages();
  }

  /// Update reading progress — with auto-completion trigger
  Future<void> updateProgress({
    required int surah,
    required int verse,
    required int page,
  }) async {
    if (state == null) return;

    // ✅ Auto-complete if user reached the end
    if (page >= 604) {
      // Track final pages before completing
      final pagesRead = (604 - state!.currentPage).clamp(0, 604);
      if (pagesRead > 0) await _addTodayPages(pagesRead);
      await complete();
      return;
    }

    // ✅ Clamp to prevent negative tracking on backward navigation
    final pagesRead = (page - state!.currentPage).clamp(0, 604);
    if (pagesRead > 0) {
      await _addTodayPages(pagesRead);
    }

    state = state!.copyWith(
      currentSurah: surah,
      currentVerse: verse,
      currentPage: page,
      progressPercentage: (page - 1) / 603.0, // ✅ Precise: page 1=0%, page 604=100%
    );
    await _saveToHive();
  }

  /// Complete and archive current Khatmah
  Future<void> complete() async {
    if (state == null) return;
    final box = await _getBox();

    final completed = CompletedKhatmah(
      name: state!.name,
      completedDate: DateTime.now(),
      durationDays: DateTime.now().difference(state!.startDate).inDays,
    );

    final List<dynamic> existing = box.get(_completedKey, defaultValue: <dynamic>[]);
    existing.add(completed.toMap());
    await box.put(_completedKey, existing);

    state = null;
    await _saveToHive();
    await _resetTodayPages();
  }

  /// Get completed khatmah history
  Future<List<CompletedKhatmah>> getCompletedHistory() async {
    final box = await _getBox();
    final List<dynamic> data = box.get(_completedKey, defaultValue: <dynamic>[]);
    return data.map((e) => CompletedKhatmah.fromMap(Map<dynamic, dynamic>.from(e))).toList();
  }

  /// Get pages read today — ✅ timezone-safe date normalization
  Future<int> getTodayPagesRead() async {
    final box = await _getBox();
    final storedDate = box.get(_todayDateKey, defaultValue: '');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();

    if (storedDate != today) {
      // New day — reset
      await box.put(_todayDateKey, today);
      await box.put(_todayPagesKey, 0);
      return 0;
    }
    return box.get(_todayPagesKey, defaultValue: 0) as int;
  }

  Future<void> _addTodayPages(int count) async {
    final current = await getTodayPagesRead();
    final box = await _getBox();
    await box.put(_todayPagesKey, current + count);
  }

  Future<void> _resetTodayPages() async {
    final box = await _getBox();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    await box.put(_todayDateKey, today);
    await box.put(_todayPagesKey, 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final khatmahProvider = StateNotifierProvider<KhatmahNotifier, Khatmah?>((ref) {
  return KhatmahNotifier();
});

/// Today's pages read — auto-resets daily
final todayPagesReadProvider = FutureProvider<int>((ref) async {
  ref.watch(khatmahProvider);
  final notifier = ref.read(khatmahProvider.notifier);
  return notifier.getTodayPagesRead();
});

/// Completed khatmah history
final completedKhatmahsProvider = FutureProvider<List<CompletedKhatmah>>((ref) async {
  ref.watch(khatmahProvider);
  final notifier = ref.read(khatmahProvider.notifier);
  return notifier.getCompletedHistory();
});

/// Generated reading schedule for next 3 days
final khatmahScheduleProvider = Provider<List<ReadingDay>>((ref) {
  final khatmah = ref.watch(khatmahProvider);
  if (khatmah == null) return [];
  return generateSchedule(khatmah);
});
