import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('Tafsir database asset ships and is non-empty', () async {
    // Content is guarded by test/tafsir_db_integrity_test.dart (checksum +
    // corpus counts); here we only prove the prebuilt asset is bundled.
    final bytes = await rootBundle.load('assets/db/tafsir.db');
    expect(bytes.lengthInBytes, greaterThan(0));
  });
}
