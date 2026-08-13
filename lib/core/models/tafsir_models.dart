/// 📖 نماذج بيانات التفسير - Tafsir Data Models
library;

/// مصدر التفسير
enum TafsirSourceId {
  muyassar,   // التفسير الميسر
  ibnKathir,  // تفسير ابن كثير
  saadi,      // تفسير السعدي
  tabari,     // تفسير الطبري
}

/// معلومات مصدر التفسير
class TafsirSource {

  const TafsirSource({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.author,
    required this.assetPath,
    this.isFullyBundled = true,
    this.apiEndpoint,
  });
  final TafsirSourceId id;
  final String arabicName;
  final String englishName;
  final String author;
  final String assetPath;
  final bool isFullyBundled;
  final String? apiEndpoint;

  /// المصادر المتاحة
  static const Map<TafsirSourceId, TafsirSource> sources = {
    TafsirSourceId.muyassar: TafsirSource(
      id: TafsirSourceId.muyassar,
      arabicName: 'التفسير الميسر',
      englishName: 'Al-Muyassar',
      author: 'مجمع الملك فهد',
      assetPath: 'assets/tafsir/muyassar/ar-tafsir-muyassar',
    ),
    TafsirSourceId.saadi: TafsirSource(
      id: TafsirSourceId.saadi,
      arabicName: 'تفسير السعدي',
      englishName: 'As-Saadi',
      author: 'الشيخ عبد الرحمن السعدي',
      assetPath: 'assets/tafsir/saadi/ar-tafseer-al-saddi',
    ),
    TafsirSourceId.tabari: TafsirSource(
      id: TafsirSourceId.tabari,
      arabicName: 'تفسير الطبري',
      englishName: 'At-Tabari',
      author: 'الإمام ابن جرير الطبري',
      assetPath: 'assets/tafsir/tabari/ar-tafsir-al-tabari',
    ),
    TafsirSourceId.ibnKathir: TafsirSource(
      id: TafsirSourceId.ibnKathir,
      arabicName: 'تفسير ابن كثير',
      englishName: 'Ibn Kathir',
      author: 'الإمام ابن كثير',
      assetPath: 'assets/tafsir/ibn_kathir/full/ar-tafsir-ibn-kathir',
    ),
  };

  static TafsirSource get(TafsirSourceId id) => sources[id]!;
  static List<TafsirSource> get all => sources.values.toList();
}

/// تفسير آية واحدة
class TafsirEntry {

  const TafsirEntry({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.source,
    this.references,
    this.cachedAt,
  });

  factory TafsirEntry.fromJson(
    Map<String, dynamic> json,
    TafsirSourceId source,
  ) {
    return TafsirEntry(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      text: json['text'] as String,
      source: source,
    );
  }
  final int surah;
  final int ayah;
  final String text;
  final TafsirSourceId source;
  final List<TafsirReference>? references;
  final DateTime? cachedAt;

  /// المفتاح الفريد
  String get key => '${source.name}:$surah:$ayah';
  
  /// معرف الآية
  String get verseId => '$surah:$ayah';

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'text': text,
    'source': source.name,
    'cachedAt': cachedAt?.toIso8601String(),
  };

  /// نسخة مع تاريخ التخزين
  TafsirEntry withCacheTime() => TafsirEntry(
    surah: surah,
    ayah: ayah,
    text: text,
    source: source,
    references: references,
    cachedAt: DateTime.now(),
  );
}

/// تفسير سورة كاملة
class SurahTafsir {

  const SurahTafsir({
    required this.surah,
    required this.source,
    required this.entries,
  });

  factory SurahTafsir.fromJson(
    Map<String, dynamic> json,
    TafsirSourceId source,
  ) {
    final ayahs = json['ayahs'] as List;
    final surah = ayahs.isNotEmpty ? (ayahs.first as Map)['surah'] as int : 0;
    
    return SurahTafsir(
      surah: surah,
      source: source,
      entries: ayahs.map((a) => TafsirEntry.fromJson(Map<String, dynamic>.from(a as Map), source)).toList(),
    );
  }
  final int surah;
  final TafsirSourceId source;
  final List<TafsirEntry> entries;

  /// الحصول على تفسير آية
  TafsirEntry? getAyah(int ayah) {
    try {
      return entries.firstWhere((e) => e.ayah == ayah);
    } on Exception catch (_) {
      return null;
    }
  }

  /// عدد الآيات
  int get length => entries.length;
}

/// مرجع في التفسير
class TafsirReference {

  const TafsirReference({
    required this.type,
    required this.text,
    this.source,
    this.link,
  });
  final TafsirReferenceType type;
  final String text;
  final String? source;
  final String? link;
}

/// نوع المرجع
enum TafsirReferenceType {
  hadith,       // حديث
  verse,        // آية أخرى
  sababNuzul,   // سبب نزول
  linguisitic,  // تفسير لغوي
}

/// إعدادات عرض التفسير
class TafsirDisplaySettings {

  const TafsirDisplaySettings({
    this.primarySource = TafsirSourceId.muyassar,
    this.compareSources = const [],
    this.showReferences = true,
    this.fontSize = 18.0,
    this.displayMode = TafsirDisplayMode.inline,
  });
  final TafsirSourceId primarySource;
  final List<TafsirSourceId> compareSources;
  final bool showReferences;
  final double fontSize;
  final TafsirDisplayMode displayMode;

  TafsirDisplaySettings copyWith({
    TafsirSourceId? primarySource,
    List<TafsirSourceId>? compareSources,
    bool? showReferences,
    double? fontSize,
    TafsirDisplayMode? displayMode,
  }) {
    return TafsirDisplaySettings(
      primarySource: primarySource ?? this.primarySource,
      compareSources: compareSources ?? this.compareSources,
      showReferences: showReferences ?? this.showReferences,
      fontSize: fontSize ?? this.fontSize,
      displayMode: displayMode ?? this.displayMode,
    );
  }
}

/// وضع العرض
enum TafsirDisplayMode {
  inline,       // تحت الآية مباشرة
  bottomSheet,  // شاشة سفلية
  fullScreen,   // شاشة كاملة
}

/// علامة تفسير محفوظة
class TafsirBookmark {

  const TafsirBookmark({
    required this.surah,
    required this.ayah,
    required this.source,
    required this.createdAt,
    this.note,
  });

  factory TafsirBookmark.fromJson(Map<String, dynamic> json) {
    return TafsirBookmark(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      source: TafsirSourceId.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => TafsirSourceId.muyassar,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final DateTime createdAt;
  final String? note;

  String get key => '${source.name}:$surah:$ayah';

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'source': source.name,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };
}

/// سجل قراءة التفسير
class TafsirReadingHistory {

  const TafsirReadingHistory({
    required this.surah,
    required this.ayah,
    required this.source,
    required this.lastRead,
    this.readCount = 1,
  });
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final DateTime lastRead;
  final int readCount;

  String get key => '${source.name}:$surah:$ayah';

  TafsirReadingHistory incrementCount() => TafsirReadingHistory(
    surah: surah,
    ayah: ayah,
    source: source,
    lastRead: DateTime.now(),
    readCount: readCount + 1,
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PHASE 6: HIGHLIGHTS & ANNOTATIONS (Tadabbur Integration)
/// ═══════════════════════════════════════════════════════════════════════════

/// لون التظليل
enum HighlightColor {
  yellow,
  green,
  blue,
  pink,
  orange,
}

/// تظليل نص في التفسير
class TafsirHighlight {

  const TafsirHighlight({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.source,
    required this.highlightedText,
    required this.createdAt, this.color = HighlightColor.yellow,
  });

  factory TafsirHighlight.fromJson(Map<String, dynamic> json) {
    return TafsirHighlight(
      id: json['id'] as String,
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      source: TafsirSourceId.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => TafsirSourceId.muyassar,
      ),
      highlightedText: json['highlightedText'] as String,
      color: HighlightColor.values.firstWhere(
        (e) => e.name == json['color'],
        orElse: () => HighlightColor.yellow,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  final String id;
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final String highlightedText;
  final HighlightColor color;
  final DateTime createdAt;

  String get key => 'hl:${source.name}:$surah:$ayah:$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    'surah': surah,
    'ayah': ayah,
    'source': source.name,
    'highlightedText': highlightedText,
    'color': color.name,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// ملاحظة تدبر مرتبطة بالتفسير
class TafsirAnnotation {

  const TafsirAnnotation({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.source,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TafsirAnnotation.fromJson(Map<String, dynamic> json) {
    return TafsirAnnotation(
      id: json['id'] as String,
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      source: TafsirSourceId.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => TafsirSourceId.muyassar,
      ),
      noteText: json['noteText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  final String id;
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get key => 'ann:${source.name}:$surah:$ayah:$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    'surah': surah,
    'ayah': ayah,
    'source': source.name,
    'noteText': noteText,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
