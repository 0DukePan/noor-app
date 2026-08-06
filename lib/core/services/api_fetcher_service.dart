import 'dart:convert';
import 'package:http/http.dart' as http;

/// خدمة جلب البيانات من المصادر الخارجية - API Fetcher Service
class ApiFetcherService {
  static const _quranBaseUrl = 'https://api.alquran.cloud/v1';
  static const _quranBackupUrl = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1';
  static const _hadithBaseUrl = 'https://api.sunnah.com/v1';
  static const _prayerBaseUrl = 'https://api.aladhan.com/v1';
  static const _mosqueBaseUrl = 'https://masjidnear.me/api/v1';

  final http.Client _client;
  String? _hadithApiKey;

  ApiFetcherService({http.Client? client}) : _client = client ?? http.Client();

  void setHadithApiKey(String key) => _hadithApiKey = key;

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN APIs
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch all Surahs metadata
  Future<List<Map<String, dynamic>>> fetchAllSurahs() async {
    try {
      final response = await _get('$_quranBaseUrl/surah');
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } catch (e) {
      // Fallback to backup API
      return _fetchSurahsFromBackup();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSurahsFromBackup() async {
    final response = await _get('$_quranBackupUrl/chapters.json');
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Fetch Surah with verses
  Future<Map<String, dynamic>> fetchSurah(int surahNumber, {String edition = 'quran-uthmani'}) async {
    try {
      final response = await _get('$_quranBaseUrl/surah/$surahNumber/$edition');
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      return _fetchSurahFromBackup(surahNumber);
    }
  }

  Future<Map<String, dynamic>> _fetchSurahFromBackup(int surahNumber) async {
    final response = await _get('$_quranBackupUrl/chapters/$surahNumber.json');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fetch available editions (recitations, translations, tafsirs)
  Future<List<Map<String, dynamic>>> fetchEditions({String? type}) async {
    final url = type != null
        ? '$_quranBaseUrl/edition/type/$type'
        : '$_quranBaseUrl/edition';
    final response = await _get(url);
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']);
  }

  /// Fetch Tafsir for a verse
  Future<Map<String, dynamic>> fetchTafsir({
    required int surahNumber,
    required int verseNumber,
    String tafsirEdition = 'ar.muyassar',
  }) async {
    final ref = '$surahNumber:$verseNumber';
    final response = await _get('$_quranBaseUrl/ayah/$ref/$tafsirEdition');
    final data = jsonDecode(response.body);
    return data['data'] as Map<String, dynamic>;
  }

  /// Fetch audio recitation URL
  Future<String?> fetchRecitationUrl({
    required int surahNumber,
    required int verseNumber,
    String reciter = 'ar.alafasy',
  }) async {
    final ref = '$surahNumber:$verseNumber';
    final response = await _get('$_quranBaseUrl/ayah/$ref/$reciter');
    final data = jsonDecode(response.body);
    return data['data']['audio'] as String?;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH APIs
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch hadith collections
  Future<List<Map<String, dynamic>>> fetchHadithCollections() async {
    final response = await _get(
      '$_hadithBaseUrl/collections',
      headers: _hadithHeaders,
    );
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']);
  }

  /// Fetch hadiths by collection
  Future<List<Map<String, dynamic>>> fetchHadithsByCollection(
    String collection, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _get(
      '$_hadithBaseUrl/hadiths?collection=$collection&page=$page&limit=$limit',
      headers: _hadithHeaders,
    );
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']);
  }

  /// Fetch single hadith by URN
  Future<Map<String, dynamic>?> fetchHadithByUrn(String urn) async {
    final response = await _get(
      '$_hadithBaseUrl/hadiths/$urn',
      headers: _hadithHeaders,
    );
    final data = jsonDecode(response.body);
    return data['data'] as Map<String, dynamic>?;
  }

  Map<String, String> get _hadithHeaders => {
        if (_hadithApiKey != null) 'X-API-Key': _hadithApiKey!,
      };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER TIMES APIs
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch prayer times for a date and location
  Future<Map<String, dynamic>> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    int method = 4, // Umm al-Qura
  }) async {
    final dateStr = '${date.day}-${date.month}-${date.year}';
    final response = await _get(
      '$_prayerBaseUrl/timings/$dateStr?latitude=$latitude&longitude=$longitude&method=$method',
    );
    final data = jsonDecode(response.body);
    return data['data'] as Map<String, dynamic>;
  }

  /// Fetch monthly prayer calendar
  Future<List<Map<String, dynamic>>> fetchMonthlyCalendar({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    int method = 4,
  }) async {
    final response = await _get(
      '$_prayerBaseUrl/calendar/$year/$month?latitude=$latitude&longitude=$longitude&method=$method',
    );
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']);
  }

  /// Fetch Qibla direction
  Future<double> fetchQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _get(
      '$_prayerBaseUrl/qibla/$latitude/$longitude',
    );
    final data = jsonDecode(response.body);
    return (data['data']['direction'] as num).toDouble();
  }

  /// Fetch available calculation methods
  Future<Map<String, dynamic>> fetchCalculationMethods() async {
    final response = await _get('$_prayerBaseUrl/methods');
    final data = jsonDecode(response.body);
    return data['data'] as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOSQUE FINDER APIs
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find nearby mosques
  Future<List<Map<String, dynamic>>> findNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    try {
      final response = await _get(
        '$_mosqueBaseUrl/masjid?lat=$latitude&long=$longitude&radius=$radiusMeters',
      );
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['masjids'] ?? []);
    } catch (e) {
      // Fallback to empty list
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<http.Response> _get(String url, {Map<String, String>? headers}) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        ...?headers,
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException('API Error: ${response.statusCode}', url);
    }

    return response;
  }

  void dispose() {
    _client.close();
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final String url;

  ApiException(this.message, this.url);

  @override
  String toString() => 'ApiException: $message (URL: $url)';
}
