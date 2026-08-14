import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/quran_audio_engine.dart';

/// Tests the box-backed logic of QuranAudioEngine (progress restore) and the
/// static reciter catalogue — no audio playback involved.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_audio_test');
    Hive.init(tempDir.path);
    // init opens the boxes first, then configures the audio session (which
    // needs platform channels and is unavailable in unit tests) — the boxes
    // are what the logic under test reads.
    try {
      await QuranAudioEngine.init();
    } on Object {
      // Audio session setup is expected to fail in the test environment.
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('reciter catalogue is populated with known reciters', () {
    const reciters = QuranAudioEngine.reciters;
    expect(reciters, isNotEmpty);
    // Expanded catalogue: at least a dozen reciters on the open CDN.
    expect(reciters.length, greaterThanOrEqualTo(12));
    expect(reciters.containsKey('ar.alafasy'), isTrue);
    expect(
      reciters['ar.alafasy']!.baseUrl,
      contains('cdn.islamic.network'),
    );
  });

  test('default reciter is Alafasy', () {
    expect(QuranAudioEngine.currentReciterInfo.id, 'ar.alafasy');
  });

  test('reciter base URLs are all HTTPS', () {
    for (final reciter in QuranAudioEngine.reciters.values) {
      expect(reciter.baseUrl, startsWith('https://'));
    }
  });

  test('getLastPosition returns null when nothing was saved', () async {
    expect(await QuranAudioEngine.getLastPosition(), isNull);
  });

  test('getLastPosition restores the saved resume info', () async {
    final box = await Hive.openBox<dynamic>('audio_progress');
    await box.put('last_position', {
      'surah': 2,
      'ayah': 255,
      'position': 45000,
      'reciter': 'ar.husary',
      'timestamp': '2026-08-01T10:00:00.000',
    });

    final resume = await QuranAudioEngine.getLastPosition();
    expect(resume, isNotNull);
    expect(resume!.surah, 2);
    expect(resume.ayah, 255);
    expect(resume.position, const Duration(milliseconds: 45000));
    expect(resume.reciter, 'ar.husary');
    expect(resume.timestamp, isNotNull);
  });

  test('repeat mode is a plain stateful field', () {
    final before = QuranAudioEngine.repeatMode;
    QuranAudioEngine.repeatMode = RepeatMode.ayah;
    expect(QuranAudioEngine.repeatMode, RepeatMode.ayah);
    QuranAudioEngine.repeatMode = before;
  });
}
