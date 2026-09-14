import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/features/quran/data/datasources/remote_quran_data_source.dart';

/// Tests the offline-first remote stub: it must degrade gracefully (empty
/// list / placeholder / null) instead of throwing, since it represents the
/// "no network" branch of the offline-first architecture.
void main() {
  final ds = RemoteQuranDataSourceImpl();

  test('fetchAllSurahs returns an empty list (offline fallback)', () async {
    expect(await ds.fetchAllSurahs(), isEmpty);
  });

  test('fetchTafsir returns a placeholder marking unavailability', () async {
    final t = await ds.fetchTafsir(1, 1, 'muyassar');
    expect(t.surahNumber, 1);
    expect(t.verseNumber, 1);
    expect(t.source, 'muyassar');
    expect(t.briefText, 'التفسير غير متوفر بدون اتصال بالإنترنت');
    expect(t.author, isEmpty);
  });

  test('fetchRevelationCause returns null (offline fallback)', () async {
    expect(await ds.fetchRevelationCause(1, 1), isNull);
  });

  test('syncQuranData is a safe no-op', () async {
    await ds.syncQuranData(); // must not throw
  });
}
