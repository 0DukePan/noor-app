import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/utils/isolate_parser.dart';

Map<String, dynamic> _myParser(String json, int id, String id2) {
  final decoded = jsonDecode(json);
  // surahs.json decodes to a List; wrap it so the Map contract holds.
  if (decoded is List) {
    return {'count': decoded.length, 'id': id, 'tag': id2};
  }
  return Map<String, dynamic>.from(decoded as Map);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test IsolateParser with Closure', () async {
    const id = 1;
    const id2 = 'quran';
    try {
      final result = await IsolateParser.parseInBackground(
        // A small permanent asset: this test pins isolate mechanics, not any
        // particular corpus (the tafsir JSONs moved to tool/data + tafsir.db).
        assetPath: 'assets/quran/surahs.json',
        parser: (json) => _myParser(json, id, id2),
      );
      expect(result, isNotNull);
    } on Exception catch (e, stack) {
      fail('Failed with closure: $e\n$stack');
    }
  });
}
