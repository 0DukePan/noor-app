import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/hive_box_registry.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_hive_registry_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('registered box names are unique', () {
    expect(
      HiveBoxes.allBoxNames.toSet().length,
      HiveBoxes.allBoxNames.length,
    );
  });

  test('registry preserves existing persisted box names', () {
    expect(HiveBoxes.analytics, 'analytics');
    expect(HiveBoxes.offlineQuran, 'quran_offline');
    expect(HiveBoxes.offlineHadith, 'hadith_offline');
    expect(HiveBoxes.hadithProgress, 'hadith_progress');
  });

  test('openAll opens every registered box and closeAll closes them', () async {
    await HiveBoxes.openAll();

    for (final name in HiveBoxes.allBoxNames) {
      expect(Hive.isBoxOpen(name), isTrue, reason: '$name should be open');
    }

    await Hive.box<dynamic>(HiveBoxes.appStatistics).put('verses_read', 1);
    await HiveBoxes.closeAll();

    for (final name in HiveBoxes.allBoxNames) {
      expect(Hive.isBoxOpen(name), isFalse, reason: '$name should be closed');
    }
  });
}
