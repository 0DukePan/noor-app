import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'isnad_parser_service.dart';

/// 📚 قاعدة بيانات الرواة - Narrator Database Service
///
/// Provides lookup for narrator biographies, ranks, teachers, and students.
/// Data sourced from Ibn Hajar's Taqrib al-Tahdhib and other classical works.
class NarratorDatabaseService {
  NarratorDatabaseService._();

  static List<NarratorProfile>? _narrators;
  static bool _initialized = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load the narrator database from assets
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final jsonStr = await rootBundle.loadString('assets/hadith/narrators.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = data['narrators'] as List<dynamic>;

      _narrators = list.map((item) {
        final m = item as Map<String, dynamic>;
        return NarratorProfile(
          name: m['name'] as String,
          aliases: List<String>.from(m['aliases'] ?? []),
          rank: m['rank'] as String? ?? '',
          rankSource: m['rankSource'] as String? ?? '',
          birthYear: m['birthYear'] as int? ?? 0,
          deathYear: m['deathYear'] as int? ?? 0,
          role: m['role'] as String? ?? '',
          teachers: List<String>.from(m['teachers'] ?? []),
          students: List<String>.from(m['students'] ?? []),
        );
      }).toList();

      _initialized = true;
      debugPrint('Narrator database loaded: ${_narrators!.length} narrators');
    } catch (e) {
      debugPrint('Error loading narrator database: $e');
      _narrators = [];
      _initialized = true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOOKUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Look up a narrator by name (fuzzy matching against aliases)
  static NarratorProfile? lookup(String name) {
    if (_narrators == null || _narrators!.isEmpty) return null;

    final normalized = _normalize(name);
    if (normalized.isEmpty) return null;

    // Exact match on name or alias
    for (final narrator in _narrators!) {
      if (_normalize(narrator.name) == normalized) return narrator;
      for (final alias in narrator.aliases) {
        if (_normalize(alias) == normalized) return narrator;
      }
    }

    // Partial match (name contains or is contained by alias)
    for (final narrator in _narrators!) {
      final normName = _normalize(narrator.name);
      if (normName.contains(normalized) || normalized.contains(normName)) {
        return narrator;
      }
      for (final alias in narrator.aliases) {
        final normAlias = _normalize(alias);
        if (normAlias.contains(normalized) || normalized.contains(normAlias)) {
          return narrator;
        }
      }
    }

    return null;
  }

  /// Look up a narrator from a [NarratorInfo] parsed result
  static NarratorProfile? lookupFromNarratorInfo(NarratorInfo info) {
    return lookup(info.normalizedName) ?? lookup(info.name);
  }

  /// Get all narrators in the database
  static List<NarratorProfile> get allNarrators => _narrators ?? [];

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .replaceAll(RegExp(r'[\u0670]'), '')
        .replaceAll(RegExp(r'[\u06D6-\u06ED]'), '')
        .replaceAll('ـ', '')
        .replaceAll('آ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// ملف الراوي الشامل - Complete Narrator Profile
class NarratorProfile {
  final String name;
  final List<String> aliases;
  final String rank;
  final String rankSource;
  final int birthYear;
  final int deathYear;
  final String role;
  final List<String> teachers;
  final List<String> students;

  const NarratorProfile({
    required this.name,
    required this.aliases,
    required this.rank,
    required this.rankSource,
    required this.birthYear,
    required this.deathYear,
    required this.role,
    required this.teachers,
    required this.students,
  });

  /// Display-friendly death year
  String get deathYearDisplay => deathYear > 0 ? '$deathYear هـ' : 'غير معلوم';

  /// Display-friendly birth year
  String get birthYearDisplay => birthYear > 0 ? '$birthYear هـ' : 'غير معلوم';

  /// Is this the Prophet ﷺ
  bool get isProphet => role.contains('النبي');

  /// Is this a companion
  bool get isCompanion => role.contains('صحابي') || role.contains('أم المؤمنين');

  @override
  String toString() => 'NarratorProfile($name, $rank)';
}
