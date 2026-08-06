import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/utils/isolate_parser.dart';
import 'dart:convert';

Map<String, dynamic> _myParser(String json, int id, String id2) {
  return jsonDecode(json);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test IsolateParser with Closure', () async {
    int id = 1;
    String id2 = 'muyassar';
    try {
      final result = await IsolateParser.parseInBackground(
        assetPath: 'assets/tafsir/muyassar/ar-tafsir-muyassar/1.json',
        parser: (json) => _myParser(json, id, id2),
      );
      expect(result, isNotNull);
      print('IsolateParser with closure succeeded');
    } catch (e, stack) {
      print('Isolate closure error: \$e');
      print(stack);
      fail('Failed with closure');
    }
  });
}
