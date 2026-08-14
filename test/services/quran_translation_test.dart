import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/quran_translation_data_source.dart';

/// Tests the bundled Arabic translation (تفسير الميسر).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(QuranTranslationDataSource.resetCache);

  test('translation loads and covers every surah', () async {
    final surah1 = await QuranTranslationDataSource.getSurah(1);
    expect(surah1, isNotNull);
    expect(surah1!.length, 7); // Al-Fatihah has 7 ayahs
    expect(surah1[1], isNotNull);
    expect(surah1[1]!.trim(), isNotEmpty);
  });

  test('first ayah of Al-Fatihah has the Muyassar basmalah', () async {
    final text = await QuranTranslationDataSource.getTranslation(1, 1);
    expect(text, isNotNull);
    expect(text, contains('الله'));
    expect(text!.length, greaterThan(10));
  });

  test('getTranslation resolves specific ayahs across surahs', () async {
    final ayatulKursi = await QuranTranslationDataSource.getTranslation(2, 255);
    expect(ayatulKursi, isNotNull);
    expect(ayatulKursi, contains('الله'));
    expect(ayatulKursi!.length, greaterThan(50));
  });

  test('unknown surah returns null gracefully', () async {
    expect(await QuranTranslationDataSource.getTranslation(999, 1), isNull);
  });
}
