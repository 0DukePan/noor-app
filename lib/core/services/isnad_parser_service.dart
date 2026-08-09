
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

    // Not an Arabic isnad — nothing to parse.
    if (!_containsArabic(normalized)) return [];

    // Arabic commas separate names; turn them into plain spaces so the
    // "next transmission keyword" lookahead can see across name boundaries.
    final spaced = normalized.replaceAll(RegExp(r'[،,؛]'), ' ');
    final narrators = <NarratorInfo>[];

    // Transmission keywords. The leading `(?:^|\s)` requires each keyword to
    // be a standalone word, so the short forms (ثنا/نا/انا/عن/قال) cannot
    // match inside words like "منا" or "اثنا عشر".
    // NOTE: built with a raw string so backslashes are literal, but the
    // alternation is inlined because raw strings do not interpolate `$`.
    final regex = RegExp(
      r'(?:^|\s)(?:حدثنا|حدثني|اخبرنا|اخبرني|انبانا|ثنا|نا|انا|عن|قال|سمعت)\s+'
      r'([^،,\.:]+?)(?=\s*(?:حدثنا|حدثني|اخبرنا|اخبرني|انبانا|ثنا|نا|انا|عن|قال|سمعت)|$)',
      unicode: true,
    );

    final matches = regex.allMatches(spaced);

    for (final match in matches) {
      final rawName = match.group(1)?.trim() ?? '';
      if (rawName.isEmpty || rawName.length < 2) continue;

      // Clean the name
      final cleanName = _cleanNarratorName(rawName);
      if (cleanName.isEmpty) continue;

      // Avoid duplicates
      if (narrators.any((n) => n.normalizedName == cleanName)) continue;

      // Classify using the RAW name: honorifics (رضي الله عنه, صلى الله عليه
      // وسلم) are the most reliable signals for companion/prophet and are
      // stripped away by _cleanNarratorName.
      final role = _classifyNarrator(rawName, arabicText);
      final isProphet = _isProphet(rawName);
      final isCompanion = _isCompanion(rawName, arabicText);

      narrators.add(NarratorInfo(
        name: _restoreOriginalName(cleanName, arabicText),
        normalizedName: cleanName,
        role: role,
        isProphet: isProphet,
        isCompanion: isCompanion,
        level: narrators.length,
        linkWord: _extractLinkWord(match.group(0) ?? '', cleanName),
      ),);

      // The chain is complete once we reach the Prophet or a Companion.
      // Everything after is matn (the body), not more narrators.
      if (isProphet || isCompanion) break;
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
        role: _classifyNarrator(name, arabicText),
        isProphet: _isProphet(name),
        isCompanion: _isCompanion(name, arabicText),
        level: narrators.length,
        linkWord: 'عن',
      ),);

      // Stop at the Prophet/Companion — everything after is matn.
      final last = narrators.last;
      if (last.isProphet || last.isCompanion) break;
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

  /// Whether the text contains Arabic script characters.
  static bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Clean a raw narrator name
  static String _cleanNarratorName(String name) {
    var cleaned = name
        .replaceAll(RegExp(r'رضي الله عنه(ما|م|ا)?'), '')
        .replaceAll(RegExp(r'صلى الله عليه وسلم'), '')
        .replaceAll(RegExp(r'عليه(ما)? السلام'), '')
        .replaceAll(RegExp(r'رحمه الله'), '')
        .replaceAll('ﷺ', '') // U+FDFA, the "Sallallahu Alayhi Wasallam" ligature
        .replaceAll(RegExp(r'[،,:\.]'), '')
        .replaceAll(RegExp(r'^\s*(ان|انه|انها)\s+'), '')
        .trim();

    // Remove trailing particles
    cleaned = cleaned.replaceAll(RegExp(r'\s+(قال|يقول|انه|انها)$'), '').trim();

    // Skip if it's just a verb or particle. (النبي/الرسول are deliberately NOT
    // here: a name of exactly "النبي" or "رسول الله" is the Prophet node.)
    final skipWords = {
      'قال', 'يقول', 'سمعت', 'ان', 'انه', 'انها', 'كان', 'كانت',
      'الله', 'فقال', 'فان',
    };
    if (skipWords.contains(cleaned)) return '';

    return cleaned;
  }

  /// Try to find the original (with diacritics) name in the source text.
  ///
  /// Both the start and end mapping count every non-diacritic character —
  /// including spaces — so indices line up with [String.indexOf] on the
  /// diacritic-stripped text.
  static String _restoreOriginalName(String normalizedName, String originalText) {
    final strippedOriginal = _stripDiacritics(originalText);
    final idx = strippedOriginal.indexOf(normalizedName);
    if (idx < 0) return normalizedName;

    final origChars = originalText.runes.toList();

    // Walk the original text rune-by-rune, counting visible characters until
    // we reach the start of the name (visible index `idx`).
    int origStart = 0;
    int visibleCount = 0;
    for (int i = 0; i < origChars.length; i++) {
      final ch = String.fromCharCode(origChars[i]);
      if (_isVisibleChar(ch)) {
        if (visibleCount == idx) {
          origStart = i;
          break;
        }
        visibleCount++;
      }
    }

    // Walk forward the same way for the length of the (diacritic-free) name.
    int remaining = normalizedName.length;
    int origEnd = origStart;
    for (int i = origStart; i < origChars.length && remaining > 0; i++) {
      final ch = String.fromCharCode(origChars[i]);
      if (_isVisibleChar(ch)) {
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

  /// Whether a single character is "visible" (not a diacritic or tatweel).
  /// Spaces count as visible so index mapping matches the stripped text.
  static bool _isVisibleChar(String ch) {
    if (ch == 'ـ') return false;
    return !RegExp(r'[\u064B-\u0652\u0670\u06D6-\u06ED]').hasMatch(ch);
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

  /// Check if a name refers to the Prophet ﷺ.
  ///
  /// Deliberately does NOT match the bare name "محمد": hundreds of narrators
  /// (al-Bukhari, Muslim, Tirmidhi...) are named Muhammad and would otherwise
  /// be misclassified as the Prophet, truncating the chain. Only unambiguous
  /// designations are treated as the Prophet.
  static bool _isProphet(String name) {
    final prophetMarkers = [
      'النبي', 'الرسول', 'رسول الله', 'نبي الله', 'صلى الله عليه وسلم',
    ];
    final normalized = _stripDiacritics(name);
    return prophetMarkers.any((p) => normalized.contains(p));
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
