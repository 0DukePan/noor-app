import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../data/data_sources/hadith_database.dart';

/// 🔍 محرك البحث العلمي للأحاديث - Scientific Hadith Search Engine
/// 
/// Features:
/// - Diacritics-insensitive search (تجاهل التشكيل)
/// - Fuzzy search (التقريبي)
/// - Search in Matn only
/// - Search in Sanad only
/// - Search by Companion (Sahabi)
/// - Search by topic
class HadithSearchEngine {
  static Box<dynamic>? _indexBox;
  static Box<dynamic>? _cacheBox;
  static List<HadithIndexEntry>? _searchIndex;
  static Map<String, List<String>>? _companionIndex;
  static Map<String, List<String>>? _topicIndex;

  /// Bump to force a rebuild of cached indexes on existing installs.
  static const int _indexVersion = 3;

  /// أحكام منقّحة لكل حديث (كتاب → رقم الحديث → الحكم مع العالم).
  /// تُحمّل من grades.json وتُستخدم قبل الاحتكام العام للكتاب.
  static Map<String, Map<int, HadithGrade>> _gradeDataset = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init({Database? forTesting}) async {
    _indexBox = await Hive.openBox<dynamic>('hadith_search_index');
    _cacheBox = await Hive.openBox<dynamic>('hadith_search_cache');
    await _loadGradeDataset();

    // Build search index if not cached (or always when a test DB is passed).
    // The version bumps force a rebuild whenever the index derivation changes
    // (e.g. companion/topic extraction, grades) on existing installs.
    if (forTesting != null ||
        _indexBox?.get('index_built') != true ||
        _indexBox?.get('index_version') != _indexVersion) {
      await _buildSearchIndex(forTesting);
    } else {
      _loadIndexFromCache();
    }
  }

  /// تحميل بيانات الأحكام المنقحة (ألباني…) — لا تفشل إن غابت.
  static Future<void> _loadGradeDataset() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/hadith/grades.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final dataset = <String, Map<int, HadithGrade>>{};
      json.forEach((book, entries) {
        if (book == '_meta') return;
        final byNumber = <int, HadithGrade>{};
        (entries as Map<String, dynamic>).forEach((number, gradeJson) {
          final g = gradeJson as Map<String, dynamic>;
          byNumber[int.parse(number)] = HadithGrade(
            grade: (g['grade'] as String?) ?? '',
            scholar: (g['scholar'] as String?) ?? '',
          );
        });
        dataset[book] = byNumber;
      });
      _gradeDataset = dataset;
    } on Exception {
      _gradeDataset = {};
    }
  }

  /// حكم حديث: المنقّح أولاً ثم الاحتكام العام للكتاب.
  static String gradeFor(String bookId, int idInBook) {
    final refined = _gradeDataset[bookId]?[idInBook];
    if (refined != null && refined.grade.isNotEmpty) return refined.grade;
    return gradeForBook(bookId);
  }

  /// عالم الحكم المنقّح (مثل الألباني) إن وجد.
  static String? gradeScholarFor(String bookId, int idInBook) {
    return _gradeDataset[bookId]?[idInBook]?.scholar;
  }

  /// بناء فهرس البحث
  static Future<void> _buildSearchIndex([Database? overrideDb]) async {
    debugPrint('Building hadith search index...');

    _searchIndex = [];
    _companionIndex = {};
    _topicIndex = {};

    // Build the index from the SQLite corpus (the same data the reader uses),
    // rather than re-parsing the per-chapter JSON assets.
    final db = overrideDb ?? await HadithDatabase.database;
    final rows = await db.query('hadiths', columns: [
      'rowid',
      'collection_id',
      'id_in_book',
      'chapter_id',
      'arabic',
      'english_narrator',
    ],);

    for (final row in rows) {
      final entry = _createIndexEntry(row);
      _searchIndex!.add(entry);

      // Index by companion
      if (entry.companion.isNotEmpty) {
        _companionIndex![entry.companion] ??= [];
        _companionIndex![entry.companion]!.add(entry.id);
      }

      // Index by topic
      for (final topic in entry.topics) {
        _topicIndex![topic] ??= [];
        _topicIndex![topic]!.add(entry.id);
      }
    }

    // Cache the index
    await _cacheIndex();

    debugPrint('Index built: ${_searchIndex!.length} hadiths');
  }

  static HadithIndexEntry _createIndexEntry(Map<String, dynamic> row) {
    final book = row['collection_id'] as String? ?? '';
    final chapter = row['chapter_id'] as int? ?? 0;
    final text = row['arabic'] as String? ?? '';
    final narrator = row['english_narrator'] as String? ?? '';
    final number = row['id_in_book'] as int? ?? 0;

    // Normalize FIRST: the corpus is fully vocalized, so the companion and
    // topic patterns («عن», «قال», «صلاة»…) can never match raw text.
    final normalizedText = _normalize(text);
    final normalizedNarrator = _normalize(narrator);

    // Extract companion name from the normalized Arabic sanad
    final companion = _extractCompanion(normalizedText);

    // Extract topics from the normalized text
    final topics = _extractTopics(normalizedText);

    return HadithIndexEntry(
      id: '${book}_${row['rowid']}',
      book: book,
      chapter: chapter,
      number: number,
      text: text,
      normalizedText: normalizedText,
      narrator: narrator,
      normalizedNarrator: normalizedNarrator,
      companion: companion,
      grade: gradeFor(book, number),
      gradeScholar: gradeScholarFor(book, number),
      topics: topics,
    );
  }

  /// Per-book grade basis — the same approach used by hadith collections
  /// apps: the Sahihain (Bukhari & Muslim) are wholly authentic; the other
  /// collections are graded by their source scholars per hadith, so we show
  /// the honest source label instead of fabricating per-hadith verdicts.
  static String gradeForBook(String bookId) {
    switch (bookId) {
      case 'bukhari':
      case 'muslim':
        return 'صحيح';
      default:
        return 'من المصدر';
    }
  }

  /// استخراج اسم الصحابي من السند
  static String _extractCompanion(String narrator) {
    // Common companion patterns
    final patterns = [
      RegExp(r'عن\s+(.+?)\s+رضي الله عنه'),
      RegExp(r'قال\s+(.+?)\s*:'),
      RegExp(r'عن\s+أبي\s+(\w+)'),
      RegExp(r'عن\s+(\w+)\s+بن\s+\w+'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(narrator);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }

  /// استخراج المواضيع من النص
  static List<String> _extractTopics(String text) {
    final topics = <String>[];
    
    // Topic keywords
    final topicPatterns = {
      'الصلاة': ['صلاة', 'يصلي', 'صلوا', 'المصلي', 'ركعة'],
      'الصيام': ['صيام', 'صوم', 'يصوم', 'رمضان', 'إفطار'],
      'الزكاة': ['زكاة', 'صدقة', 'زكوا', 'ينفق'],
      'الحج': ['حج', 'عمرة', 'طواف', 'الكعبة', 'منى'],
      'الأخلاق': ['أخلاق', 'صدق', 'أمانة', 'كذب', 'خلق'],
      'الإيمان': ['إيمان', 'يؤمن', 'مؤمن', 'كفر', 'توحيد'],
      'العلم': ['علم', 'تعلم', 'فقه', 'حديث', 'قرآن'],
      'الجهاد': ['جهاد', 'غزوة', 'شهيد', 'قتال'],
      'النكاح': ['نكاح', 'زواج', 'طلاق', 'عقد'],
      'البيوع': ['بيع', 'شراء', 'تجارة', 'ربا'],
      'الدعاء': ['دعاء', 'يدعو', 'استغفار', 'ذكر'],
      'الآداب': ['أدب', 'سلام', 'استئذان', 'طعام'],
    };
    
    for (final entry in topicPatterns.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          topics.add(entry.key);
          break;
        }
      }
    }
    
    return topics;
  }

  /// تخزين الفهرس
  static Future<void> _cacheIndex() async {
    final indexData = _searchIndex!.map((e) => e.toMap()).toList();
    await _indexBox?.put('search_index', indexData);
    await _indexBox?.put('companion_index', _companionIndex);
    await _indexBox?.put('topic_index', _topicIndex);
    await _indexBox?.put('index_built', true);
    await _indexBox?.put('index_version', _indexVersion);
    await _indexBox?.put('index_date', DateTime.now().toIso8601String());
  }

  /// تحميل الفهرس من الكاش
  static void _loadIndexFromCache() {
    final indexData = _indexBox?.get('search_index') as List?;
    if (indexData != null) {
      _searchIndex = indexData
          .map((e) => HadithIndexEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    
    _companionIndex = Map<String, List<String>>.from(
      Map<String, dynamic>.from((_indexBox?.get('companion_index') ?? <dynamic, dynamic>{}) as Map),
    );
    
    _topicIndex = Map<String, List<String>>.from(
      Map<String, dynamic>.from((_indexBox?.get('topic_index') ?? <dynamic, dynamic>{}) as Map),
    );
    
    debugPrint('Loaded ${_searchIndex?.length ?? 0} hadiths from cache');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NORMALIZATION (تجاهل التشكيل)
  // ═══════════════════════════════════════════════════════════════════════════

  /// إزالة التشكيل والتطبيع
  static String _normalize(String text) {
    // Remove Arabic diacritics
    final normalized = text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Tashkeel
        .replaceAll(RegExp(r'[\u0670]'), '')        // Alef superscript
        .replaceAll(RegExp(r'[\u06D6-\u06ED]'), '') // Extended diacritics
        .replaceAll('ـ', '')                         // Tatweel
        .replaceAll('آ', 'ا')                        // Alef with madda
        .replaceAll('أ', 'ا')                        // Alef with hamza above
        .replaceAll('إ', 'ا')                        // Alef with hamza below
        .replaceAll('ٱ', 'ا')                        // Alef-wasla
        .replaceAll('ؤ', 'و')                        // Waw with hamza
        .replaceAll('ئ', 'ي')                        // Ya with hamza
        .replaceAll('ة', 'ه')                        // Ta marbuta
        .replaceAll('ى', 'ي')                        // Alef maksura
        .toLowerCase()
        .trim();
    
    // Remove extra spaces
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// البحث العام
  static Future<List<HadithSearchResult>> search(
    String query, {
    SearchTarget target = SearchTarget.all,
    String? book,
    String? companion,
    String? topic,
    String? grade,
    int limit = 50,
  }) async {
    if (query.isEmpty && companion == null && topic == null) {
      return [];
    }
    
    // Check cache first — the key must cover EVERY filter, otherwise a
    // grade/companion-filtered search poisons the cache for plain searches.
    final cacheKey =
        '${query}_${target.name}_${book}_${companion}_${topic}_$grade';
    final cached = _cacheBox?.get(cacheKey);
    if (cached != null) {
      return (cached as List)
          .map((e) => HadithSearchResult.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    
    if (_searchIndex == null) return [];
    
    final normalizedQuery = _normalize(query);
    final results = <HadithSearchResult>[];
    
    for (final entry in _searchIndex!) {
      // Apply filters
      if (book != null && entry.book != book) continue;
      if (companion != null && entry.companion != companion) continue;
      if (topic != null && !entry.topics.contains(topic)) continue;
      if (grade != null && entry.grade != grade) continue;
      
      double score = 0;
      
      if (query.isNotEmpty) {
        // Search based on target
        switch (target) {
          case SearchTarget.matn:
            score = _calculateScore(normalizedQuery, entry.normalizedText);
          case SearchTarget.sanad:
            score = _calculateScore(normalizedQuery, entry.normalizedNarrator);
          case SearchTarget.all:
            final matnScore = _calculateScore(normalizedQuery, entry.normalizedText);
            final sanadScore = _calculateScore(normalizedQuery, entry.normalizedNarrator);
            score = matnScore > sanadScore ? matnScore : sanadScore;
        }
        
        if (score == 0) continue;
      } else {
        score = 1; // For filter-only searches
      }
      
      results.add(HadithSearchResult(
        entry: entry,
        score: score,
        matchType: target,
      ),);
    }
    
    // Sort by score
    results.sort((a, b) => b.score.compareTo(a.score));
    
    // Limit results
    final limited = results.take(limit).toList();
    
    // Cache results
    await _cacheBox?.put(
      cacheKey,
      limited.map((e) => e.toMap()).toList(),
    );
    
    return limited;
  }

  /// حساب درجة التطابق
  static double _calculateScore(String query, String text) {
    if (text.isEmpty) return 0;
    
    // Exact match
    if (text.contains(query)) {
      return 1;
    }
    
    // Word-by-word match
    final queryWords = query.split(' ');
    var matchedWords = 0;
    
    for (final word in queryWords) {
      if (word.length > 2 && text.contains(word)) {
        matchedWords++;
      }
    }
    
    if (matchedWords > 0) {
      return matchedWords / queryWords.length * 0.8;
    }
    
    // Fuzzy match (Levenshtein-like)
    for (final word in queryWords) {
      if (word.length > 3) {
        // Check for partial match (typos)
        if (_fuzzyMatch(word, text)) {
          return 0.5;
        }
      }
    }
    
    return 0;
  }

  /// البحث التقريبي (Fuzzy)
  static bool _fuzzyMatch(String word, String text) {
    // Allow 1-2 character difference
    final words = text.split(' ');
    
    for (final textWord in words) {
      if (textWord.length < 3) continue;
      
      // Check if similar
      final distance = _levenshteinDistance(word, textWord);
      if (distance <= (word.length > 5 ? 2 : 1)) {
        return true;
      }
    }
    
    return false;
  }

  /// Levenshtein Distance
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    var prev = List<int>.generate(s2.length + 1, (i) => i);
    var curr = List<int>.filled(s2.length + 1, 0);
    
    for (var i = 0; i < s1.length; i++) {
      curr[0] = i + 1;
      
      for (var j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1,
          prev[j + 1] + 1,
          prev[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    
    return prev[s2.length];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPANION & TOPIC BROWSING
  // ═══════════════════════════════════════════════════════════════════════════

  /// جميع الصحابة
  static List<String> getCompanions() {
    return _companionIndex?.keys.toList() ?? [];
  }

  /// الأحاديث حسب الصحابي
  static Future<List<HadithSearchResult>> getByCompanion(String companion) async {
    return search('', companion: companion);
  }

  /// جميع المواضيع
  static List<String> getTopics() {
    return _topicIndex?.keys.toList() ?? [];
  }

  /// عدد الأحاديث لكل موضوع
  static Map<String, int> getTopicCounts() {
    if (_topicIndex == null) return {};
    return _topicIndex!.map((key, value) => MapEntry(key, value.length));
  }

  /// عدد الأحاديث المفهرسة
  static int getSearchIndexCount() {
    return _searchIndex?.length ?? 0;
  }

  /// الأحاديث حسب الموضوع
  static Future<List<HadithSearchResult>> getByTopic(String topic) async {
    return search('', topic: topic);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIMILAR HADITHS
  // ═══════════════════════════════════════════════════════════════════════════

  /// أحاديث مشابهة
  static Future<List<HadithSearchResult>> getSimilar(
    HadithIndexEntry hadith, {
    int limit = 10,
  }) async {
    final results = <HadithSearchResult>[];
    
    if (_searchIndex == null) return [];
    
    for (final entry in _searchIndex!) {
      if (entry.id == hadith.id) continue;
      
      double score = 0;
      
      // Same companion
      if (entry.companion == hadith.companion && hadith.companion.isNotEmpty) {
        score += 0.3;
      }
      
      // Same topic
      final commonTopics = hadith.topics
          .where(entry.topics.contains)
          .length;
      score += commonTopics * 0.2;
      
      // Text similarity
      final textScore = _calculateScore(
        hadith.normalizedText.substring(0, hadith.normalizedText.length.clamp(0, 50)),
        entry.normalizedText,
      );
      score += textScore * 0.5;
      
      if (score > 0.3) {
        results.add(HadithSearchResult(
          entry: entry,
          score: score,
          matchType: SearchTarget.all,
        ),);
      }
    }
    
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// هدف البحث
enum SearchTarget {
  all,    // الكل
  matn,   // المتن فقط
  sanad,  // السند فقط
}

/// مدخل فهرس الحديث
class HadithIndexEntry {

  const HadithIndexEntry({
    required this.id,
    required this.book,
    required this.chapter,
    required this.number,
    required this.text,
    required this.normalizedText,
    required this.narrator,
    required this.normalizedNarrator,
    required this.companion,
    required this.grade,
    required this.topics,
    this.gradeScholar,
  });

  factory HadithIndexEntry.fromMap(Map<String, dynamic> map) {
    return HadithIndexEntry(
      id: (map['id'] ?? '') as String,
      book: (map['book'] ?? '') as String,
      chapter: (map['chapter'] ?? 0) as int,
      number: (map['number'] ?? 0) as int,
      text: (map['text'] ?? '') as String,
      normalizedText: (map['normalizedText'] ?? '') as String,
      narrator: (map['narrator'] ?? '') as String,
      normalizedNarrator: (map['normalizedNarrator'] ?? '') as String,
      companion: (map['companion'] ?? '') as String,
      grade: (map['grade'] ?? '') as String,
      gradeScholar: map['gradeScholar'] as String?,
      topics: List<String>.from(map['topics'] as List? ?? []),
    );
  }
  final String id;
  final String book;
  final int chapter;
  final int number;
  final String text;
  final String normalizedText;
  final String narrator;
  final String normalizedNarrator;
  final String companion;
  final String grade;

  /// اسم العالم صاحب الحكم المنقّح (مثل الألباني) إن وُجد.
  final String? gradeScholar;
  final List<String> topics;

  Map<String, dynamic> toMap() => {
    'id': id,
    'book': book,
    'chapter': chapter,
    'number': number,
    'text': text,
    'normalizedText': normalizedText,
    'narrator': narrator,
    'normalizedNarrator': normalizedNarrator,
    'companion': companion,
    'grade': grade,
    'gradeScholar': gradeScholar,
    'topics': topics,
  };
}

/// حكم منقّح من عالم معيّن
class HadithGrade {

  const HadithGrade({required this.grade, required this.scholar});
  final String grade;
  final String scholar;
}

/// نتيجة البحث
class HadithSearchResult {

  const HadithSearchResult({
    required this.entry,
    required this.score,
    required this.matchType,
  });

  factory HadithSearchResult.fromMap(Map<String, dynamic> map) {
    return HadithSearchResult(
      entry: HadithIndexEntry.fromMap(Map<String, dynamic>.from(map['entry'] as Map)),
      score: (map['score'] ?? 0) as double,
      matchType: SearchTarget.values[(map['matchType'] ?? 0) as int],
    );
  }
  final HadithIndexEntry entry;
  final double score;
  final SearchTarget matchType;

  Map<String, dynamic> toMap() => {
    'entry': entry.toMap(),
    'score': score,
    'matchType': matchType.index,
  };
}
