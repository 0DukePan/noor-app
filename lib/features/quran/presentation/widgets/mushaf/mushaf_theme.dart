import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../core/services/hive_box_registry.dart';
import '../../../../../core/utils/verse_counts.dart' as vc;
import '../../../../../l10n/generated/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MUSHAF THEMES — one immutable colour scheme, localized labels (QUR-07)
// ═══════════════════════════════════════════════════════════════════════════

enum MushafTheme {
  madaniCream, // Classic printed Quran look
  snowWhite, // Clean modern look
  midnightBlack, // OLED dark, reference dark tokens
  deepSepia, // Warm night reading
  highContrast, // Maximum legibility (accessibility)
}

class MushafThemeData {
  const MushafThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.verseMarkerColor,
    required this.headerColor,
    required this.headerTextColor,
    required this.borderColor,
    required this.label,
  });
  final Color backgroundColor;
  final Color textColor;
  final Color verseMarkerColor;
  final Color headerColor;
  final Color headerTextColor;
  final Color borderColor;

  /// Fallback label (Arabic) for contexts without BuildContext (tests).
  final String label;

  /// Localized label from ARB (QUR-07: no hard-coded reader labels in UI).
  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (identical(this, madaniCreamTheme)) return l10n.mushafThemeClassic;
    if (identical(this, snowWhiteTheme)) return l10n.mushafThemeWhite;
    if (identical(this, midnightBlackTheme)) return l10n.mushafThemeDark;
    if (identical(this, deepSepiaTheme)) return l10n.mushafThemeNight;
    if (identical(this, highContrastTheme)) return l10n.mushafThemeContrast;
    return label;
  }

  static const madaniCreamTheme = MushafThemeData(
    backgroundColor: Color(0xFFFDF6E3),
    textColor: Color(0xFF1A1A1A),
    verseMarkerColor: Color(0xFF8B7355),
    headerColor: Color(0xFF2E7D32),
    headerTextColor: Colors.white,
    borderColor: Color(0xFFD4B896),
    label: 'كلاسيكي',
  );
  static const snowWhiteTheme = MushafThemeData(
    backgroundColor: Color(0xFFFFFFFE),
    textColor: Color(0xFF212121),
    verseMarkerColor: Color(0xFF1B5E20),
    headerColor: Color(0xFF1B5E20),
    headerTextColor: Colors.white,
    borderColor: Color(0xFFE0E0E0),
    label: 'أبيض',
  );

  /// Reference dark tokens: bg ~#141416, text ~#E8E5E1, muted ~#8B8E99.
  static const midnightBlackTheme = MushafThemeData(
    backgroundColor: Color(0xFF141416),
    textColor: Color(0xFFE8E5E1),
    verseMarkerColor: Color(0xFFF3C623),
    headerColor: Color(0xFF1A1A1A),
    headerTextColor: Color(0xFFE8E5E1),
    borderColor: Color(0xFF2A2A2A),
    label: 'داكن',
  );
  static const deepSepiaTheme = MushafThemeData(
    backgroundColor: Color(0xFF2C2416),
    textColor: Color(0xFFD4C5A9),
    verseMarkerColor: Color(0xFFC9A96E),
    headerColor: Color(0xFF3D3222),
    headerTextColor: Color(0xFFD4C5A9),
    borderColor: Color(0xFF4A3D2A),
    label: 'ليلي',
  );

  /// High-contrast variant (Phase 4): pure black/white with a luminous
  /// marker. Changes colours only — never ordering, boundaries, or text.
  static const highContrastTheme = MushafThemeData(
    backgroundColor: Color(0xFF000000),
    textColor: Color(0xFFFFFFFF),
    verseMarkerColor: Color(0xFFFFD60A),
    headerColor: Color(0xFF000000),
    headerTextColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFFFFFFF),
    label: 'تباين عالٍ',
  );

  static const Map<MushafTheme, MushafThemeData> themes = {
    MushafTheme.madaniCream: madaniCreamTheme,
    MushafTheme.snowWhite: snowWhiteTheme,
    MushafTheme.midnightBlack: midnightBlackTheme,
    MushafTheme.deepSepia: deepSepiaTheme,
    MushafTheme.highContrast: highContrastTheme,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// READER PREFERENCE STATE — versioned, persisted, recovers safely (QUR-07)
// ═══════════════════════════════════════════════════════════════════════════

final mushafThemeProvider = StateProvider<MushafTheme>(
  (ref) => MushafTheme.madaniCream,
);

/// Whether top/bottom controls overlay is visible
final mushafShowControlsProvider = StateProvider<bool>((ref) => true);

/// Discrete Quran-text zoom levels (QUR-03): unrestricted scaling breaks
/// fixed page boundaries, so only approved levels are offered.
final mushafZoomProvider = StateProvider<double>((ref) => 1.0);

/// Approved zoom levels.
const List<double> kMushafZoomLevels = [0.85, 1.0, 1.15, 1.3, 1.5];

/// Versioned reader-preferences record (QUR-07).
class MushafPreferences {
  const MushafPreferences({
    this.version = MushafPreferences.currentVersion,
    this.theme = MushafTheme.madaniCream,
    this.zoom = 1.0,
    this.showControls = true,
    this.lastPage = 1,
  });

  static const int currentVersion = 1;
  static const String boxKey = 'mushaf_reader_prefs_v1';

  final int version;
  final MushafTheme theme;
  final double zoom;
  final bool showControls;
  final int lastPage;

  /// Corrupt values return safe defaults (never a crash).
  factory MushafPreferences.fromStored(Map<dynamic, dynamic>? stored) {
    if (stored == null) return const MushafPreferences();
    try {
      final version = stored['version'] as int? ?? currentVersion;
      if (version != currentVersion) return const MushafPreferences();
      final themeIndex = stored['theme'] as int?;
      final theme =
          themeIndex != null &&
              themeIndex >= 0 &&
              themeIndex < MushafTheme.values.length
          ? MushafTheme.values[themeIndex]
          : MushafTheme.madaniCream;
      final zoom = (stored['zoom'] as num?)?.toDouble() ?? 1.0;
      final safeZoom = kMushafZoomLevels.contains(zoom) ? zoom : 1.0;
      final showControls = stored['showControls'] as bool? ?? true;
      final lastPage = vc.clampPage((stored['lastPage'] as int?) ?? 1);
      return MushafPreferences(
        theme: theme,
        zoom: safeZoom,
        showControls: showControls,
        lastPage: lastPage,
      );
    } on Object {
      return const MushafPreferences();
    }
  }

  Map<String, Object?> toStored() => {
    'version': version,
    'theme': theme.index,
    'zoom': zoom,
    'showControls': showControls,
    'lastPage': lastPage,
  };
}

/// Best-effort persistence owner for reader preferences (Hive settings box).
/// Corrupt values and missing Hive init fall back silently to defaults.
class MushafPreferenceStore {
  static Future<Map<dynamic, dynamic>?> readStored() async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) return null;
      final box = Hive.box<dynamic>(HiveBoxes.settings);
      final raw = box.get(MushafPreferences.boxKey);
      if (raw is Map) return Map<dynamic, dynamic>.from(raw);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Best-effort write. Never opens a box: box lifecycle belongs to
  /// [HiveService]. When the settings box is not open (tests, early
  /// startup), the write is skipped silently.
  static Future<void> writeStored(MushafPreferences prefs) async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) return;
      final box = Hive.box<dynamic>(HiveBoxes.settings);
      await box.put(MushafPreferences.boxKey, prefs.toStored());
    } catch (_) {
      // Preferences are best-effort; never block reading.
    }
  }
}
