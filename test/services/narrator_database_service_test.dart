import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/isnad_parser_service.dart';
import 'package:noor_app/core/services/narrator_database_service.dart';

/// Tests for NarratorDatabaseService against the real bundled asset
/// (assets/hadith/narrators.json, 63 narrators), plus the lookup /
/// normalization / profile-getter behaviour.
bool _hasHamza(String s) =>
    s.contains('أ') || s.contains('إ') || s.contains('آ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NarratorDatabaseService', () {
    setUpAll(() async {
      await NarratorDatabaseService.init();
    });

    test('init loads the bundled narrator database', () {
      expect(NarratorDatabaseService.allNarrators.length, 63);
    });

    test('every narrator has a non-empty name', () {
      for (final n in NarratorDatabaseService.allNarrators) {
        expect(n.name, isNotEmpty, reason: 'narrator name must not be empty');
      }
    });

    test('data integrity: one Prophet, 23 Companions, 62 known death years',
        () {
      final all = NarratorDatabaseService.allNarrators;
      expect(all.where((n) => n.isProphet).length, 1);
      expect(all.where((n) => n.isCompanion).length, 23);
      // Only the Prophets' death year is unrecorded (0) in this dataset.
      expect(all.where((n) => n.deathYear > 0).length, 62);
    });

    test('citation guard: every Ilm al-Rijal claim carries a source', () {
      // Policy: scholarly fields (tadlis, ikhtilat, verdictSource) must never
      // be populated without a citation — and are currently left empty rather
      // than fabricated. This guard fails the suite if anyone adds a claim
      // without its source.
      for (final n in NarratorDatabaseService.allNarrators) {
        final hasClaim = n.tadlis.isNotEmpty ||
            n.ikhtilat.isNotEmpty ||
            n.verdictSource.isNotEmpty;
        if (hasClaim) {
          expect(
            n.verdictSource,
            isNotEmpty,
            reason:
                '${n.name}: an Ilm al-Rijal claim requires a source (verdictSource)',
          );
        }
        // Every narrator currently ships with no populated verdicts — honest
        // emptiness is the policy, and any future claim must flip this.
        expect(
          n.tadlis,
          isEmpty,
          reason: '${n.name}: tadlis must be empty until sourced',
        );
        expect(
          n.ikhtilat,
          isEmpty,
          reason: '${n.name}: ikhtilat must be empty until sourced',
        );
      }
    });

    test('lookup by exact name returns the same narrator', () {
      final all = NarratorDatabaseService.allNarrators;
      for (final n in all.take(5)) {
        final hit = NarratorDatabaseService.lookup(n.name);
        expect(hit, isNotNull, reason: 'self-lookup of ${n.name}');
        expect(hit!.name, n.name);
      }
    });

    test('lookup by any alias returns the same narrator', () {
      final all = NarratorDatabaseService.allNarrators;
      for (final n in all.take(5)) {
        if (n.aliases.isEmpty) continue;
        final hit = NarratorDatabaseService.lookup(n.aliases.first);
        expect(hit, isNotNull, reason: 'alias lookup of ${n.aliases.first}');
        expect(hit!.name, n.name);
      }
    });

    test('lookup normalises hamza/taa-marbuta variants of the same name', () {
      final all = NarratorDatabaseService.allNarrators;
      // Take narrators whose name contains a normalizable letter.
      final withHamza = all.where((n) => _hasHamza(n.name)).toList();
      expect(withHamza, isNotEmpty);

      final n = withHamza.first;
      final variant =
          n.name.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
      final hit = NarratorDatabaseService.lookup(variant);
      expect(hit, isNotNull, reason: 'normalized variant of ${n.name}');
      expect(hit!.name, n.name);
    });

    test('lookup returns null for unknown or empty names', () {
      // 'فلان بن علان' shares no token with any real narrator, so even the
      // fuzzy partial match must miss it.
      expect(NarratorDatabaseService.lookup('فلان بن علان'), isNull);
      expect(NarratorDatabaseService.lookup(''), isNull);
      expect(NarratorDatabaseService.lookup('   '), isNull);
    });

    test('lookupFromNarratorInfo matches via the normalized name', () {
      final all = NarratorDatabaseService.allNarrators;
      final n = all.first;
      final info = NarratorInfo(
        name: n.name,
        normalizedName: n.name,
        role: n.role,
        isProphet: n.isProphet,
        isCompanion: n.isCompanion,
        level: 0,
      );
      final hit = NarratorDatabaseService.lookupFromNarratorInfo(info);
      expect(hit, isNotNull);
      expect(hit!.name, n.name);
    });

    test('Prophet profile: isProphet true, death year 11 AH, no rank', () {
      final prophet =
          NarratorDatabaseService.allNarrators.firstWhere((n) => n.isProphet);
      expect(prophet.isCompanion, isFalse);
      expect(prophet.deathYear, 11);
      expect(prophet.deathYearDisplay, '11 هـ');
      expect(prophet.rank, isEmpty);
    });

    test('profile display getters and toString', () {
      final all = NarratorDatabaseService.allNarrators;

      // A companion is classified as such and displays a known death year.
      final companion = all.firstWhere((n) => n.isCompanion && n.deathYear > 0);
      expect(companion.isCompanion, isTrue);
      expect(companion.deathYearDisplay, '${companion.deathYear} هـ');
      expect(
        companion.birthYearDisplay,
        companion.birthYear > 0 ? '${companion.birthYear} هـ' : 'غير معلوم',
      );

      // The one narrator without a recorded death year shows 'غير معلوم'.
      final noDeath = all.firstWhere((n) => n.deathYear == 0);
      expect(noDeath.deathYearDisplay, 'غير معلوم');

      expect(companion.toString(), startsWith('NarratorProfile('));
    });
  });
}
