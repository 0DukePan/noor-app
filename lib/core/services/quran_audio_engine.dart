import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

/// 🔊 محرك الصوت الاحترافي - Professional Quran Audio Engine
/// 
/// Features:
/// - Background playback (lock screen controls)
/// - Offline smart caching
/// - Resume position
/// - Speed control
/// - Repeat modes
/// - Multiple reciters
class QuranAudioEngine {
  static final AudioPlayer _player = AudioPlayer();
  static Box? _cacheBox;
  static Box? _progressBox;
  
  // State
  static int _currentSurah = 1;
  static int _currentAyah = 1;
  static String _currentReciter = 'ar.alafasy';
  static RepeatMode _repeatMode = RepeatMode.none;
  static double _speed = 1.0;
  
  // Streams
  static final _currentAyahController = StreamController<int>.broadcast();
  static Stream<int> get currentAyahStream => _currentAyahController.stream;
  
  static final _playStateController = StreamController<PlayState>.broadcast();
  static Stream<PlayState> get playStateStream => _playStateController.stream;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// تهيئة المحرك
  static Future<void> init() async {
    // Initialize Hive boxes
    _cacheBox = await Hive.openBox('audio_cache');
    _progressBox = await Hive.openBox('audio_progress');
    
    // Initialize audio session for background playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
    
    // Listen to player state
    _player.playerStateStream.listen((state) {
      _playStateController.add(PlayState(
        isPlaying: state.playing,
        processingState: state.processingState,
      ));
      
      // Handle completion
      if (state.processingState == ProcessingState.completed) {
        _onAyahComplete();
      }
    });
    
    // Listen to position for progress saving
    _player.positionStream.listen((position) {
      _saveProgress(position);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECITERS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, ReciterInfo> reciters = {
    'ar.alafasy': ReciterInfo(
      id: 'ar.alafasy',
      arabicName: 'مشاري راشد العفاسي',
      englishName: 'Mishary Rashid Alafasy',
      baseUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy',
      flag: '🇰🇼',
    ),
    'ar.abdulbasit': ReciterInfo(
      id: 'ar.abdulbasit',
      arabicName: 'عبد الباسط عبد الصمد',
      englishName: 'Abdul Basit Abdul Samad',
      baseUrl: 'https://cdn.islamic.network/quran/audio/128/ar.abdulbasitmurattal',
      flag: '🇪🇬',
    ),
    'ar.minshawi': ReciterInfo(
      id: 'ar.minshawi',
      arabicName: 'محمد صديق المنشاوي',
      englishName: 'Muhammad Siddiq Al-Minshawi',
      baseUrl: 'https://cdn.islamic.network/quran/audio/128/ar.minshawi',
      flag: '🇪🇬',
    ),
    'ar.husary': ReciterInfo(
      id: 'ar.husary',
      arabicName: 'محمود خليل الحصري',
      englishName: 'Mahmoud Khalil Al-Husary',
      baseUrl: 'https://cdn.islamic.network/quran/audio/128/ar.husary',
      flag: '🇪🇬',
    ),
    'ar.sudais': ReciterInfo(
      id: 'ar.sudais',
      arabicName: 'عبد الرحمن السديس',
      englishName: 'Abdurrahman As-Sudais',
      baseUrl: 'https://cdn.islamic.network/quran/audio/128/ar.abdurrahmaansudais',
      flag: '🇸🇦',
    ),
    'ar.shuraym': ReciterInfo(
      id: 'ar.shuraym',
      arabicName: 'سعود الشريم',
      englishName: 'Saud Al-Shuraim',
      baseUrl: 'https://cdn.islamic.network/quran/audio/128/ar.shuraym',
      flag: '🇸🇦',
    ),
  };

  static ReciterInfo get currentReciterInfo => 
      reciters[_currentReciter] ?? reciters.values.first;

  static void setReciter(String reciterId) {
    if (reciters.containsKey(reciterId)) {
      _currentReciter = reciterId;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYBACK CONTROL
  // ═══════════════════════════════════════════════════════════════════════════

  /// تشغيل آية
  static Future<void> playAyah({
    required int surah,
    required int ayah,
    String? reciter,
  }) async {
    _currentSurah = surah;
    _currentAyah = ayah;
    if (reciter != null) _currentReciter = reciter;
    
    _currentAyahController.add(ayah);
    
    try {
      final audioSource = await _getAudioSource(surah, ayah);
      
      await _player.setAudioSource(audioSource);
      await _player.setSpeed(_speed);
      await _player.play();
      
      // Check for saved position
      final savedPosition = _getSavedPosition(surah, ayah);
      if (savedPosition != null && savedPosition.inSeconds > 3) {
        await _player.seek(savedPosition);
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  /// تشغيل السورة من البداية
  static Future<void> playSurah({
    required int surah,
    String? reciter,
  }) async {
    await playAyah(surah: surah, ayah: 1, reciter: reciter);
  }

  /// تشغيل/إيقاف
  static Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// إيقاف
  static Future<void> pause() async {
    await _player.pause();
  }

  /// استئناف
  static Future<void> resume() async {
    await _player.play();
  }

  /// إيقاف كامل
  static Future<void> stop() async {
    await _player.stop();
    _currentAyahController.add(0);
  }

  /// الآية السابقة
  static Future<void> previousAyah() async {
    if (_currentAyah > 1) {
      await playAyah(surah: _currentSurah, ayah: _currentAyah - 1);
    }
  }

  /// الآية التالية
  static Future<void> nextAyah() async {
    await playAyah(surah: _currentSurah, ayah: _currentAyah + 1);
  }

  /// التقديم/الترجيع
  static Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// سرعة التشغيل
  static Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _player.setSpeed(_speed);
  }

  static double get speed => _speed;

  /// وضع التكرار
  static void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  static RepeatMode get repeatMode => _repeatMode;

  // ═══════════════════════════════════════════════════════════════════════════
  // OFFLINE CACHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على مصدر الصوت (محلي أو عبر الإنترنت)
  static Future<AudioSource> _getAudioSource(int surah, int ayah) async {
    final reciterInfo = currentReciterInfo;
    final verseNumber = _getAbsoluteVerseNumber(surah, ayah);
    
    // Check local cache first
    final localPath = await _getLocalPath(surah, ayah);
    final localFile = File(localPath);
    
    if (localFile.existsSync()) {
      debugPrint('Playing from cache: $localPath');
      return AudioSource.file(
        localPath,
        tag: _createMediaItem(surah, ayah),
      );
    }
    
    // Stream from network
    final url = '${reciterInfo.baseUrl}/$verseNumber.mp3';
    debugPrint('Streaming: $url');
    
    // Start background download for caching
    _downloadForCache(surah, ayah, url);
    
    return AudioSource.uri(
      Uri.parse(url),
      tag: _createMediaItem(surah, ayah),
    );
  }

  /// تحميل للتخزين المؤقت (في الخلفية)
  static Future<void> _downloadForCache(int surah, int ayah, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final localPath = await _getLocalPath(surah, ayah);
        final file = File(localPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        
        // Update cache index
        await _updateCacheIndex(surah, ayah, localPath);
        
        debugPrint('Cached: $localPath');
      }
    } catch (e) {
      debugPrint('Cache download failed: $e');
    }
  }

  /// مسار الملف المحلي
  static Future<String> _getLocalPath(int surah, int ayah) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/audio/$_currentReciter/$surah/$ayah.mp3';
  }

  /// تحديث فهرس الكاش
  static Future<void> _updateCacheIndex(int surah, int ayah, String path) async {
    final key = '$_currentReciter:$surah:$ayah';
    await _cacheBox?.put(key, {
      'path': path,
      'timestamp': DateTime.now().toIso8601String(),
      'surah': surah,
      'ayah': ayah,
    });
  }

  /// تنظيف الكاش القديم (بعد 7 أيام)
  static Future<void> cleanOldCache() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheBox?.toMap().forEach((key, value) {
      if (value is Map) {
        final timestamp = DateTime.tryParse(value['timestamp'] ?? '');
        if (timestamp != null && now.difference(timestamp).inDays > 7) {
          // Delete file
          final path = value['path'];
          if (path != null) {
            File(path).deleteSync();
          }
          keysToRemove.add(key);
        }
      }
    });
    
    for (final key in keysToRemove) {
      await _cacheBox?.delete(key);
    }
    
    debugPrint('Cleaned ${keysToRemove.length} old cached files');
  }

  /// حجم الكاش
  static Future<String> getCacheSize() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    
    if (!audioDir.existsSync()) return '0 MB';
    
    int totalSize = 0;
    audioDir.listSync(recursive: true).whereType<File>().forEach((file) {
      totalSize += file.lengthSync();
    });
    
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// مسح الكاش
  static Future<void> clearCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    
    if (audioDir.existsSync()) {
      await audioDir.delete(recursive: true);
    }
    await _cacheBox?.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROGRESS TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ التقدم
  static Future<void> _saveProgress(Duration position) async {
    if (position.inSeconds < 3) return;
    
    await _progressBox?.put('last_position', {
      'surah': _currentSurah,
      'ayah': _currentAyah,
      'position': position.inMilliseconds,
      'reciter': _currentReciter,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// استعادة آخر موضع
  static Future<ResumeInfo?> getLastPosition() async {
    final data = _progressBox?.get('last_position');
    if (data == null) return null;
    
    return ResumeInfo(
      surah: data['surah'] ?? 1,
      ayah: data['ayah'] ?? 1,
      position: Duration(milliseconds: data['position'] ?? 0),
      reciter: data['reciter'] ?? 'ar.alafasy',
      timestamp: DateTime.tryParse(data['timestamp'] ?? ''),
    );
  }

  static Duration? _getSavedPosition(int surah, int ayah) {
    final data = _progressBox?.get('last_position');
    if (data == null) return null;
    if (data['surah'] != surah || data['ayah'] != ayah) return null;
    return Duration(milliseconds: data['position'] ?? 0);
  }

  /// استئناف من آخر موضع
  static Future<void> resumeLastPosition() async {
    final info = await getLastPosition();
    if (info == null) return;
    
    await playAyah(
      surah: info.surah,
      ayah: info.ayah,
      reciter: info.reciter,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  static void _onAyahComplete() {
    switch (_repeatMode) {
      case RepeatMode.ayah:
        // Repeat same ayah
        playAyah(surah: _currentSurah, ayah: _currentAyah);
        break;
      case RepeatMode.surah:
        // Next ayah or restart surah
        nextAyah();
        break;
      case RepeatMode.none:
        // Auto-advance to next ayah
        nextAyah();
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// رقم الآية المطلق (1-6236)
  static int _getAbsoluteVerseNumber(int surah, int ayah) {
    // Verse counts per surah
    const verseCounts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
      111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30,
      73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29,
      18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18,
      12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
      29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19,
      5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ];
    
    int absoluteNumber = 0;
    for (int i = 0; i < surah - 1; i++) {
      absoluteNumber += verseCounts[i];
    }
    return absoluteNumber + ayah;
  }

  /// إنشاء MediaItem للإشعارات
  static MediaItem _createMediaItem(int surah, int ayah) {
    return MediaItem(
      id: '$surah:$ayah',
      title: 'الآية $ayah',
      album: 'سورة ${_getSurahName(surah)}',
      artist: currentReciterInfo.arabicName,
    );
  }

  static String _getSurahName(int surah) {
    const names = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
      'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر', 'النحل',
      'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون', 'النور',
      'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم', 'لقمان', 'السجدة',
      'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
      'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
      'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة',
      'الحديد', 'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة', 'المنافقون', 'التغابن',
      'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن',
      'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية',
      'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق',
      'القدر', 'البينة', 'الزلزلة', 'العاديات', 'القارعة', 'التكاثر', 'العصر', 'الهمزة',
      'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص',
      'الفلق', 'الناس',
    ];
    if (surah < 1 || surah > 114) return 'القرآن الكريم';
    return names[surah - 1];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  static AudioPlayer get player => _player;
  static int get currentSurah => _currentSurah;
  static int get currentAyah => _currentAyah;
  static bool get isPlaying => _player.playing;
  static Duration get position => _player.position;
  static Duration? get duration => _player.duration;
  static Stream<Duration> get positionStream => _player.positionStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// معلومات القارئ
class ReciterInfo {
  final String id;
  final String arabicName;
  final String englishName;
  final String baseUrl;
  final String flag;

  const ReciterInfo({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.baseUrl,
    required this.flag,
  });
}

/// وضع التكرار
enum RepeatMode {
  none,   // لا تكرار - تقدم تلقائي
  ayah,   // تكرار الآية الحالية
  surah,  // تكرار السورة
}

extension RepeatModeInfo on RepeatMode {
  String get arabicName {
    switch (this) {
      case RepeatMode.none: return 'بدون تكرار';
      case RepeatMode.ayah: return 'تكرار الآية';
      case RepeatMode.surah: return 'تكرار السورة';
    }
  }

  IconData get icon {
    switch (this) {
      case RepeatMode.none: return Icons.repeat;
      case RepeatMode.ayah: return Icons.repeat_one;
      case RepeatMode.surah: return Icons.repeat;
    }
  }
}

/// حالة التشغيل
class PlayState {
  final bool isPlaying;
  final ProcessingState processingState;

  const PlayState({
    required this.isPlaying,
    required this.processingState,
  });

  bool get isLoading => processingState == ProcessingState.loading ||
      processingState == ProcessingState.buffering;
  bool get isCompleted => processingState == ProcessingState.completed;
}

/// معلومات الاستئناف
class ResumeInfo {
  final int surah;
  final int ayah;
  final Duration position;
  final String reciter;
  final DateTime? timestamp;

  const ResumeInfo({
    required this.surah,
    required this.ayah,
    required this.position,
    required this.reciter,
    this.timestamp,
  });
}

