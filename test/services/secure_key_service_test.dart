import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/secure_key_service.dart';

/// SecureKeyService (previously zero-covered): device-derived AES keys with
/// no plugin hardware — the flutter_secure_storage channel is mocked, so
/// these are plain zone-safe tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final written = <String, String>{};
  var stored = <String, String>{};
  var writeCalls = 0;

  setUp(() {
    written.clear();
    stored = {};
    writeCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          final args = call.arguments as Map<dynamic, dynamic>;
          return stored[args['key'] as String];
        case 'write':
          final args = call.arguments as Map<dynamic, dynamic>;
          writeCalls++;
          written[args['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
        case 'deleteAll':
          return null;
        case 'containsKey':
          return false;
        case 'readAll':
          return <String, dynamic>{};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns the stored key without writing', () async {
    stored = {'noor_encryption_key:tadabbur': 'existing-key'};
    final key = await SecureKeyService.getOrCreateKey('tadabbur');
    expect(key, 'existing-key');
    expect(writeCalls, 0);
  });

  test('generates a 32-byte key and persists it when absent', () async {
    final key = await SecureKeyService.getOrCreateKey('tadabbur');
    expect(writeCalls, 1);
    expect(written['noor_encryption_key:tadabbur'], key);
    expect(base64Decode(key), hasLength(32));
  });

  test('empty stored value is treated as absent', () async {
    stored = {'noor_encryption_key:tadabbur': ''};
    final key = await SecureKeyService.getOrCreateKey('tadabbur');
    expect(writeCalls, 1);
    expect(base64Decode(key), hasLength(32));
  });

  test('namespaces are isolated and two generations differ', () async {
    final first = await SecureKeyService.getOrCreateKey('a');
    final second = await SecureKeyService.getOrCreateKey('b');
    expect(written.keys,
        containsAll(['noor_encryption_key:a', 'noor_encryption_key:b']),);
    expect(first, isNot(equals(second)));
  });
}
