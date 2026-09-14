import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/widget_service.dart';

/// WidgetService (previously zero-covered): the home_widget channel is
/// mocked with an in-memory store, geolocator is denied (Makkah fallback),
/// and Hive runs in a temp dir — plain zone-safe tests throughout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final store = <String, Object?>{};
  var updateCalls = 0;
  var saveCalls = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_widget_test');
    Hive.init(tempDir.path);
    // Same generic type HiveService uses for settings.
    await Hive.openBox<Map<dynamic, dynamic>>('settings');
    store.clear();
    updateCalls = 0;
    saveCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (call) async {
          switch (call.method) {
            case 'saveWidgetData':
              saveCalls++;
              final args = call.arguments as Map<dynamic, dynamic>;
              store[args['id'] as String] = args['data'];
              return null;
            case 'getWidgetData':
              final args = call.arguments as Map<dynamic, dynamic>;
              final id = args['id'] as String;
              return store.containsKey(id)
                  ? store[id]
                  : args['defaultValue'];
            case 'updateWidget':
              updateCalls++;
              return null;
            case 'setAppGroupId':
            case 'registerInteractivityCallback':
              return null;
          }
          return null;
        },
      )
      // Geolocator: denied, service off → Makkah fallback, no GPS wait.
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (call) async {
          if (call.method == 'checkPermission') return 0;
          if (call.method == 'requestPermission') return 0;
          if (call.method == 'isLocationServiceEnabled') return false;
          return null;
        },
      );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(const MethodChannel('home_widget'), null)
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        null,
      );
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('backgroundCallback ignores null and unknown hosts silently', () async {
    await WidgetService.backgroundCallback(null);
    await WidgetService.backgroundCallback(Uri.parse('noor://other'));
    expect(saveCalls, 0);
    expect(updateCalls, 0);
  });

  test('updateQiblaWidget persists the direction', () async {
    await WidgetService.updateQiblaWidget(58.5);
    expect(store['qibla_direction'], 58.5);
    expect(updateCalls, 1);
  });

  test('adhkar widget writes count/target/progress; increment round-trips',
      () async {
    await WidgetService.updateAdhkarWidget();
    expect(store['adhkar_count'], 0);
    expect(store['adhkar_target'], 100);
    expect(store['adhkar_progress'], 0.0);

    await WidgetService.incrementAdhkar();
    expect(store['adhkar_count'], 1);
    expect(store['adhkar_target'], 100);
    expect(store['adhkar_progress'], closeTo(0.01, 1e-9));
  });

  test('prayer widget falls back to Makkah and formats H:MM', () async {
    await WidgetService.updatePrayerWidget();
    final name = store['prayer_name'] as String?;
    final time = store['prayer_time'] as String?;
    final icon = store['prayer_icon'] as String?;
    expect(name, isNotNull);
    expect(name, isNotEmpty);
    expect(time, matches(RegExp(r'^\d{1,2}:\d{2}$')));
    expect(icon, isNotNull);
    expect(updateCalls, 1);
  });

  test('verse widget saves text + reference from the bundled cache',
      () async {
    await WidgetService.updateVerseWidget();
    final text = store['verse_text'] as String?;
    final reference = store['verse_reference'] as String?;
    // Guards the ayahs/verses shape regression: the bundled cache stores
    // verses under 'verses', which the widget must accept.
    expect(text, isNotNull);
    expect(text, isNotEmpty);
    expect(text!.length, lessThanOrEqualTo(103));
    expect(reference, contains('آية'));
    expect(updateCalls, 1);
  });
}
