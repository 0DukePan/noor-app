import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔍 محرك البحث العلمي للأحاديث - Scientific Hadith Search Engine
/// 
/// Features:
/// - Diacritics-insensitive search (تجاهل التشكيل)
/// - Fuzzy search (التقريبي)
/// - Search in Matn only
/// - Search in Sanad only
/// - Search by Companion (Sahabi)
/// - Search by topic
/// - Supabase cloud sync
class HadithSearchEngine {
  static Box? _indexBox;
  static Box? _cacheBox;
  static List<HadithIndexEntry>? _searchIndex;
  static Map<String, List<String>>? _companionIndex;
  static Map<String, List<String>>? _topicIndex;
  
  // Supabase client
  static SupabaseClient? _supabase;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init({SupabaseClient? supabase}) async {
    _indexBox = await Hive.openBox('hadith_search_index');
    _cacheBox = await Hive.openBox('hadith_search_cache');
    _supabase = supabase;
    
    // Build search index if not cached
    if (_indexBox?.get('index_built') != true) {
      await _buildSearchIndex();
    } else {
      _loadIndexFromCache();
    }
  }

  /// بناء فهرس البحث
  static Future<void> _buildSearchIndex() async {
    debugPrint('Building hadith search index...');
    
    _searchIndex = [];
    _companionIndex = {};
    _topicIndex = {};
    
    // Load all hadith books
    final books = [
      'bukhari', 'muslim', 'tirmidhi', 'abudawud', 'nasai',
      'ibnmajah', 'malik', 'ahmad', 'darimi'
    ];
    
    for (final book in books) {
      try {
        // Load book structure
        final structureJson = await rootBundle.loadString(
          'assets/hadith/$book/structure.json'
        );
        final structure = jsonDecode(structureJson);
        final chapters = structure['chapters'] as List? ?? [];
        
        for (int i = 0; i < chapters.length; i++) {
          try {
            // Load chapter hadiths
            final chapterJson = await rootBundle.loadString(
              'assets/hadith/$book/chapters/${i + 1}.json'
            );
            final chapterData = jsonDecode(chapterJson);
            final hadiths = chapterData['hadiths'] as List? ?? [];
            
            for (final hadith in hadiths) {
              // Extract and index
              final entry = _createIndexEntry(hadith, book, i + 1);
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
          } catch (e) {
            // Skip missing chapters
          }
        }
      } catch (e) {
        debugPrint('Error indexing $book: $e');
      }
    }
    
    // Cache the index
    await _cacheIndex();
    
    debugPrint('Index built: ${_searchIndex!.length} hadiths');
  }

  static HadithIndexEntry _createIndexEntry(
    Map<String, dynamic> hadith,
    String book,
    int chapter,
  ) {
    final text = hadith['arabic'] ?? hadith['text'] ?? hadith['hadith_text'] ?? '';
    final narrator = hadith['narrator'] ?? hadith['rawi'] ?? '';
    final number = hadith['number'] ?? hadith['hadith_number'] ?? 0;
    final grade = hadith['grade'] ?? hadith['status'] ?? '';
    
    // Extract companion name from narrator chain
    final companion = _extractCompanion(narrator);
    
    // Normalize for search (remove diacritics)
    final normalizedText = _normalize(text);
    final normalizedNarrator = _normalize(narrator);
    
    // Extract topics from text
    final topics = _extractTopics(text);
    
    return HadithIndexEntry(
      id: '${book}_${chapter}_$number',
      book: book,
      chapter: chapter,
      number: number,
      text: text,
      normalizedText: normalizedText,
      narrator: narrator,
      normalizedNarrator: normalizedNarrator,
      companion: companion,
      grade: grade,
      topics: topics,
    );
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
    await _indexBox?.put('index_date', DateTime.now().toIso8601String());
  }

  /// تحميل الفهرس من الكاش
  static void _loadIndexFromCache() {
    final indexData = _indexBox?.get('search_index') as List?;
    if (indexData != null) {
      _searchIndex = indexData
          .map((e) => HadithIndexEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    
    _companionIndex = Map<String, List<String>>.from(
      _indexBox?.get('companion_index') ?? {}
    );
    
    _topicIndex = Map<String, List<String>>.from(
      _indexBox?.get('topic_index') ?? {}
    );
    
    debugPrint('Loaded ${_searchIndex?.length ?? 0} hadiths from cache');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NORMALIZATION (تجاهل التشكيل)
  // ═══════════════════════════════════════════════════════════════════════════

  /// إزالة التشكيل والتطبيع
  static String _normalize(String text) {
    // Remove Arabic diacritics
    var normalized = text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Tashkeel
        .replaceAll(RegExp(r'[\u0670]'), '')        // Alef superscript
        .replaceAll(RegExp(r'[\u06D6-\u06ED]'), '') // Extended diacritics
        .replaceAll('ـ', '')                         // Tatweel
        .replaceAll('آ', 'ا')                        // Alef with madda
        .replaceAll('أ', 'ا')                        // Alef with hamza above
        .replaceAll('إ', 'ا')                        // Alef with hamza below
        .replaceAll('ؤ', 'و')                        // Waw with hamza
        .replaceAll('ئ', 'ي')                        // Ya with hamza
        .replaceAll('ة', 'ه')                        // Ta marbuta
        .replaceAll('ى', 'ي')                        // Alef maksura
        .toLowerCase()
        .trim();
    
    // Remove extra spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized;
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
    
    // Check cache first
    final cacheKey = '${query}_${target.name}_$book\_$companion\_$topic';
    final cached = _cacheBox?.get(cacheKey);
    if (cached != null) {
      return (cached as List)
          .map((e) => HadithSearchResult.fromMap(Map<String, dynamic>.from(e)))
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
            break;
          case SearchTarget.sanad:
            score = _calculateScore(normalizedQuery, entry.normalizedNarrator);
            break;
          case SearchTarget.all:
            final matnScore = _calculateScore(normalizedQuery, entry.normalizedText);
            final sanadScore = _calculateScore(normalizedQuery, entry.normalizedNarrator);
            score = matnScore > sanadScore ? matnScore : sanadScore;
            break;
        }
        
        if (score == 0) continue;
      } else {
        score = 1; // For filter-only searches
      }
      
      results.add(HadithSearchResult(
        entry: entry,
        score: score,
        matchType: target,
      ));
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
      return 1.0;
    }
    
    // Word-by-word match
    final queryWords = query.split(' ');
    int matchedWords = 0;
    
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
    
    List<int> prev = List.generate(s2.length + 1, (i) => i);
    List<int> curr = List.filled(s2.length + 1, 0);
    
    for (int i = 0; i < s1.length; i++) {
      curr[0] = i + 1;
      
      for (int j = 0; j < s2.length; j++) {
        int cost = s1[i] == s2[j] ? 0 : 1;
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
          .where((t) => entry.topics.contains(t))
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
        ));
      }
    }
    
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPABASE SYNC
  // ═══════════════════════════════════════════════════════════════════════════

  /// مزامنة المفضلة والملاحظات
  static Future<void> syncToCloud({
    required String userId,
    required List<String> favorites,
    required Map<String, String> notes,
  }) async {
    if (_supabase == null) return;
    
    try {
      await _supabase!.from('hadith_user_data').upsert({
        'user_id': userId,
        'favorites': favorites,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Hadith data synced to Supabase');
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  /// استرجاع من السحابة
  static Future<Map<String, dynamic>?> syncFromCloud(String userId) async {
    if (_supabase == null) return null;
    
    try {
      final response = await _supabase!
          .from('hadith_user_data')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Fetch error: $e');
      return null;
    }
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
  final List<String> topics;

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
  });

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
    'topics': topics,
  };

  factory HadithIndexEntry.fromMap(Map<String, dynamic> map) {
    return HadithIndexEntry(
      id: map['id'] ?? '',
      book: map['book'] ?? '',
      chapter: map['chapter'] ?? 0,
      number: map['number'] ?? 0,
      text: map['text'] ?? '',
      normalizedText: map['normalizedText'] ?? '',
      narrator: map['narrator'] ?? '',
      normalizedNarrator: map['normalizedNarrator'] ?? '',
      companion: map['companion'] ?? '',
      grade: map['grade'] ?? '',
      topics: List<String>.from(map['topics'] ?? []),
    );
  }
}

/// نتيجة البحث
class HadithSearchResult {
  final HadithIndexEntry entry;
  final double score;
  final SearchTarget matchType;

  const HadithSearchResult({
    required this.entry,
    required this.score,
    required this.matchType,
  });

  Map<String, dynamic> toMap() => {
    'entry': entry.toMap(),
    'score': score,
    'matchType': matchType.index,
  };

  factory HadithSearchResult.fromMap(Map<String, dynamic> map) {
    return HadithSearchResult(
      entry: HadithIndexEntry.fromMap(Map<String, dynamic>.from(map['entry'])),
      score: map['score'] ?? 0,
      matchType: SearchTarget.values[map['matchType'] ?? 0],
    );
  }
}
