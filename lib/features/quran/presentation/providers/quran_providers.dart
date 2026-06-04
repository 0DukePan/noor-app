
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart'; // kept for Hive box usage if needed or legacy

// Entities
import '../../../../core/domain/entities/surah.dart';
import '../../../../core/domain/entities/tafsir.dart';

// Core Repositories (Tafsir remains on Core for now)
import '../../../../core/domain/repositories/tafsir_repository.dart';
import '../../../../core/data/repositories/tafsir_repository_impl.dart';
import '../../../../core/data/data_sources/local_tafsir_data_source.dart';

// Feature Repositories (Quran moves to Feature Architecture)
import '../../domain/repositories/quran_repository.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../data/datasources/local_quran_data_source.dart'; // Impl
import '../../data/datasources/remote_quran_data_source.dart'; // Stub
import '../../data/datasources/quran_datasources.dart'; // Abstract Classes
import '../../../../core/domain/policies/offline_policy.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY & DATA SOURCES
// ═══════════════════════════════════════════════════════════════════════════

// Quran Data Sources
final localQuranDataSourceProvider = Provider<LocalQuranDataSourceImpl>((ref) {
  return LocalQuranDataSourceImpl();
});

final remoteQuranDataSourceProvider = Provider<RemoteQuranDataSourceImpl>((ref) {
  return RemoteQuranDataSourceImpl();
});

final offlinePolicyProvider = Provider<OfflinePolicy>((ref) {
  return DefaultOfflinePolicy();
});

// Quran Repository
final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final localDS = ref.watch(localQuranDataSourceProvider);
  final remoteDS = ref.watch(remoteQuranDataSourceProvider);
  final policy = ref.watch(offlinePolicyProvider);
  
  return QuranRepositoryImpl(
    localDataSource: localDS,
    remoteDataSource: remoteDS,
    offlinePolicy: policy,
  );
});

// Tafsir Data Sources (Legacy Core)
final localTafsirDataSourceProvider = Provider<LocalTafsirDataSource>((ref) {
  return LocalTafsirDataSource();
});

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) {
  final dataSource = ref.watch(localTafsirDataSourceProvider);
  return TafsirRepositoryImpl(dataSource);
});

// ═══════════════════════════════════════════════════════════════════════════
// USE CASE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// All Surahs List (Index)
final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  final result = await repo.getAllSurahs();
  
  return result.fold(
    (failure) => throw failure.message, // Propagate error to AsyncValue
    (surahs) => surahs,
  );
});

/// Specific Surah with Verses (Full Text)
final surahProvider = FutureProvider.family<Surah, int>((ref, surahNumber) async {
  final repo = ref.watch(quranRepositoryProvider);
  final result = await repo.getSurahWithVerses(surahNumber);
  
  return result.fold(
    (failure) => throw failure.message,
    (surah) => surah,
  );
});



/// Verses for a specific Mushaf page (1-604)
final quranPageProvider = FutureProvider.family<List<Verse>, int>((ref, pageNumber) async {
  final ds = ref.watch(localQuranDataSourceProvider);
  return ds.getVersesByPage(pageNumber);
});

/// Current Mushaf page number (1-604)
final mushafCurrentPageProvider = StateProvider<int>((ref) => 1);

// ═══════════════════════════════════════════════════════════════════════════
// READING STATE
// ═══════════════════════════════════════════════════════════════════════════

class ReadingSettings {
  final double fontSize;
  final bool showTranslation;
  final bool isKhushuMode;

  const ReadingSettings({
    this.fontSize = 24.0,
    this.showTranslation = true,
    this.isKhushuMode = false,
  });

  ReadingSettings copyWith({double? fontSize, bool? showTranslation, bool? isKhushuMode}) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      isKhushuMode: isKhushuMode ?? this.isKhushuMode,
    );
  }
}

class ReadingSettingsNotifier extends StateNotifier<ReadingSettings> {
  ReadingSettingsNotifier() : super(const ReadingSettings());

  void setFontSize(double size) => state = state.copyWith(fontSize: size);
  void toggleTranslation() => state = state.copyWith(showTranslation: !state.showTranslation);
  void toggleKhushuMode() => state = state.copyWith(isKhushuMode: !state.isKhushuMode);
}

final readingSettingsProvider = StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  return ReadingSettingsNotifier();
});

/// Last Read Position Logic
final lastReadPositionProvider = FutureProvider<Map<String, int>?>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  final result = await repo.getLastReadingPosition();
  
  return result.fold(
    (failure) => null, // Fail silently/gracefully for optional features
    (pos) => {'surah': pos.surahNumber, 'verse': pos.verseNumber, 'page': pos.page},
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// UI STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Search query for Quran Index
final quranSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected Verse Index for Tafsir (per Surah)
final surahSelectedVerseProvider = StateProvider.family<int?, int>((ref, surahId) => null);

/// Selected Tafsir Book ID
final selectedTafsirBookProvider = StateProvider<String>((ref) => 'muyassar');

/// Available Tafsir Books
final availableTafsirBooksProvider = Provider<List<TafsirBook>>((ref) => TafsirBook.values);

/// Tafsir for a specific Verse
final tafsirProvider = FutureProvider.family<TafsirVerse?, ({int surahId, int verseId})>((ref, params) async {
  final repo = ref.watch(tafsirRepositoryProvider);
  final bookId = ref.watch(selectedTafsirBookProvider);
  return repo.getTafsir(params.surahId, params.verseId, source: bookId);
});

// ═══════════════════════════════════════════════════════════════════════════
// SMART FILTERING (Moved out of UI rebuild cycle)
// ═══════════════════════════════════════════════════════════════════════════

/// Filter type: 'all', 'meccan', 'medinan'
final surahFilterProvider = StateProvider<String>((ref) => 'all');

/// Normalize Arabic text for smart search
/// Removes diacritics (tashkeel), normalizes hamza variants, etc.
String normalizeArabic(String text) {
  return text
      // Remove Arabic diacritics (tashkeel)
      .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'), '')
      // Normalize Alef variants (أ إ آ → ا)
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      // Normalize Taa Marbuta (ة → ه)
      .replaceAll('ة', 'ه')
      // Normalize Alef Maksura (ى → ي)
      .replaceAll('ى', 'ي')
      .trim();
}

/// Reactive filtered surahs — recomputes only when surahs, query, or filter changes
/// NOT on every UI rebuild
final filteredSurahsProvider = Provider<AsyncValue<List<Surah>>>((ref) {
  final surahsAsync = ref.watch(surahsProvider);
  final query = ref.watch(quranSearchQueryProvider);
  final filter = ref.watch(surahFilterProvider);

  return surahsAsync.whenData((allSurahs) {
    final normalizedQuery = normalizeArabic(query);

    return allSurahs.where((surah) {
      // Search match (smart Arabic normalization)
      final matchesSearch = query.isEmpty ||
          normalizeArabic(surah.nameArabic).contains(normalizedQuery) ||
          surah.nameEnglish.toLowerCase().contains(query.toLowerCase()) ||
          surah.number.toString() == query;

      // Filter match
      bool matchesType = true;
      if (filter == 'meccan') {
        matchesType = surah.revelationType == RevelationType.meccan;
      } else if (filter == 'medinan') {
        matchesType = surah.revelationType == RevelationType.medinan;
      }

      return matchesSearch && matchesType;
    }).toList();
  });
});

