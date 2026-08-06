import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة Supabase - Supabase Service
class SupabaseService {
  static SupabaseClient? _client;

  /// Initialize Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _client = Supabase.instance.client;
  }

  /// Get Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => _client?.auth.currentUser != null;

  /// Get current user
  static User? get currentUser => _client?.auth.currentUser;

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch Quran surahs
  static Future<List<Map<String, dynamic>>> fetchSurahs() async {
    final response = await client
        .from('surahs')
        .select()
        .order('number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch verses for a surah
  static Future<List<Map<String, dynamic>>> fetchVerses(int surahNumber) async {
    final response = await client
        .from('verses')
        .select()
        .eq('surah_number', surahNumber)
        .order('verse_number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch tafsir for a verse
  static Future<Map<String, dynamic>?> fetchTafsir({
    required int surahNumber,
    required int verseNumber,
    String source = 'ibn_kathir',
  }) async {
    final response = await client
        .from('tafsir')
        .select()
        .eq('surah_number', surahNumber)
        .eq('verse_number', verseNumber)
        .eq('source', source)
        .maybeSingle();
    return response;
  }

  /// Fetch revelation cause
  static Future<Map<String, dynamic>?> fetchRevelationCause({
    required int surahNumber,
    required int verseNumber,
  }) async {
    final response = await client
        .from('revelation_causes')
        .select()
        .eq('surah_number', surahNumber)
        .eq('verse_number', verseNumber)
        .maybeSingle();
    return response;
  }

  /// Fetch hadiths by category
  static Future<List<Map<String, dynamic>>> fetchHadithsByCategory(
    String categoryId,
  ) async {
    final response = await client
        .from('hadiths')
        .select()
        .contains('topics', [categoryId]);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch adhkar by category
  static Future<List<Map<String, dynamic>>> fetchAdhkarByCategory(
    String category,
  ) async {
    final response = await client
        .from('adhkar')
        .select()
        .eq('category', category)
        .order('order_index', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER DATA (Synced)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync reading progress
  static Future<void> syncReadingProgress({
    required int surahNumber,
    required int verseNumber,
    required int page,
  }) async {
    if (!isAuthenticated) return;

    await client.from('reading_progress').upsert({
      'user_id': currentUser!.id,
      'surah_number': surahNumber,
      'verse_number': verseNumber,
      'page': page,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get reading progress
  static Future<Map<String, dynamic>?> getReadingProgress() async {
    if (!isAuthenticated) return null;

    return await client
        .from('reading_progress')
        .select()
        .eq('user_id', currentUser!.id)
        .maybeSingle();
  }

  /// Sync bookmarks
  static Future<void> syncBookmark({
    required String type,
    required String itemId,
    required bool isBookmarked,
  }) async {
    if (!isAuthenticated) return;

    if (isBookmarked) {
      await client.from('bookmarks').upsert({
        'user_id': currentUser!.id,
        'type': type,
        'item_id': itemId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await client
          .from('bookmarks')
          .delete()
          .eq('user_id', currentUser!.id)
          .eq('type', type)
          .eq('item_id', itemId);
    }
  }
}
