import 'dart:io';

/// Generates the interaction catalogue inventory (INT-01, Phase 0.7).
///
/// Scans `lib/` for callback declarations and emits
/// `docs/interaction-catalogue.md`: hand-reviewed critical contracts first,
/// then the full generated inventory where every row starts as `unverified`.
/// Re-running overwrites only the inventory section between the markers.
///
/// Usage: `dart run tool/gen_interaction_catalogue.dart`
void main() {
  final libDir = Directory('lib');
  final pattern = RegExp(
    r'on(Pressed|Tap|LongPress|Changed|Selected|Submitted|Saved|Toggle|Jump|Preview|Settle|Retry|Expand|Bookmark|Resume|JumpTo|PageChanged|SelectedBook|Deleted|Confirmed|Cancelled|Added|Removed|Opened|Closed|Completed|Skipped|Retried)\b',
  );
  final classPattern = RegExp(r'^\s*(?:class|mixin|extension)\s+(\w+)');

  final rows = <List<String>>[];
  final files =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final lines = file.readAsLinesSync();
    var enclosing = '-';
    for (var i = 0; i < lines.length; i++) {
      final classMatch = classPattern.firstMatch(lines[i]);
      if (classMatch != null) enclosing = classMatch.group(1)!;
      for (final match in pattern.allMatches(lines[i])) {
        final rel = file.path
            .replaceAll('\\', '/')
            .replaceFirst(RegExp(r'^lib/'), '');
        rows.add([
          rel,
          (i + 1).toString(),
          enclosing,
          'on${match.group(1)}',
          lines[i].trim().length > 90
              ? '${lines[i].trim().substring(0, 90)}…'
              : lines[i].trim(),
        ]);
      }
    }
  }

  final buffer = StringBuffer()
    ..writeln('# Interaction catalogue (INT-01)')
    ..writeln()
    ..writeln(
      'Living release artefact. Every reachable callback, gesture, menu item, '
      'dialog choice, selector, and permission prompt gets one stable row. '
      'The release gate is catalogue coverage: no reachable action without an '
      'owner, precondition, observable outcome, and current regression or '
      'device evidence.',
    )
    ..writeln()
    ..writeln(
      'Generated inventory: ${rows.length} callback declarations across '
      '`${files.length}` files under `lib/` '
      '(`dart run tool/gen_interaction_catalogue.dart`). '
      'Rows marked `unverified` are an honest test gap, not a pass.',
    )
    ..writeln()
    ..writeln('## Critical contracts (reviewed, with evidence)')
    ..writeln()
    ..writeln(
      '| ID | Location | Trigger + preconditions | Intended outcome | '
      'Feedback | Persistence | Evidence |',
    )
    ..writeln('|---|---|---|---|---|---|---|');
  for (final row in _criticalContracts) {
    buffer.writeln('| ${row.join(' | ')} |');
  }
  buffer
    ..writeln()
    ..writeln('<!-- INVENTORY:BEGIN (generated — do not hand-edit) -->')
    ..writeln()
    ..writeln(
      '| Inventory ID | File | Line | Enclosing | Callback | Source | Status |',
    )
    ..writeln('|---|---|---|---|---|---|---|');
  for (var i = 0; i < rows.length; i++) {
    final id = 'INT-${(i + 1).toString().padLeft(3, '0')}';
    buffer.writeln(
      '| $id | ${rows[i][0]} | ${rows[i][1]} | ${rows[i][2]} | '
      '${rows[i][3]} | `${_escape(rows[i][4])}` | unverified |',
    );
  }
  buffer
    ..writeln()
    ..writeln('<!-- INVENTORY:END -->')
    ..writeln()
    ..writeln(
      'Pure formatting and small presentation callbacks take focused widget '
      'tests; data, navigation, permission, audio, share, destructive, or '
      'cross-feature actions require a state assertion plus device evidence '
      'where platform plugins are involved.',
    );

  File('docs/interaction-catalogue.md').writeAsStringSync(buffer.toString());
  stdout.writeln(
    'wrote docs/interaction-catalogue.md '
    '(${rows.length} inventory rows, '
    '${_criticalContracts.length} critical contracts)',
  );
}

String _escape(String input) => input.replaceAll('|', r'\|');

/// Hand-reviewed critical contracts for every confirmed P1 interaction fix.
/// Evidence IDs are real test files in this checkout; `device-pending`
/// marks the honest remaining gap (QA-01).
const List<List<String>> _criticalContracts = [
  [
    'NAV-01-surah',
    'lib/core/router/app_router.dart surah/:surahNumber',
    'open /quran/surah/:n(+?ayah=); any string incl. malformed',
    'validated SurahPage(surah, initialAyah?) or localized recovery screen',
    'recovery title/body/value + safe back button; never a red screen',
    'none',
    'test/unit/route_decoder_test.dart; device-pending for deep links',
  ],
  [
    'NAV-01-tadabbur',
    'lib/core/router/app_router.dart tadabbur/:verseNumber',
    'open nested tadabbur path; malformed surah/verse',
    'validated TadabburMihrabPage or recovery screen',
    'same recovery contract',
    'none',
    'test/unit/route_decoder_test.dart',
  ],
  [
    'QUR-04-mushaf-link',
    'lib/core/router/app_router.dart mushaf?page=',
    'page=1/604/0/negative/huge/malformed/missing',
    'clamped QuranMushafPage before PageController sees it',
    'slider/page indicator agree from first paint',
    'last page persisted on settle only',
    'test/unit/route_decoder_test.dart; test/widget/quran_mushaf_page_test.dart',
  ],
  [
    'QUR-05-page-error',
    'lib/features/quran/presentation/pages/quran_mushaf_page.dart _MushafErrorPane',
    'missing/corrupt page asset',
    'localized pane, diagnostic ID, retry; no raw exception',
    'retry button (Key mushafRetryButton); snackbar-free inline',
    'none',
    'test/widget/quran_mushaf_page_test.dart (retry recovers)',
  ],
  [
    'QUR-06-ayah-action',
    'lib/features/quran/presentation/pages/quran_mushaf_page.dart _ContinuousVerseBlock',
    'tap/long-press correct ayah region; blank-tap toggles controls',
    'AyahActionsSheet for that (surah, ayah); controls untouched',
    'haptic + sheet; 350ms toggle suppression after ayah tap',
    'none',
    'code contract; device TalkBack/VoiceOver pass pending (QA-01)',
  ],
  [
    'QUR-07-prefs',
    'lib/features/quran/presentation/pages/quran_mushaf_page.dart MushafPreferences',
    'change theme/zoom/controls; relaunch; corrupt stored values',
    'approved values persist; corrupt values safely default (v1)',
    'theme/zoom controls localized; 48dp targets',
    'versioned settings-box record; best-effort, never blocks reading',
    'test/unit/mushaf_preferences_test.dart; device relaunch pending',
  ],
  [
    'QUR-09-continue',
    'home ContinueReadingCard, QuranPage last-position, search result, Khatmah resume',
    'saved non-first ayah location; tap card/result/resume',
    'study reader opens SAME surah+ayah with highlight; Back returns to results where applicable',
    'visible context matches the card/query',
    'reads shared reading_progress record; no overwrite',
    'test/widget/surah_initial_ayah_test.dart; entry wiring code-reviewed; device pending',
  ],
  [
    'QUR-12-bookmark',
    'lib/features/quran/data/repositories/quran_repository_impl.dart',
    'add same ayah twice; remove; relaunch',
    'one bookmark stored then removed; last-reading unchanged',
    'verseBookmarkSaved snackbar on study page',
    'idempotent bookmarks box rows; migration-safe tryFromMap pattern reused',
    'test/data/quran_bookmarks_test.dart',
  ],
  [
    'AUD-01-verse-play',
    'SurahPage verse options; QuranAudioService.playVerse',
    'select non-first ayah, tap play',
    'engine receives exact (surah, ayah); pending/playing/error UI accurate',
    'playback error stream + localized error + one safe retry',
    'resume position per (surah, ayah)',
    'code contract; engine unit part in test/services/audio_boundary_test.dart; device audio pending',
  ],
  [
    'AUD-02-boundary',
    'lib/core/services/quran_audio_engine.dart nextAyahIdentity/_onAyahComplete',
    'completion on each surah final ayah under every repeat/queue mode',
    'stop or valid same-surah restart; never an out-of-range pair or mislabeled recording',
    'end-of-surah/Quran state; no request for invalid identity',
    'none beyond resume marker',
    'test/services/audio_boundary_test.dart (all 114 surahs x modes)',
  ],
  [
    'AUD-03-failure',
    'lib/core/services/quran_audio_engine.dart PlaybackFailure',
    'offline, invalid URL, player error',
    'typed failure emitted (never log-only); coherent stopped state; one safe retry',
    'localized audioError* strings + audioRetry',
    'none',
    'test/services/audio_boundary_test.dart (typing); offline/player-error device pass pending',
  ],
  [
    'TAF-01-availability',
    'lib/core/data/data_sources/tafsir_database.dart; mushaf ayah sheet',
    'missing asset, checksum mismatch, copy/storage failure, corrupt DB, failed open',
    'distinct typed states with truthful localized UI + safe retry; never generic “no Tafsir”',
    'tafsirState* strings; retry re-runs verified init',
    're-copy only after checksum verification',
    'test/unit/mushaf_preferences_test.dart (resolver); DB-failure device pass pending',
  ],
  [
    'TAF-03-exact-entry',
    'lib/features/tafsir/presentation/pages/tafsir_page.dart; TafsirReaderPage',
    'open from Mushaf/Surah/search/bookmark/history/deep link at non-first ayah',
    'full reader/preview identifies, scrolls to, highlights exact surah+ayah+source; Back restores origin',
    'highlighted card border + ayah badge',
    'history only on explicit read (TAF-05)',
    'code contract; automated scroll test pending; device pending',
  ],
  [
    'TAF-04-compare-bound',
    'lib/features/quran/presentation/pages/tafsir_reader_page.dart compare mode',
    'forward/back at first/final ayah every surah; partial source set',
    'navigation stays in valid range; per-source available/absent rows; never spins forever',
    'disabled end action with end-label; partial rows informative',
    'none',
    'code contract (verse-count bound + distinct states); widget test pending',
  ],
  [
    'APP-04-hive-owner',
    'lib/main.dart; lib/core/services/hive_service.dart',
    'cold start; init failure; existing store',
    'exactly one Hive.initFlutter owner (HiveService.initialize)',
    'startup proceeds; failures logged non-fatally',
    'existing boxes opened, never wiped',
    'code contract; cold-start timing device pending',
  ],
];
