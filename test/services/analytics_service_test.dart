import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:noor_app/core/services/analytics_service.dart';

/// Fake HTTP client recording requests for flush() tests.
class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  http.BaseRequest? lastRequest;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    if (request is http.Request) {
      lastBody = request.body;
    }
    return handler(request);
  }
}

Future<http.StreamedResponse> _ok(http.BaseRequest _) async =>
    http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
    );

Future<http.StreamedResponse> _serverError(http.BaseRequest _) async =>
    http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      500,
    );

/// Tests for AnalyticsService: default-off, allowlisted counting, and the
/// guarded flush path. No network is ever touched (fake client).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_analytics_test');
    Hive.init(tempDir.path);
    await AnalyticsService.init();
  });

  tearDown(() async {
    await AnalyticsService.resetForTest();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('recording is a no-op until the user opts in', () {
    expect(AnalyticsService.optedIn, isFalse);
    AnalyticsService.record('app_open');
    expect(AnalyticsService.count('app_open'), 0);
  });

  test('opt-in persists across re-init and never leaks into snapshots',
      () async {
    await AnalyticsService.setOptedIn(value: true);
    AnalyticsService.record('app_open');
    expect(AnalyticsService.optedIn, isTrue);
    // The internal flag key is not a countable/uploadable counter.
    expect(AnalyticsService.snapshot(), {'app_open': 1});

    // A fresh init (app restart) restores the persisted choice.
    await AnalyticsService.init();
    expect(AnalyticsService.optedIn, isTrue);
    expect(AnalyticsService.count('app_open'), 1);

    await AnalyticsService.setOptedIn(value: false);
    await AnalyticsService.init();
    expect(AnalyticsService.optedIn, isFalse);
  });

  test('opted-in recording counts allowlisted events', () {
    AnalyticsService.optedIn = true;
    AnalyticsService.record('app_open');
    AnalyticsService.record('app_open');
    AnalyticsService.record('surah_opened');
    expect(AnalyticsService.count('app_open'), 2);
    expect(AnalyticsService.count('surah_opened'), 1);
    expect(AnalyticsService.count('prayer_viewed'), 0);
  });

  test('unknown, empty and oversize event names are dropped', () {
    AnalyticsService.optedIn = true;
    AnalyticsService.record('not_a_real_event');
    AnalyticsService.record('');
    AnalyticsService.record('x' * 33);
    expect(AnalyticsService.snapshot(), isEmpty);
  });

  test('snapshot returns a copy, not the live store', () {
    AnalyticsService.optedIn = true;
    AnalyticsService.record('app_open');
    final snap = AnalyticsService.snapshot();
    snap['app_open'] = 999;
    expect(AnalyticsService.count('app_open'), 1);
  });

  test('flush sends nothing without opt-in or endpoint', () async {
    final client = _FakeClient(_ok);
    expect(await AnalyticsService.flush(client: client), isFalse);
    expect(client.lastRequest, isNull);

    AnalyticsService.optedIn = true;
    expect(await AnalyticsService.flush(client: client), isFalse);
    expect(client.lastRequest, isNull);
  });

  test('flush uploads aggregates and clears on 2xx', () async {
    AnalyticsService.optedIn = true;
    AnalyticsService.endpoint = 'https://stats.example.invalid/v1/events';
    AnalyticsService.record('app_open');
    AnalyticsService.record('app_open');
    AnalyticsService.record('qibla_viewed');

    final client = _FakeClient(_ok);
    expect(await AnalyticsService.flush(client: client), isTrue);

    expect(client.lastRequest, isNotNull);
    final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
    expect(
      body['events'],
      {'app_open': 2, 'qibla_viewed': 1},
    );
    // Cleared after a successful upload.
    expect(AnalyticsService.snapshot(), isEmpty);
  });

  test('garbage endpoints send nothing and keep the counts', () async {
    AnalyticsService.optedIn = true;
    AnalyticsService.record('app_open');

    final client = _FakeClient(_ok);
    AnalyticsService.endpoint = 'not a url';
    expect(await AnalyticsService.flush(client: client), isFalse);
    expect(client.lastRequest, isNull);
    expect(AnalyticsService.count('app_open'), 1);
  });

  test('flush keeps the counts when the upload fails', () async {
    AnalyticsService.optedIn = true;
    AnalyticsService.endpoint = 'https://stats.example.invalid/v1/events';
    AnalyticsService.record('app_open');

    final client = _FakeClient(_serverError);
    expect(await AnalyticsService.flush(client: client), isFalse);
    expect(AnalyticsService.count('app_open'), 1);
  });
}
