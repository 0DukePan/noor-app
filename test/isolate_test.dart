import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/utils/isolate_parser.dart';
import 'dart:convert';

Map<String, dynamic> _myParser(String json, int id, String id2) {
  return jsonDecode(json);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test IsolateParser with Closure', () async {
    const int id = 1;
    const String id2 = 'muyassar';
    try {
      final result = await IsolateParser.parseInBackground(
        assetPath: 'assets/tafsir/muyassar/ar-tafsir-muyassar/1.json',
        parser: (json) => _myParser(json, id, id2),
      );
      expect(result, isNotNull);
    } catch (e, stack) {
      fail('Failed with closure: $e\n$stack');
    }
  });
}
