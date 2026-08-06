import 'package:flutter/foundation.dart';

/// 🔗 خدمة تحليل الإسناد - Isnad Chain Parser Service
///
/// Parses Arabic hadith text to extract the chain of narrators (Isnad).
/// Uses robust regex patterns to handle all common Arabic narrator
/// introduction formulas: حدثنا، أخبرنا، عن، قال، سمعت، أنبأنا، ثنا
class IsnadParserService {
  IsnadParserService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN PARSING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parse a full Arabic hadith text and extract the isnad chain.
  ///
  /// The Arabic text typically starts with the isnad:
  /// "حَدَّثَنَا عِمْرَانُ بْنُ مَيْسَرَةَ، حَدَّثَنَا عَبْدُ الْوَارِثِ..."
  ///
  /// Returns a list of [NarratorInfo] from author → Prophet (top → bottom).
  static List<NarratorInfo> parseChain(String arabicText) {
    if (arabicText.isEmpty) return [];

    final normalized = _stripDiacritics(arabicText);
    final narrators = <NarratorInfo>[];

    // Split by narrator introduction keywords
    final regex = RegExp(
      r'(?:حدثنا|اخبرنا|ثنا|انبانا|انا|عن|قال|سمعت|حدثني|اخبرني|نا)\s+'
      r'([^،,\.]+?)(?=\s*(?:حدثنا|اخبرنا|ثنا|انبانا|انا|عن|قال|سمعت|حدثني|اخبرني|نا)\s|$)',
      unicode: true,
    );

    final matches = regex.allMatches(normalized);

    for (final match in matches) {
      final rawName = match.group(1)?.trim() ?? '';
      if (rawName.isEmpty || rawName.length < 2) continue;

      // Clean the name
      final cleanName = _cleanNarratorName(rawName);
      if (cleanName.isEmpty) continue;

      // Avoid duplicates
      if (narrators.any((n) => n.normalizedName == cleanName)) continue;

      // Classify the narrator
      final role = _classifyNarrator(cleanName, arabicText);
      final isProphet = _isProphet(cleanName);
      final isCompanion = _isCompanion(cleanName, arabicText);

      narrators.add(NarratorInfo(
        name: _restoreOriginalName(cleanName, arabicText),
        normalizedName: cleanName,
        role: role,
        isProphet: isProphet,
        isCompanion: isCompanion,
        level: narrators.length,
        linkWord: _extractLinkWord(match.group(0) ?? '', cleanName),
      ));
    }

    // If regex found nothing, try simpler splitting
    if (narrators.isEmpty) {
      return _fallbackParse(arabicText);
    }

    return narrators;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FALLBACK PARSER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Simpler parser for texts that don't match the standard patterns well.
  /// Splits by common separators: عن, حدثنا etc.
  static List<NarratorInfo> _fallbackParse(String arabicText) {
    final normalized = _stripDiacritics(arabicText);
    final narrators = <NarratorInfo>[];

    // Split by "عن" which is the most universal connector
    final parts = normalized.split(RegExp(r'\s+عن\s+'));

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;

      // Extract the first name-like segment
      final nameMatch = RegExp(
        r'^([^\s]+(?:\s+(?:بن|ابن|ابي|ابا|ام)\s+[^\s]+)*)',
        unicode: true,
      ).firstMatch(part);

      final name = nameMatch?.group(1)?.trim() ?? part.split(' ').take(3).join(' ');
      if (name.length < 2) continue;

      final cleanName = _cleanNarratorName(name);
      if (cleanName.isEmpty) continue;
      if (narrators.any((n) => n.normalizedName == cleanName)) continue;

      narrators.add(NarratorInfo(
        name: _restoreOriginalName(cleanName, arabicText),
        normalizedName: cleanName,
        role: _classifyNarrator(cleanName, arabicText),
        isProphet: _isProphet(cleanName),
        isCompanion: _isCompanion(cleanName, arabicText),
        level: narrators.length,
        linkWord: 'عن',
      ));
    }

    return narrators;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAME PROCESSING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Remove Arabic diacritics (tashkeel) for reliable matching
  static String _stripDiacritics(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Tashkeel
        .replaceAll(RegExp(r'[\u0670]'), '')        // Alef superscript
        .replaceAll(RegExp(r'[\u06D6-\u06ED]'), '') // Extended marks
        .replaceAll('ـ', '')                         // Tatweel
        .replaceAll(RegExp(r'\s+'), ' ')             // Multiple spaces
        .trim();
  }

  /// Clean a raw narrator name
  static String _cleanNarratorName(String name) {
    var cleaned = name
        .replaceAll(RegExp(r'رضي الله عنه(ما|م|ا)?'), '')
        .replaceAll(RegExp(r'صلى الله عليه وسلم'), '')
        .replaceAll(RegExp(r'عليه(ما)? السلام'), '')
        .replaceAll(RegExp(r'رحمه الله'), '')
        .replaceAll(RegExp(r'[،,:\.]'), '')
        .replaceAll(RegExp(r'^\s*(ان|انه|انها)\s+'), '')
        .trim();

    // Remove trailing particles
    cleaned = cleaned.replaceAll(RegExp(r'\s+(قال|يقول|انه|انها)$'), '').trim();

    // Skip if it's just a verb or particle
    final skipWords = {
      'قال', 'يقول', 'سمعت', 'ان', 'انه', 'انها', 'كان', 'كانت',
      'النبي', 'الرسول', 'رسول', 'الله', 'فقال', 'فان',
    };
    if (skipWords.contains(cleaned)) return '';

    return cleaned;
  }

  /// Try to find the original (with diacritics) name in the source text
  static String _restoreOriginalName(String normalizedName, String originalText) {
    // Find position in stripped text
    final strippedOriginal = _stripDiacritics(originalText);
    final idx = strippedOriginal.indexOf(normalizedName);
    if (idx < 0) return normalizedName;

    // Map back to original text position
    int origIdx = 0;
    int strippedIdx = 0;
    final strippedChars = _stripDiacritics(originalText).runes.toList();
    final origChars = originalText.runes.toList();

    // Find starting position in original
    int origStart = 0;
    int stripped = 0;
    for (int i = 0; i < origChars.length && stripped < idx; i++) {
      final ch = String.fromCharCode(origChars[i]);
      final strippedCh = _stripDiacritics(ch);
      if (strippedCh.isNotEmpty) {
        stripped++;
      }
      origStart = i + 1;
    }

    // Find ending position
    int remaining = normalizedName.length;
    int origEnd = origStart;
    for (int i = origStart; i < origChars.length && remaining > 0; i++) {
      final ch = String.fromCharCode(origChars[i]);
      final strippedCh = _stripDiacritics(ch);
      if (strippedCh.isNotEmpty) {
        remaining--;
      }
      origEnd = i + 1;
    }

    if (origStart < origEnd && origEnd <= originalText.length) {
      try {
        return originalText.substring(origStart, origEnd).trim();
      } catch (_) {
        return normalizedName;
      }
    }

    return normalizedName;
  }

  /// Extract the link word (عن, حدثنا, etc.) used before this narrator
  static String _extractLinkWord(String matchGroup, String name) {
    final keywords = ['حدثنا', 'حدثني', 'اخبرنا', 'اخبرني', 'ثنا', 'انبانا', 'عن', 'قال', 'سمعت', 'نا', 'انا'];
    final normalized = _stripDiacritics(matchGroup);

    for (final kw in keywords) {
      if (normalized.trimLeft().startsWith(kw)) {
        return kw;
      }
    }
    return 'عن';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Classify narrator role
  static String _classifyNarrator(String name, String fullText) {
    if (_isProphet(name)) return 'النبي ﷺ';
    if (_isCompanion(name, fullText)) return 'صحابي';
    return 'راوي';
  }

  /// Check if a name refers to the Prophet ﷺ
  static bool _isProphet(String name) {
    final prophetNames = [
      'النبي', 'الرسول', 'رسول الله', 'محمد',
      'نبي', 'رسول',
    ];
    final normalized = _stripDiacritics(name);
    return prophetNames.any((p) => normalized.contains(p));
  }

  /// Check if narrator is a Companion (Sahabi)
  static bool _isCompanion(String name, String fullText) {
    final strippedText = _stripDiacritics(fullText);

    // Check for رضي الله عنه near the name
    final nameIdx = strippedText.indexOf(_stripDiacritics(name));
    if (nameIdx >= 0) {
      final afterName = strippedText.substring(
        nameIdx,
        (nameIdx + name.length + 30).clamp(0, strippedText.length),
      );
      if (afterName.contains('رضي الله عنه')) return true;
    }

    // Well-known companion names
    final companionNames = [
      'ابي هريره', 'ابو هريره', 'عمر بن الخطاب', 'ابي بكر', 'ابو بكر',
      'عثمان بن عفان', 'علي بن ابي طالب', 'عائشه', 'ابن عباس',
      'ابن عمر', 'ابن مسعود', 'انس بن مالك', 'انس', 'جابر بن عبد الله',
      'جابر', 'ابي سعيد', 'ابو سعيد', 'معاذ بن جبل', 'بلال',
      'ابي ذر', 'ابو ذر', 'سعد بن ابي وقاص', 'ابي موسى', 'ابو موسى',
      'عبد الله بن عمرو', 'ابي ايوب', 'ابو ايوب', 'زيد بن ثابت',
      'حذيفه', 'ابي الدرداء', 'ام سلمه', 'ام المومنين', 'خديجه',
    ];

    final normalizedName = _stripDiacritics(name);
    return companionNames.any((c) => normalizedName.contains(c));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// معلومات الراوي - Narrator information extracted from the isnad
class NarratorInfo {
  final String name;
  final String normalizedName;
  final String role;
  final bool isProphet;
  final bool isCompanion;
  final int level;
  final String linkWord; // عن, حدثنا, etc.

  const NarratorInfo({
    required this.name,
    required this.normalizedName,
    required this.role,
    required this.isProphet,
    required this.isCompanion,
    required this.level,
    this.linkWord = 'عن',
  });

  @override
  String toString() => 'NarratorInfo($name, $role, level=$level)';
}
