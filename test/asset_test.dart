import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Decode Quran Assets', () async {
    final surahsStr = await rootBundle.loadString('assets/quran/surahs.json');
    final surahs = jsonDecode(surahsStr);
    expect(surahs, isNotNull);

    final uthmaniStr = await rootBundle.loadString('assets/quran/quran_uthmani.json');
    final uthmani = jsonDecode(uthmaniStr);
    expect(uthmani, isNotNull);
  });

  test('Decode Hadith Asset', () async {
    final bukhariStr = await rootBundle.loadString('assets/hadith/by_book/the_9_books/bukhari.json');
    final bukhari = jsonDecode(bukhariStr);
    expect(bukhari, isNotNull);
  });

  test('Decode Tafsir Asset', () async {
    final tafsirStr = await rootBundle.loadString('assets/tafsir/muyassar/ar-tafsir-muyassar/1.json');
    final tafsir = jsonDecode(tafsirStr);
    expect(tafsir, isNotNull);
  });
}
